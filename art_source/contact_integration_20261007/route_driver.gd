extends Node
const OUT := "/Users/xudawei/bunny_team/art_source/contact_integration_20261007/"
var checks := []
var captures := []
var battle: Node3D
var chapter: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var overlay := CanvasLayer.new()
	overlay.layer = 100
	add_child(overlay)
	var strip := SliceUI.panel(overlay, Vector2(446, 8), Vector2(676, 30))
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	SliceUI.label(strip, "DEBUG PLAYTHROUGH / AI disabled · teleport · ordinary material grant", Vector2(10, 4), 12, SliceUI.CYAN)
	chapter = SliceUI.label(overlay, "", Vector2(446, 697), 12, SliceUI.CYAN)
	_run.call_deferred()

func _process(_delta: float) -> void:
	if get_tree().paused and FlowMenu.mode == "pause": FlowMenu.close()

func check(ok: bool, title: String) -> bool:
	checks.append({"pass":ok,"check":title})
	print("PLAYTEST ","PASS " if ok else "FAIL ",title)
	if not ok:
		_report()
		get_tree().quit(1)
	return ok

func _run() -> void:
	get_tree().current_scene = null # Keep this isolated driver alive across real scene transitions.
	var profile := ProfileRuntime.new_profile()
	# First verify the real menu-to-base path with a genuinely fresh profile.
	GameState.presentation_enabled = true
	check(ProfileRuntime.save_profile() == OK, "fresh profile saved before menu/base route")
	get_tree().change_scene_to_file("res://scenes/presentation/slice/boot.tscn")
	await _scene("Boot")
	get_tree().current_scene.show_menu()
	get_tree().current_scene._enter()
	await _scene("Hideout")
	check(not profile.first_mission_completed and not profile.narrative_slice.settled.Q01, "new game reaches base without fabricated tutorial or quest progress")
	check(get_tree().current_scene.find_child("ContactsToggle",true,false) != null, "fresh base exposes contacts")
	get_tree().current_scene.find_child("ContactsToggle",true,false).pressed.emit()
	await get_tree().process_frame
	var fresh_contact: ContactPanel = get_tree().current_scene.find_child("ContactPanel",true,false)
	check(fresh_contact.contact_id == "tang_kui", "fresh base opens Tang Kui resident supplies")
	fresh_contact.find_child("ContactQuests",true,false).pressed.emit()
	await _capture("fresh_contacts_locked_quests")
	check(fresh_contact.find_child("SubmitQ02",true,false) == null and fresh_contact.find_child("SubmitQ04",true,false) == null, "fresh contact UI preserves narrative prerequisites")
	profile.first_mission_completed = true # Debug skip tutorial for the subsequent field route.
	GameState.presentation_enabled = true
	GameState.hideout_section = "Overview"
	if not check(ProfileRuntime.save_profile() == OK, "debug tutorial skip saved in isolated profile"): return
	get_tree().change_scene_to_file("res://scenes/presentation/slice/boot.tscn")
	await _scene("Boot")
	get_tree().current_scene.show_menu()
	await get_tree().create_timer(0.8).timeout
	await _capture("00_main_menu")
	get_tree().current_scene._settings()
	await _capture("00_settings")
	get_tree().current_scene.show_menu()
	get_tree().current_scene._enter()
	await _scene("Hideout")
	await get_tree().create_timer(2.0).timeout
	await _capture("01_base_entry")
	var panel := await _contracts()
	await _capture("02_q01_contract")
	get_tree().current_scene.show_section("Hanger")
	await _capture("02_loadout")
	get_tree().current_scene.show_section("Workshop")
	var contacts: ContactPanel = get_tree().current_scene.find_child("ContactPanel",true,false)
	for id: String in ContactDefinition.CONTACTS:
		contacts.find_child("Contact_" + id,true,false).pressed.emit()
		await _capture("contact_" + id + "_trade")
		check(contacts.get_global_rect().end.y < 644, "contact shop fits above base navigation " + id)
		contacts.find_child("ContactQuests",true,false).pressed.emit()
		await _capture("contact_" + id + "_quests")
		check(contacts.get_global_rect().end.y < 644, "contact quests fit above base navigation " + id)
		contacts.find_child("ContactTrade",true,false).pressed.emit()
	await _deploy()
	var session := SortieRuntime.get_current_session()
	var assigned: Array = battle.area_root.find_children("*","ExtractionPoint",true,false).filter(func(exit):return exit.available)
	if not check(assigned.size() == 2, "Q01 two assigned exits"): return
	for index in assigned.size():
		await _interact(assigned[index].get_node("ExitPlaque"))
		await _capture("03_q01_exit_"+str(index+1))
	if not check(session.exit_observations.size() == 2, "Q01 actual plaque interactions recorded"): return
	await _extract("04_q01_debrief")
	profile = ProfileRuntime.get_profile()
	if not check(profile.narrative_slice.settled.Q01 and profile.credits == 1650, "Q01 returned through result UI, reward +150"): return
	panel = await _contracts()
	await _capture("05_q02_request")
	# Debug grant only ordinary materials; pharmacy observation/quest state untouched.
	for index in 2: check(SupplyService.transact("buy","medical.field_dressing",1).error == OK, "normal dressing purchase")
	check(profile.inventory.add_item(ItemInstance.new(&"material.fabric",2)), "debug ordinary fabric grant")
	check(ProfileRuntime.save_profile() == OK, "debug materials persist through normal save")
	panel._refresh()
	if not check(panel.find_child("SubmitQ02",true,false).disabled, "materials alone cannot enable Q02 submission"): return
	await _deploy()
	await _interact(battle.area_root.get_node("PharmacyBatch"))
	await _capture("06_q02_pharmacy")
	FlowMenu.suspend_sortie("menu")
	await _scene("Boot")
	if not check(not ProfileRuntime.get_profile().sortie_checkpoint.is_empty(), "real suspend menu preserves checkpoint"): return
	FlowMenu.resume_sortie()
	await _scene("Battle")
	battle = get_tree().current_scene
	_disable_combat()
	if not check(SortieRuntime.get_current_session().pharmacy_batch == NarrativeSlice.PHARMACY_BATCH, "Q02 observation survives menu/resume scene route"): return
	await get_tree().create_timer(2.0).timeout
	await _capture("07_q02_resumed")
	await _extract("08_q02_debrief")
	panel = await _contracts()
	var button: Button = panel.find_child("SubmitQ02",true,false)
	if not check(not button.disabled, "base submission enabled after successful Q02 observation"): return
	await _capture("09_q02_ready")
	var credits: int = ProfileRuntime.get_profile().credits
	button.pressed.emit()
	await get_tree().process_frame
	if not check(ProfileRuntime.get_profile().narrative_slice.settled.Q02 and ProfileRuntime.get_profile().credits == credits+150, "Q02 real base button consumes supplies and pays once"): return
	await _capture("10_q04_available")
	await _deploy()
	await _interact(battle.area_root.get_node("DeliveryReceipt"))
	await _capture("11_q04_receipt")
	await _interact(battle.area_root.get_node("PharmacyBatch"))
	await _capture("12_q04_pharmacy")
	await _extract("13_q04_debrief")
	panel = await _contracts()
	button = panel.find_child("SubmitQ04",true,false)
	if not check(button != null and not button.disabled, "Q04 both successful facts enable submission"): return
	await _capture("14_q04_ready")
	credits = ProfileRuntime.get_profile().credits
	button.pressed.emit()
	await get_tree().process_frame
	profile = ProfileRuntime.get_profile()
	if not check(profile.narrative_slice.settled.Q04 and profile.credits == credits+200 and profile.narrative_slice.q04.log == NarrativeSlice.Q04_LOG, "Q04 real base submit pays +200 and writes exact factual log"): return
	if not check(panel.find_child("SubmitQ04",true,false) == null, "terminal UI has no follow-up narrative action"): return
	await _capture("15_chain_a_stopped")
	var before := profile.to_dict()
	if not check(ProfileRuntime.load_profile() and JSON.stringify(ProfileRuntime.get_profile().to_dict()) == JSON.stringify(before), "all completed states survive disk reload"): return
	check(SupplyService.transact("buy","medical.field_dressing",1).error == OK, "procurement stays available after hard stop")
	await _deploy()
	session = SortieRuntime.get_current_session()
	if not check(session.slice_context.is_empty() and not session.q02_active and not session.q04_active and not battle.area_root.has_node("PharmacyBatch") and not battle.area_root.has_node("DeliveryReceipt"), "fresh free sortie generates no active narrative quest or marker"): return
	await _capture("16_free_sortie")
	await _extract("17_free_debrief")
	_report()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(0.4).timeout
	get_tree().quit()

