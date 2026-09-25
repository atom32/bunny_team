extends Node3D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const COVER_SCENE := preload("res://scenes/world/cover_obstacle.tscn")
const DESTRUCTIBLE_SCENE := preload("res://scenes/world/destructible_world_object.tscn")

const WEAPON_CASES := [
	{
		"id": &"weapon.assault_rifle_01",
		"label": "AR",
		"secondary": &"weapon.rocket_launcher_01",
	},
	{
		"id": &"weapon.smg_01",
		"label": "SMG",
		"secondary": &"weapon.rocket_launcher_01",
	},
	{
		"id": &"weapon.rocket_launcher_01",
		"label": "Rocket",
		"secondary": &"weapon.assault_rifle_01",
	},
]

const TARGET_CASES := [
	{
		"id": &"prototype_basic_enemy",
		"label": "Basic",
	},
	{
		"id": &"prototype_heavy_enemy",
		"label": "Heavy",
	},
]

const LOADOUT_CASES := [
	{
		"primary": &"weapon.assault_rifle_01",
		"secondary": &"weapon.smg_01",
		"label": "AR + SMG",
	},
	{
		"primary": &"weapon.assault_rifle_01",
		"secondary": &"weapon.rocket_launcher_01",
		"label": "AR + Rocket",
	},
	{
		"primary": &"weapon.smg_01",
		"secondary": &"weapon.rocket_launcher_01",
		"label": "SMG + Rocket",
	},
]

var failures: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	var combat_metrics := await _record_combat_baseline()
	var world_metrics := await _record_world_baseline()
	await _record_ammo_baseline()
	_record_loadout_baseline(combat_metrics, world_metrics)
	_record_arena_baseline()
	_print_relation_baseline(combat_metrics, world_metrics)
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(0.2).timeout
	if failures.is_empty():
		print("COMBAT_TUNING_BASELINE_TEST: PASS")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("COMBAT_TUNING_BASELINE_TEST: %s" % failure)
		print("COMBAT_TUNING_BASELINE_TEST: FAIL (%d)" % failures.size())
		get_tree().quit(1)


func _record_combat_baseline() -> Dictionary:
	var metrics := {}
	for weapon_case in WEAPON_CASES:
		var weapon_id: StringName = weapon_case.id
		metrics[weapon_id] = {}
		for target_case in TARGET_CASES:
			var result := await _measure_enemy_engagement(weapon_case, target_case)
			metrics[weapon_id][target_case.label] = result
			var blast_value := "%.2f" % result.blast_center_damage if weapon_id == &"weapon.rocket_launcher_01" else "n/a"
			print(
				"COMBAT_BASELINE weapon=%s target=%s shots_to_kill=%d damage_per_hit=%.2f ammo_spent=%d blast_center_damage=%s" % [
					weapon_case.label,
					target_case.label,
					result.shots_to_kill,
					result.damage_per_hit,
					result.ammo_spent,
					blast_value,
				]
			)
	_assert_combat_baseline(metrics)
	return metrics


func _measure_enemy_engagement(weapon_case: Dictionary, target_case: Dictionary) -> Dictionary:
	var fixture := await _create_player_fixture(weapon_case.id, weapon_case.secondary)
	if fixture.is_empty():
		return {"shots_to_kill": -1, "damage_per_hit": -1.0, "ammo_spent": -1}
	var player: PlayerController = fixture.player
	var session: SortieSession = fixture.session
	var weapon_state: WeaponRuntimeState = fixture.primary_state
	var enemy := EnemySpawnService.spawn(
		ContentDB.get_enemy_definition(target_case.id),
		Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, -8.0)),
		self
	)
	check(enemy != null, "%s engagement spawns %s through EnemySpawnService" % [weapon_case.label, target_case.label])
	if not enemy:
		await _cleanup_fixture(fixture)
		return {"shots_to_kill": -1, "damage_per_hit": -1.0, "ammo_spent": -1}
	enemy.set_physics_process(false)
	await _settle_physics()
	player.aim_world_point = enemy.global_position + Vector3.UP * 0.9
	var ammo_before := _runtime_ammo_total(session, weapon_state)
	var first_hit_damage := -1.0
	var shots := 0
	var killed := false
	while not killed and shots < 128:
		if weapon_state.magazine_ammo == 0:
			var loaded := session.reload_weapon(fixture.primary_id)
			check(loaded > 0, "%s reloads through SortieSession while recording %s" % [weapon_case.label, target_case.label])
			if loaded <= 0:
				break
		var health_before: float = enemy.health
		var fire_result := await _fire_player_weapon(player, enemy.global_position)
		check(fire_result.fired, "%s fires through PlayerController against %s" % [weapon_case.label, target_case.label])
		if not fire_result.fired:
			break
		shots += 1
		var applied_damage: float = health_before - enemy.health
		if first_hit_damage < 0.0:
			first_hit_damage = applied_damage
		killed = enemy.is_dead
		if player.weapon_data.action_type == &"projectile":
			await get_tree().process_frame
	var ammo_after := _runtime_ammo_total(session, weapon_state)
	var result := {
		"shots_to_kill": shots,
		"damage_per_hit": first_hit_damage,
		"ammo_spent": ammo_before - ammo_after,
		"blast_center_damage": ContentDB.get_weapon(weapon_case.id).damage if weapon_case.id == &"weapon.rocket_launcher_01" else 0.0,
	}
	check(killed, "%s defeats %s through the production attack path" % [weapon_case.label, target_case.label])
	check(result.ammo_spent == shots, "%s spends exactly one runtime round per accepted shot against %s" % [weapon_case.label, target_case.label])
	if is_instance_valid(enemy):
		enemy.queue_free()
	await _cleanup_fixture(fixture)
	return result


