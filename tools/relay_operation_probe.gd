extends "res://tools/ammo_packing_probe.gd"
## Real Operations selection/deploy UI. Initial tutorial completion is a fixture;
## separate streets_combat_run --relay covers combat/repair/loot/extraction.
func _run() -> void:
	if evidence.is_empty() or DisplayServer.get_name() == "headless": quit(2);return
	DirAccess.make_dir_recursive_absolute(evidence)
	var profile = root.get_node("ProfileRuntime").new_profile()
	profile.first_mission_completed = true
	root.get_node("GameState").presentation_enabled = true
	change_scene_to_file("res://scenes/presentation/slice/hideout.tscn")
	await _frames(90)
	current_scene.show_section("Operations")
	await _frames(10)
	var choice = current_scene.screen.get_node("MissionChoice")
	check(choice.item_count == 2,"normal Operations offers records and repair")
	choice.select(1);choice.item_selected.emit(1)
	await _frames(10)
	check(current_scene.screen.get_node("MissionChoice").selected == 1,"real selection remains relay after UI refresh")
	for locale in ["en","zh_CN"]:
		root.get_node("GameLanguage").set_language(locale,false)
		current_scene.show_section("Operations")
		await _frames(5)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(evidence.path_join("operations_"+locale+".png"))
	var deploy = null
	for button in current_scene.screen.find_children("*","Button",true,false):
		if button.text == "CONFIRM DEPLOYMENT": deploy = button
	await _click(deploy)
	for frame in 900:
		await _frames(1)
		if current_scene and current_scene.scene_file_path.ends_with("battle.tscn") and not root.get_node("GameState").is_transitioning(): break
	check(current_scene.scene_file_path.ends_with("battle.tscn"),"normal deployment reaches battle")
	if current_scene.scene_file_path.ends_with("battle.tscn"):
		var battle = current_scene
		check(battle.session.mission_id == &"streets_relay","Hanger deploys actual selected mission, not default records")
		check(battle.area_root.has_node("RelayOffice") and battle.area_root.has_node("RelayRepair"),"production field work exists")
		check(root.get_node("SortieRuntime").save_checkpoint() == OK,"actual selected mission/world saves")
		battle.area_root.route_map.expanded = true
		await _frames(120) # Inspect steady gameplay after the short arrival presentation.
		for locale in ["en","zh_CN"]:
			root.get_node("GameLanguage").set_language(locale,false)
			await _frames(5)
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(evidence.path_join("map_"+locale+".png"))
	FileAccess.open(evidence.path_join("result.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"pass":failures.is_empty()}))
	root.get_node("FlowMenu").close()
	root.get_node("SortieRuntime").clear_session()
	if is_instance_valid(current_scene): current_scene.free()
	root.get_node("AudioDirector").shutdown_for_test()
	await create_timer(.5).timeout
	print("RELAY_OPERATION_PRODUCTION: ","PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)
