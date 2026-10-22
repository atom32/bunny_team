extends "res://tests/sortie_guidance_test.gd"
## Declared outcome fixtures, not earned victories. Real Outcome factory and UI;
## no file settlement, inventory rewards, battle movement or human playtime claim.

func capture(name: String, _hub: Node3D = null) -> void:
	# This fixture has a CanvasLayer, not the parent's live battle/camera.
	if DisplayServer.get_name() == "headless" or "--capture" not in OS.get_cmdline_user_args(): return
	await RenderingServer.frame_post_draw
	check(get_viewport().get_texture().get_image().save_png(OS.get_environment("BUNNY_EVIDENCE").path_join(name + ".png")) == OK, "actual debrief UI frame saved")

func make_outcome(spec: Dictionary) -> SortieOutcome:
	var profile := profile_at(spec.phase)
	check(profile.validate(), "valid progression fixture: " + spec.name)
	var session := SortieSession.create_from_profile(profile.create_sortie_request(&"street_district", &"streets_recon"), profile)
	check(session != null and session.activate(), "normal session factory: " + spec.name)
	if session == null: return null
	for key in spec.get("facts", {}): session.campus[key] = spec.facts[key]
	if spec.get("legacy_supply", false):
		session.campus.version = 3; session.campus.erase("supply_received")
	if spec.get("legacy_empty", false): session.campus = {}
	if spec.get("recorder", false):
		var item := ItemInstance.new(CampusChapter.RECORDER_ID)
		check(session.inventory.add_item(item), "declared fixture carries recorder")
		session.campus.recorder_revealed = true; session.campus.recorder_instance = item.instance_id
	if spec.get("exit_signs", false):
		session.slice_context.exit_conditions = {"streets_exit_0":"", "streets_exit_1":"streets_terminal"}
		session.exit_observations.assign(["streets_exit_0", "streets_exit_1"])
	if spec.get("optional_complete", false):
		check(session.record_objective_interaction(&"streets_terminal") and session.record_objective_reached(&"streets_survey"), "fixture completes both real optional objective definitions")
	var result: int = spec.get("result", SortieOutcome.ResultType.COMPLETED)
	check(session.complete_extraction() if result == SortieOutcome.ResultType.COMPLETED else session.fail() if result == SortieOutcome.ResultType.FAILED else session.abandon(), "real terminal session method")
	var outcome := SortieOutcome.create_from_session(session)
	check(outcome != null and outcome.validate(), "validated immutable outcome: " + spec.name)
	return outcome

