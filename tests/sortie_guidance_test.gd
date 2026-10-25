extends Node
## Explicit progression fixtures, real deployment/Controls/work points. Not blind playtesting.
const PATH := "user://sortie_guidance_test.json"
var checks := 0
var failures: Array[String] = []
var battle: Node3D

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message); push_error(message)

func _ready() -> void:
	_run.call_deferred()

func frames() -> void:
	for index in 5: await get_tree().process_frame

func profile_at(phase: String) -> ProfileState:
	var profile := ProfileRuntime.new_profile()
	if phase == "tutorial": return profile
	profile.first_mission_completed = true
	if phase == "q01": return profile
	profile.narrative_slice.settled.Q01 = true
	profile.narrative_slice.q01_exits = ["streets_exit_0", "streets_exit_1"]
	if phase == "q02":
		profile.narrative_slice.q02.delivered["medical.field_dressing"] = 1
		return profile
	profile.narrative_slice.settled.Q02 = true
	profile.narrative_slice.q02.delivered = {"medical.field_dressing":2, "material.fabric":2}
	profile.narrative_slice.q02.message = NarrativeSlice.Q02_MESSAGE
	if phase == "relay": return profile
	var state := profile.campus_chapter
	state.relays_returned = true
	if phase == "recorder": return profile
	state.recorder_revealed = true
	state.recorder_returned = true
	if phase == "power": return profile
	state.branch_disconnected = true
	if phase == "cut": return profile
	state.power_returned = true
	state.delivered_ammo = 4
	if phase == "supply": return profile
	state.delivered_armor = true
	state.delivered_ammo = 60
	if phase == "complete": state.finished = true
	return profile

func start_world(phase: String, mission: StringName = &"streets_recon") -> void:
	SortieRuntime.clear_session()
	var profile := profile_at(phase)
	check(DeploymentPlan.deploy(profile, &"street_district", mission, PATH).error == OK, "Actual deployment: " + phase)
	battle = load("res://scenes/battle/battle.tscn").instantiate()
	battle.result_transition_enabled = false
	add_child(battle)
	battle.player.set_physics_process(false)
	for enemy in battle.enemy_container.get_children(): enemy.set_physics_process(false)
	await frames()
	check(battle.hud.objective_label.text == SortieGuidance.field(profile, battle.session)[0], "Primary HUD is the actual resident contract")
	check(battle.hud.objective_toggle.visible, "All selected-operation objectives remain accessible")
	check(battle.hud.objective_toggle.text == tr("OPTIONAL OBJECTIVES %d") % battle.session.get_objective_summary().size(), "Field-operation count never hides the former first objective")
	check(battle.area_root.route_map._mission_brief() == SortieGuidance.field(profile, battle.session), "Map and primary HUD agree")
	check(battle.hud.interaction_prompt.visible == not battle.hud.interaction_prompt.text.is_empty(), "No empty prompt card obscures the field before the first interaction")

func close_world() -> void:
	battle.free()
	battle = null
	SortieRuntime.clear_session()
	await frames()

func click(button: Button) -> void:
	if DisplayServer.get_name() == "headless": button.pressed.emit()
	else:
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
	await frames()

func capture(name: String, hub: Node3D = null) -> void:
	if DisplayServer.get_name() == "headless" or not "--capture" in OS.get_cmdline_user_args(): return
	# Capture the actual camera after its normal transition, not midway through a wall.
	var deadline := Time.get_ticks_msec() + 10000
	var settled := false
	while Time.get_ticks_msec() < deadline:
		if hub:
			settled = hub.camera.position.distance_to(hub.section_camera_position) < .03 and hub.relaxed_preview.phase == "idle"
		else:
			var focus: Vector3 = battle.player.global_position + battle.player.aim_direction * 1.45 + Vector3.UP * .85
			settled = battle.camera.global_position.distance_to(focus + Vector3(0, 18.2, 13.7)) < .08
		if settled: break
		await get_tree().process_frame
	check(settled, "Normal camera transition settled before capture")
	await RenderingServer.frame_post_draw
	check(get_viewport().get_texture().get_image().save_png(OS.get_environment("BUNNY_EVIDENCE").path_join(name + ".png")) == OK, "Rendered evidence saved")

