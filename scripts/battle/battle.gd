extends Node3D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const HUD_SCENE := preload("res://scenes/ui/battle_hud.tscn")

var player: PlayerController
var camera: Camera3D
var hud: BattleHUD
var session: SortieSession
var area_root: Node3D
var enemy_container: Node3D
var enemies_remaining := 0
var ending := false
var result_transition_enabled := true
@export var loot_seed: int = 0
var _camera_trauma := 0.0
var _camera_time := 0.0
var _last_health := 0.0


func _ready() -> void:
	session = SortieRuntime.get_current_session()
	if not session or session.status != SortieSession.Status.ACTIVE:
		push_error("Battle requires an active SortieSession")
		return
	if not _load_area():
		return
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	AudioDirector.set_music_context(&"battle")
	if not _spawn_player():
		return
	_build_camera()
	if not _spawn_enemies():
		return
	hud = HUD_SCENE.instantiate() as BattleHUD
	add_child(hud)
	hud.set_enemy_count(enemies_remaining)
	_sync_objective_hud()
	_sync_weapon_hud()
	hud.set_threat_level(session.threat_level)
	player.health_changed.connect(hud.set_health)
	player.health_changed.connect(_on_player_health_changed)
	player.weapon_fired.connect(_on_player_weapon_fired)
	player.ammo_changed.connect(_on_player_ammo_changed)
	player.weapon_switched.connect(_on_player_weapon_switched)
	player.died.connect(_on_player_died)
	if player.interaction_component:
		player.interaction_component.prompt_changed.connect(hud.set_interaction_prompt)
		player.interaction_component.interaction_finished.connect(_on_interaction_finished)
	_spawn_world_interactions()
	_configure_objective_world()
	hud.set_inventory_capacity(session.inventory.get_used_capacity(), session.inventory.capacity)
	_last_health = player.health


func _process(delta: float) -> void:
	if not is_instance_valid(player) or not camera:
		return
	_camera_time += delta
	_camera_trauma = move_toward(_camera_trauma, 0.0, delta * 1.85)
	var shake_strength := _camera_trauma * _camera_trauma
	var shake := Vector3(sin(_camera_time * 43.0), 0.0, cos(_camera_time * 37.0)) * shake_strength
	var focus := player.global_position + player.aim_direction * 1.45 + Vector3.UP * 0.85
	var target_position := focus + Vector3(0.0, 18.2, 13.7) + shake
	camera.global_position = camera.global_position.lerp(target_position, 1.0 - exp(-9.5 * delta))
	camera.look_at(focus + shake * 0.28, Vector3.UP)


func _load_area() -> bool:
	var definition := ContentDB.get_area_definition(session.area_id, false)
	if not definition:
		push_error("Battle could not resolve area ID: %s" % session.area_id)
		return false
	area_root = AreaLoader.instantiate_area(definition)
	if not area_root:
		push_error("Battle could not instantiate area ID: %s" % session.area_id)
		return false
	var area_container := Node3D.new()
	area_container.name = "AreaRoot"
	add_child(area_container)
	area_container.add_child(area_root)
	return true


func _spawn_player() -> bool:
	var spawn_points := _get_area_group_nodes(&"player_spawn_point")
	if spawn_points.size() != 1:
		push_error("Area %s requires exactly one player spawn point" % session.area_id)
		return false
	player = PLAYER_SCENE.instantiate() as PlayerController
	player.configure_sortie(session)
	add_child(player)
	player.global_position = spawn_points[0].global_position
	return true


func _build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "HighAngleCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 24.5
	camera.position = player.position + Vector3(0.0, 18.2, 13.7)
	camera.current = true
	add_child(camera)
	camera.look_at(player.position + Vector3.UP * 0.85, Vector3.UP)


func _on_player_weapon_fired(recoil_strength: float) -> void:
	_camera_trauma = maxf(_camera_trauma, recoil_strength)


func _on_player_ammo_changed(magazine: int, magazine_capacity: int, reserve: int) -> void:
	if not hud:
		return
	_sync_weapon_hud()
	hud.set_inventory_capacity(session.inventory.get_used_capacity(), session.inventory.capacity)


func _on_player_weapon_switched(_slot_id: StringName) -> void:
	_sync_weapon_hud()


func _sync_weapon_hud() -> void:
	if not hud or not player:
		return
	hud.set_weapon_slots(
		player.get_weapon_status(LoadoutState.SLOT_WEAPON_PRIMARY),
		player.get_weapon_status(LoadoutState.SLOT_WEAPON_SECONDARY),
		player.active_weapon_slot
	)


