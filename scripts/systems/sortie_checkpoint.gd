class_name SortieCheckpoint
extends RefCounted
## Versioned JSON state, not a PackedScene or executable Variant. Only explicit
## gameplay fields are persisted; original geometry, materials and rigs are untouched.
const VERSION := 4
const PLAYER_FIELDS := ["position", "rotation", "velocity", "health", "aim_direction", "aim_world_point", "_shot_cooldown", "_dodge_time", "_dodge_cooldown_time", "_dodge_direction", "_move_direction"]
const ENEMY_FIELDS := ["position", "rotation", "velocity", "health", "_shot_cooldown", "_path_refresh", "_knockback_velocity", "_strafe_direction", "_is_telegraphing", "_engaged", "_movement_direction", "_shot_aim_point", "visible", "collision_layer", "collision_mask"]
const AWARENESS_FIELDS := ["initialized", "state", "home", "home_forward", "last_known", "suspicion", "memory_remaining", "search_elapsed", "patrol_index", "patrol_wait", "target_visible"]
const TACTICS_FIELDS := ["role", "has_plan", "goal", "planned_contact", "plan_remaining"]
const DIRECTOR_FIELDS := ["stage", "start_position", "start_aim", "moved_distance", "last_position", "elapsed", "reload_seen", "fired", "patrol_looted", "bonus_looted", "reinforcements_remaining"]
const ROCKET_FIELDS := ["position", "rotation", "direction", "speed", "damage", "armor_penetration", "structure_damage", "blast_radius", "knockback", "traveled", "max_distance"]
const ROCKET_SCRIPT := preload("res://scripts/combat/rocket_projectile.gd")
const TERMINAL_SCRIPT := preload("res://scripts/first_mission/terminal.gd")
const EXTRACTION_SCRIPT := preload("res://scripts/first_mission/extraction.gd")
const POSE_FIELDS := ["transform"]
const HUMAN_FIRE_FIELDS := ["_aim_point", "_shot_remaining", "_move_speed"]
const KITE_FIRE_FIELDS := ["elapsed", "_recoil", "_pose_initialized", "_move_speed"]

static func integer(value: Variant, low := 0, high := 1000000000) -> bool:
	return SaveService.is_number(value) and value >= low and value <= high and floor(value) == value

static func session_data(session: SortieSession) -> Dictionary:
	var rounds := {}
	for id in session._weapon_runtime_states:
		var weapon = session._weapon_runtime_states[id]
		rounds[id] = {"ammo": String(weapon.ammo_definition_id), "capacity": weapon.magazine_capacity, "rounds": weapon.magazine_ammo}
	return {"q04_active": session.q04_active, "delivery_receipt": session.delivery_receipt, "q02_active": session.q02_active, "pharmacy_batch": session.pharmacy_batch, "slice_context": session.slice_context.duplicate(true), "exit_observations": session.exit_observations.duplicate(), "id": session.session_id, "status": session.status, "area": String(session.area_id), "mission": String(session.mission_id), "inventory": session.inventory.to_dict(), "loadout": session.loadout.to_dict(), "initial_ids": session.get_initial_carried_instance_ids(), "objectives": session.get_objective_summary(), "mission_completed": session.mission_completed, "kills": session.enemies_defeated, "damage": session.damage_taken, "upgrade": session.ar_damage_upgraded, "threat": session.threat_level, "weapons": rounds}

