extends SceneTree
## Automated rendered evidence in an isolated project/profile. Not manual acceptance.
var evidence := OS.get_environment("BUNNY_EVIDENCE")
var metrics := {}

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if evidence.is_empty() or DisplayServer.get_name() == "headless":
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(evidence)
	var profiles := root.get_node("ProfileRuntime")
	var flow := root.get_node("FlowMenu")
	var game := root.get_node("GameState")
	profiles.new_profile()
	change_scene_to_file("res://scenes/presentation/slice/boot.tscn")
	await create_timer(2).timeout
	current_scene.show_menu()
	await _capture("01_menu")
	game.hideout_section = "Hanger"
	current_scene._enter()
	await create_timer(2.5).timeout
	await _capture("02_loadout")
	flow.show_pause()
	await _capture("03_pause_base")
	flow.close()
	current_scene._deploy()
	await create_timer(2).timeout
	current_scene._launch()
	await create_timer(3).timeout
	var battle := current_scene
	if not battle.get("player"):
		push_error("P0 presentation route failed to enter battle")
		quit(1)
		return
	# Let ordinary AI run for the sample, then pause for readable UI captures.
	var durations: Array[float] = []
	for index in 90:
		var start := Time.get_ticks_usec()
		await process_frame
		durations.append((Time.get_ticks_usec() - start) / 1000.0)
	durations.sort()
	metrics["renderer"] = RenderingServer.get_current_rendering_method()
	metrics["device"] = RenderingServer.get_video_adapter_name()
	metrics["sample_frames"] = durations.size()
	metrics["frame_ms_median"] = durations[45]
	metrics["frame_ms_p95"] = durations[85]
	await _capture("04_battle")
	flow.show_pause()
	await _capture("05_pause_battle")
	flow.request_leave("base")
	await _capture("06_abandon_confirmation")
	for button in flow.find_children("*", "Button", true, false):
		if button.text == "ABANDON & BASE":
			button.pressed.emit()
			break
	await create_timer(2.5).timeout
	await _capture("07_return_base")
	flow.save_path = "user://not-a-directory/save.json"
	flow.request_leave("base")
	await _capture("08_save_failure")
	flow.close()
	var corrupt_path := "user://presentation_corrupt.json"
	var broken := FileAccess.open(corrupt_path, FileAccess.WRITE)
	broken.store_string("{ incomplete save")
	broken.close()
	profiles.initialize(corrupt_path)
	flow.show_save_recovery()
	await _capture("09_save_recovery")
	flow.close()
	var f := FileAccess.open(evidence.path_join("metrics.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(metrics, "\t"))
	f.close()
	root.get_node("AudioDirector").shutdown_for_test()
	print("P0_PRESENTATION_PROBE: PASS ", metrics)
	await create_timer(0.2).timeout
	quit()

func _capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(evidence.path_join(name + ".png"))
