extends Node
const PATH := "user://q02_slice_test.json"
var failures: Array[String] = []
var checks := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); print("CHECK FAILED: " + message)
func _ready() -> void:
	await get_tree().process_frame
	var profile := ProfileRuntime.new_profile()
	for id in NarrativeSlice.Q02_INPUTS: profile.inventory.add_item(ItemInstance.new(id, 2))
	var before := JSON.stringify(profile.to_dict())
	check(NarrativeSlice.submit_q02(PATH).error != OK and JSON.stringify(profile.to_dict()) == before, "Q01 gate preserves possessions")
	profile.first_mission_completed = true
	profile.narrative_slice.settled.Q01 = true
	profile.narrative_slice.q01_exits = ["streets_exit_0", "streets_exit_1"]
	for id in NarrativeSlice.Q02_INPUTS:
		for item in profile.inventory.get_items():
			if item.definition_id == id: profile.inventory.consume_item(item.instance_id, item.quantity)
	profile.inventory.add_item(ItemInstance.new(&"medical.field_dressing", 1))
	var credits := profile.credits
	before = JSON.stringify(profile.to_dict())
	check(NarrativeSlice.submit_q02("user://missing-dir/q02.json").error != OK and JSON.stringify(profile.to_dict()) == before, "save failure consumes nothing")
	check(NarrativeSlice.submit_q02(PATH).error == OK, "partial warehouse delivery needs no pharmacy")
	check(profile.narrative_slice.q02.delivered["medical.field_dressing"] == 1 and not profile.narrative_slice.settled.Q02 and profile.credits == credits, "partial delivery records consumption without reward")
	check(ProfileRuntime.load_profile(PATH), "partial delivery reloads")
	profile = ProfileRuntime.get_profile()
	check(profile.narrative_slice.q02.observed_batch.is_empty(), "no fabricated pharmacy observation")
	profile.inventory.add_item(ItemInstance.new(&"medical.field_dressing", 1))
	profile.inventory.add_item(ItemInstance.new(&"material.fabric", 2))
	var panel := CampaignPanel.new()
	panel.contact_id = "tang_kui"; panel.save_path = PATH
	add_child(panel)
	var button: Button = panel.find_child("SubmitQ02", true, false)
	check(button != null and not button.disabled, "contact offers real delivery button")
	button.pressed.emit()
	await get_tree().process_frame
	check(profile.narrative_slice.settled.Q02 and profile.credits == credits + NarrativeSlice.Q02_REWARD, "completion saves and rewards once")
	check(SupplyService.count(profile, &"medical.field_dressing") == 0 and SupplyService.count(profile, &"material.fabric") == 0, "delivered supplies really consumed")
	check(panel.find_child("SubmitQ02", true, false) == null and panel.find_child("SubmitQ04", true, false) == null, "endpoint has no obsolete submit action")
	before = JSON.stringify(profile.to_dict())
	check(NarrativeSlice.submit_q02(PATH).error != OK and JSON.stringify(profile.to_dict()) == before, "repeat cannot consume or reward")
	panel.free()
	check(ProfileRuntime.load_profile(PATH) and JSON.stringify(ProfileRuntime.get_profile().to_dict()) == before, "completed delivery reloads exactly")
	profile = ProfileRuntime.get_profile()
	check(DeploymentPlan.deploy(profile, &"street_district", &"streets_recon", PATH).error == OK, "free sortie after endpoint")
	var battle: Node3D = load("res://scenes/battle/battle.tscn").instantiate()
	add_child(battle)
	await get_tree().process_frame
	check(not SortieRuntime.get_current_session().q04_active, "no retired logistics task activated")
	check(battle.area_root.get_node_or_null("DeliveryReceipt") == null and battle.area_root.get_node_or_null("PharmacyBatch") == null, "no logistics world interactions")
	check(SortieRuntime.get_current_session().abandon() and SortieRuntime.finalize_sortie(PATH) == OK, "normal abandonment settlement still works")
	battle.free()
	AudioDirector.shutdown_for_test()
	print("Q02_SLICE_TEST: %s (%d checks)" % ["PASS" if failures.is_empty() else "FAIL", checks])
	get_tree().quit(0 if failures.is_empty() else 1)