static func restore_session(data: Dictionary) -> SortieSession:
	for key in ["id", "area", "mission"]:
		if typeof(data.get(key)) != TYPE_STRING or data[key].is_empty(): return null
	for key in ["inventory", "loadout", "weapons"]:
		if typeof(data.get(key)) != TYPE_DICTIONARY: return null
	for key in ["initial_ids", "objectives"]:
		if typeof(data.get(key)) != TYPE_ARRAY: return null
	for key in ["mission_completed", "upgrade"]:
		if typeof(data.get(key)) != TYPE_BOOL: return null
	if not integer(data.get("status"), 1, 4) or not integer(data.get("threat"), 0, 1) or not integer(data.get("kills")) or not integer(data.get("damage")): return null
	var ids: Array[String] = []
	for id in data.initial_ids:
		if typeof(id) != TYPE_STRING or id.is_empty() or id in ids: return null
		ids.append(id)
	var inventory := InventoryState.from_dict(data.inventory)
	var loadout := LoadoutState.from_dict(data.loadout)
	if not inventory or not loadout or not inventory.validate() or not loadout.validate(inventory): return null
	if not ContentDB.get_area_definition(StringName(data.area), false): return null
	var session := SortieSession.new(inventory, loadout, StringName(data.area), StringName(data.mission), data.id, ids)
	if not NarrativeSlice.valid_q04(data.get("q04_active", false), data.get("delivery_receipt", ""), session.area_id): return null
	session.q04_active = data.get("q04_active", false)
	session.delivery_receipt = data.get("delivery_receipt", "")
	if typeof(data.get("q02_active", false)) != TYPE_BOOL: return null
	if not NarrativeSlice.valid_pharmacy(data.get("q02_active", false) or session.q04_active, data.get("pharmacy_batch", ""), session.area_id): return null
	session.q02_active = data.get("q02_active", false)
	session.pharmacy_batch = data.get("pharmacy_batch", "")
	var context: Variant = data.get("slice_context", {})
	var observations: Variant = data.get("exit_observations", [])
	if not NarrativeSlice.valid_facts(context, observations, session.area_id): return null
	session.slice_context = context.duplicate(true)
	for id in observations: session.exit_observations.append(id)
	session.status = int(data.status)
	session.threat_level = int(data.threat)
	session.mission_completed = data.mission_completed
	session.ar_damage_upgraded = data.upgrade
	session.enemies_defeated = int(data.kills)
	session.damage_taken = int(data.damage)
	session.objective_states.clear()
	for raw in data.objectives:
		if typeof(raw) != TYPE_DICTIONARY: return null
		for key in ["objective_type", "status", "progress", "target"]:
			if not integer(raw.get(key)): return null
		if typeof(raw.get("required")) != TYPE_BOOL or typeof(raw.get("objective_id")) != TYPE_STRING or typeof(raw.get("target_id")) != TYPE_STRING: return null
		var state := ObjectiveState.from_dict(raw)
		if not state: return null
		session.objective_states.append(state)
	if not session._initialize_weapon_runtime_state() or session._weapon_runtime_states.size() != data.weapons.size(): return null
	for id in session._weapon_runtime_states:
		var weapon = session._weapon_runtime_states[id]
		var saved: Variant = data.weapons.get(id)
		if typeof(saved) != TYPE_DICTIONARY: return null
		if saved.get("ammo") != String(weapon.ammo_definition_id) or saved.get("capacity") != weapon.magazine_capacity or not integer(saved.get("rounds"), 0, weapon.magazine_capacity): return null
		weapon.magazine_ammo = int(saved.rounds)
	session._sync_loaded_weight()
	return session if session.validate() else null

static func fields(object: Object, names: Array) -> Dictionary:
	var result := {}
	for key in names:
		var value: Variant = object.get(key)
		if value is Vector3: result[key] = [value.x, value.y, value.z]
		elif value is Transform3D:
			result[key] = [value.basis.x.x, value.basis.x.y, value.basis.x.z, value.basis.y.x, value.basis.y.y, value.basis.y.z, value.basis.z.x, value.basis.z.y, value.basis.z.z, value.origin.x, value.origin.y, value.origin.z]
		else: result[key] = value
	return result

static func valid_fields(data: Variant, object: Object, names: Array) -> bool:
	if typeof(data) != TYPE_DICTIONARY or data.size() != names.size(): return false
	for key in names:
		var original: Variant = object.get(key)
		var value: Variant = data.get(key)
		match typeof(original):
			TYPE_TRANSFORM3D:
				if typeof(value) != TYPE_ARRAY or value.size() != 12: return false
				for coordinate in value:
					if not SaveService.is_number(coordinate) or abs(coordinate) > 1000000: return false
				if absf(_transform(value).basis.determinant()) < 0.000001: return false
			TYPE_VECTOR3:
				if typeof(value) != TYPE_ARRAY or value.size() != 3: return false
				for coordinate in value:
					if not SaveService.is_number(coordinate) or abs(coordinate) > 1000000: return false
			TYPE_INT:
				if not integer(value, -1000000000): return false
			TYPE_FLOAT:
				if not SaveService.is_number(value) or abs(value) > 1000000000: return false
			TYPE_BOOL:
				if typeof(value) != TYPE_BOOL: return false
			_: return false
	return true