func _record_world_baseline() -> Dictionary:
	var metrics := {}
	for weapon_case in WEAPON_CASES:
		var weapon_id: StringName = weapon_case.id
		var cover_result := await _measure_cover_interaction(weapon_case)
		var barrier_result := await _measure_barrier_interaction(weapon_case)
		metrics[weapon_id] = {
			"Cover": cover_result,
			"Barrier": barrier_result,
		}
		print(
			"WORLD_BASELINE weapon=%s target=Cover blocked=%s structure_damage=%.2f shots_to_destroy=%s target_damage=%.2f" % [
				weapon_case.label,
				cover_result.blocked,
				cover_result.structure_damage,
				cover_result.shots_to_destroy,
				cover_result.target_damage,
			]
		)
		print(
			"WORLD_BASELINE weapon=%s target=Barrier blocked=%s structure_damage=%.2f shots_to_destroy=%s" % [
				weapon_case.label,
				barrier_result.blocked,
				barrier_result.structure_damage,
				barrier_result.shots_to_destroy,
			]
		)
	_assert_world_baseline(metrics)
	return metrics


func _measure_cover_interaction(weapon_case: Dictionary) -> Dictionary:
	var fixture := await _create_player_fixture(weapon_case.id, weapon_case.secondary)
	if fixture.is_empty():
		return {"blocked": false, "structure_damage": -1.0, "shots_to_destroy": "error", "target_damage": -1.0}
	var player: PlayerController = fixture.player
	var cover := COVER_SCENE.instantiate() as CoverObstacle
	cover.position = Vector3(0.0, 0.0, -4.0)
	add_child(cover)
	var enemy := EnemySpawnService.spawn(
		ContentDB.get_enemy_definition(&"prototype_basic_enemy"),
		Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, -8.0)),
		self
	)
	enemy.set_physics_process(false)
	await _settle_physics()
	player.aim_world_point = enemy.global_position + Vector3.UP * 0.9
	var health_before: float = enemy.health
	var weapon := ContentDB.get_weapon(weapon_case.id)
	var fire_result: Dictionary
	if weapon.action_type == &"projectile":
		fire_result = await _fire_player_weapon(player, Vector3(0.0, 0.0, -3.5))
	else:
		fire_result = await _fire_player_weapon(player, enemy.global_position)
	check(fire_result.fired, "%s fires once at the authored Cover relationship" % weapon_case.label)
	var target_damage: float = health_before - enemy.health
	var result := {
		"blocked": is_zero_approx(target_damage),
		"structure_damage": 0.0,
		"shots_to_destroy": "indestructible",
		"target_damage": target_damage,
	}
	var cover_collision := cover.find_child("CollisionShape3D", true, false) as CollisionShape3D
	check(cover_collision != null and not cover_collision.disabled and not cover.has_method("receive_damage"), "%s leaves permanent Cover collision intact" % weapon_case.label)
	if is_instance_valid(enemy):
		enemy.queue_free()
	cover.queue_free()
	await _cleanup_fixture(fixture)
	return result


