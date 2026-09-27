extends SceneTree
var checks := {}
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	change_scene_to_file("res://scenes/presentation/slice/boot.tscn")
	await create_timer(0.2).timeout
	current_scene.show_menu()
	current_scene._settings()
	var sliders = current_scene.screen.find_children("*","HSlider",true,false)
	checks["Two audio settings"] = sliders.size() == 2
	sliders[0].value = 0.35
	sliders[1].value = 0.25
	checks["Music volume works"] = is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))),0.35)
	checks["SFX volume works"] = is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX"))),0.25)
	var prefs := ConfigFile.new()
	checks["Presentation preferences saved separately"] = prefs.load("user://presentation.cfg") == OK and prefs.get_value("audio","Music") == 0.35 and prefs.get_value("opening","seen")
	current_scene.show_menu()
	for button in current_scene.screen.find_children("*","Button",true,false):
		if button.text == "LOADOUT": button.pressed.emit(); break
	await create_timer(1.5).timeout
	checks["Menu Loadout enters Hanger bay"] = current_scene.name == "Hideout" and current_scene.section == "Hanger"
	var terminal: Button
	for button in current_scene.hanger.hanger_ui.find_children("*","Button",true,false):
		if button.text == "MISSION TERMINAL": terminal=button
	checks["Hanger button clear of hub navigation"] = terminal.get_global_rect().end.y < 644
	terminal.pressed.emit()
	current_scene._deploy()
	await create_timer(0.5).timeout
	checks["Deployment scene started"] = current_scene.name == "Deployment"
	current_scene._launch() # User skipping during the still-running inbound fade.
	await create_timer(0.9).timeout
	current_scene._launch()
	await create_timer(1.5).timeout
	checks["Skip does not trap deployment"] = current_scene.name == "Battle" and current_scene.player != null
	var f := FileAccess.open(OS.get_environment("BUNNY_EVIDENCE").path_join("menu_contract.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify(checks,"  "))
	print(JSON.stringify(checks))
	root.get_node("AudioDirector").shutdown_for_test()
	quit(1 if checks.values().has(false) else 0)