static func apply_fields(data: Dictionary, object: Object, names: Array) -> void:
	for key in names:
		var value: Variant = data[key]
		if object.get(key) is Vector3: value = Vector3(value[0], value[1], value[2])
		elif object.get(key) is Transform3D: value = _transform(value)
		elif typeof(object.get(key)) == TYPE_INT: value = int(value)
		object.set(key, value)

static func _transform(value: Array) -> Transform3D:
	return Transform3D(Basis(Vector3(value[0], value[1], value[2]), Vector3(value[3], value[4], value[5]), Vector3(value[6], value[7], value[8])), Vector3(value[9], value[10], value[11]))

static func _world_nodes(battle: Node) -> Dictionary:
	var nodes := {}
	for node in battle.area_root.find_children("*", "", true, false):
		if node is Door or node is DestructibleWorldObject or node is ThreatEvent or node is LootSpawnPoint or node is EnemySpawnPoint or node is ExtractionPoint or node is RelayStation or node.get_script() == TERMINAL_SCRIPT:
			nodes[String(battle.area_root.get_path_to(node))] = node
	return nodes

static func _node_fields(node: Node) -> Array:
	if node is RelayStation: return ["remaining", "start_damage"]
	if node is Door: return ["state"]
	if node is DestructibleWorldObject: return ["current_structure_health", "destroyed"]
	if node is ThreatEvent: return ["triggered", "reinforcement_spawned"]
	if node is EnemySpawnPoint: return ["has_spawned"]
	if node is LootSpawnPoint: return ["position", "visible", "enabled", "has_rolled"]
	if node.get_script() == EXTRACTION_SCRIPT: return ["available", "extraction_remaining"]
	if node is ExtractionPoint: return ["available"]
	if node.get_script() == TERMINAL_SCRIPT: return ["investigation_remaining"]
	return []

static func layout_signature(area: Node3D) -> String:
	# Captured once before restoration. Detect changed authored collision/navigation,
	# not generated node IDs, resource RIDs or render-only details.
	var parts: Array[String] = []
	for node in area.find_children("*", "CollisionShape3D", true, false):
		var shape: Shape3D = node.shape
		if not shape: continue
		var dimensions := ""
		if shape is BoxShape3D: dimensions = str(shape.size)
		elif shape is SphereShape3D: dimensions = str(shape.radius)
		elif shape is CapsuleShape3D or shape is CylinderShape3D: dimensions = str([shape.radius, shape.height])
		elif shape is ConcavePolygonShape3D: dimensions = str(shape.get_faces())
		elif shape is ConvexPolygonShape3D: dimensions = str(shape.points)
		parts.append(str([shape.get_class(), dimensions, node.global_transform]))
	for node in area.find_children("*", "NavigationRegion3D", true, false):
		if node.navigation_mesh: parts.append(str(node.navigation_mesh.vertices))
	parts.sort()
	return "\n".join(parts).sha256_text()

static func _firing_pose(enemy: EnemyController) -> Dictionary:
	var visual = enemy.presentation
	var human := enemy.humanoid_presentation
	var bones := {}
	if human:
		var skeleton: Skeleton3D = visual.model.find_child("Skeleton3D", true, false)
		for index in skeleton.get_bone_count():
			var p := skeleton.get_bone_pose_position(index)
			var q := skeleton.get_bone_pose_rotation(index)
			var s := skeleton.get_bone_pose_scale(index)
			bones[skeleton.get_bone_name(index)] = [p.x, p.y, p.z, q.x, q.y, q.z, q.w, s.x, s.y, s.z]
	return {"human": human, "body": fields(visual, POSE_FIELDS), "pose": fields(visual.model if human else visual.weapon_pose_root, POSE_FIELDS), "state": fields(visual, HUMAN_FIRE_FIELDS if human else KITE_FIRE_FIELDS), "clip": String(visual.animation_player.current_animation) if human else "", "time": visual.animation_player.current_animation_position if human else 0.0, "bones": bones, "hit_elapsed": enemy._hit_tween.get_total_elapsed_time() if enemy._hit_tween and enemy._hit_tween.is_valid() and enemy._hit_tween.is_running() else -1.0, "hit_side": enemy._hit_reaction_side}

