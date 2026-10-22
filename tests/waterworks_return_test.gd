extends Node
## Outcome/persistence tests use real session APIs; the dialogue UI is a fixture,
## not a claim that an automated player has read or enjoyed these exchanges.
const PATH := "user://waterworks_return_test.json"
const PUBLIC := "user://waterworks_return_public.json"
const TANKER := "user://waterworks_return_tanker.json"
var checks := 0
var failures: Array[String] = []

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message); push_error(message)

func _ready() -> void: _run.call_deferred()

func _frames() -> void:
	for tick in 3: await get_tree().process_frame

func _click(button: Button) -> void:
	if DisplayServer.get_name() == "headless": button.pressed.emit()
	else:
		await RenderingServer.frame_post_draw
		await get_tree().process_frame
		var presses := [0]
		var count_press := func(): presses[0] += 1
		button.pressed.connect(count_press)
		for pressed in [true, false]:
			var event := InputEventMouseButton.new()
			event.position = button.get_global_rect().get_center()
			event.button_index = MOUSE_BUTTON_LEFT
			event.pressed = pressed
			get_viewport().push_input(event)
			await get_tree().process_frame
		check(presses[0] == 1, "Native viewport click activates exactly once: " + button.name)
		button.pressed.disconnect(count_press)
	await _frames()

func _deploy(branch := "") -> SortieSession:
	SortieRuntime.clear_session()
	check(DeploymentPlan.deploy(ProfileRuntime.get_profile(), WaterworksStory.AREA, WaterworksStory.MISSION, PATH).error == OK, "Deploy through normal saved transaction")
	var session := SortieRuntime.get_current_session()
	if not branch.is_empty():
		# Settlement fixture: physical delivery is covered by waterworks_test/run.
		session.waterworks={"version":2,"branch":"public" if branch=="water_public" else "tanker","public_fix":"bypass" if branch=="water_public" else "","gate_open":branch=="water_tanker","delivered":true}
		check(session.record_objective_interaction(&"water_pump"), "Fixture records pump interaction")
		check(session.record_objective_interaction(StringName(branch)), "Fixture records one real branch objective")
		check(session.record_objective_interaction(&"water_delivery") and session.is_mission_completed() and session.validate(), "Fixture satisfies actual mission definition")
	return session

func _write(path: String, envelope: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(envelope))
	file.close()

func _read() -> void:
	for branch in ["water_public", "water_tanker"]:
		var path := PUBLIC if branch == "water_public" else TANKER
		var loaded := SaveService.load_profile(path, false)
		check(loaded != null and loaded.waterworks_memory == branch, "Separate process reload retains actual returned branch")
		if loaded:
			for contact: String in ContactDefinition.CONTACTS:
				check(WaterworksStory.return_scene(loaded, contact) == WaterworksStory.RETURNS.data[branch + "_" + contact], "Reload resolves exact authored contact scene")

func _read_prior() -> void:
	var path := "user://waterworks_prior_schema8.json"
	var envelope: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	check(envelope.schema_version == 8 and not envelope.profile.has("waterworks_memory"), "Input is actual previous schema 8 without new field")
	var loaded := SaveService.load_profile(path, false)
	var expected: Dictionary = envelope.profile.duplicate(true); expected.waterworks_memory = ""
	# JSON numbers are floats, while validated inventory/campaign values are ints.
	# Compare in the existing save format, including its existing float precision,
	# not Godot's type-sensitive nested Dictionary equality.
	var expected_saved: Variant = JSON.parse_string(JSON.stringify(expected))
	check(loaded != null and JSON.parse_string(JSON.stringify(loaded.to_dict())) == expected_saved, "Actual prior package retains all JSON-normalized values; choice stays unknown")
	if "--read-migrated-schema9" in OS.get_cmdline_user_args():
		var saved := SaveService.load_profile("user://waterworks_prior_migrated9.json", false)
		check(saved != null and JSON.parse_string(JSON.stringify(saved.to_dict())) == expected_saved, "Independent process retains all JSON-normalized migrated values")
	else:
		check(SaveService.save_profile(loaded, "user://waterworks_prior_migrated9.json") == OK, "Actual previous exported profile writes current schema")