func _run() -> void:
	await get_tree().process_frame
	for language in ["en", "zh_CN"]:
		GameLanguage.set_language(language, false)
		for phase in ["tutorial", "q01", "q02", "relay", "recorder", "power", "cut", "supply", "packed", "complete"]:
			var profile := profile_at(phase)
			check(profile.validate(), "Valid stage fixture: " + phase)
			var before := profile.to_dict()
			var guide := SortieGuidance.at_base(profile)
			check(guide.is_empty() == (phase == "tutorial"), "Tutorial keeps normal operation; finished campus now has a real next chapter")
			if phase=="complete":check(guide==FinaleStory.at_base(profile) and FinaleStory.next_mission(profile)==WaterworksStory.MISSION,"finished campus points to water without inventing completed side operations")
			if phase == "q02": check(guide[1].contains("1/2") and guide[1].contains("0/2"), "Base briefing shows submitted quantities, not invented deliveries")
			if phase == "supply": check(guide[1].contains("4/60"), "Partial ammunition delivery is visible before departure")
			if phase == "packed": check(guide[1] == tr("Dormitory south window / clear two gunmen, send packed equipment inside"), "Ready supplies require field handoff, not an empty extraction")
			var request := profile.create_sortie_request(&"street_district", &"streets_recon")
			var session := SortieSession.create_from_profile(request, profile)
			session.activate()
			var expected := SortieGuidance.field(profile, session)
			var restored := SortieCheckpoint.restore_session(SortieCheckpoint.session_data(session))
			check(restored != null and SortieGuidance.field(profile, restored) == expected, "Session roundtrip preserves actual assignment, not new profile guesses")
			if phase == "relay":
				session.campus.version = 1; session.campus.erase("supply_received")
				check(SortieGuidance.field(profile, session)[1].contains("dormitory") if language == "en" else SortieGuidance.field(profile, session)[1].contains("宿舍"), "Legacy retained site remains honest")
				session.campus = {}
				check(SortieGuidance.field(profile, session).is_empty(), "Old suspended session never gains today's chapter")
			check(profile.to_dict() == before, "All guidance is read-only")
		# Exact actor/interaction checks, with enemy AI disabled as a declared fixture.
		await start_world("q01")
		var signs: Array[Node] = battle.area_root.find_children("ExitPlaque", "Node3D", true, false)
		check(signs.size() == 2, "Both actual assigned exit signs exist")
		for index in signs.size():
			var gate := signs[index].exit_point.physical_gate() as CampusExitGate
			if gate and not gate.is_open():
				battle.player.global_position = gate.to_global(Vector3(0,0,2.4))
				check(gate.get_node("OutsideLatch").interact(battle.player,battle.session).success, "Explicit guidance fixture operates actual outside bolt before north sign")
			battle.player.global_position = signs[index].global_position
			check(signs[index].interact(battle.player, battle.session).success, "Actual assigned exit sign observed")
			battle._process(0)
			check(battle.hud.slice_label.text == NarrativeSlice.status_text(ProfileRuntime.get_profile(), battle.session), "Plaque progress immediately updates prominent request")
		check(not ProfileRuntime.get_profile().narrative_slice.settled.Q01, "Both signs still require extraction")
		await capture("q01_ready_" + language)
		await close_world()
		await start_world("relay", &"streets_relay")
		var profile := ProfileRuntime.get_profile()
		var credits := profile.credits
		var rounds: int = battle.player.get_magazine_ammo()
		await click(battle.hud.objective_toggle)
		check(battle.hud.objective_details.visible and battle.player.get_magazine_ammo() == rounds, "Actual disclosure click does not fire")
		await click(battle.hud.objective_toggle)
		for name in ["RelayOffice", "RelayRepair"]:
			var relay := battle.area_root.get_node(name) as RelayStation
			battle.player.global_position = relay.global_position + Vector3.RIGHT
			check(relay.interact(battle.player, battle.session).success, "Chosen relay operation uses real timed equipment")
			relay.tick(12.1)
			battle._process(0)
		check(battle.session.campus.relays.size() == 2, "Same real repairs advance campus facts")
		check(battle.hud.objective_label.text == tr("CAMPUS / EXPERIMENT RECORDER"), "Second repair advances main request, not an unrelated complete banner")
		check(battle.hud.banner.text == "FIELD OPERATION COMPLETE / EXTRACT WHEN READY", "Completed optional mission is labelled as field operation")
		var recorder := battle.area_root.get_node("ExperimentRecorder") as CampusAction
		battle.player.global_position = recorder.global_position + Vector3.RIGHT
		battle.player.interaction_component._current_target = recorder
		check(battle.player.interaction_component.interact_with_current().success, "Actual interaction component picks up unique recorder and displays its information")
		battle._process(0)
		check(battle.hud.slice_label.text == tr("Experiment recorder / bring it home"), "Carried device replaces find-device instructions")
		check(battle.area_root.route_map._mission_brief()[1] == battle.hud.slice_label.text, "Map updates with carried device")
		var alarm := battle.area_root.get_node("StreetTerminal/RecordsAlarm") as RecordsAlarm
		check(battle.session.record_objective_interaction(&"streets_terminal") and alarm.arm(battle.session), "Actual optional terminal starts its warning")
		battle.area_root.route_map._process(0)
		check(battle.area_root.route_map.alarm_hint.text == alarm.caption(), "Live alarm countdown overrides quiet next-action hint")
		battle._sync_objective_hud()
		await click(battle.hud.objective_toggle)
		check(battle.hud.objective_details.text.contains(tr("COMPLETE")), "Completed field objectives remain inspectable, not discarded")
		await capture("relay_recorder_" + language)
		var world := SortieCheckpoint.capture_world(battle)
		var session_data := SortieCheckpoint.session_data(battle.session)
		check(SortieCheckpoint.restore_session(session_data) != null and SortieCheckpoint.restore_world(world, battle), "Real checkpoint/world restore retains facts and visuals")
		battle._process(0)
		check(battle.hud.slice_label.text == tr("Experiment recorder / bring it home") and profile.credits == credits and not profile.campus_chapter.recorder_returned, "Restore never grants or announces a returned-device reward")
		await close_world()
		await start_world("power")
		var control := battle.area_root.get_node("L02BranchControl") as CampusAction
		battle.player.global_position = control.global_position + Vector3.RIGHT
		check(control.interact(battle.player, battle.session).success and control.confirm_power(), "Actual branch confirmation starts work")
		control._process(6.1)
		check(not battle.session.campus.power_cut,"New encounter cannot be bypassed by advancing the retired work timer")
		var encounter:=control._encounter()
		for enemy in battle.enemy_container.get_children():
			if enemy is CampusRammer:enemy.take_damage(1000) # Controlled UI fixture, not a playthrough.
		encounter._physics_process(0)
		control.interact(battle.player,battle.session)
		battle._process(0)
		check(battle.hud.slice_label.text == tr("L-02B OFF / L-02A ON / Extract"), "Only completed physical switch advances extraction instruction")
		await capture("power_extract_" + language)
		await close_world()
		await start_world("supply")
		check(battle.hud.slice_label.text == tr("Deliver spare armor and 60 standard 5.56 rounds at base"), "Missing supplies never claim extraction will complete the chapter")
		await close_world()
		# Native base shortcuts connect the guidance to the existing owning contact.
		for phase in ["q02", "relay", "packed", "complete"]:
			profile = profile_at(phase)
			var hub = load("res://scenes/presentation/slice/hideout.tscn").instantiate()
			add_child(hub)
			hub.show_section("Operations")
			await frames()
			var before := profile.to_dict()
			var mission := DeploymentPlan.selected_street_mission
			var detail := hub.screen.find_child("MissionBriefing", true, false) as Label
			check(detail.size.y >= detail.get_minimum_size().y, "Base briefing fits its actual text height")
			var brief_scroll := detail.get_parent() as ScrollContainer
			check(brief_scroll != null and detail.size.x <= brief_scroll.size.x and brief_scroll.get_parent().get_global_rect().encloses(brief_scroll.get_global_rect()), "Scrollable briefing text and viewport stay inside panel horizontally")
			var shortcut := hub.screen.find_child("RequestDetails", true, false) as Button
			check((shortcut == null) == (phase == "complete"), "Only an active resident request gets a contact shortcut")
			if shortcut:
				check(detail.text.contains(SortieGuidance.at_base(profile)[0]), "Base and field use the same request heading")
				check(not brief_scroll.get_global_rect().intersects(shortcut.get_global_rect()), "Scrollable mission viewport clears contact action")
				await capture("base_" + phase + "_" + language, hub)
				await click(shortcut)
				var contact := hub.screen.get_node("ContactPanel") as ContactPanel
				check(hub.section == "Workshop" and contact.selected_tab == "quests" and contact.contact_id == SortieGuidance.contact_at_base(profile), "Native shortcut opens actual task owner and request tab")
			check(DeploymentPlan.selected_street_mission == mission and profile.to_dict() == before, "Viewing requests never changes chosen operation, wallet or equipment")
			hub.free()
			await frames()
	AudioDirector.shutdown_for_test()
	print("SORTIE_GUIDANCE_TEST: %s (%d checks; native mouse: %s)" % ["PASS" if failures.is_empty() else "FAIL", checks, DisplayServer.get_name() != "headless"])
	get_tree().quit(0 if failures.is_empty() else 1)