static func _valid_firing_pose(raw: Variant, human: bool, battle: Node) -> bool:
	if typeof(raw) != TYPE_DICTIONARY or typeof(raw.get("human")) != TYPE_BOOL or raw.human != human: return false
	var visual: Node3D = HumanoidEnemyPresentation.new() if human else KiteEnemyPresentation.new()
	var valid := valid_fields(raw.get("body"), visual, POSE_FIELDS) and valid_fields(raw.get("pose"), visual, POSE_FIELDS) and valid_fields(raw.get("state"), visual, HUMAN_FIRE_FIELDS if human else KITE_FIRE_FIELDS)
	visual.free()
	if not valid or typeof(raw.get("clip")) != TYPE_STRING or not SaveService.is_number(raw.get("time")) or raw.time < 0 or raw.time > 3600: return false
	if human and raw.clip not in ["Idle_Gun_Pointing", "Run_Shoot", "Gun_Shoot"]: return false
	if typeof(raw.get("bones")) != TYPE_DICTIONARY: return false
	if human:
		var skeletons: Array = battle.enemy_container.find_children("*", "Skeleton3D", true, false)
		if skeletons.is_empty() or raw.bones.size() != skeletons[0].get_bone_count(): return false
		for bone in raw.bones:
			var value: Variant = raw.bones[bone]
			if typeof(bone) != TYPE_STRING or skeletons[0].find_bone(bone) < 0 or typeof(value) != TYPE_ARRAY or value.size() != 10: return false
			for number in value:
				if not SaveService.is_number(number) or abs(number) > 10000: return false
			if not is_equal_approx(Quaternion(value[3], value[4], value[5], value[6]).length(), 1.0): return false
	elif not raw.bones.is_empty(): return false
	if not SaveService.is_number(raw.get("hit_elapsed")) or raw.hit_elapsed < -1 or raw.hit_elapsed > 1 or not SaveService.is_number(raw.get("hit_side")) or abs(raw.hit_side) > 1: return false
	return true

static func _restore_firing_pose(saved: Dictionary, enemy: EnemyController) -> void:
	var visual = enemy.presentation
	if saved.hit_elapsed >= 0:
		enemy._flash_hit(Vector3(-0.01 if saved.hit_side == 0 else saved.hit_side, 0, 0))
		enemy._hit_tween.custom_step(saved.hit_elapsed)
	apply_fields(saved.body, visual, POSE_FIELDS)
	apply_fields(saved.pose, visual.model if enemy.humanoid_presentation else visual.weapon_pose_root, POSE_FIELDS)
	apply_fields(saved.state, visual, HUMAN_FIRE_FIELDS if enemy.humanoid_presentation else KITE_FIRE_FIELDS)
	if enemy.humanoid_presentation:
		visual.animation_player.play(saved.clip)
		visual.animation_player.seek(saved.time, true)
		# A clip/time alone loses an in-progress blend and shifts the attached pistol.
		# Restore the sampled animation pose, not the authored rest/skin/geometry.
		var skeleton: Skeleton3D = visual.model.find_child("Skeleton3D", true, false)
		for name in saved.bones:
			var index := skeleton.find_bone(name)
			var value: Array = saved.bones[name]
			skeleton.set_bone_pose_position(index, Vector3(value[0], value[1], value[2]))
			skeleton.set_bone_pose_rotation(index, Quaternion(value[3], value[4], value[5], value[6]))
			skeleton.set_bone_pose_scale(index, Vector3(value[7], value[8], value[9]))
		skeleton.force_update_all_bone_transforms()
		skeleton.advance(0.0)
		for attachment in skeleton.find_children("*", "BoneAttachment3D", true, false):
			attachment.on_skeleton_update()

