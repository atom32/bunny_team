extends Node
## Explicit owned-tool fixtures; not earned discovery, field use or human play.
const TOOL := &"tool.portable_alarm"
const PATH := "user://portable_alarm_packing.json"
const EXPECTED_PATH := "user://portable_alarm_packing_expected.json"
var checks := 0
var failures: Array[String] = []

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message)

func frames() -> void:
	for tick in 3: await get_tree().process_frame

func fresh(amount := 0) -> ProfileState:
	SortieRuntime.clear_session()
	ProfileRuntime.recovery_required = false
	var profile := ProfileRuntime.new_profile()
	profile.first_mission_completed = true
	for index in amount:
		check(profile.inventory.add_item_preserving_instance(ItemInstance.new(TOOL)), "explicit fixture owns each distinct complete alarm box")
	return profile

func ids(profile: ProfileState) -> Array[String]:
	var result: Array[String] = []
	for item in profile.inventory.get_items():
		if item.definition_id == TOOL: result.append(item.instance_id)
	result.sort()
	return result

func _ready() -> void:
	await get_tree().process_frame
	var definition := ContentDB.get_item(TOOL,false)
	check(definition != null and not definition.stackable and is_equal_approx(definition.weight,1.0) and not definition is MedicalDefinition, "alarm is a registered complete nonstacked one-kilogram tool, not medicine")
	if definition:
		if "--read" in OS.get_cmdline_user_args():
			var saved := SaveService.load_profile(PATH,false)
			var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(EXPECTED_PATH))
			check(saved != null and saved.pack_alarm and saved.to_dict() == ProfileState.from_dict(expected).to_dict(), "independent process retains explicit tool preference and exact owned IDs")
		else:
			_preferences()
			_plans()
			_limits()
			_settlement()
			await _ui()
			var profile := fresh(2)
			check(DeploymentPlan.set_alarm_packed(true,PATH) == OK, "final isolated tool configuration saves")
			var file := FileAccess.open(EXPECTED_PATH,FileAccess.WRITE)
			file.store_string(JSON.stringify(profile.to_dict())); file.close()
	SortieRuntime.clear_session(); ProfileRuntime.recovery_required = false
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(.4).timeout
	for failure in failures: push_error("PORTABLE_ALARM_PACKING: " + failure)
	print("PORTABLE_ALARM_PACKING_TEST: %s (%d checks; controlled fixtures)" % ["PASS" if failures.is_empty() else "FAIL",checks])
	get_tree().quit(0 if failures.is_empty() else 1)

func _preferences() -> void:
	var profile := fresh(2)
	check(not profile.pack_alarm, "new profiles never silently carry a recovered tool")
	var old := profile.to_dict(); old.erase("pack_alarm")
	var migrated := ProfileState.from_dict(old)
	check(migrated != null and not migrated.pack_alarm and ids(migrated) == ids(profile), "old profile without tool preference defaults to false without resetting ownership")
	for value in [0,1,"false",null,[],{},INF]:
		var invalid := profile.to_dict(); invalid.pack_alarm = value
		check(ProfileState.from_dict(invalid) == null, "non-boolean tool packing preference is rejected")
	var inventory := profile.inventory
	var original_ids := ids(profile)
	check(DeploymentPlan.set_alarm_packed(true,PATH) == OK and profile.pack_alarm and profile.inventory == inventory and ids(profile) == original_ids, "preference saves atomically without splitting or replacing warehouse objects")
	check(SaveService.load_profile(PATH,false).pack_alarm, "durable preference matches the published boolean")
	var before := profile.to_dict()
	var disk := FileAccess.get_file_as_string(PATH)
	check(DeploymentPlan.set_alarm_packed(false,"user://missing_alarm_pack_directory/profile.json") != OK and profile.to_dict() == before and FileAccess.get_file_as_string(PATH) == disk, "failed preference save preserves prior profile and verified disk")
	profile.sortie_checkpoint = {"controlled_pending":true}
	before = profile.to_dict()
	check(DeploymentPlan.set_alarm_packed(false,PATH) == ERR_BUSY and profile.to_dict() == before, "pending sortie prevents changing tool risk selection")
	profile.sortie_checkpoint = {}
	ProfileRuntime.recovery_required = true
	check(DeploymentPlan.set_alarm_packed(false,PATH) == ERR_BUSY and profile.pack_alarm, "recovery-required profile cannot change tool packing")
	ProfileRuntime.recovery_required = false

