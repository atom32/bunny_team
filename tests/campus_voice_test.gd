extends Node
## All progress below is an explicit UI fixture, not a campaign playthrough.
var checks := 0
var failures: Array[String] = []
var panel: ContactPanel
var context := ""

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(context + " / " + message); push_error(context + " / " + message)

func _ready() -> void:
	_run.call_deferred()

func _frames() -> void:
	for index in 3: await get_tree().process_frame

func _fixture(phase: String) -> ProfileState:
	var profile := ProfileRuntime.new_profile()
	if phase == "intro": return profile
	profile.first_mission_completed = true
	profile.narrative_slice.settled.Q01 = true
	profile.narrative_slice.q01_exits = ["streets_exit_0", "streets_exit_1"]
	if phase == "medicine": return profile
	profile.narrative_slice.settled.Q02 = true
	profile.narrative_slice.q02.delivered = {"medical.field_dressing": 2, "material.fabric": 2}
	profile.narrative_slice.q02.message = NarrativeSlice.Q02_MESSAGE
	if phase == "relay": return profile
	var state := profile.campus_chapter
	if phase == "lost": state.recorder_revealed = true; return profile
	state.relays_returned = true
	if phase == "recover": return profile
	state.recorder_revealed = true
	state.recorder_returned = true
	if phase == "power": return profile
	state.branch_disconnected = true
	if phase == "cut": return profile # Physical change persisted after failure, not a reward.
	state.power_returned = true
	if phase == "supply": return profile
	state.delivered_armor = true
	state.delivered_ammo = 60
	if phase == "complete": state.finished = true
	return profile

func _click(button: Button) -> void:
	if DisplayServer.get_name() == "headless": button.pressed.emit()
	else:
		# A capture resumes at frame_post_draw. Inject the next click in a fresh
		# process frame, after layout/rendering, not in the tail of that draw.
		await RenderingServer.frame_post_draw
		await get_tree().process_frame
		var activations := [0]
		var count_press := func(): activations[0] += 1
		button.pressed.connect(count_press)
		var motion := InputEventMouseMotion.new()
		motion.position = button.get_global_rect().get_center()
		get_viewport().push_input(motion)
		for pressed in [true, false]:
			var event := InputEventMouseButton.new()
			event.position = motion.position
			event.button_index = MOUSE_BUTTON_LEFT
			event.pressed = pressed
			get_viewport().push_input(event)
			await get_tree().process_frame
		check(activations[0] == 1, "One mouse click activates " + button.name + " exactly once at " + str(button.get_global_rect()))
		button.pressed.disconnect(count_press)
	await _frames()

func _capture(filename: String) -> void:
	if DisplayServer.get_name() == "headless" or not "--capture" in OS.get_cmdline_user_args(): return
	await RenderingServer.frame_post_draw
	check(get_viewport().get_texture().get_image().save_png(OS.get_environment("BUNNY_EVIDENCE").path_join(filename + ".png")) == OK, "Save rendered evidence")