static func capture_world(battle: Node) -> Dictionary:
	var enemies := {}
	for enemy in battle.enemy_container.get_children():
		if not enemy is EnemyController or enemy.is_dead or enemy.is_queued_for_deletion(): continue
		var entry := fields(enemy, ENEMY_FIELDS)
		entry["physics"] = enemy.is_physics_processing()
		entry["shot_remaining"] = maxf(0.000001, enemy._shot_timer.time_left) if enemy._shot_timer else 0.0
		entry["firing"] = _firing_pose(enemy)
		enemy.ensure_awareness()
		entry["awareness"] = fields(enemy.awareness, AWARENESS_FIELDS)
		entry["tactics"] = fields(enemy.tactics, TACTICS_FIELDS)
		enemies[enemy.get_meta("spawn_key")] = entry
	var nodes := {}
	var objects := _world_nodes(battle)
	for path in objects:
		var node: Node = objects[path]
		var entry := fields(node, _node_fields(node))
		if node is LootSpawnPoint:
			entry["items"] = []
			for pickup in node.get_children():
				if pickup is LootPickup and not pickup.consumed and not pickup.is_queued_for_deletion():
					entry.items.append({"item": pickup.item_instance.to_dict(), "interactable": pickup.is_in_group("interactable")})
		nodes[path] = entry
	var rockets: Array = []
	for node in battle.get_children():
		if node.get_script() != ROCKET_SCRIPT or node.is_queued_for_deletion(): continue
		var entry := fields(node, ROCKET_FIELDS)
		entry["weapon"] = String(node.source_weapon)
		rockets.append(entry)
	var director: Node = battle.get_node_or_null("FirstMissionDirector")
	var alarm: RecordsAlarm = battle.area_root.get_node_or_null("StreetTerminal/RecordsAlarm")
	var records: RecordsTerminal = battle.area_root.get_node_or_null("StreetTerminal")
	return {"q04_active": battle.session.q04_active, "delivery_receipt": battle.session.delivery_receipt, "q02_active": battle.session.q02_active, "pharmacy_batch": battle.session.pharmacy_batch, "slice_context": battle.session.slice_context.duplicate(true), "exit_observations": battle.session.exit_observations.duplicate(), "records_work": records.snapshot() if records else {}, "records_alarm": alarm.snapshot() if alarm else {}, "layout": battle.checkpoint_layout_signature, "player": fields(battle.player, PLAYER_FIELDS), "footstep_distance": battle.player._footstep_distance, "medical": battle.player.medical.snapshot(), "weapon_slot": String(battle.player.active_weapon_slot), "reloads": battle.player._reload_remaining_by_weapon.duplicate(), "enemies": enemies, "nodes": nodes, "rockets": rockets, "director": fields(director, DIRECTOR_FIELDS) if director else {}}

