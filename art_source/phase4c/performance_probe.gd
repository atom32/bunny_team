extends SceneTree
## Static rendering cost at the exact production camera, NOT gameplay FPS.
var folder := OS.get_environment("BUNNY_EVIDENCE")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	# Benchmark-only settings; no project or production runtime setting changes.
	OS.low_processor_usage_mode = false
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	change_scene_to_file("res://scenes/hanger/hanger.tscn")
	await create_timer(.6).timeout
	for button in current_scene.find_children("*","Button",true,false):
		if button.text=="DEPLOY":
			button.pressed.emit()
			break
	await create_timer(.8).timeout
	paused = true
	var presentation = current_scene.find_child("UrbanDefensePresentation",true,false)
	var report := {}
	for state in ["before_1","after_1","after_2","before_2"]:
		presentation.set_presentation_visible(state.begins_with("after"))
		for frame in 60: await RenderingServer.frame_post_draw
		var samples := []
		var focused := 0
		var last := Time.get_ticks_usec()
		for frame in 120:
			await RenderingServer.frame_post_draw
			var now := Time.get_ticks_usec()
			samples.append((now-last)/1000.0)
			last=now
			if DisplayServer.window_is_focused(): focused+=1
		var sum := 0.0
		for value in samples: sum+=value
		samples.sort()
		report[state] = {"wall_render_interval_ms_mean":sum/samples.size(),"wall_render_interval_ms_p95":samples[114],"wall_render_interval_ms_median":samples[60],"focused_samples":focused,
			"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
			"render_video_memory_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),
			"texture_memory_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)}
		if state.ends_with("1"): root.get_texture().get_image().save_png(folder.path_join("arena_"+state.trim_suffix("_1")+".png"))
	report["scope"] = "1280x720 production Sortie camera, same frozen scene ABBA; VSync off, 60 warmup + 120 frames each; wall render interval, NOT GPU timing or combat FPS; engine allocated video memory, NOT board-wide VRAM"
	var f := FileAccess.open(folder.path_join("performance.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify(report,"  "))
	paused=false
	root.get_node("AudioDirector").shutdown_for_test()
	quit()