func _run() -> void:
	if "--read-prior-schema8" in OS.get_cmdline_user_args() or "--read-migrated-schema9" in OS.get_cmdline_user_args(): _read_prior(); _finish(); return
	if "--read" in OS.get_cmdline_user_args(): _read(); _finish(); return
	SortieRuntime.clear_session()
	var profile := ProfileRuntime.new_profile()
	profile.first_mission_completed = true
	check(profile.waterworks_memory.is_empty() and WaterworksStory.return_scene(profile, "tang_kui").is_empty(), "No prior return means no invented memory")
	var first_outcome: SortieOutcome
	for branch in ["water_public", "water_tanker"]:
		var previous_memory := profile.waterworks_memory
		var session := _deploy(branch)
		check(profile.waterworks_memory == previous_memory, "Choosing in the field does not publish a base memory")
		check(session.complete_extraction(), "Successful extraction through actual session API")
		var outcome := SortieRuntime.get_outcome()
		if branch == "water_public": first_outcome = outcome
		var before := profile.to_dict()
		check(SortieRuntime.finalize_sortie("user://missing_return_directory/profile.json") != OK, "Unwritable destination prevents settlement")
		check(profile.to_dict() == before and SortieRuntime.get_outcome() == outcome, "Failed save publishes neither memory nor rewards; retry retains outcome")
		check(SortieRuntime.finalize_sortie(PATH) == OK and profile.waterworks_memory == branch, "Durable return commits exact branch with rewards")
		var saved := PUBLIC if branch == "water_public" else TANKER
		check(SaveService.save_profile(profile, saved) == OK, "Write real settled branch for independent process")
		before = profile.to_dict()
		check(SortieOutcomeService.commit_outcome(profile, outcome) == OK and profile.to_dict() == before, "Duplicate settlement never rewards or mutates memory twice")
	check(SortieOutcomeService.commit_outcome(profile, first_outcome) == OK and profile.waterworks_memory == "water_tanker", "Replaying old settled outcome cannot roll latest memory backward")
	var retreat := _deploy()
	check(retreat.complete_extraction() and SortieRuntime.finalize_sortie(PATH) == OK and profile.waterworks_memory == "water_tanker", "Successful early retreat does not invent or erase delivery")
	check(DeploymentPlan.deploy(profile, &"street_district", &"streets_recon", PATH).error == OK, "Deploy unrelated sortie normally")
	check(SortieRuntime.get_current_session().complete_extraction() and SortieRuntime.finalize_sortie(PATH) == OK and profile.waterworks_memory == "water_tanker", "Unrelated sortie does not erase last successful waterworks return")
	for result in ["failed", "abandoned"]:
		# Restore real successful inventory before each destructive fixture.
		check(ProfileRuntime.load_profile(TANKER), "Restore known successful profile for destructive fixture")
		profile = ProfileRuntime.get_profile()
		var session := _deploy("water_public")
		check(session.fail() if result == "failed" else session.abandon(), "Fixture closes sortie: " + result)
		check(SortieRuntime.finalize_sortie(PATH) == OK and profile.waterworks_memory == "water_tanker", "Completed field objective without safe return never changes memory: " + result)
	var legacy := SaveService.load_profile(TANKER, false).to_dict()
	legacy.erase("waterworks_memory")
	_write("user://waterworks_legacy8.json", {"schema_version": 8, "profile": legacy})
	var migrated := SaveService.load_profile("user://waterworks_legacy8.json", false)
	var expected := legacy.duplicate(true); expected.waterworks_memory = ""
	check(migrated != null and migrated.to_dict() == expected, "Schema 8 migration preserves every old field; unknown choice stays empty")
	check(SaveService.save_profile(migrated, "user://waterworks_migrated9.json") == OK, "Migrated profile writes schema 11")
	_write("user://waterworks_invalid.json", {"schema_version": 9, "profile": legacy})
	check(SaveService.load_profile("user://waterworks_invalid.json", false) == null, "Schema 9 requires memory field")
	for bad in [null, false, 1, [], {}, "both", "water_pump"]:
		var data := expected.duplicate(true); data.waterworks_memory = bad
		_write("user://waterworks_invalid.json", {"schema_version": 9, "profile": data})
		check(SaveService.load_profile("user://waterworks_invalid.json", false) == null, "Reject invalid memory value: " + str(bad))
	_read()
	await _ui()
	_finish()