static func validate_world(data: Dictionary, battle: Node) -> bool:
	if not NarrativeSlice.world_matches(data, battle.session): return false
	if typeof(data.get("nodes")) != TYPE_DICTIONARY: return false
	if not battle.session.slice_context.is_empty():
		var assigned := {}
		for exit in battle.area_root.find_children("*", "ExtractionPoint", true, false):
			var path := String(battle.area_root.get_path_to(exit))
			var saved: Variant = data.get("nodes", {}).get(path)
			if typeof(saved) != TYPE_DICTIONARY: return false
			if saved.get("available", false): assigned[String(exit.extraction_id)] = String(exit.required_objective_id)
		if assigned != battle.session.slice_context.exit_conditions: return false
	if not RecordsAlarm.valid_snapshot(data.get("records_alarm", {})): return false
	var work: Variant = data.get("records_work", {})
	if not RecordsTerminal.valid_snapshot(work): return false
	if not battle.area_root.has_node("StreetTerminal") and not work.is_empty(): return false
	if not work.is_empty() and work.remaining > 0:
		var objective: ObjectiveState = battle.session.get_objective_state(&"streets_terminal")
		if not objective or objective.status == ObjectiveState.Status.COMPLETED: return false
		if work.urgent and data.get("records_alarm",{}).get("phase") != RecordsAlarm.Phase.SOUNDED: return false
	if not battle.area_root.has_node("StreetTerminal/RecordsAlarm") and not data.get("records_alarm", {}).is_empty(): return false
	if typeof(data.get("layout")) != TYPE_STRING or data.layout != battle.checkpoint_layout_signature: return false
	if not valid_fields(data.get("player"), battle.player, PLAYER_FIELDS): return false
	if data.player.health <= 0 or data.player.health > battle.player.max_health: return false
	if not SaveService.is_number(data.get("footstep_distance", 0.0)) or data.get("footstep_distance", 0.0) < 0.0 or data.get("footstep_distance", 0.0) >= 1.4: return false
	if not battle.player.medical.valid_snapshot(data.get("medical", {})): return false
	if typeof(data.get("weapon_slot")) != TYPE_STRING or not battle.player.get_weapon_instance(StringName(data.weapon_slot)): return false
	for key in ["reloads", "enemies", "nodes", "director"]:
		if typeof(data.get(key)) != TYPE_DICTIONARY: return false
	if typeof(data.get("rockets")) != TYPE_ARRAY or data.rockets.size() > 128: return false
	for id in data.reloads:
		if not battle.session.get_weapon_runtime_state(id) or not SaveService.is_number(data.reloads[id]) or data.reloads[id] < 0 or data.reloads[id] > 120: return false
	var objects := _world_nodes(battle)
	if objects.size() != data.nodes.size(): return false
	var item_ids := {}
	for path in objects:
		var node: Node = objects[path]
		var raw: Variant = data.nodes.get(path)
		if typeof(raw) != TYPE_DICTIONARY: return false
		var entry: Dictionary = raw.duplicate(true)
		if node is LootSpawnPoint:
			if typeof(entry.get("items")) != TYPE_ARRAY or entry.items.size() > 64: return false
			for pickup in entry.items:
				if typeof(pickup) != TYPE_DICTIONARY or typeof(pickup.get("item")) != TYPE_DICTIONARY or typeof(pickup.get("interactable")) != TYPE_BOOL: return false
				var item := ItemInstance.from_dict(pickup.item)
				if not item or item.instance_id.is_empty() or not ContentDB.has_item(item.definition_id) or item_ids.has(item.instance_id) or battle.session.inventory.contains(item.instance_id): return false
				item_ids[item.instance_id] = true
			entry.erase("items")
		if not valid_fields(entry, node, _node_fields(node)): return false
		if node is RelayStation:
			if entry.remaining < 0 or entry.remaining > RelayStation.DURATION or entry.start_damage < 0 or entry.start_damage > battle.session.damage_taken: return false
			var state: ObjectiveState = battle.session.get_objective_state(node.objective_id)
			if not state or (entry.remaining > 0 and state.status == ObjectiveState.Status.COMPLETED): return false
		if node is Door and not integer(entry.state, 0, 1): return false
		if node is DestructibleWorldObject and (entry.current_structure_health < 0 or entry.current_structure_health > node.max_structure_health or entry.destroyed != (entry.current_structure_health == 0)): return false
		for timer in ["investigation_remaining", "extraction_remaining"]:
			if entry.has(timer) and (entry[timer] < 0 or entry[timer] > 8): return false
	for path in data.enemies:
		var point: Node = objects.get(path)
		if not point is EnemySpawnPoint or not data.nodes[path].has_spawned: return false
		if typeof(data.enemies[path]) != TYPE_DICTIONARY: return false
		var entry: Dictionary = data.enemies[path].duplicate()
		if typeof(entry.get("physics")) != TYPE_BOOL or not SaveService.is_number(entry.get("shot_remaining")) or entry.shot_remaining < 0 or entry.shot_remaining > 0.38: return false
		if entry.get("_is_telegraphing") != (entry.shot_remaining > 0): return false
		entry.erase("physics")
		entry.erase("shot_remaining")
		var template := EnemyController.new()
		var definition := ContentDB.get_enemy_definition(point.enemy_definition_id, false)
		var firing_valid := _valid_firing_pose(entry.get("firing"), definition.humanoid_presentation, battle)
		entry.erase("firing")
		var awareness_valid := valid_awareness(entry.get("awareness", {}))
		entry.erase("awareness")
		var role: int = point.tactical_role if point.tactical_role >= 0 else definition.tactical_role
		var tactics_valid := valid_tactics(entry.get("tactics", {}), role)
		entry.erase("tactics")
		var valid: bool = valid_fields(entry, template, ENEMY_FIELDS) and entry.health > 0 and entry.health <= definition.max_health
		template.free()
		if not valid or not firing_valid or not awareness_valid or not tactics_valid: return false
	for raw in data.rockets:
		if typeof(raw) != TYPE_DICTIONARY or typeof(raw.get("weapon")) != TYPE_STRING or not ContentDB.get_weapon(StringName(raw.weapon), false): return false
		var entry: Dictionary = raw.duplicate()
		entry.erase("weapon")
		var template := ROCKET_SCRIPT.new()
		var valid := valid_fields(entry, template, ROCKET_FIELDS)
		template.free()
		if not valid or entry.speed <= 0 or entry.traveled < 0 or entry.traveled >= entry.max_distance or entry.damage < 0 or entry.blast_radius <= 0: return false
	var director: Node = battle.get_node_or_null("FirstMissionDirector")
	if director:
		if not valid_fields(data.director, director, DIRECTOR_FIELDS) or data.director.stage < 0 or data.director.stage > 9: return false
		if data.director.stage <= director.Stage.PMC and not data.enemies.has(director.patrol.get_meta("spawn_key")): return false
	elif not data.director.is_empty(): return false
	return true