func _scene(name: String) -> void:
	var deadline := Time.get_ticks_msec()+20000
	while Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
		if get_tree().current_scene and get_tree().current_scene.name == name and not GameState.is_transitioning():
			await get_tree().create_timer(0.3).timeout
			return
	check(false,"scene timeout: "+name)

func _contracts() -> CampaignPanel:
	var base = get_tree().current_scene
	base.show_section("Overview")
	await get_tree().process_frame
	base.find_child("ContactsToggle",true,false).pressed.emit()
	await get_tree().process_frame
	var contacts: ContactPanel = base.find_child("ContactPanel",true,false)
	var id := "tang_kui" if ProfileRuntime.get_profile().narrative_slice.settled.Q01 else "shen_yanshuang"
	contacts.find_child("Contact_" + id,true,false).pressed.emit()
	contacts.find_child("ContactQuests",true,false).pressed.emit()
	await get_tree().process_frame
	var panel: CampaignPanel = contacts.find_child("CampaignPanel",true,false)
	check(panel.contact_id == id,"real base contact entry opens existing quest UI for " + id)
	check(contacts.find_child("Portrait",true,false) != null,"contact portrait region survives sortie return")
	return panel

func _deploy() -> void:
	var base = get_tree().current_scene
	base.show_section("Operations")
	await get_tree().process_frame
	var button: Button
	for found in base.find_children("*","Button",true,false):
		if found.text == "CONFIRM DEPLOYMENT": button = found
	if not check(button != null,"production deployment button present"): return
	button.pressed.emit()
	await _scene("Deployment")
	get_tree().current_scene._launch() # Debug skip cinematic; keep production launch/arrival.
	await _scene("Battle")
	battle = get_tree().current_scene
	_disable_combat()
	await get_tree().create_timer(2.0).timeout