func _plans() -> void:
	var profile := fresh(3)
	var owned := ids(profile)
	var untouched := profile.to_dict()
	var unrequested := DeploymentPlan.build(profile,&"streets_recon")
	check(unrequested.tool_ids.is_empty() and unrequested.carried_ids().all(func(id): return id not in owned) and profile.to_dict() == untouched, "unrequested alarm boxes remain in warehouse without changing the preview")
	check(DeploymentPlan.set_alarm_packed(true,PATH) == OK, "player explicitly requests one box")
	var before := profile.to_dict()
	var plan := DeploymentPlan.build(profile,&"streets_recon")
	check(plan.tool_ids.size() == 1 and plan.tool_ids[0] in owned and is_equal_approx(plan.weight-unrequested.weight,1.0), "preview selects one actual owned tool and includes its real kilogram")
	check(plan.carried_ids().has(plan.tool_ids[0]) and not plan.medical_ids.has(plan.tool_ids[0]) and not plan.cargo_ids.has(plan.tool_ids[0]), "tool IDs have their own packing category and join the actual carried request")
	var prepared := DeploymentPlan.prepare(profile,&"street_district",&"streets_recon")
	check(prepared.error == OK and profile.to_dict() == before, "tool materialization validates a detached candidate without mutating ownership")
	if prepared.error == OK:
		check(prepared.request.carried_item_instance_ids.has(plan.tool_ids[0]) and ids(prepared.candidate) == owned, "prepared request keeps the exact selected ID and never creates another box")
	var failed := DeploymentPlan.deploy(profile,&"street_district",&"streets_recon","user://missing_alarm_deploy_directory/profile.json")
	check(failed.error != OK and not SortieRuntime.get_current_session() and profile.to_dict() == before, "failed deployment save does not publish tool ownership, IDs or a live session")
	var deployed := DeploymentPlan.deploy(profile,&"street_district",&"streets_recon",PATH)
	check(deployed.error == OK, "normal persisted deployment carries the selected physical box")
	if deployed.error == OK:
		var session: SortieSession = deployed.session
		var carried := session.inventory.get_items().filter(func(item): return item.definition_id == TOOL)
		check(carried.size() == 1 and carried[0].instance_id == plan.tool_ids[0] and session.get_initial_carried_instance_ids().has(plan.tool_ids[0]), "one selected box enters inventory and original risk IDs; other boxes do not deploy")
		check(is_equal_approx(session.inventory.current_weight,plan.weight), "actual carried weight including loaded ammo matches tool packing preview")
		var unchanged := profile.to_dict()
		check(DeploymentPlan.set_alarm_packed(false,PATH) == ERR_BUSY and profile.to_dict() == unchanged, "live sortie prevents changing the packed-tool request")
	SortieRuntime.clear_session()

func _limits() -> void:
	var profile := fresh(2); profile.pack_alarm = true
	profile.loadout.unequip(LoadoutState.SLOT_BACKPACK)
	check(profile.inventory.add_item(ItemInstance.new(&"ammo.556_standard",1000)), "capacity fixture explicitly provides finite owned ammo")
	profile.ammo_pack["ammo.556_standard"] = 1000
	var before := profile.to_dict()
	var plan := DeploymentPlan.build(profile,&"streets_recon")
	check(plan.error.is_empty() and plan.capacity-plan.weight < 1.0 and plan.tool_ids.is_empty() and profile.to_dict() == before and profile.pack_alarm, "tool is not packed when ammo and equipment leave less than one kilogram; request remains explicit")
	check(plan.message.contains(tr("Portable alarm / PACKED %d OF 1") % 0), "overweight tool is visibly reported as unpacked rather than granted or charged")
	var prepared := DeploymentPlan.prepare(profile,&"street_district",&"streets_recon")
	check(prepared.error == OK and prepared.request.carried_item_instance_ids.all(func(id): return id not in ids(profile)), "capacity-limited actual request contains no alarm box")
	profile = fresh(); profile.pack_alarm = true
	plan = DeploymentPlan.build(profile,&"streets_recon")
	check(plan.tool_ids.is_empty() and SupplyService.count(profile,TOOL) == 0 and profile.pack_alarm, "missing stock never creates a requested box or clears the player's choice")