static func restore_world(data: Dictionary, battle: Node) -> bool:
	# Validate the entire snapshot against the instantiated layout BEFORE mutation.
	if not validate_world(data, battle): return false
	var alarm: RecordsAlarm = battle.area_root.get_node_or_null("StreetTerminal/RecordsAlarm")
	if alarm: alarm.restore(data.get("records_alarm", {}),battle.session)
	apply_fields(data.player, battle.player, PLAYER_FIELDS)
	var records: RecordsTerminal = battle.area_root.get_node_or_null("StreetTerminal")
	if records: records.restore(data.get("records_work", {}),battle.player,battle.session)
	battle.player._footstep_distance = data.get("footstep_distance", 0.0)
	battle.player._reload_remaining_by_weapon = data.reloads.duplicate()
	battle.player._activate_weapon_slot(StringName(data.weapon_slot))
	battle.player.clear_buffered_input()
	battle.player.medical.restore(data.get("medical", {}))
	var objects := _world_nodes(battle)
	var director: Node = battle.get_node_or_null("FirstMissionDirector")
	for path in objects:
		var node: Node = objects[path]
		var entry: Dictionary = data.nodes[path]
		apply_fields(entry, node, _node_fields(node))
		if node is RelayStation:
			node.bind_actor(battle.player,battle.session)
		if node is Door: node._apply_state()
		if node is DestructibleWorldObject:
			node.visual.visible = not node.destroyed
			node.collision_shape.disabled = node.destroyed
		if node.get_script() in [TERMINAL_SCRIPT, EXTRACTION_SCRIPT]:
			node.actor = battle.player
			node.active_session = battle.session
		if node is LootSpawnPoint:
			for child in node.get_children():
				if child is LootPickup: child.free()
			for saved in entry.items:
				var pickup := LootSpawnPoint.LOOT_PICKUP_SCENE.instantiate() as LootPickup
				pickup.setup(ItemInstance.from_dict(saved.item))
				node.add_child(pickup)
				if not saved.interactable: pickup.remove_from_group("interactable")
				if director: pickup.picked_up.connect(director._on_pickup.bind(node.name == "HighValueLootSpawn"))
	var live := {}
	for enemy in battle.enemy_container.get_children():
		if enemy is EnemyController:
			var key: String = enemy.get_meta("spawn_key")
			if data.enemies.has(key): live[key] = enemy
			else: enemy.free() # No death callback, kill credit or rerolled salvage.
	for path in data.enemies:
		var enemy: EnemyController = live.get(path)
		if not enemy:
			objects[path].has_spawned = false
			enemy = battle._spawn_enemy_at_point(objects[path])
		var entry: Dictionary = data.enemies[path]
		apply_fields(entry, enemy, ENEMY_FIELDS)
		enemy.set_physics_process(entry.physics)
		enemy.target = battle.player
		if not entry.get("awareness", {}).is_empty():
			apply_fields(entry.awareness, enemy.awareness, AWARENESS_FIELDS)
		else:
			# Pre-perception checkpoints had no trustworthy last-known position.
			# Keep actor/shot state, start a local patrol instead of inventing intel.
			enemy.awareness = EnemyAwareness.new()
			enemy.ensure_awareness()
		if not entry.get("tactics", {}).is_empty():
			apply_fields(entry.tactics, enemy.tactics, TACTICS_FIELDS)
		else:
			enemy.tactics = EnemyTactics.new()
			var point: EnemySpawnPoint = objects[path]
			enemy.tactics.role = point.tactical_role if point.tactical_role >= 0 else ContentDB.get_enemy_definition(point.enemy_definition_id).tactical_role
		# Older snapshots keep the authored duty, with no fabricated flank plan.
		enemy.navigation_agent.target_position = enemy.tactics.current_destination(enemy)
		enemy._update_awareness_indicator()
		_restore_firing_pose(entry.firing, enemy)
		if entry.shot_remaining > 0: enemy._finish_telegraphed_shot(entry.shot_remaining)
	battle.enemies_remaining = data.enemies.size()
	for saved in data.rockets:
		var rocket := PlayerController.ROCKET_SCENE.instantiate()
		apply_fields(saved, rocket, ROCKET_FIELDS)
		rocket.shooter = battle.player
		rocket.source_weapon = StringName(saved.weapon)
		battle.add_child(rocket)
	if director:
		apply_fields(data.director, director, DIRECTOR_FIELDS)
		director.choice_buttons.visible = director.stage == director.Stage.CHOICE
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if director.choice_buttons.visible else Input.MOUSE_MODE_HIDDEN
		director._refresh_guide()
		director._refresh_destination()
	battle._last_health = battle.player.health
	battle.hud.set_health(battle.player.health, battle.player.max_health)
	battle.hud.set_enemy_count(battle.enemies_remaining)
	battle.camera.position = battle.player.position + Vector3.UP * 0.85 + Vector3(0.0, 18.2, 13.7)
	return true

