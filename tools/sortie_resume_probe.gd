extends SceneTree
## Actual production scenes/menu callbacks, rendered with an isolated profile.
## Button callbacks are API automation, not a claim of human keyboard/mouse testing.
var evidence := OS.get_environment("BUNNY_EVIDENCE")
var failures: Array[String] = []

func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	if evidence.is_empty() or DisplayServer.get_name() == "headless": quit(2); return
	DirAccess.make_dir_recursive_absolute(evidence)
	var profiles := root.get_node("ProfileRuntime")
	var runtime := root.get_node("SortieRuntime")
	var flow := root.get_node("FlowMenu")
	var language := root.get_node("GameLanguage")
	var saved_service = load("res://scripts/systems/save_service.gd")
	if "--load" in OS.get_cmdline_user_args():
		check(profiles.load_profile(), "separate process loads suspended production profile")
	else:
		var profile = profiles.new_profile()
		profile.first_mission_completed = true # Explicit Streets-access fixture; no tutorial completion claim.
		check(profiles.save_profile() == OK, "isolated Streets fixture saved")
	change_scene_to_file("res://scenes/presentation/slice/boot.tscn")
	await create_timer(1.7).timeout
	language.set_language("zh_CN", false)
	current_scene.show_menu()
	if "--load" in OS.get_cmdline_user_args():
		await _capture("04_resume_menu")
		check(_press(current_scene, "RESUME SORTIE"), "normal menu exposes Resume Sortie")
		await create_timer(2.0).timeout
		check(current_scene.scene_file_path == "res://scenes/battle/battle.tscn", "normal menu restores battle, not base")
		flow.show_pause()
		var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(evidence.path_join("expected.json")))
		var actual = profiles.get_profile().sortie_checkpoint
		check(actual.session.id == expected.session.id, "same logical sortie ID")
		# Expected JSON has float numbers; compare both sides in that same representation.
		check(JSON.parse_string(JSON.stringify(actual.session.weapons)) == expected.session.weapons, "loaded rounds are not replenished")
		check(JSON.parse_string(JSON.stringify(actual.session.inventory)) == expected.session.inventory, "carried inventory is not rerolled")
		check(current_scene.player.position.distance_to(Vector3(expected.world.player.position[0], expected.world.player.position[1], expected.world.player.position[2])) < 0.6, "player resumes at saved location")
		await _capture("05_resumed_pause")
		flow.close()
		await _capture("06_resumed_streets")
		# Settlement integration only: actual extraction API, not a traversal claim.
		var exit: Node
		for candidate in current_scene.area_root.find_children("*", "ExtractionPoint", true, false):
			if candidate.available: exit = candidate; break
		check(exit.extract(current_scene.session), "restored sortie can extract")
		await create_timer(4.3).timeout
		check(current_scene.scene_file_path == "res://scenes/result/result.tscn", "restored sortie reaches normal Result")
		current_scene._return_to_hanger()
		await create_timer(1.8).timeout
		check(current_scene.scene_file_path == "res://scenes/presentation/slice/hideout.tscn", "Result returns to normal Hideout")
		check(saved_service.load_profile().sortie_checkpoint.is_empty(), "settled production save has no stale checkpoint")
		await _capture("07_returned_hideout")
		_finish()
		return
	check(_press(current_scene, "CONTINUE / BASE"), "menu continue callback")
	await create_timer(1.8).timeout
	current_scene.show_section("Operations")
	check(_press(current_scene, "CONFIRM DEPLOYMENT"), "actual mission deployment button")
	await create_timer(1.8).timeout
	check(not profiles.get_profile().sortie_checkpoint.is_empty(), "deployment creates journal automatically")
	_press(current_scene, "SKIP  /  ENTER")
	await create_timer(2.0).timeout
	check(current_scene.scene_file_path == "res://scenes/battle/battle.tscn", "production deployment enters battle")
	flow.close()
	Input.action_press("move_right")
	await create_timer(.7).timeout
	Input.action_release("move_right")
	Input.action_press("fire")
	await create_timer(.3).timeout
	Input.action_release("fire")
	current_scene.player.reload_weapon()
	flow.show_pause()
	await _capture("01_suspend_pause")
	check(_press(flow, "SUSPEND / MAIN MENU"), "actual suspend/menu button")
	var expected: Dictionary = profiles.get_profile().sortie_checkpoint.duplicate(true)
	await create_timer(1.8).timeout
	check(current_scene.scene_file_path == "res://scenes/presentation/slice/boot.tscn" and runtime.get_current_session() == null, "suspend opens menu and unloads live session")
	current_scene.show_menu()
	await _capture("02_suspended_menu")
	check(_press(current_scene, "RESUME SORTIE"), "resume button callback")
	await create_timer(1.8).timeout
	check(current_scene.scene_file_path == "res://scenes/battle/battle.tscn" and current_scene.session.session_id == expected.session.id, "menu roundtrip resumes same sortie")
	flow.show_pause()
	await _capture("03_before_quit")
	check(runtime.save_checkpoint() == OK, "pre-quit snapshot")
	var file := FileAccess.open(evidence.path_join("expected.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(profiles.get_profile().sortie_checkpoint)); file.close()
	# This invokes real production quit, not a test-only clear/save surrogate.
	check(_press(flow, "SUSPEND / SAVE & QUIT"), "actual suspend/quit button")
	_finish(false)

func _press(node: Node, caption: String) -> bool:
	for button in node.find_children("*", "Button", true, false):
		if button.text == caption and button.is_visible_in_tree() and not button.disabled:
			button.pressed.emit()
			return true
	return false

func _capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(evidence.path_join(name + ".png")) == OK, "capture " + name)

func check(value: bool, message: String) -> void:
	print("RESUME_GRAPH %s: %s" % ["PASS" if value else "FAIL", message])
	if not value: failures.append(message)

func _finish(quit_now := true) -> void:
	root.get_node("AudioDirector").shutdown_for_test()
	print("SORTIE_RESUME_GRAPH: " + ("PASS" if failures.is_empty() else "FAIL"))
	if quit_now or not failures.is_empty(): quit(0 if failures.is_empty() else 1)
