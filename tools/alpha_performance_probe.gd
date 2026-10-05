extends "res://tests/streets_combat_run.gd"
## Rendered, real-time traversal of the existing combat route. No fixed-fps,
## disabled enemies or altered graphics settings. Uses the existing explicit
## profile fixture and objective/loot APIs; not a human or full UI playthrough.
var samples: Array[Dictionary] = []
var launch_usec := Time.get_ticks_usec()
var first_live_usec := 0
var previous_usec := 0
var startup_max_ms := 0.0
var render_size := Vector2i.ZERO
var texture_size := Vector2i.ZERO
var window_size := Vector2i.ZERO
var image_size := Vector2i.ZERO

func _run() -> void:
	if DisplayServer.get_name() == "headless" or OS.get_environment("BUNNY_EVIDENCE").is_empty():
		push_error("Rendered performance probe requires BUNNY_EVIDENCE and a graphical renderer.")
		get_tree().quit(2)
		return
	var requested := Vector2i(1920,1080) if "--perf-1080p" in OS.get_cmdline_user_args() else Vector2i(1280,720)
	if "--keep-window-size" not in OS.get_cmdline_user_args() or DisplaySettings.apply_preferences(false,requested) != OK:
		push_error("Performance probe requires --keep-window-size and writable isolated display preferences.")
		get_tree().quit(2)
		return
	await super._run()
	if image_size != requested or window_size != requested:
		failures.append("Actual render resolution did not match requested resolution")
	var report := {
		"route_pass": failures.is_empty(), "failures":failures,
		"engine":Engine.get_version_info(), "renderer":RenderingServer.get_current_rendering_method(),
		"adapter":RenderingServer.get_video_adapter_name(), "cpu":OS.get_processor_name(),
		"render_size":[render_size.x,render_size.y], "image_size":[image_size.x,image_size.y], "texture_size":[texture_size.x,texture_size.y], "window_size":[window_size.x,window_size.y], "vsync":DisplayServer.window_get_vsync_mode(), "max_fps":Engine.max_fps,
		"elapsed_wall_seconds":(Time.get_ticks_usec()-launch_usec)/1000000.0,
		"first_live_seconds":(first_live_usec-launch_usec)/1000000.0,
		"warmup_excluded_seconds":2.0, "startup_max_frame_ms":startup_max_ms,
		"sample_count":samples.size(), "frame_ms":summary("frame_ms"), "cpu_process_ms":summary("cpu_process_ms"),
		"draw_calls":summary("draw_calls"), "primitives":summary("primitives"),
		"render_resource_bytes":summary("render_resource_bytes"), "static_memory_bytes":summary("static_memory_bytes"),
		"objects":summary("objects"), "nodes":summary("nodes"),
		"shots":fired,"reloads":reloads,"recovered":recovered_ids.size(),
		"memory_note":"Godot tracked render resources, not total physical GPU VRAM residency. CPU process monitor is not a GPU timer.",
		"samples":samples}
	var out := OS.get_environment("BUNNY_EVIDENCE")
	DirAccess.make_dir_recursive_absolute(out)
	FileAccess.open(out.path_join("performance.json"),FileAccess.WRITE).store_string(JSON.stringify(report))
	print("ALPHA_PERFORMANCE samples=",samples.size()," frame_ms=",report.frame_ms," route_pass=",report.route_pass)
	if samples.size() < 120 or not failures.is_empty(): get_tree().quit(2)

func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	if not is_instance_valid(battle) or not battle.is_inside_tree(): previous_usec = now;return
	if first_live_usec == 0: first_live_usec = now
	var frame_ms := (now-previous_usec)/1000.0 if previous_usec else 0.0
	previous_usec = now
	if now-first_live_usec < 2000000:
		startup_max_ms = maxf(startup_max_ms,frame_ms)
		return
	if image_size == Vector2i.ZERO:
		var reference := get_tree().root.get_texture().get_image()
		image_size = reference.get_size()
		reference.save_png(OS.get_environment("BUNNY_EVIDENCE").path_join("reference.png"))
		previous_usec = Time.get_ticks_usec() # Exclude one-time screenshot readback/write.
		return
	render_size = get_viewport().get_visible_rect().size
	texture_size = get_tree().root.get_texture().get_size()
	window_size = DisplayServer.window_get_size()
	samples.append({"wall_seconds":(now-first_live_usec)/1000000.0,
		"frame_ms":frame_ms,"cpu_process_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000.0,
		"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		"render_resource_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),
		"static_memory_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),
		"objects":Performance.get_monitor(Performance.OBJECT_COUNT),"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT)})

func summary(field: String) -> Dictionary:
	var values: Array[float] = []
	var total := 0.0
	var over_60 := 0
	var over_30 := 0
	for sample in samples:
		var value: float = sample[field]
		values.append(value);total += value
		if value > 1000.0/60: over_60 += 1
		if value > 1000.0/30: over_30 += 1
	if values.is_empty(): return {}
	values.sort()
	var result := {"mean":total/values.size(),"p50":values[ceili(values.size()*.5)-1],"p95":values[ceili(values.size()*.95)-1],"p99":values[ceili(values.size()*.99)-1],"max":values[-1]}
	if field == "frame_ms":
		result["over_16_67ms_percent"] = 100.0*over_60/values.size()
		result["over_33_33ms_percent"] = 100.0*over_30/values.size()
	return result
