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
	await _loot_input_contract(battle, presentation, player)
	await _cargo_exchange_contract(battle, presentation, player)
	# Reproduce focus notification during a busy child traversal. The real
	# pause UI must be deferred, not allocated into a temporarily locked parent.
	var focus_event := func(_child: Node): FlowMenu._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	FlowMenu.child_entered_tree.connect(focus_event)
	var focus_fixture := Node.new()
	FlowMenu.add_child(focus_fixture)
	FlowMenu.child_entered_tree.disconnect(focus_event)
	check(not get_tree().paused, "Focus-loss pause waits for safe tree mutation")
	await get_tree().process_frame
	await get_tree().process_frame
	check(get_tree().paused and FlowMenu.mode == "pause" and FlowMenu.screen.is_inside_tree(), "Deferred focus pause has a real attached UI")
	FlowMenu.close()
	focus_fixture.free()
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

func _loot_input_contract(battle: Node, presentation: Node, player: PlayerController) -> void:
	var original := player.global_position
	player.global_position = presentation.container.global_position + Vector3.RIGHT
	player.velocity = Vector3.ZERO
	await get_tree().physics_frame
	presentation._show_loot()
	check(player.aim_input_captured and not get_tree().paused, "Loot captures aim without pausing combat")
	var aim := player.aim_direction
	var point := player.aim_world_point
	var ammo := player.get_magazine_ammo()
	await _loot_capture("loot_open")
	get_viewport().warp_mouse(Vector2(1100,210))
	Input.action_press("aim_left")
	Input.action_press("fire")
	player._fire_queued = true
	for frame in 8: await get_tree().physics_frame
	check(player.aim_direction.is_equal_approx(aim) and player.aim_world_point.is_equal_approx(point), "Loot cursor/stick cannot rotate player or camera aim lead")
	check(player.get_magazine_ammo()==ammo and not player._fire_queued, "Loot blocks held and buffered fire without consuming rounds")
	Input.action_release("aim_left")
	await _loot_capture("loot_cursor_moved")
	var health := player.health
	player.take_damage(1.0)
	check(player.health<health, "Loot does not grant damage immunity")
	var start := player.global_position
	Input.action_press("move_right")
	for frame in 6: await get_tree().physics_frame
	Input.action_release("move_right")
	check(player.global_position.distance_to(start)>.05, "Movement remains available while inspecting loot")
	presentation._close_loot()
	check(not player.aim_input_captured and not Input.is_action_pressed("fire"), "Closing loot releases capture without replaying held fire")
	Input.action_press("aim_right")
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release("aim_right")
	check(not player.aim_direction.is_equal_approx(aim), "Aiming resumes after closing loot")
	player.global_position = presentation.container.global_position + Vector3.RIGHT
	player.velocity = Vector3.ZERO
	presentation._show_loot()
	player.global_position += Vector3.RIGHT * 5
	await get_tree().process_frame
	await get_tree().process_frame
	check(not is_instance_valid(presentation.panel) and not player.aim_input_captured, "Walking out of range closes loot and releases aim capture")
	player.global_position = original
	player.velocity = Vector3.ZERO

func _loot_capture(label: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args(): return
	await get_tree().create_timer(.8).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_environment("BUNNY_EVIDENCE").path_join(label+".png"))

func _cargo_exchange_contract(battle: Node, presentation: Node, player: PlayerController) -> void:
	var original := player.position
	var cargo := ItemInstance.new(&"material.scrap",1)
	check(battle.session.inventory.add_item_preserving_instance(cargo), "Exchange fixture uses actual carried cargo")
	var pickup: LootPickup = presentation.container.contents()[0]
	var incoming_id := pickup.item_instance.instance_id
	player.global_position = presentation.container.global_position + Vector3.RIGHT
	player.velocity = Vector3.ZERO
	presentation.exchange_id = cargo.instance_id
	presentation._show_loot()
	await _loot_capture("cargo_exchange_before")
	var exchange: Button
	for button in presentation.panel.find_children("*","Button",true,false):
		if button.text == "EXCHANGE":
			exchange = button
			break
	check(exchange != null and not exchange.disabled, "Actual UI exposes selected cargo exchange")
	if exchange: exchange.pressed.emit()
	check(battle.session.inventory.contains(incoming_id) and not battle.session.inventory.contains(cargo.instance_id), "UI exchange changes actual carried inventory")
	check(pickup.item_instance == cargo and not pickup.consumed, "Replaced cargo remains in original world pickup")
	check(player.aim_input_captured and not get_tree().paused, "Exchange retains loot input capture without stopping battle")
	var world := SortieCheckpoint.capture_world(battle)
	check(SortieCheckpoint.validate_world(world,battle), "Checkpoint accepts swapped ownership without duplicate item IDs")
	var restored := SortieCheckpoint.restore_session(SortieCheckpoint.session_data(battle.session))
	check(restored != null and restored.inventory.contains(incoming_id) and not restored.inventory.contains(cargo.instance_id), "Session roundtrip preserves exchanged cargo")
	await _loot_capture("cargo_exchange_after")
	# A stale click after leaving range cannot remotely move items.
	presentation.exchange_id = incoming_id
	player.global_position += Vector3.RIGHT * 10
	presentation._exchange(pickup)
	check(pickup.item_instance == cargo and battle.session.inventory.contains(incoming_id), "Out-of-range exchange rejected")
	presentation._close_loot()
	check(SortieCheckpoint.restore_world(world,battle), "World roundtrip restores exchanged cache through existing checkpoint format")
	var restored_cargo := false
	for remaining in presentation.container.contents():
		if remaining.item_instance.instance_id == cargo.instance_id: restored_cargo = true
	check(restored_cargo, "Left-behind salvage remains available after world restoration")
	player.position = original
	player.velocity = Vector3.ZERO
