extends Node3D

const BATTLE_SCENE := preload("res://scenes/battle/battle.tscn")

var failures: Array[String] = []
var battle: Node3D
var player: PlayerController
var session: SortieSession


func _ready() -> void:
	ProfileRuntime.new_profile()
	SortieRuntime.clear_session()
	var profile := ProfileRuntime.get_profile()
	var request := profile.create_sortie_request(
		SortieRequest.PROTOTYPE_AREA_ID,
		SortieRequest.PROTOTYPE_MISSION_ID,
		_get_carried_ammo_ids(profile)
	)
	session = SortieRuntime.start_sortie(request, profile)
	check(session != null, "presentation fixture creates an ACTIVE Sortie")
	if session:
		await _run_building_route()
	Input.action_release("move_left")
	Input.action_release("move_forward")
	SortieRuntime.clear_session()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(0.2).timeout
	if failures.is_empty():
		print("PRESENTATION_GAMEPLAY_TEST: PASS")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("PRESENTATION_GAMEPLAY_TEST: %s" % failure)
		print("PRESENTATION_GAMEPLAY_TEST: FAIL (%d)" % failures.size())
		get_tree().quit(1)


func _run_building_route() -> void:
	battle = BATTLE_SCENE.instantiate()
	battle.result_transition_enabled = false
	add_child(battle)
	await get_tree().process_frame
	await get_tree().physics_frame
	player = battle.player as PlayerController
	var area := battle.area_root as Node3D
	var building := area.find_child("FieldOffice", true, false) as Node3D if area else null
	var door := area.find_child("SouthAccessDoor", true, false) as Door if area else null
	check(player != null and building != null and door != null, "real Battle loads Player, Field Office, and entrance Door")
	if not player or not building or not door:
		return
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		var enemy := enemy_node as EnemyController
		if enemy:
			enemy.set_process(false)
			enemy.set_physics_process(false)

	player.global_position = building.to_global(Vector3(0.0, 0.0, 9.0))
	player.velocity = Vector3.ZERO
	await get_tree().physics_frame
	await _capture("01_outdoor_closed_door")
	check(not door.is_open(), "authored entrance starts closed during live Battle")
	var interaction := player.interaction_component.interact_with_current()
	await get_tree().physics_frame
	check(bool(interaction.get("success", false)) and door.is_open(), "Player interaction opens the real entrance Door")
	await _capture("02_open_door")

	await _drive_until_z(building.to_global(Vector3.ZERO).z + 2.0)
	var entered_local := building.to_local(player.global_position)
	check(absf(entered_local.x) < 1.4 and entered_local.z < 7.0 and entered_local.z > -7.0, "PlayerController input drives the player into the Interior")
	await _capture("03_inside_field_office")

	var target := _get_nearest_enemy(building.to_global(Vector3(-3.0, 0.0, 0.0)))
	check(target != null, "Interior combat route resolves a spawned Enemy runtime")
	if target:
		player.global_position = building.to_global(Vector3(-3.0, 0.0, 2.0))
		target.global_position = building.to_global(Vector3(-3.0, 0.1, -1.0))
		player.velocity = Vector3.ZERO
		await get_tree().physics_frame
		player.set_physics_process(false)
		player.aim_direction = (target.global_position - player.global_position).normalized()
		player.aim_world_point = target.global_position + Vector3.UP
		var health_before := target.health
		var hit_confirmed := false
		for _shot in 8:
			if not is_instance_valid(target) or target.is_dead:
				break
			check(player.debug_fire_once(), "real Player weapon fires inside the authored building")
			await get_tree().process_frame
			if is_instance_valid(target) and target.health < health_before:
				hit_confirmed = true
		check(hit_confirmed, "interior Enemy receives the production DamagePacket path")
		check(not is_instance_valid(target) or target.is_dead, "interior Basic Enemy can be defeated before traversal continues")
		await _capture("04_interior_combat")
		player.set_physics_process(true)

	await _drive_until_z(building.to_global(Vector3.ZERO).z - 5.0)
	var west_route_local := building.to_local(player.global_position)
	check(west_route_local.z < -4.5, "PlayerController routes around the live destructible Barrier")
	await _drive_right_until_x(building.to_global(Vector3.ZERO).x)
	await _drive_until_z(building.to_global(Vector3.ZERO).z - 8.0)
	var exited_local := building.to_local(player.global_position)
	check(
		absf(exited_local.x) < 1.4 and exited_local.z < -7.0,
		"PlayerController input leaves through the authored rear exit (local %s)" % exited_local
	)
	await _capture("05_back_outdoors")
	battle.queue_free()
	await get_tree().process_frame


func _drive_until_z(target_z: float) -> void:
	Input.action_press("move_forward")
	for _frame in 180:
		await get_tree().physics_frame
		if player.global_position.z <= target_z:
			break
	Input.action_release("move_forward")
	player.velocity = Vector3.ZERO
	await get_tree().physics_frame


func _drive_right_until_x(target_x: float) -> void:
	Input.action_press("move_right")
	for _frame in 120:
		await get_tree().physics_frame
		if player.global_position.x >= target_x - 0.15:
			break
	Input.action_release("move_right")
	player.velocity = Vector3.ZERO
	await get_tree().physics_frame


func _get_nearest_enemy(world_position: Vector3) -> EnemyController:
	var nearest: EnemyController
	var nearest_distance := INF
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		var enemy := enemy_node as EnemyController
		if not enemy or enemy.definition_id != &"prototype_basic_enemy":
			continue
		var distance := enemy.global_position.distance_squared_to(world_position)
		if distance < nearest_distance:
			nearest = enemy
			nearest_distance = distance
	return nearest


func _get_carried_ammo_ids(profile: ProfileState) -> Array[String]:
	var ids: Array[String] = []
	var ammo_definition_ids: Dictionary = {}
	for slot_id in LoadoutState.WEAPON_SLOT_IDS:
		var weapon_item := profile.loadout.get_item(slot_id, profile.inventory)
		var weapon := ContentDB.get_weapon(weapon_item.definition_id, false) if weapon_item else null
		if weapon:
			ammo_definition_ids[weapon.get_runtime_ammo_definition_id()] = true
	for item in profile.inventory.get_items():
		if ammo_definition_ids.has(item.definition_id):
			ids.append(item.instance_id)
	return ids


func _capture(stage_name: String) -> void:
	var capture_dir := OS.get_environment("PRESENTATION_CAPTURE_DIR")
	if capture_dir.is_empty():
		return
	var directory_error := DirAccess.make_dir_recursive_absolute(capture_dir)
	check(directory_error == OK, "presentation capture directory is available")
	if directory_error != OK:
		return
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := capture_dir.path_join("%s.png" % stage_name)
	var save_error := image.save_png(path)
	check(save_error == OK, "presentation frame %s is saved" % stage_name)
	if save_error == OK:
		print("PRESENTATION_CAPTURE: %s" % path)


func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