func _measure_barrier_interaction(weapon_case: Dictionary) -> Dictionary:
	var fixture := await _create_player_fixture(weapon_case.id, weapon_case.secondary)
	if fixture.is_empty():
		return {"blocked": false, "structure_damage": -1.0, "shots_to_destroy": "error"}
	var player: PlayerController = fixture.player
	var session: SortieSession = fixture.session
	var weapon_state: WeaponRuntimeState = fixture.primary_state
	var barrier := DESTRUCTIBLE_SCENE.instantiate() as DestructibleWorldObject
	barrier.position = Vector3(0.0, 0.0, -4.0)
	add_child(barrier)
	await _settle_physics()
	player.aim_world_point = barrier.global_position + Vector3.UP
	var initial_health := barrier.current_structure_health
	var first_hit_damage := -1.0
	var shots := 0
	var weapon := ContentDB.get_weapon(weapon_case.id)
	var max_shots := 1 if is_zero_approx(weapon.structure_damage) else 64
	while not barrier.destroyed and shots < max_shots:
		if weapon_state.magazine_ammo == 0:
			var loaded := session.reload_weapon(fixture.primary_id)
			check(loaded > 0, "%s reloads while recording Barrier interaction" % weapon_case.label)
			if loaded <= 0:
				break
		var health_before := barrier.current_structure_health
		var fire_result := await _fire_player_weapon(player, barrier.global_position)
		check(fire_result.fired, "%s fires through PlayerController at Barrier" % weapon_case.label)
		if not fire_result.fired:
			break
		shots += 1
		if first_hit_damage < 0.0:
			first_hit_damage = health_before - barrier.current_structure_health
	var shots_to_destroy: Variant = shots if barrier.destroyed else "not_destroyed"
	var result := {
		"blocked": not barrier.destroyed,
		"structure_damage": first_hit_damage,
		"shots_to_destroy": shots_to_destroy,
		"initial_structure_health": initial_health,
	}
	barrier.queue_free()
	await _cleanup_fixture(fixture)
	return result


func _record_ammo_baseline() -> void:
	for weapon_case in WEAPON_CASES:
		var fixture := await _create_player_fixture(weapon_case.id, weapon_case.secondary)
		if fixture.is_empty():
			continue
		var profile: ProfileState = fixture.profile
		var session: SortieSession = fixture.session
		var player: PlayerController = fixture.player
		var state: WeaponRuntimeState = fixture.primary_state
		var ammo_definition_id := state.ammo_definition_id
		var reserve_before := state.get_reserve_ammo(session.inventory)
		var magazine_before := state.magazine_ammo
		var total_before := reserve_before + magazine_before
		var fire_result := await _fire_player_weapon(player, Vector3(0.0, 0.0, -12.0))
		check(fire_result.fired, "%s ammo baseline fires through PlayerController" % weapon_case.label)
		var reserve_after_fire := state.get_reserve_ammo(session.inventory)
		var magazine_after_fire := state.magazine_ammo
		check(player.reload_weapon(), "%s ammo baseline reloads through PlayerController" % weapon_case.label)
		var reserve_after_reload := state.get_reserve_ammo(session.inventory)
		var magazine_before_extract := state.magazine_ammo
		check(reserve_after_fire == reserve_before, "%s fire consumes magazine rather than reserve" % weapon_case.label)
		check(reserve_after_reload == reserve_after_fire - 1, "%s reload consumes the one fired round from reserve" % weapon_case.label)
		check(magazine_before_extract == state.magazine_capacity, "%s reload restores its authored magazine capacity" % weapon_case.label)
		check(session.complete_extraction(), "%s ammo baseline completes extraction" % weapon_case.label)
		var outcome := SortieOutcomeService.create_outcome(session)
		check(outcome != null and SortieOutcomeService.commit_outcome(profile, outcome) == OK, "%s ammo baseline commits through the existing recovery boundary" % weapon_case.label)
		var recovered_after_extract := _total_quantity(profile.inventory, ammo_definition_id)
		check(state.magazine_ammo == 0, "%s extraction clears materialized runtime magazine" % weapon_case.label)
		check(recovered_after_extract == total_before - 1, "%s extraction recovers every unspent round exactly once" % weapon_case.label)
		print(
			"AMMO_BASELINE weapon=%s ammo=%s magazine_capacity=%d reserve_before=%d magazine_before=%d reserve_after_fire=%d magazine_after_fire=%d reload_consumption=%d reserve_after_reload=%d magazine_before_extract=%d recovered_after_extract=%d" % [
				weapon_case.label,
				ammo_definition_id,
				state.magazine_capacity,
				reserve_before,
				magazine_before,
				reserve_after_fire,
				magazine_after_fire,
				reserve_after_fire - reserve_after_reload,
				reserve_after_reload,
				magazine_before_extract,
				recovered_after_extract,
			]
		)
		await _cleanup_fixture(fixture)