func _settlement() -> void:
	for terminal in ["complete","fail","abandon"]:
		var profile := fresh(3); profile.pack_alarm = true
		var original := ids(profile)
		var deployed := DeploymentPlan.deploy(profile,&"street_district",&"streets_recon",PATH)
		check(deployed.error == OK, "tool settlement fixture uses normal deployment")
		if deployed.error != OK: continue
		var session: SortieSession = deployed.session
		var selected := ""
		for item in session.inventory.get_items():
			if item.definition_id == TOOL: selected = item.instance_id
		check(session.complete_extraction() if terminal == "complete" else (session.fail() if terminal == "fail" else session.abandon()), "tool fixture enters the real terminal outcome method")
		check(SortieRuntime.finalize_sortie(PATH) == OK, "normal settlement commits the selected tool's risk")
		var expected := original.duplicate()
		if terminal != "complete": expected.erase(selected)
		check(ids(profile) == expected and profile.inventory.contains(selected) == (terminal == "complete") and profile.pack_alarm, "unused safe return retains the exact box; death/abandonment lose only the carried box and retain warehouse stock")
		var after := profile.to_dict()
		check(SortieRuntime.finalize_sortie(PATH) == OK and profile.to_dict() == after, "repeated settlement cannot duplicate or consume another warehouse box")
		check(SaveService.load_profile(PATH,false).to_dict() == profile.to_dict(), "tool risk and unchanged preference survive disk settlement")

func _ui() -> void:
	var profile := fresh()
	var previous_path := FlowMenu.save_path; FlowMenu.save_path = PATH
	var panel := MedicalPacking.new(); panel.compact = true; panel.size = Vector2(260,440); add_child(panel)
	await frames()
	check(panel.find_child("PackAlarm",true,false) == null, "unowned unrequested tool does not add an empty packing control")
	check(profile.inventory.add_item_preserving_instance(ItemInstance.new(TOOL)), "UI fixture owns one real box")
	panel._refresh(); await frames()
	var choice := panel.find_child("PackAlarm",true,false) as CheckBox
	check(choice != null and not choice.button_pressed and not choice.disabled, "owned tool appears as an explicit unchecked packing choice")
	choice.button_pressed = true; await frames()
	choice = panel.find_child("PackAlarm",true,false) as CheckBox
	var status := panel.find_child("Packed_tool_portable_alarm",true,false) as Label
	check(profile.pack_alarm and SaveService.load_profile(PATH,false).pack_alarm and choice.button_pressed and status.text == tr("PACKED %d / OWNED %d") % [1,1], "actual checkbox persists the choice and reports real packed/owned amounts")
	check((panel.find_child("AlarmPackingWeight",true,false) as Label).text == tr("1.0 kg each / only packed boxes leave base."), "tool mass and warehouse consequence are visible beside the choice")
	var before := profile.to_dict()
	FlowMenu.save_path = "user://missing_alarm_ui_directory/profile.json"
	choice.button_pressed = false; await frames()
	check(profile.to_dict() == before and (panel.find_child("PackAlarm",true,false) as CheckBox).button_pressed and (panel.find_child("PackingInfo",true,false) as Label).text.contains(tr("Save failed. Request unchanged.")), "failed checkbox save restores visible request with feedback and no profile changes")
	FlowMenu.save_path = PATH
	profile.sortie_checkpoint = {"controlled_pending":true}; panel._refresh(); await frames()
	check((panel.find_child("PackAlarm",true,false) as CheckBox).disabled, "pending sortie disables the real tool checkbox")
	profile.sortie_checkpoint = {}
	var deployed := DeploymentPlan.deploy(profile,&"street_district",&"streets_recon",PATH,false)
	check(deployed.error == OK, "UI live-sortie fixture starts normally")
	panel._refresh(); await frames()
	check((panel.find_child("PackAlarm",true,false) as CheckBox).disabled, "live sortie disables the real tool checkbox")
	SortieRuntime.clear_session()
	profile = fresh(); profile.pack_alarm = true; panel._refresh(); await frames()
	check(panel.find_child("PackAlarm",true,false) != null and (panel.find_child("PackAlarm",true,false) as CheckBox).button_pressed, "requested but missing tool remains visible so player can turn it off")
	panel.free(); FlowMenu.save_path = previous_path
