extends SceneTree
## Run with Godot 4.7.2 --path <isolated imported copy> --script <this file>.
## BUNNY_EVIDENCE must point outside the project. This is NOT manual acceptance.
## Normal AI, health, collision, production camera and outcome flow stay enabled.

var evidence := OS.get_environment("BUNNY_EVIDENCE")
var held := {}
var checks := {}
var battle: Node
var player: Node3D
var shots := 0
var weapon_checks: Array = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if evidence.is_empty() or DisplayServer.get_name() == "headless":
		push_error("Requires an isolated profile, BUNNY_EVIDENCE and a real graphics renderer")
		quit(2)
		return
	print("PHASE2B_ROUTE: AUTOMATED INPUT/API, NOT MANUAL; NORMAL AI; NO TELEPORT/INVULNERABILITY")
	change_scene_to_file("res://scenes/hanger/hanger.tscn")
	await create_timer(1.0).timeout
	checks["Hanger launches"] = current_scene != null and current_scene.name == "Hanger"
	if OS.get_environment("BUNNY_PRIMARY") == "SMG":
		var profile = root.get_node("ProfileRuntime").get_profile()
		for item in profile.inventory.get_items():
			if item.definition_id == &"weapon.smg_01":
				current_scene._on_weapon_selected(item.instance_id)
				break
		await create_timer(0.4).timeout
	await _capture("01_hanger")
	var deploy: Button
	for button in current_scene.find_children("*", "Button", true, false):
		if button.text == "DEPLOY": deploy = button
	if not deploy:
		await _finish("DEPLOY button missing")
		return
	# The production button signal invokes the unmodified Hanger sortie flow.
	deploy.pressed.emit()
	await create_timer(1.0).timeout
	battle = current_scene
	player = battle.get("player") as Node3D
	if not player:
		await _finish("Battle player missing")
		return
	player.weapon_fired.connect(func(_recoil: float): shots += 1)
	checks["Production camera"] = root.get_camera_3d() == battle.get("camera")
	if not await _move_to(Vector3(-16.0, 0, 26.0)):
		await _finish("Could not approach Field Office")
		return
	checks["Player movement"] = true
	var door = battle.find_child("SouthAccessDoor", true, false)
	checks["Field Office entrance visible"] = door != null and not root.get_camera_3d().is_position_behind(door.global_position)
	await _capture("02_entrance")
	if not await _move_to(Vector3(-16.0, 0, 24.7)):
		await _finish("Door approach failed")
		return
	await _tap(KEY_E)
	checks["Door interaction"] = door.is_open()
	if not checks["Door interaction"]:
		await _finish("Door did not open through interaction input")
		return
	if not await _move_to(Vector3(-16.0, 0, 21.5)) or not await _move_to(Vector3(-19.5, 0, 21.0)):
		await _finish("Entrance traversal failed")
		return
	checks["Enter Field Office"] = true
	await _capture("03_inside")
	var initial_id: String = player.weapon_data.id
	for index in 4:
		await _tap(KEY_Q)
		var id: String = player.weapon_data.id
		var expected: String = "Rocket" if index % 2 == 0 else ("SMG" if OS.get_environment("BUNNY_PRIMARY") == "SMG" else "Rifle")
		var fired: bool = player.debug_fire_once()
		await create_timer(0.12).timeout
		var before: int = player.get_magazine_ammo()
		var reloaded: bool = player.reload_weapon()
		var after: int = player.get_magazine_ammo()
		weapon_checks.append({"id":id,"expected_pose":expected,"selected_pose":player.combat_rig.selected_pose,"fired":fired,"reload":reloaded,"ammo_before":before,"ammo_after":after})
		checks["switch_pose_"+str(index)] = player.combat_rig.selected_pose == expected
		checks["reload_"+str(index)] = reloaded and after > before
		await _capture("switch_"+str(index)+"_"+expected)
		await create_timer(1.0).timeout
	checks["Initial weapon restored"] = player.weapon_data.id == initial_id
	if not await _move_to(Vector3(-19.5, 0, 13.1)):
		await _finish("Interior traversal failed")
		return
	checks["Interior traversal"] = true
	var terminal = battle.find_child("PrototypeTerminal", true, false)
	checks["Terminal area reachable"] = player.global_position.distance_to(terminal.global_position) < 2.6
	await _capture("04_terminal")
	await _tap(KEY_E)
	var active_session = root.get_node("SortieRuntime").get_current_session()
	var terminal_state = active_session.get_objective_state(terminal.objective_id)
	checks["Terminal interaction completed"] = terminal_state != null and terminal_state.status == ObjectiveState.Status.COMPLETED
	await _capture("04b_terminal_interacted")
	if not checks["Terminal interaction completed"]:
		await _finish("Terminal interaction did not complete objective")
		return
	if not await _move_to(Vector3(-19.5, 0, 21.0)) or not await _move_to(Vector3(-16.0, 0, 21.5)) or not await _move_to(Vector3(-16.0, 0, 26.0)):
		await _finish("Exit traversal failed")
		return
	checks["Exit Field Office"] = true
	await _capture("05_exit")
	if not await _move_to(Vector3(0, 0, 30.0)) or not await _move_to(Vector3(2.5, 0, 32.0)):
		await _finish("Return route failed")
		return
	checks["Return to original route"] = true
	await _tap(KEY_E)
	await create_timer(3.5).timeout
	var session = root.get_node("SortieRuntime").get_current_session()
	checks["Extraction"] = session != null and session.status == session.Status.COMPLETED
	checks["Result"] = current_scene != null and current_scene.name == "Result"
	print("OUTCOME enemies_defeated=", session.enemies_defeated, " damage_taken=", session.damage_taken, " mission_completed=", session.mission_completed)
	await _capture("06_result")
	await _finish("")

