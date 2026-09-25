extends Node

const BATTLE_SCENE := preload("res://scenes/battle/battle.tscn")

var battle: Node3D
var player: PlayerController
var phase_label: Label
var _advance_requested := false


func _ready() -> void:
	var profile := ProfileRuntime.new_profile()
	SortieRuntime.start_sortie(profile.create_sortie_request(), profile)
	battle = BATTLE_SCENE.instantiate()
	add_child(battle)
	player = battle.player
	battle.result_transition_enabled = false
	player.max_health = 10000.0
	player.health = 10000.0
	player.global_position = Vector3(0.0, 0.1, 12.0)
	player.collision_mask = 0
	battle.camera.size = 4.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
	await get_tree().process_frame
	await get_tree().physics_frame
	_build_phase_label()
	if "--movement-only" in OS.get_cmdline_user_args():
		Input.action_press("move_forward")
		Input.action_press("aim_right")
		phase_label.text = "RUN FORWARD | AIM RIGHT 90 DEG | LOOP"
		return
	await _wait_for_enter("READY | TWO-HAND AR")

	Input.action_press("move_forward")
	Input.action_press("aim_right")
	await _wait_for_enter("RUN FORWARD | AIM RIGHT 90 DEG")

	Input.action_release("move_forward")
	Input.action_press("move_left")
	Input.action_press("fire")
	await _wait_for_enter("RUN LEFT | AIM RIGHT | FIRE")

	Input.action_release("move_left")
	Input.action_release("aim_right")
	Input.action_press("aim_left")
	await _wait_for_enter("IDLE | AIM LEFT | FIRE")

	Input.action_release("fire")
	player.combat_rig.reload_duration = 3.0
	player.debug_reload_once()
	await _wait_for_enter("AR RELOAD | LEFT HAND TO MAG")
	while player.combat_rig.is_reloading():
		await get_tree().physics_frame
	await _wait_for_enter("RELOAD RECOVERY | BOTH HANDS RETURN")

	Input.action_release("aim_left")
	Input.action_press("aim_right")
	Input.action_press("move_forward")
	Engine.time_scale = 0.08
	Input.action_press("dodge")
	await get_tree().physics_frame
	Input.action_release("dodge")
	await _wait_for_enter("DODGE | WEAPON STAYS BETWEEN HANDS")
	Engine.time_scale = 1.0
	while player._dodge_time > 0.0:
		await get_tree().physics_frame
	Input.action_press("fire")
	await _wait_for_enter("POST-DODGE | IMMEDIATE FIRE")

	_release_actions()
	phase_label.text = "VISUAL PASS COMPLETE | R TO REPLAY"
	if DisplayServer.get_name() == "headless":
		await _finish_headless()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_advance_requested = true
	if event.is_action_pressed("reload") and phase_label and phase_label.text.begins_with("VISUAL PASS"):
		get_tree().reload_current_scene()


func _wait_for_enter(title: String) -> void:
	if DisplayServer.get_name() == "headless":
		await get_tree().create_timer(0.12).timeout
		return
	_advance_requested = false
	phase_label.text = "%s | ENTER" % title
	while not _advance_requested:
		await get_tree().process_frame


func _release_actions() -> void:
	for action in ["move_forward", "move_left", "aim_right", "aim_left", "fire", "dodge"]:
		Input.action_release(action)


func _build_phase_label() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := ColorRect.new()
	panel.position = Vector2(286.0, 12.0)
	panel.size = Vector2(344.0, 34.0)
	panel.color = Color("101823dd")
	layer.add_child(panel)
	phase_label = Label.new()
	phase_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	phase_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	phase_label.add_theme_color_override("font_color", Color("79f1e7"))
	phase_label.add_theme_font_size_override("font_size", 13)
	panel.add_child(phase_label)


func _exit_tree() -> void:
	Engine.time_scale = 1.0
	_release_actions()


func _finish_headless() -> void:
	# Complete the scripted visual smoke instead of leaving an Enter coroutine
	# suspended until --quit-after tears down its scene resources.
	set_process(false)
	battle.queue_free()
	await get_tree().process_frame
	SortieRuntime.clear_session()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(0.2).timeout
	print("VISUAL_COMBAT_ACCEPTANCE: PASS (scripted smoke; no visual assertion)")
	get_tree().quit(0)
