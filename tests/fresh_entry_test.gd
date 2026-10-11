extends Node
var failures: Array[String] = []

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var profile := ProfileRuntime.new_profile()
	GameLanguage.set_language("zh_CN",false)
	GameState.presentation_enabled = true
	check(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/presentation/slice/boot.tscn", "Normal entry uses the presentation boot")
	check(ContentDB.get_area_definition(&"first_mission_area").scene.resource_path == "res://scenes/areas/first_mission.tscn", "New saves retain the original tutorial until refurbishment")
	check(ResourceLoader.exists("res://scenes/areas/first_mission.tscn"), "Original tutorial art remains available")
	var hideout = load("res://scenes/presentation/slice/hideout.tscn").instantiate()
	add_child(hideout)
	hideout.show_section("Operations")
	var notice = hideout.screen.find_child("LegacyTutorialNotice", true, false)
	check(notice != null and notice.text == "旧教学场景 / 未翻新的教程", "Fresh briefing explicitly labels the unrefurbished tutorial")
	hideout.queue_free()
	await get_tree().process_frame
	var session := SortieRuntime.start_sortie(profile.create_sortie_request(&"first_mission_area",&"first_mission"),profile)
	check(session != null, "Fresh deployment has a real session")
	var deployment = load("res://scenes/presentation/slice/deployment.tscn").instantiate()
	add_child(deployment)
	deployment.set_process(false)
	check(deployment._destination() == tr("TUTORIAL / UNREFURBISHED"), "Tutorial departure identifies the unrefurbished area")
	check(deployment.screen.find_child("DeploymentDestination", true, false).text == tr("BASTION 07 → %s") % deployment._destination(), "Departure caption uses the actual session destination")
	# Presentation reads the selected area and time without changing the sortie.
	session.area_id = &"street_district"
	for variant in ["day", "night"]:
		session.lighting_variant = variant
		check(deployment._destination().contains(tr("NIGHT" if variant == "night" else "DAY")), "Campus departure identifies " + variant)
	session.area_id = &"first_mission_area"
	session.lighting_variant = "day"
	var room = deployment.get_node("DeploymentHideout")
	check(room.menu_backdrop and room.has_node("CompactEnvironment"), "Deployment reuses the current compact hideout")
	for path in ["Floor","BackWall","MaintenanceBackground"]:
		check(not room.hanger.get_node(path).visible, "Deployment hides archived Hanger shell: "+path)
	check(not room.hanger.hanger_ui.visible and not room.screen.get_child_count(), "Deployment backdrop exposes no loadout or hub controls")
	deployment._process(2.3)
	check(deployment.transit_started and deployment.status.text == tr("TRANSIT LINK OPEN / DEPLOYING"), "Chinese deployment advances its status without comparing translated text to English")
	check(deployment.camera.position.z >= 1.65 and deployment.camera.position.z <= 1.82, "Deployment camera remains inside compact room")
	deployment.launched = true
	deployment.queue_free()
	SortieRuntime.clear_session()
	await get_tree().process_frame
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(.15).timeout
	print("FRESH_ENTRY_TEST ", "PASS" if failures.is_empty() else "FAIL")
	get_tree().quit(0 if failures.is_empty() else 1)

func check(ok: bool, title: String) -> void:
	if ok: print("PASS / ", title)
	else: failures.append(title);push_error(title)
