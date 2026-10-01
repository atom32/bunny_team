extends Node

var failures: Array[String] = []

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	await get_tree().process_frame
	get_tree().current_scene = null
	var profile := ProfileRuntime.new_profile()
	var hideout = load("res://scenes/presentation/slice/hideout.tscn").instantiate()
	get_tree().root.add_child(hideout)
	get_tree().current_scene = hideout
	hideout.show_section("Hanger")
	var ar_id := ""
	var smg_id := ""
	for item in profile.inventory.get_items():
		if item.definition_id == &"weapon.assault_rifle_01": ar_id = item.instance_id
		if item.definition_id == &"weapon.smg_01": smg_id = item.instance_id
	hideout.hanger.hanger_ui.weapon_selected.emit(ar_id)
	hideout.hanger.hanger_ui.secondary_weapon_selected.emit(smg_id)
	_check(FirstMissionPreparation.has_starter_kit(profile), "Manual Hanger selections equip the starter weapons")
	_check(not profile.bunny_selected, "Manual selection does not require the Overview character button")
	hideout.show_section("Overview")
	_check(_button(hideout.screen, "FIRST MISSION / DEPLOY") != null, "Overview recognizes manually equipped weapons")
	hideout.show_section("Hanger")
	_button(hideout.hanger.hanger_ui, "MISSION TERMINAL").pressed.emit()
	_check(hideout.section == "Operations", "Hanger mission button opens Operations")
	_button(hideout.screen, "CONFIRM DEPLOYMENT").pressed.emit()
	var session := SortieRuntime.get_current_session()
	_check(session != null and session.mission_id == &"first_mission", "Confirm starts First Mission without hidden selection flag")
	_check(profile.bunny_selected, "Successful first deployment records Bunny selection")
	while GameState.is_transitioning():
		await get_tree().process_frame
	var deployment := get_tree().current_scene
	_check(deployment != null and deployment.scene_file_path.ends_with("deployment.tscn"), "Deployment scene opens")
	if deployment != null:
		deployment._launch()
		while GameState.is_transitioning():
			await get_tree().process_frame
		var battle := get_tree().current_scene
		_check(battle != null and battle.has_node("FirstMissionDirector"), "Manual loadout reaches the playable first mission")
		get_tree().current_scene = null
		battle.queue_free()
		await get_tree().process_frame
	SortieRuntime.clear_session()
	AudioDirector.shutdown_for_test()
	print("HANGER_FIRST_MISSION_TEST ", "PASS" if failures.is_empty() else "FAIL")
	get_tree().quit(0 if failures.is_empty() else 1)

func _button(root: Node, text: String) -> Button:
	for button in root.find_children("*", "Button", true, false):
		if button.text == text: return button
	return null

func _check(condition: bool, message: String) -> void:
	if condition: print("PASS / ", message)
	else:
		failures.append(message)
		push_error(message)
