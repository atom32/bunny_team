extends SceneTree
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	root.size=Vector2i(1280,720)
	change_scene_to_file("res://scenes/presentation/slice/hideout.tscn")
	await create_timer(0.8).timeout
	current_scene._deploy()
	var start := Time.get_ticks_msec()
	while not current_scene or current_scene.name != "Battle":
		await process_frame
		if Time.get_ticks_msec()-start>15000: quit(1); return
	# Capture after the inbound fade, before arrival camera returns to gameplay.
	await create_timer(1.1).timeout
	var arrival: bool = root.get_camera_3d() != current_scene.camera
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("BUNNY_EVIDENCE").path_join("arrival.png"))
	print("ARRIVAL_CAMERA_AFTER_FADE: ","PASS" if arrival else "FAIL")
	root.get_node("AudioDirector").shutdown_for_test()
	quit(0 if arrival else 1)