func _ui() -> void:
	get_window().size = Vector2i(1280, 720)
	var panel := ContactPanel.new()
	panel.position = Vector2(24, 24); panel.size = Vector2(1232, 672)
	add_child(panel)
	var seen := {}
	for language in ["zh_CN", "en"]:
		GameLanguage.set_language(language, false)
		for branch in ["water_public", "water_tanker"]:
			check(ProfileRuntime.load_profile(PUBLIC if branch == "water_public" else TANKER), "UI loads real returned profile")
			var profile := ProfileRuntime.get_profile()
			var before := profile.to_dict()
			for contact: String in ContactDefinition.CONTACTS:
				panel.open_contact(contact, "quests"); await _frames()
				var memory := panel.find_child("WaterworksReturn", true, false) as ContactConversation
				var current := panel.find_child("ContactConversation", true, false) as ContactConversation
				check(current.scene_data == CampusConversations.get_scene(profile, contact), "Active campus story remains available, not replaced by waterworks")
				var scene := WaterworksStory.return_scene(profile, contact)
				seen[branch + "_" + contact] = true
				check(memory != null and not memory.opened and scene == memory.scene_data, "Optional collapsed memory matches actual choice")
				check(tr(scene.title) != scene.title if language == "zh_CN" else tr(scene.title) == scene.title, "Memory title is bilingual")
				await _click(memory.title_button)
				check(memory.opened and memory.exchange.visible, "Actual title button opens memory")
				for index in scene.lines.size():
					var line: Dictionary = scene.lines[index]
					check(CampusConversations.SPEAKERS.has(line.speaker), "Authored speaker is known")
					check(tr(line.text) != line.text if language == "zh_CN" else tr(line.text) == line.text, "Each line has real bilingual text")
					check(memory.line_index == index and memory.line_label.text == tr(line.text), "Next input visits every line in order")
					check(memory.line_label.size.y >= memory.line_label.get_minimum_size().y, "Dialogue wraps without clipping")
					if index == 2 and DisplayServer.get_name() != "headless" and "--capture" in OS.get_cmdline_user_args():
						await RenderingServer.frame_post_draw
						check(get_viewport().get_texture().get_image().save_png(OS.get_environment("BUNNY_EVIDENCE").path_join(branch + "_" + contact + "_" + language + ".png")) == OK, "Save actual rendered contact view")
					await _click(memory.advance_button)
				check(memory.line_index == 0, "Replay wraps without new flags or rewards")
				await _click(memory.close_button)
				check(not memory.opened and before == profile.to_dict(), "Reading and replay never mutate any profile fact or inventory")
				check(Rect2(Vector2.ZERO, Vector2(1280, 720)).encloses(panel.get_global_rect()), "Contact panel fits 720p")
	check(seen.size() == WaterworksStory.RETURNS.data.size(), "Every authored return scene is reachable by real branch and contact")
	check(WaterworksStory.return_scene(ProfileRuntime.get_profile(), "unknown").is_empty(), "Unknown contact never fabricates dialogue")
	var copy := WaterworksStory.return_scene(ProfileRuntime.get_profile(), "tang_kui")
	copy.lines[0].text = "mutated copy"
	check(WaterworksStory.return_scene(ProfileRuntime.get_profile(), "tang_kui").lines[0].text != "mutated copy", "Callers cannot change authored static data")
	var before := ProfileRuntime.get_profile().to_dict()
	panel.open_contact("tang_kui", "quests"); await _frames()
	GameLanguage.set_language("zh_CN", false); await _frames()
	var translated := panel.find_child("WaterworksReturn", true, false) as ContactConversation
	check(translated != null and translated.title_button.text.contains("湿袖口") and ProfileRuntime.get_profile().to_dict() == before, "Live language switch refreshes memory without changing the actual return")
	ProfileRuntime.new_profile()
	panel.open_contact("tang_kui", "quests"); await _frames()
	check(panel.find_child("WaterworksReturn", true, false) == null, "No memory card on fresh or unknown legacy profiles")
	panel.free()

func _finish() -> void:
	SortieRuntime.clear_session()
	AudioDirector.shutdown_for_test()
	print("WATERWORKS_RETURN_TEST: %s (%d checks; native mouse: %s)" % ["PASS" if failures.is_empty() else "FAIL", checks, DisplayServer.get_name() != "headless"])
	get_tree().quit(0 if failures.is_empty() else 1)