static func valid_awareness(raw: Variant) -> bool:
	if typeof(raw) != TYPE_DICTIONARY: return false
	if raw.is_empty(): return true # Version 1 checkpoint before perception existed.
	if not valid_fields(raw, EnemyAwareness.new(), AWARENESS_FIELDS): return false
	var forward := Vector3(raw.home_forward[0], raw.home_forward[1], raw.home_forward[2])
	return (raw.initialized and integer(raw.state, 0, EnemyAwareness.State.RETURN)
		and raw.suspicion >= 0.0 and raw.suspicion <= 1.0
		and raw.memory_remaining >= 0.0 and raw.memory_remaining <= 60.0
		and raw.search_elapsed >= 0.0 and raw.search_elapsed <= 60.0
		and integer(raw.patrol_index, 0, 3) and raw.patrol_wait >= 0.0 and raw.patrol_wait <= 8.0
		and absf(forward.length() - 1.0) < 0.001 and absf(forward.y) < 0.001)

static func valid_tactics(raw: Variant, expected_role: int) -> bool:
	if typeof(raw) != TYPE_DICTIONARY: return false
	if raw.is_empty(): return true # Pre-role snapshots keep authored duty, no plan.
	if not valid_fields(raw, EnemyTactics.new(), TACTICS_FIELDS): return false
	return (integer(raw.role, EnemyTactics.Role.PATROL, EnemyTactics.Role.PRESSURE)
		and raw.role == expected_role and raw.plan_remaining >= 0 and raw.plan_remaining <= 4
		and (not raw.has_plan or raw.role == EnemyTactics.Role.FLANKER))