func _run() -> void:
	await frames()
	var specs := [
		{"name":"relay_partial", "phase":"relay", "facts":{"relays":["relay_office"]}, "contains":"Relays repaired %d/2 / repair both in one outing, then extract.", "count":1},
		{"name":"relay_both", "phase":"relay", "facts":{"relays":["relay_office","relay_repair"]}, "contains":"Relays repaired 2/2 / ready to settle."},
		{"name":"relay_recorder", "phase":"relay", "facts":{"relays":["relay_office","relay_repair"]}, "recorder":true, "contains":"Recorder carried back / ready to settle."},
		{"name":"relay_failed", "phase":"relay", "facts":{"relays":["relay_office","relay_repair"]}, "recorder":true, "result":SortieOutcome.ResultType.FAILED, "contains":"Recorder lost with carried gear; its information is remembered."},
		{"name":"recorder_empty", "phase":"recorder", "contains":"Recorder not brought back / collect it on a later sortie."},
		{"name":"recorder_return", "phase":"recorder", "recorder":true, "contains":"Recorder carried back / ready to settle."},
		{"name":"power_not_cut", "phase":"power", "contains":"Branch isolation not completed / no power-operation milestone."},
		{"name":"power_cut", "phase":"cut", "contains":"L-02B isolated; shelter L-02A preserved. Ready to settle."},
		{"name":"power_failed", "phase":"cut", "result":SortieOutcome.ResultType.FAILED, "contains":"L-02B remains isolated. A safe return is still needed."},
		{"name":"supply_unpacked", "phase":"supply", "contains":"Delivery milestone pending / hand off equipment, then return safely."},
		{"name":"supply_packed", "phase":"packed", "contains":"Delivery milestone pending / hand off equipment, then return safely."},
		{"name":"supply_received", "phase":"packed", "facts":{"supply_received":true}, "contains":"Dormitory received the equipment / ready to settle."},
		{"name":"supply_abandoned", "phase":"packed", "facts":{"supply_received":true}, "result":SortieOutcome.ResultType.ABANDONED, "contains":"Delivery milestone pending / hand off equipment, then return safely."},
		{"name":"supply_legacy", "phase":"packed", "legacy_supply":true, "contains":"Legacy equipment sortie / ready to settle."},
		{"name":"q01_partial", "phase":"q01", "contains":"Exit observations not banked / read both signs in one outing and return safely."},
		{"name":"q01_complete", "phase":"q01", "exit_signs":true, "contains":"Exit signs 2/2 / ready to settle."},
		{"name":"q02_empty_return", "phase":"q02", "contains":"Deliver recovered dressings and fabric to Tang Kui at base. Extraction alone does not submit them."},
		{"name":"q02_failed", "phase":"q02", "result":SortieOutcome.ResultType.FAILED, "contains":"No carried supplies recovered. Existing warehouse delivery progress is kept."},
		{"name":"optional_completed", "phase":"relay", "optional_complete":true, "contains":"Relays repaired %d/2 / repair both in one outing, then extract.", "count":0},
		{"name":"campus_complete", "phase":"complete", "no_primary":true},
		{"name":"legacy_no_context", "phase":"relay", "legacy_empty":true, "no_primary":true},
	]
	for language in ["zh_CN", "en"]:
		GameLanguage.set_language(language, false)
		for spec: Dictionary in specs:
			var outcome := make_outcome(spec)
			if outcome == null: continue
			var profile := ProfileRuntime.get_profile()
			var before_profile := profile.to_dict(); var before_outcome := outcome.to_dict()
			var guide := SortieGuidance.debrief(outcome)
			var no_primary: bool = spec.get("no_primary", false)
			check(guide.is_empty() == no_primary, "only actual sortie context selects primary: " + spec.name)
			if not no_primary:
				var expected: String = tr(spec.contains)
				if spec.has("count"): expected = expected % spec.count
				check(guide[1].contains(expected), "actual post-sortie fact, not a generic mission verdict: " + spec.name)
			var ui := load("res://scenes/ui/result_ui.tscn").instantiate() as ResultUI
			ui.configure(outcome); add_child(ui); await frames()
			check(ui.objective_labels.size() == outcome.get_objective_summaries().size(), "all optional objective rows are retained")
			check(ui.mission_completion_label.text == ("MISSION COMPLETE" if outcome.mission_completed else "MISSION INCOMPLETE") if no_primary else ui.mission_completion_label.text == tr("OPTIONAL OPERATION COMPLETE" if outcome.mission_completed else "OPTIONAL OPERATION NOT COMPLETED"), "mission verdict explicitly qualified when a story commission exists")
			if not no_primary:
				var notes := ui.find_child("ReturnFacts", true, false) as Label
				check(notes.text.contains(guide[0]) and notes.text.contains(guide[1]) and notes.text.contains(tr("Return to base to save the result. This screen does not settle rewards.")), "story facts and pending-save boundary stay together")
				check(ui.find_child("CampaignPreview", true, false) == null, "unrelated bastion preview does not compete with active story commission")
				check((ui.find_child("ObjectiveHeading", true, false) as Label).text == tr("OPTIONAL OBJECTIVES"), "selected field objective list is explicitly optional")
				check(Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size).encloses(notes.get_global_rect()), "story facts fit the viewport")
				if notes.size.x > 361: print("DEBRIEF_LAYOUT_DIAGNOSTIC ", language, " ", spec.name, " rect=", notes.get_rect(), " minimum=", notes.get_combined_minimum_size(), " wrap=", notes.autowrap_mode)
				check(notes.size.x <= 361, "wrapped facts stay in the left column, not across the character preview")
			var panel := ui.find_child("DebriefPanel", true, false) as Control
			var card := ui.find_child("StoryReadout", true, false) as Panel
			for name in ["ReturnFacts", "CampaignPreview"]:
				var readout := ui.find_child(name, true, false) as Label
				if not readout: continue
				check(card != null and card.get_global_rect().encloses(readout.get_global_rect()), "all result notes stay on their opaque backing: " + spec.name + "/" + name)
				if card:
					var surface := card.get_theme_stylebox("panel") as StyleBoxFlat
					check(surface.bg_color.a == 1.0 and _contrast(readout.get_theme_color("font_color"), surface.bg_color) >= 7.0, "readout contrast does not depend on the lit 3D floor")
			if card:
				check(not card.get_global_rect().intersects(panel.get_global_rect()) and card.mouse_filter == Control.MOUSE_FILTER_IGNORE, "story backing never obscures return controls or captures input")
			if not no_primary:
				check((ui.find_child("ReturnFacts", true, false) as Label).get_theme_font_size("font_size") >= 18, "primary return facts use readable body size")
			check(Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size).encloses(panel.get_global_rect()) and panel.get_global_rect().encloses(ui.return_button.get_global_rect()), "actual debrief panel and return button fit: " + spec.name + "/" + language)
			check(profile.to_dict() == before_profile and outcome.to_dict() == before_outcome, "rendering never settles credits, inventory, quests or optional objectives")
			if spec.name in ["relay_recorder", "relay_failed", "supply_received", "legacy_no_context"]:
				await capture("debrief_" + spec.name + "_" + language)
			ui.free(); await frames()
	SortieRuntime.clear_session(); AudioDirector.shutdown_for_test()
	print("DEBRIEF_GUIDANCE_TEST: %s (%d checks; controlled outcomes, not earned play)" % ["PASS" if failures.is_empty() else "FAIL", checks])
	get_tree().quit(0 if failures.is_empty() else 1)

func _luminance(color: Color) -> float:
	var channels: Array[float] = [color.r, color.g, color.b]
	for i in 3:
		channels[i] = channels[i] / 12.92 if channels[i] <= 0.04045 else pow((channels[i] + 0.055) / 1.055, 2.4)
	return channels[0]*0.2126 + channels[1]*0.7152 + channels[2]*0.0722

func _contrast(a: Color, b: Color) -> float:
	var first := _luminance(a)
	var second := _luminance(b)
	return (maxf(first,second)+0.05)/(minf(first,second)+0.05)