func _record_loadout_baseline(combat_metrics: Dictionary, world_metrics: Dictionary) -> void:
	for loadout_case in LOADOUT_CASES:
		var primary := ContentDB.get_weapon(loadout_case.primary)
		var secondary := ContentDB.get_weapon(loadout_case.secondary)
		var shared_ammo := primary.get_runtime_ammo_definition_id() == secondary.get_runtime_ammo_definition_id()
		var heavy_solution := "%s=%.2f/hit;%s=%.2f/hit" % [
			_weapon_label(primary.id),
			combat_metrics[primary.id].Heavy.damage_per_hit,
			_weapon_label(secondary.id),
			combat_metrics[secondary.id].Heavy.damage_per_hit,
		]
		var barrier_solution := "%s=%s;%s=%s" % [
			_weapon_label(primary.id),
			_format_barrier_solution(world_metrics[primary.id].Barrier),
			_weapon_label(secondary.id),
			_format_barrier_solution(world_metrics[secondary.id].Barrier),
		]
		print(
			"LOADOUT_BASELINE primary=%s secondary=%s shared_ammo=%s independent_ammo=%s heavy_solution=%s barrier_solution=%s" % [
				_weapon_label(primary.id),
				_weapon_label(secondary.id),
				shared_ammo,
				not shared_ammo,
				heavy_solution,
				barrier_solution,
			]
		)


func _record_arena_baseline() -> void:
	var area := AreaLoader.instantiate_area(ContentDB.get_area_definition(&"prototype_arena"))
	check(area != null, "Prototype Arena resolves for authored baseline inspection")
	if not area:
		return
	var spawn_points := area.find_children("*", "EnemySpawnPoint", true, false)
	var initial_basic := 0
	var initial_heavy := 0
	var reinforcement_basic := 0
	var reinforcement_heavy := 0
	for point_node in spawn_points:
		var point := point_node as EnemySpawnPoint
		if point.initial_spawn and point.enemy_definition_id == &"prototype_basic_enemy":
			initial_basic += 1
		elif point.initial_spawn and point.enemy_definition_id == &"prototype_heavy_enemy":
			initial_heavy += 1
		elif not point.initial_spawn and point.enemy_definition_id == &"prototype_basic_enemy":
			reinforcement_basic += 1
		elif not point.initial_spawn and point.enemy_definition_id == &"prototype_heavy_enemy":
			reinforcement_heavy += 1
	var loot_spawn_count := area.find_children("*", "LootSpawnPoint", true, false).size()
	var threat_event_count := area.find_children("*", "ThreatEvent", true, false).size()
	var extraction_count := area.find_children("*", "ExtractionPoint", true, false).size()
	var mission := ContentDB.get_mission(&"prototype_combat")
	var objective_count := mission.objective_definitions.size() if mission else 0
	check(initial_basic == 9 and initial_heavy == 3, "Arena baseline preserves nine initial Basic and three initial Heavy enemies")
	check(reinforcement_basic == 2 and reinforcement_heavy == 1, "Arena baseline preserves two Basic and one Heavy reinforcement")
	check(loot_spawn_count == 4 and threat_event_count == 1 and extraction_count == 1 and objective_count == 3, "Arena authored gameplay counts match the current baseline")
	print(
		"ARENA_BASELINE initial_basic_count=%d initial_heavy_count=%d reinforcement_basic_count=%d reinforcement_heavy_count=%d loot_spawn_count=%d threat_event_count=%d extraction_count=%d objective_count=%d" % [
			initial_basic,
			initial_heavy,
			reinforcement_basic,
			reinforcement_heavy,
			loot_spawn_count,
			threat_event_count,
			extraction_count,
			objective_count,
		]
	)
	area.free()


func _print_relation_baseline(combat_metrics: Dictionary, world_metrics: Dictionary) -> void:
	for weapon_case in WEAPON_CASES:
		var weapon_id: StringName = weapon_case.id
		print(
			"RELATION_BASELINE %s vs Heavy damage_per_hit=%.2f shots_to_kill=%d" % [
				weapon_case.label,
				combat_metrics[weapon_id].Heavy.damage_per_hit,
				combat_metrics[weapon_id].Heavy.shots_to_kill,
			]
		)
		print(
			"RELATION_BASELINE %s vs Barrier structure_damage=%.2f shots_to_destroy=%s" % [
				weapon_case.label,
				world_metrics[weapon_id].Barrier.structure_damage,
				world_metrics[weapon_id].Barrier.shots_to_destroy,
			]
		)
		print(
			"RELATION_BASELINE %s vs Cover blocked=%s target_damage=%.2f" % [
				weapon_case.label,
				world_metrics[weapon_id].Cover.blocked,
				world_metrics[weapon_id].Cover.target_damage,
			]
		)