func _on_player_health_changed(current: float, maximum: float) -> void:
	if current < _last_health:
		var damage_amount := _last_health - current
		session.damage_taken += roundi(damage_amount)
		var damage_ratio := damage_amount / maximum
		_camera_trauma = maxf(_camera_trauma, 0.16 + damage_ratio * 1.8)
	_last_health = current


func _spawn_enemies() -> bool:
	var spawn_points: Array[EnemySpawnPoint] = []
	for candidate in area_root.find_children("*", "EnemySpawnPoint", true, false):
		spawn_points.append(candidate as EnemySpawnPoint)
	spawn_points.sort_custom(func(a: EnemySpawnPoint, b: EnemySpawnPoint) -> bool: return a.name.naturalnocasecmp_to(b.name) < 0)
	if spawn_points.is_empty():
		push_error("Area %s requires at least one EnemySpawnPoint" % session.area_id)
		return false
	for spawn_point in spawn_points:
		var definition := ContentDB.get_enemy_definition(spawn_point.enemy_definition_id, false)
		if not definition:
			push_error("Area %s enemy spawn %s references unknown enemy ID: %s" % [session.area_id, spawn_point.name, spawn_point.enemy_definition_id])
			return false
		if not spawn_point.initial_spawn and spawn_point.activation_group_id.is_empty():
			push_error("Area %s reinforcement spawn %s requires an activation group" % [session.area_id, spawn_point.name])
			return false

	enemy_container = Node3D.new()
	enemy_container.name = "Enemies"
	add_child(enemy_container)
	enemies_remaining = 0
	for spawn_point in spawn_points:
		if not spawn_point.initial_spawn:
			continue
		if not _spawn_enemy_at_point(spawn_point):
			enemy_container.queue_free()
			enemy_container = null
			enemies_remaining = 0
			return false
	if enemies_remaining == 0:
		push_error("Area %s requires at least one initial enemy spawn" % session.area_id)
		return false
	return true


func spawn_reinforcement_group(group_id: StringName) -> int:
	if ending or not session or session.status != SortieSession.Status.ACTIVE or group_id.is_empty():
		return 0
	var spawn_points: Array[EnemySpawnPoint] = []
	for candidate in area_root.find_children("*", "EnemySpawnPoint", true, false):
		var spawn_point := candidate as EnemySpawnPoint
		if spawn_point.is_reinforcement_for(group_id) and not spawn_point.has_spawned:
			spawn_points.append(spawn_point)
	spawn_points.sort_custom(func(a: EnemySpawnPoint, b: EnemySpawnPoint) -> bool: return a.name.naturalnocasecmp_to(b.name) < 0)
	var spawned_count := 0
	for spawn_point in spawn_points:
		if not _spawn_enemy_at_point(spawn_point):
			push_error("Area %s failed to activate reinforcement spawn: %s" % [session.area_id, spawn_point.name])
			return spawned_count
		spawned_count += 1
	if hud and spawned_count > 0:
		hud.set_enemy_count(enemies_remaining)
	return spawned_count


func _spawn_enemy_at_point(spawn_point: EnemySpawnPoint) -> EnemyController:
	if not spawn_point or spawn_point.has_spawned or not enemy_container:
		return null
	var definition := ContentDB.get_enemy_definition(spawn_point.enemy_definition_id, false)
	if not definition:
		return null
	var enemy := EnemySpawnService.spawn(definition, spawn_point.global_transform, enemy_container)
	if not enemy:
		return null
	if not spawn_point.mark_spawned():
		enemy.queue_free()
		return null
	enemy.died.connect(_on_enemy_died)
	enemies_remaining += 1
	return enemy


func _spawn_world_interactions() -> void:
	var rng := RandomNumberGenerator.new()
	if loot_seed == 0:
		rng.randomize()
	else:
		rng.seed = loot_seed
	for spawn_point in area_root.find_children("*", "LootSpawnPoint", true, false):
		spawn_point.spawn(rng)
	for extraction_point in area_root.find_children("*", "ExtractionPoint", true, false):
		if not extraction_point.extracted.is_connected(_on_extraction_completed):
			extraction_point.extracted.connect(_on_extraction_completed)
	for threat_event in area_root.find_children("*", "ThreatEvent", true, false):
		threat_event.setup(session)
		if not threat_event.activated.is_connected(_on_threat_event_activated):
			threat_event.activated.connect(_on_threat_event_activated)


