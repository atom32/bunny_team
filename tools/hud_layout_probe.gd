extends Node

var failures: Array[String] = []
var path := "user://display_probe_%s.cfg" % OS.get_process_id()

func _ready() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	if condition: print("PASS / ", message)
	else:
		failures.append(message)
		push_error(message)

func _capture(label: String) -> void:
	await get_tree().create_timer(0.3).timeout
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("/tmp/hud_"+label+".png")

func _run() -> void:
	get_tree().current_scene = null
	var original_fullscreen := DisplaySettings.fullscreen
	var original_size := DisplaySettings.window_size
	_check(DisplaySettings.apply_preferences(false, Vector2i(1600,900), path) == OK, "Window preferences save independently of profile")
	DisplaySettings.window_size = Vector2i(1280,720)
	DisplaySettings.load_preferences(path)
	_check(DisplaySettings.window_size == Vector2i(1600,900), "Selected resolution survives preference reload")
	_check(DisplaySettings.apply_preferences(false, Vector2i(1,1), path) == ERR_INVALID_PARAMETER, "Invalid resolution is rejected")
	var profile := ProfileRuntime.new_profile()
	FirstMissionPreparation.equip_starter_kit(profile)
	var plan := DeploymentPlan.build(profile)
	SortieRuntime.start_sortie(profile.create_sortie_request(&"first_mission_area", &"first_mission", plan.ammo_ids), profile)
	var battle = load("res://scenes/battle/battle.tscn").instantiate()
	add_child(battle)
	battle.player.set_physics_process(false)
	var tutorial = battle.get_node("FirstMissionDirector")
	tutorial.set_process(false)
	tutorial._refresh_destination()
	for size in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1920,1200),Vector2i(2560,1080)]:
		get_window().mode = Window.MODE_WINDOWED
		get_window().size = size
		await get_tree().process_frame
		await get_tree().process_frame
		var view := get_viewport().get_visible_rect()
		var center := Rect2(view.size * Vector2(.34,.25), view.size * Vector2(.32,.5))
		for name in ["Objectives","Vitals","Weapons"]:
			var card := battle.hud.get_child(0).get_node(name) as Control
			_check(view.encloses(card.get_global_rect()), "%s stays inside viewport %s" % [name,size])
			_check(not center.intersects(card.get_global_rect()), "%s leaves combat centre clear %s" % [name,size])
		_check(not center.intersects(tutorial.guide.get_parent().get_global_rect()), "Tutorial leaves combat centre clear %s" % size)
		await _capture("%dx%d" % [size.x,size.y])
	tutorial.stage = tutorial.Stage.CHOICE
	tutorial._refresh_guide()
	tutorial._refresh_destination()
	tutorial.choice_buttons.show()
	await _capture("choice")
	for button in tutorial.choice_buttons.get_children():
		_check(get_viewport().get_visible_rect().encloses(button.get_global_rect()), "Risk choice button remains on screen")
	var choices: Array = tutorial.choice_buttons.get_children()
	_check(not choices[0].get_global_rect().intersects(choices[1].get_global_rect()), "Risk choice buttons do not overlap")
	battle.hud.show_banner("PMC RESPONSE TEAM ARRIVED", Color.WHITE)
	battle.hud._process(3.1)
	_check(not battle.hud.banner.visible, "Combat notification expires rather than obstructing indefinitely")
	FlowMenu.show_display_settings(false)
	_check(get_tree().paused and FlowMenu.mode == "display", "Display settings pause gameplay")
	await _capture("settings")
	FlowMenu.close()
	_check(not get_tree().paused, "Closing settings resumes gameplay")
	if DisplayServer.get_name() != "headless":
		DisplaySettings.apply_preferences(true, Vector2i(1600,900), path)
		await _capture("fullscreen")
		_check(get_window().mode == Window.MODE_FULLSCREEN, "Fullscreen applies to the actual window")
	DisplaySettings.fullscreen = original_fullscreen
	DisplaySettings.window_size = original_size
	DisplaySettings._apply_window()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	battle.queue_free()
	SortieRuntime.clear_session()
	await get_tree().process_frame
	print("HUD_LAYOUT_TEST failures=", failures)
	get_tree().quit(0 if failures.is_empty() else 1)