func _assert_combat_baseline(metrics: Dictionary) -> void:
	_check_metric(metrics, &"weapon.assault_rifle_01", "Basic", 20.0, 3)
	_check_metric(metrics, &"weapon.assault_rifle_01", "Heavy", 12.0, 10)
	_check_metric(metrics, &"weapon.smg_01", "Basic", 10.0, 6)
	_check_metric(metrics, &"weapon.smg_01", "Heavy", 2.0, 60)
	_check_metric(metrics, &"weapon.rocket_launcher_01", "Basic", 60.0, 1)
	_check_metric(metrics, &"weapon.rocket_launcher_01", "Heavy", 84.0, 2)
	check(is_equal_approx(metrics[&"weapon.rocket_launcher_01"].Basic.blast_center_damage, 92.0), "Rocket center packet retains its authored ninety-two base damage before target health caps")
	check(is_equal_approx(metrics[&"weapon.rocket_launcher_01"].Heavy.blast_center_damage, 92.0), "Rocket center packet is identical for Basic and Heavy targets")


func _assert_world_baseline(metrics: Dictionary) -> void:
	var rifle_cover: Dictionary = metrics[&"weapon.assault_rifle_01"].Cover
	var smg_cover: Dictionary = metrics[&"weapon.smg_01"].Cover
	var rocket_cover: Dictionary = metrics[&"weapon.rocket_launcher_01"].Cover
	check(rifle_cover.blocked and is_zero_approx(rifle_cover.target_damage), "Cover blocks current AR hitscan")
	check(smg_cover.blocked and is_zero_approx(smg_cover.target_damage), "Cover blocks current SMG hitscan")
	check(not rocket_cover.blocked and rocket_cover.target_damage > 0.0, "Rocket blast reaches the nearby target behind intact Cover")
	var rifle_barrier: Dictionary = metrics[&"weapon.assault_rifle_01"].Barrier
	var smg_barrier: Dictionary = metrics[&"weapon.smg_01"].Barrier
	var rocket_barrier: Dictionary = metrics[&"weapon.rocket_launcher_01"].Barrier
	check(is_equal_approx(rifle_barrier.structure_damage, 5.0) and rifle_barrier.shots_to_destroy == 4, "AR destroys current Barrier in four five-damage hits")
	check(is_zero_approx(smg_barrier.structure_damage) and smg_barrier.shots_to_destroy == "not_destroyed", "SMG leaves current Barrier unchanged")
	check(is_equal_approx(rocket_barrier.structure_damage, 20.0) and rocket_barrier.shots_to_destroy == 1, "Rocket applies enough structure damage to consume the Barrier's full remaining health in one blast")


func _check_metric(metrics: Dictionary, weapon_id: StringName, target_label: String, damage: float, shots: int) -> void:
	var metric: Dictionary = metrics[weapon_id][target_label]
	check(is_equal_approx(metric.damage_per_hit, damage), "%s baseline damage against %s remains %.2f" % [_weapon_label(weapon_id), target_label, damage])
	check(metric.shots_to_kill == shots, "%s baseline shots-to-kill against %s remains %d" % [_weapon_label(weapon_id), target_label, shots])
	check(metric.ammo_spent == shots, "%s baseline ammo spent against %s equals accepted shots" % [_weapon_label(weapon_id), target_label])