func _disable_combat() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"): enemy.process_mode = Node.PROCESS_MODE_DISABLED
	battle.player.set_physics_process(false)

func _interact(node: Node3D) -> void:
	battle.player.global_position = node.global_position # Debug teleport; trigger actual nearest interaction.
	battle.player.interaction_component._current_target = null
	var response: Dictionary = battle.player.interaction_component.interact_with_current()
	check(response.success,"actual field interaction: "+node.name)
	await get_tree().create_timer(0.3).timeout

func _extract(capture_name: String) -> void:
	var exit: ExtractionPoint
	for candidate in battle.area_root.find_children("*","ExtractionPoint",true,false):
		if candidate.available and candidate.required_objective_id.is_empty(): exit = candidate
	check(exit != null,"legal free exit available")
	await _interact(exit)
	await _scene("Result")
	await _capture(capture_name)
	get_tree().current_scene.result_ui.return_button.pressed.emit()
	await _scene("Hideout")

func _capture(name: String) -> void:
	chapter.text = name.replace("_", " ").to_upper()
	await get_tree().create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	var path := OUT+"captures/"+name+".png"
	check(get_tree().root.get_texture().get_image().save_png(path) == OK,"capture "+name)
	captures.append(path)

func _report() -> void:
	var file := FileAccess.open(OUT+"playtest.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"method":"automated debug-assisted graphics playthrough; combat/tutorial bypassed; real field interactions, production scene route and UI submission", "checks":checks,"captures":captures,"profile":ProfileRuntime.get_profile().to_dict()},"\t"))
	file.close()
	print("QUEST_PLAYTEST: ","PASS" if checks.all(func(entry):return entry["pass"]) else "FAIL"," / ",checks.size()," checks")
