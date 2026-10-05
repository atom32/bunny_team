extends SceneTree
var evidence := OS.get_environment("BUNNY_EVIDENCE")
var checks := 0
func _initialize(): run.call_deferred()
func capture(label: String):
	await create_timer(0.85).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(evidence.path_join(label+".png"))
func run():
	root.get_node("ProfileRuntime").new_profile()
	change_scene_to_file("res://scenes/presentation/slice/boot.tscn")
	await create_timer(2).timeout
	current_scene.show_menu()
	await capture("menu")
	current_scene._enter()
	await create_timer(3).timeout
	assert(current_scene.scene_file_path.ends_with("hideout.tscn")); checks += 1
	await capture("hideout")
	var hub = current_scene
	assert(not hub.screen.get_node("CampaignPanel").visible); checks += 1
	hub.screen.get_node("ContractsToggle").pressed.emit()
	assert(hub.screen.get_node("CampaignPanel").visible); checks += 1
	await capture("contracts")
	for section in ["Hanger","Operations","Workshop","Rest","Overview"]:
		hub.show_section(section)
		await capture(section.to_lower())
		assert(hub.hanger.preview_character != null); checks += 1
		assert(hub.hanger.hanger_ui.visible == (section == "Hanger")); checks += 1
	print("ENTRANCE_PRESENTATION: PASS ",checks," checks")
	root.get_node("AudioDirector").shutdown_for_test()
	quit()