func _run() -> void:
	await get_tree().process_frame
	SortieRuntime.clear_session()
	get_window().size = Vector2i(1280, 720)
	panel = ContactPanel.new()
	panel.position = Vector2(24, 24)
	panel.size = Vector2(1232, 672)
	add_child(panel)
	var seen := {}
	for language in ["zh_CN", "en"]:
		GameLanguage.set_language(language, false)
		for phase in ["intro", "medicine", "relay", "recover", "lost", "power", "cut", "supply", "packed", "complete"]:
			var profile := _fixture(phase)
			check(profile.validate(), "Valid authored fixture: " + phase)
			var before := profile.to_dict()
			for contact: String in ContactDefinition.CONTACTS:
				context = language + "/" + phase + "/" + contact
				var id := CampusConversations.scene_id(profile, contact)
				seen[id] = true
				var scene := CampusConversations.get_scene(profile, contact)
				check(not scene.is_empty() and scene.lines.size() in range(4, 7), "Short complete scene: " + id)
				check(TranslationServer.translate(scene.title) != scene.title if language == "zh_CN" else TranslationServer.translate(scene.title) == scene.title, "Localized scene title: " + id)
				for line: Dictionary in scene.lines:
					check(CampusConversations.SPEAKERS.has(line.speaker), "Known speaker: " + id)
					check(TranslationServer.translate(line.text) != line.text if language == "zh_CN" else TranslationServer.translate(line.text) == line.text, "Line has real bilingual text: " + id)
				panel.open_contact(contact, "quests")
				await _frames()
				var conversation := panel.find_child("ContactConversation", true, false) as ContactConversation
				check(conversation != null and not conversation.opened, "Optional scene never blocks tasks")
				check(conversation.scene_data == scene, "Real contact page selects settled-fact scene: " + id)
				if phase in ["power", "complete"]:
					await _click(conversation.title_button)
					check(conversation.opened and conversation.exchange.visible, "Read button opens actual conversation")
					for index in scene.lines.size():
						check(conversation.line_index == index and conversation.line_label.text == tr(scene.lines[index].text), "Next-line input visits line in order")
						check(conversation.line_label.size.y >= conversation.line_label.get_minimum_size().y, "Dialogue wraps without clipping")
						if index == 2: await _capture(phase + "_" + contact + "_" + language)
						await _click(conversation.advance_button)
					check(conversation.line_index == 0, "Replay returns to first line without granting progress")
					await _click(conversation.close_button)
					check(not conversation.opened, "Closing restores business; no forced dialogue")
				check(profile.to_dict() == before, "Reading and replay never mutate inventory, progress, rewards or save")
				check(Rect2(Vector2.ZERO, Vector2(1280, 720)).encloses(panel.get_global_rect()), "Contact UI fits 720p")
	check(seen.size() == CampusConversations.SCENES.data.size(), "Every authored scene is reachable by real profile facts")
	var failed := _fixture("lost")
	check(CampusConversations.scene_id(failed, "su_mi") == "lost_su" and not failed.campus_chapter.recorder_returned, "Knowledge after failure does not fabricate returned device")
	var cut := _fixture("cut")
	check(CampusConversations.scene_id(cut, "tang_kui") == "cut_tang" and not cut.campus_chapter.power_returned, "Power reply reflects physical cut even before extraction reward")
	check(CampusConversations.get_scene(cut, "unknown").is_empty(), "Unknown contact never fabricates a scene")
	var copy := CampusConversations.get_scene(cut, "tang_kui")
	copy.lines[0].text = "changed only in the returned copy"
	check(CampusConversations.get_scene(cut, "tang_kui").lines[0].text != copy.lines[0].text, "Callers cannot mutate static scene resources")
	var path := "user://campus_voice_test.json"
	check(SaveService.save_profile(cut, path) == OK, "Real old-schema-compatible profile saves")
	var loaded := SaveService.load_profile(path, false)
	check(loaded != null and loaded.to_dict() == cut.to_dict() and CampusConversations.scene_id(loaded, "tang_kui") == "cut_tang", "Reload selects the same scene without dialogue flags")
	var before := cut.to_dict()
	GameLanguage.set_language("zh_CN", false)
	panel.open_contact("tang_kui", "quests")
	await _frames()
	var live := panel.find_child("ContactConversation", true, false) as ContactConversation
	await _click(live.title_button)
	GameLanguage.set_language("en", false)
	await _frames()
	live = panel.find_child("ContactConversation", true, false) as ContactConversation
	check(live.title_button.text.contains("Who gets the microphone") and cut.to_dict() == before, "Live language switch refreshes contact page without changing story facts")
	panel.free()
	AudioDirector.shutdown_for_test()
	print("CAMPUS_VOICE_TEST: %s (%d checks; native mouse: %s)" % ["PASS" if failures.is_empty() else "FAIL", checks, DisplayServer.get_name() != "headless"])
	get_tree().quit(0 if failures.is_empty() else 1)