func _create_player_fixture(primary_definition_id: StringName, secondary_definition_id: StringName) -> Dictionary:
	var profile := ProfileState.create_new()
	var primary_item := _find_item(profile.inventory, primary_definition_id)
	var secondary_item := _find_item(profile.inventory, secondary_definition_id)
	check(primary_item != null and secondary_item != null, "Baseline fixture owns requested weapon pair")
	if not primary_item or not secondary_item:
		return {}
	profile.loadout.unequip(LoadoutState.SLOT_WEAPON_PRIMARY)
	profile.loadout.unequip(LoadoutState.SLOT_WEAPON_SECONDARY)
	check(profile.loadout.equip(LoadoutState.SLOT_WEAPON_PRIMARY, primary_item.instance_id, profile.inventory), "Baseline fixture equips requested primary")
	check(profile.loadout.equip(LoadoutState.SLOT_WEAPON_SECONDARY, secondary_item.instance_id, profile.inventory), "Baseline fixture equips requested secondary")
	var request := profile.create_sortie_request(
		SortieRequest.PROTOTYPE_AREA_ID,
		SortieRequest.PROTOTYPE_MISSION_ID,
		_get_carried_ammo_ids(profile)
	)
	var session := SortieSession.create_from_profile(request, profile) if request else null
	check(request != null and session != null and session.activate(), "Baseline fixture creates an ACTIVE SortieSession")
	if not session or session.status != SortieSession.Status.ACTIVE:
		return {}
	var player := PLAYER_SCENE.instantiate() as PlayerController
	player.configure_sortie(session)
	add_child(player)
	await get_tree().process_frame
	player.global_position = Vector3.ZERO
	player.set_process(false)
	player.set_physics_process(false)
	var primary_state: WeaponRuntimeState = session.get_weapon_runtime_state(primary_item.instance_id)
	check(player.weapon_data != null and player.weapon_data.id == primary_definition_id, "PlayerController activates the requested primary WeaponDefinition")
	check(primary_state != null, "SortieSession owns the requested primary WeaponRuntimeState")
	return {
		"profile": profile,
		"session": session,
		"player": player,
		"primary_id": primary_item.instance_id,
		"primary_state": primary_state,
	}


func _fire_player_weapon(player: PlayerController, projectile_impact_position: Vector3) -> Dictionary:
	var fired := player.debug_fire_once()
	if not fired:
		return {"fired": false}
	if player.weapon_data.action_type == &"projectile":
		var rocket := _find_live_rocket()
		check(rocket != null, "PlayerController projectile action creates RocketProjectile")
		if not rocket:
			return {"fired": false}
		rocket.set_physics_process(false)
		rocket.global_position = projectile_impact_position
		rocket._explode()
	return {"fired": true}


func _find_live_rocket() -> Area3D:
	var rockets := find_children("RocketProjectile", "Area3D", true, false)
	for rocket_node in rockets:
		if not rocket_node.is_queued_for_deletion():
			return rocket_node as Area3D
	return null


func _get_carried_ammo_ids(profile: ProfileState) -> Array[String]:
	var ammo_definition_ids: Dictionary = {}
	for slot_id in LoadoutState.WEAPON_SLOT_IDS:
		var weapon_item := profile.loadout.get_item(slot_id, profile.inventory)
		var weapon_definition := ContentDB.get_weapon(weapon_item.definition_id, false) if weapon_item else null
		var ammo_definition_id := weapon_definition.get_runtime_ammo_definition_id() if weapon_definition else &""
		if not ammo_definition_id.is_empty():
			ammo_definition_ids[ammo_definition_id] = true
	var instance_ids: Array[String] = []
	for item in profile.inventory.get_items():
		if ammo_definition_ids.has(item.definition_id):
			instance_ids.append(item.instance_id)
	return instance_ids


func _runtime_ammo_total(session: SortieSession, state: WeaponRuntimeState) -> int:
	return state.magazine_ammo + state.get_reserve_ammo(session.inventory)


func _total_quantity(inventory: InventoryState, definition_id: StringName) -> int:
	var total := 0
	for item in inventory.get_items():
		if item.definition_id == definition_id:
			total += item.quantity
	return total


func _find_item(inventory: InventoryState, definition_id: StringName) -> ItemInstance:
	for item in inventory.get_items():
		if item.definition_id == definition_id:
			return item
	return null


func _weapon_label(weapon_id: StringName) -> String:
	match weapon_id:
		&"weapon.assault_rifle_01":
			return "AR"
		&"weapon.smg_01":
			return "SMG"
		&"weapon.rocket_launcher_01":
			return "Rocket"
	return String(weapon_id)


func _format_barrier_solution(metric: Dictionary) -> String:
	return "%.2f/shot,%s shots" % [metric.structure_damage, metric.shots_to_destroy]


func _settle_physics() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame


func _cleanup_fixture(fixture: Dictionary) -> void:
	var player: PlayerController = fixture.get("player") as PlayerController
	if is_instance_valid(player):
		player.queue_free()
	for rocket in find_children("RocketProjectile", "Area3D", true, false):
		rocket.queue_free()
	for ragdoll in find_children("RagdollProxy", "Node3D", true, false):
		ragdoll.queue_free()
	await get_tree().process_frame


func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