func _on_threat_event_activated(event: ThreatEvent, group_id: StringName) -> void:
	var spawned_count := spawn_reinforcement_group(group_id)
	if spawned_count <= 0:
		push_error("Threat event could not spawn reinforcement group: %s" % group_id)
		return
	event.mark_reinforcement_spawned()
	hud.set_threat_level(session.threat_level)
	hud.show_banner("LOCAL ALERT  /  REINFORCEMENTS INBOUND", Color("ff6b7f"))


func _configure_objective_world() -> void:
	for reach_zone in area_root.find_children("*", "ObjectiveReachZone", true, false):
		reach_zone.setup(session)
		if not reach_zone.objective_reached.is_connected(_on_world_objective_recorded):
			reach_zone.objective_reached.connect(_on_world_objective_recorded)


func _get_area_group_nodes(group_name: StringName) -> Array[Node3D]:
	var result: Array[Node3D] = []
	for candidate in get_tree().get_nodes_in_group(group_name):
		if candidate is Node3D and (candidate == area_root or area_root.is_ancestor_of(candidate)):
			result.append(candidate as Node3D)
	result.sort_custom(func(a: Node3D, b: Node3D) -> bool: return a.name.naturalnocasecmp_to(b.name) < 0)
	return result


func _on_enemy_died(_enemy: EnemyController) -> void:
	if ending:
		return
	var mission_was_completed := session.is_mission_completed()
	if not session.record_enemy_defeat():
		return
	enemies_remaining = maxi(enemies_remaining - 1, 0)
	hud.set_enemy_count(enemies_remaining)
	_sync_objective_hud()
	if not mission_was_completed and session.is_mission_completed():
		hud.show_banner("MISSION OBJECTIVE COMPLETE  /  EXTRACT WHEN READY", Color("79f1e7"))
	elif enemies_remaining <= 0:
		hud.show_banner("AREA SECURE  /  EXTRACT WHEN READY", Color("79f1e7"))


func _sync_objective_hud() -> void:
	var summaries := session.get_objective_summary()
	var mission := ContentDB.get_mission(session.mission_id, false)
	if summaries.is_empty() or not mission:
		hud.set_objective_progress("Unknown", 0, 1, false)
		return
	var hud_objectives: Array[Dictionary] = []
	for summary in summaries:
		var definition := mission.get_objective(StringName(summary.get("objective_id", "")))
		hud_objectives.append({
			"display_name": definition.display_name if definition else str(summary.get("objective_id", "Unknown")),
			"progress": int(summary.get("progress", 0)),
			"target": int(summary.get("target", 1)),
			"completed": int(summary.get("status", ObjectiveState.Status.PENDING)) == ObjectiveState.Status.COMPLETED,
		})
	hud.set_objectives(hud_objectives)


func _on_player_died() -> void:
	if not ending:
		_fail_battle()


func _on_interaction_finished(message: String, success: bool) -> void:
	hud.show_interaction_feedback(message, success)
	hud.set_inventory_capacity(session.inventory.get_used_capacity(), session.inventory.capacity)
	if success:
		_sync_objective_hud()
		_show_mission_complete_if_ready()


func _on_world_objective_recorded(_objective_id: StringName) -> void:
	_sync_objective_hud()
	_show_mission_complete_if_ready()


func _show_mission_complete_if_ready() -> void:
	if session.is_mission_completed():
		hud.show_banner("MISSION OBJECTIVES COMPLETE  /  EXTRACT WHEN READY", Color("79f1e7"))


func _on_extraction_completed(_session: SortieSession, _extraction_id: StringName) -> void:
	if ending:
		return
	ending = true
	player.set_physics_process(false)
	if player.interaction_component:
		player.interaction_component.set_enabled(false)
	AudioDirector.play_sfx(&"victory")
	hud.show_banner("EXTRACTION SUCCESSFUL", Color("79f1e7"))
	_transition_to_result()


func _fail_battle() -> void:
	if ending or not session.fail():
		return
	ending = true
	player.set_physics_process(false)
	if player.interaction_component:
		player.interaction_component.set_enabled(false)
	AudioDirector.play_sfx(&"defeat")
	hud.show_banner("UNIT LOST", Color("ff5b6f"))
	_transition_to_result()


func _transition_to_result() -> void:
	if not result_transition_enabled:
		return
	await get_tree().create_timer(2.4).timeout
	GameState.finish_mission()