func _move_to(target: Vector3) -> bool:
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < 12000:
		await physics_frame
		if not is_instance_valid(player) or player.get("is_dead") or current_scene != battle:
			_release()
			return false
		var offset := target - player.global_position
		offset.y = 0
		if offset.length() < 0.45:
			print("WAYPOINT ",target," reached ",player.global_position)
			_release()
			await create_timer(0.12).timeout
			return true
		_key(KEY_A, offset.x < -0.2)
		_key(KEY_D, offset.x > 0.2)
		_key(KEY_W, offset.z < -0.2)
		_key(KEY_S, offset.z > 0.2)
		_aim_and_fire()
	_release()
	print("WAYPOINT_TIMEOUT target=",target," position=",player.global_position," health=",player.get("health"))
	return false

func _aim_and_fire() -> void:
	var target: Node3D
	var distance := 32.0
	for enemy in get_nodes_in_group("enemies"):
		if not enemy is Node3D or enemy.get("is_dead"): continue
		var d: float = player.global_position.distance_to(enemy.global_position)
		if d < distance:
			distance = d
			target = enemy
	if target:
		var motion := InputEventMouseMotion.new()
		motion.position = root.get_camera_3d().unproject_position(target.global_position + Vector3.UP)
		motion.global_position = motion.position
		Input.parse_input_event(motion)
	var fire := InputEventMouseButton.new()
	fire.button_index = MOUSE_BUTTON_LEFT
	fire.position = root.get_mouse_position()
	fire.pressed = target != null
	Input.parse_input_event(fire)
	if player.get_magazine_ammo() == 0:
		_key(KEY_R, true)
		_key(KEY_R, false)

func _key(key: int, pressed: bool) -> void:
	if held.get(key, false) == pressed: return
	held[key] = pressed
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = pressed
	Input.parse_input_event(event)

func _tap(key: int) -> void:
	_key(key, true)
	await physics_frame
	_key(key, false)
	await create_timer(0.15).timeout

func _release() -> void:
	for key in held.keys(): _key(key, false)
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = false
	Input.parse_input_event(event)

func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var code := img.save_png(evidence.path_join(label + ".png"))
	print("CAPTURE ",label," ",img.get_size()," error=",code)

func _finish(reason: String) -> void:
	_release()
	checks["Combat still works"] = shots > 0
	if not reason.is_empty():
		print("ROUTE_FAIL ", reason)
		await _capture("failure")
	var session = root.get_node("SortieRuntime").get_current_session()
	var combat := {"shots": shots, "enemies_defeated": session.enemies_defeated if session else 0, "damage_taken": session.damage_taken if session else 0}
	var report := {"method": "automated input/API, not manual", "checks": checks, "failure": reason, "combat": combat, "weapon_checks": weapon_checks,
		"combat_scope": "weapon fire and normal enemy AI; kill/damage semantics are covered by regression suites",
		"mission_completed": session.mission_completed if session else false}
	var f := FileAccess.open(evidence.path_join("route_result.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  "))
	f.close()
	print(JSON.stringify(report))
	root.get_node("AudioDirector").shutdown_for_test()
	await create_timer(0.2).timeout
	quit(0 if reason.is_empty() and checks.get("Extraction", false) and checks.get("Result", false) and not checks.values().has(false) else 1)
