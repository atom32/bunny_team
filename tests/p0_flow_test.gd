extends Node
var failures: Array[String] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")

func _run() -> void:
	await get_tree().process_frame
	# Keep the test coordinator alive across real scene changes.
	get_tree().current_scene = null
	ProfileRuntime.new_profile()
	GameState.presentation_enabled = false
	FlowMenu.save_path = "user://p0_flow.json"
	var boot = load("res://scenes/presentation/slice/boot.tscn").instantiate()
	get_tree().root.add_child(boot)
	GameLanguage.set_language("en", false)
	get_tree().current_scene = boot
	boot._intro(0)
	boot.opening = true
	await _escape()
	check(not boot.opening and not FlowMenu.is_open(), "Esc skips opening without opening pause")
	boot._settings()
	await _escape()
	check(not boot.settings_open and not FlowMenu.is_open(), "Esc leaves settings first")
	boot.queue_free()
	get_tree().current_scene = null
	await get_tree().process_frame
	var hideout = load("res://scenes/presentation/slice/hideout.tscn").instantiate()
	get_tree().root.add_child(hideout)
	get_tree().current_scene = hideout
	hideout.show_section("Operations")
	var profile := ProfileRuntime.get_profile()
	profile.loadout.unequip(LoadoutState.SLOT_WEAPON_PRIMARY)
	profile.loadout.unequip(LoadoutState.SLOT_WEAPON_SECONDARY)
	hideout._deploy()
	check(FlowMenu.is_open() and hideout.ui.visible and SortieRuntime.get_current_session() == null, "Failed deployment keeps hub UI and reports reason")
	FlowMenu.close()
	hideout.queue_free()
	get_tree().current_scene = null
	await get_tree().process_frame
	profile = ProfileRuntime.new_profile()
	GameState.presentation_enabled = false
	var plan := DeploymentPlan.build(profile)
	var session := SortieRuntime.start_sortie(profile.create_sortie_request(SortieRequest.PROTOTYPE_AREA_ID, SortieRequest.PROTOTYPE_MISSION_ID, plan.ammo_ids), profile)
	check(session != null, "Gameplay fixture starts")
	get_tree().change_scene_to_file("res://scenes/battle/battle.tscn")
	await get_tree().process_frame
	await get_tree().process_frame
	var battle := get_tree().current_scene
	var player: PlayerController = battle.player
	var presentation := battle.get_node("SlicePresentation")
	presentation.container = presentation.crates.values()[0]
	presentation._show_loot()
	await _escape()
	check(not is_instance_valid(presentation.panel) and not FlowMenu.is_open(), "Esc closes loot before opening pause")
	var enemy := battle.enemy_container.get_child(0) as EnemyController
	enemy.target = player
	enemy._telegraph_shot()
	var before_position := player.global_position
	var before_ammo := player.get_magazine_ammo()
	Input.action_press("fire")
	player._fire_queued = true
	await _escape()
	check(FlowMenu.mode == "pause" and get_tree().paused, "Esc pauses live combat")
	check(not Input.is_action_pressed("fire") and not player._fire_queued, "Pause flushes held and buffered fire")
	Input.action_press("move_forward")
	await get_tree().create_timer(0.55, true).timeout
	check(player.global_position == before_position and player.get_magazine_ammo() == before_ammo, "Paused combat does not move or shoot")
	check(enemy._is_telegraphing, "Pending enemy shot timer freezes during pause")
	await _escape()
	check(not get_tree().paused and not FlowMenu.is_open(), "Esc resumes")
	await get_tree().physics_frame
	check(player.get_magazine_ammo() == before_ammo and not Input.is_action_pressed("move_forward"), "Resume does not replay buffered controls")
	FlowMenu.request_leave("base")
	check(FlowMenu.mode == "confirm" and session.status == SortieSession.Status.ACTIVE, "Leaving active combat requires abandon confirmation")
	_button("CANCEL / KEEP PLAYING").pressed.emit()
	check(not get_tree().paused and session.status == SortieSession.Status.ACTIVE, "Cancel returns to unchanged live session")
	FlowMenu._notification(NOTIFICATION_WM_CLOSE_REQUEST)
	check(FlowMenu.mode == "confirm", "Window close uses abandon confirmation")
	FlowMenu.close()
	FlowMenu.request_leave("base")
	_button("ABANDON & BASE").pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	check(SortieRuntime.get_current_session() == null and get_tree().current_scene.scene_file_path.ends_with("hanger.tscn"), "Abandon returns to real base and clears session")
	check(not get_tree().paused and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Base is interactive after abandon")
	# Save failure exits have a reachable in-memory continuation.
	FlowMenu.save_path = "user://missing-folder/flow.json"
	FlowMenu.request_leave("base")
	check(FlowMenu.mode == "save_failure" and get_tree().paused, "Save failure is visible with recovery controls")
	_button("CONTINUE WITHOUT SAVING").pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	check(not FlowMenu.is_open() and not get_tree().paused, "Explicit in-memory continuation returns control")
	check(GameState.present_scene("res://missing-scene.tscn", "TEST") == ERR_FILE_NOT_FOUND and not GameState.is_transitioning(), "Missing scene does not leave transition busy")
	FlowMenu.save_path = "user://p0_flow.json"
	get_tree().change_scene_to_file("res://scenes/result/result.tscn")
	await get_tree().process_frame
	await get_tree().process_frame
	check(FlowMenu.mode == "fatal", "Missing Result session opens a recovery surface")
	_button("DISCARD UNAVAILABLE SORTIE / RETURN TO BASE").pressed.emit()
	_button("DISCARD SORTIE / RETURN TO BASE").pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	check(not get_tree().paused and get_tree().current_scene.scene_file_path.ends_with("hanger.tscn"), "Invalid Result can return to an interactive base")
	FlowMenu.save_path = SaveService.DEFAULT_SAVE_PATH
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(0.2).timeout
	for failure in failures:
		push_error(failure)
	print("P0_FLOW_TEST: " + ("PASS" if failures.is_empty() else "FAIL"))
	get_tree().quit(0 if failures.is_empty() else 1)

func _escape() -> void:
	var key := InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.pressed = true
	Input.parse_input_event(key)
	await get_tree().process_frame
	key = InputEventKey.new()
	key.keycode = KEY_ESCAPE
	Input.parse_input_event(key)
	await get_tree().process_frame

func _button(caption: String) -> Button:
	for button in FlowMenu.find_children("*", "Button", true, false):
		if button.text == caption: return button
	return null

func check(condition: bool, description: String) -> void:
	if not condition: failures.append(description)
