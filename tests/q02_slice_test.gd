extends Node
const PATH := "user://q02_slice_test.json"
var checks := 0
var failures: Array[String] = []
var battle: Node3D
var session: SortieSession

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		print("CHECK FAILED: " + message)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	_migration()
	var profile := _base()
	for id in NarrativeSlice.Q02_INPUTS: profile.inventory.add_item(ItemInstance.new(id, 2))
	var before := JSON.stringify(profile.to_dict())
	check(NarrativeSlice.submit_q02(PATH).error != OK and JSON.stringify(profile.to_dict()) == before, "C materials alone cannot submit or complete")
	# Failure and abandonment each observe the real pharmacy node.
	for abandoned in [false, true]:
		_base()
		await _deploy()
		_observe()
		check(session.abandon() if abandoned else session.fail(), "B terminate observed sortie")
		check(SortieRuntime.finalize_sortie(PATH) == OK, "B failed result settles")
		check(ProfileRuntime.get_profile().narrative_slice.q02.observed_batch.is_empty(), "B death/abandon does not persist observation")
		check(NarrativeSlice.submit_q02(PATH).error != OK, "B no new observation can be submitted")
		await _cleanup()
	profile = _base()
	await _deploy()
	check(battle.hud.pharmacy_information.text == NarrativeSlice.BATCH_INFORMATION, "fixed receipt/stock information displayed separately from loot")
	check(battle.area_root.get_node("PharmacyBatch").position == NarrativeSlice.PHARMACY_POSITION, "fixed pharmacy interior position")
	battle.area_root.route_map.expanded = true
	check(session.pharmacy_batch.is_empty(), "map/UI/owned items never substitute for pharmacy observation")
	var node: Node3D = battle.area_root.get_node("PharmacyBatch")
	battle.player.global_position = node.global_position + Vector3(10,0,0)
	check(not node.interact(battle.player,session).success, "remote interaction rejected")
	var objectives := session.get_objective_summary()
	_observe()
	check(not node.interact(battle.player,session).success, "duplicate observation rejected")
	check(session.get_objective_summary() == objectives, "Q02 facts do not enter objective summaries")
	check(SortieRuntime.save_checkpoint() == OK, "A observation checkpoint saved")
	var durable := profile.sortie_checkpoint.duplicate(true)
	var bad := durable.duplicate(true)
	bad.world.pharmacy_batch = ""
	_reject(bad, "world/session pharmacy mismatch rejected")
	bad = durable.duplicate(true)
	bad.session.erase("pharmacy_batch")
	_reject(bad, "v3 missing pharmacy field rejected")
	check(ProfileRuntime.load_profile(PATH) and SortieRuntime.resume_saved(PATH) == OK, "A load/resume disk checkpoint")
	battle.free()
	get_tree().paused = false
	session = SortieRuntime.get_current_session()
	await _make_battle()
	check(session.pharmacy_batch == NarrativeSlice.PHARMACY_BATCH, "A observation survives world restore")
	check(NarrativeSlice.q02_status(ProfileRuntime.get_profile(),session).contains("尚未"), "provisional status before extraction")
	check(NarrativeSlice.submit_q02(PATH).error == ERR_BUSY, "cannot submit during sortie")
	# Successful observation without any material: distinct permanent fact, no completion.
	var outcome := await _extract()
	profile = ProfileRuntime.get_profile()
	check(profile.narrative_slice.q02.observed_batch == NarrativeSlice.PHARMACY_BATCH, "F successful extraction publishes observation")
	check(not profile.narrative_slice.settled.Q02 and NarrativeSlice.submit_q02(PATH).error != OK, "D observed but no materials cannot complete")
	var observed := JSON.stringify(profile.to_dict())
	check(SortieOutcomeService.commit_outcome(profile,outcome) == OK and JSON.stringify(profile.to_dict()) == observed, "G duplicate successful outcome does not republish/reward")
	check(ProfileRuntime.load_profile(PATH) and JSON.stringify(ProfileRuntime.get_profile().to_dict()) == observed, "H permanent observation reload")
	# Two further successful sorties bring one of each material, then explicit partial delivery.
	for run in 2:
		await _cleanup()
		await _deploy()
		for id in NarrativeSlice.Q02_INPUTS: check(session.inventory.add_item(ItemInstance.new(id)), "normal recovered material added")
		await _extract()
		profile = ProfileRuntime.get_profile()
		var credits := profile.credits
		var current := JSON.stringify(profile.to_dict())
		check(NarrativeSlice.submit_q02("user://no_such_q02_directory/profile.json").error != OK and JSON.stringify(profile.to_dict()) == current, "save failure preserves warehouse/progress/reward")
		if run == 0:
			var delivery_panel := CampaignPanel.new()
			delivery_panel.save_path = PATH
			delivery_panel.size = Vector2(800,474)
			add_child(delivery_panel)
			var button: Button = delivery_panel.find_child("SubmitQ02",true,false)
			check(not button.disabled, "base UI offers actual delivery")
			button.pressed.emit()
			await get_tree().process_frame
			check(delivery_panel.size.y == 474, "scrolling keeps base panel inside its allotted space")
			delivery_panel.free()
		else:
			check(NarrativeSlice.submit_q02(PATH).error == OK, "E explicit material delivery after successful sortie")
		check(profile.narrative_slice.q02.delivered["medical.field_dressing"] == run + 1 and profile.narrative_slice.q02.delivered["material.fabric"] == run + 1, "E actual partial deliveries accumulate")
		check(SupplyService.count(profile,&"medical.field_dressing") == 0 and SupplyService.count(profile,&"material.fabric") == 0, "delivery consumes existing warehouse items")
		check(profile.narrative_slice.settled.Q02 == (run == 1), "only full actual delivery completes")
		check(profile.credits == credits + (NarrativeSlice.Q02_REWARD if run == 1 else 0), "150 credit reward only on final delivery")
		check(SaveService.load_profile(PATH,false).narrative_slice == profile.narrative_slice, "H partial/completed delivery reload")
	check(profile.narrative_slice.q02.message == NarrativeSlice.Q02_MESSAGE, "fixed completion clue persisted")
	var completed := JSON.stringify(profile.to_dict())
	check(NarrativeSlice.submit_q02(PATH).error != OK and JSON.stringify(profile.to_dict()) == completed, "G repeated submit cannot consume or reward")
	check(SortieRuntime.finalize_sortie(PATH) == OK and JSON.stringify(profile.to_dict()) == completed, "G repeat return idempotent")
	check(not profile.narrative_slice.settled.Q04, "Q02 settlement cannot also settle Q04")
	var panel := CampaignPanel.new()
	panel.save_path = PATH
	add_child(panel)
	check(panel.find_child("SubmitQ02",true,false).disabled, "completed UI only displays state; submission disabled")
	panel.free()
	await _cleanup()
	await _deploy()
	check(not session.q02_active and session.q04_active and session.pharmacy_batch.is_empty(), "Q02 stays closed; Q04 requires a fresh pharmacy observation")
	check(profile.narrative_slice.settled.Q01 and profile.narrative_slice.q01_exits == ["streets_exit_0","streets_exit_1"], "Q01 persistent semantics preserved")
	await _cleanup()
	# Existing warehouse fabric and normal shop dressings are accepted equally.
	profile = _base()
	profile.inventory.add_item(ItemInstance.new(&"material.fabric",3))
	for index in 2:
		check(SupplyService.transact("buy","medical.field_dressing",1,PATH).error == OK, "normal shop dressing purchase")
	check(not profile.narrative_slice.settled.Q02 and profile.narrative_slice.q02.observed_batch.is_empty(), "buying/owning supplies cannot observe or deliver")
	await _deploy()
	check(session.pharmacy_batch.is_empty(), "carrying purchased medicine does not observe pharmacy")
	_observe()
	await _extract()
	var credits_before_delivery := profile.credits
	check(NarrativeSlice.submit_q02(PATH).error == OK and profile.narrative_slice.settled.Q02, "warehouse/shop materials qualify only after explicit delivery")
	check(profile.credits == credits_before_delivery + 150, "mixed sources receive exactly the design reward")
	check(SupplyService.count(profile,&"material.fabric") == 1, "delivery consumes only outstanding quantities, preserving extra warehouse stock")
	await _cleanup()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(0.4).timeout
	for failure in failures: push_error("Q02: " + failure)
	print("Q02_SLICE_TEST: %s (%d checks)" % ["PASS" if failures.is_empty() else "FAIL", checks])
	get_tree().quit(0 if failures.is_empty() else 1)

func _base() -> ProfileState:
	var profile := ProfileRuntime.new_profile()
	profile.first_mission_completed = true
	profile.narrative_slice.settled.Q01 = true
	profile.narrative_slice.q01_exits = ["streets_exit_0","streets_exit_1"]
	check(profile.validate(), "Q01-completed base fixture valid")
	return profile

func _deploy() -> void:
	var result := DeploymentPlan.deploy(ProfileRuntime.get_profile(),&"street_district",&"streets_recon",PATH)
	check(result.error == OK, "production deployment")
	session = SortieRuntime.get_current_session()
	await _make_battle()

func _make_battle() -> void:
	battle = load("res://scenes/battle/battle.tscn").instantiate()
	battle.result_transition_enabled = false
	add_child(battle)
	await get_tree().process_frame
	get_tree().paused = true

func _observe() -> void:
	var node: Node3D = battle.area_root.get_node("PharmacyBatch")
	battle.player.global_position = node.global_position
	battle.player.interaction_component._current_target = null
	check(battle.player.interaction_component.interact_with_current().success, "actual nearest pharmacy batch interaction")
	check(session.pharmacy_batch == NarrativeSlice.PHARMACY_BATCH, "fixed batch observed")

func _extract() -> SortieOutcome:
	for exit in battle.area_root.find_children("*","ExtractionPoint",true,false):
		if exit.available and exit.required_objective_id.is_empty():
			check(exit.extract(session), "actual legal extraction")
			break
	check(SortieRuntime.save_checkpoint() == OK, "result checkpoint saved")
	var outcome := SortieRuntime.get_outcome()
	var durable := ProfileRuntime.get_profile().sortie_checkpoint.duplicate(true)
	var bad := durable.duplicate(true)
	bad.outcome.pharmacy_batch = "" if not session.pharmacy_batch.is_empty() else NarrativeSlice.PHARMACY_BATCH
	_reject(bad, "strict result session/outcome pharmacy mismatch rejected")
	ProfileRuntime.get_profile().sortie_checkpoint = durable
	check(SortieRuntime.resume_saved(PATH) == OK, "valid result resume")
	check(SortieRuntime.finalize_sortie(PATH) == OK, "successful candidate save/publish")
	return outcome

func _reject(saved: Dictionary, message: String) -> void:
	SortieRuntime.clear_session()
	ProfileRuntime.get_profile().sortie_checkpoint = saved
	check(SortieRuntime.resume_saved(PATH) == ERR_INVALID_DATA and not SortieRuntime.get_current_session(), message)

func _migration() -> void:
	var profile := _base()
	var old := profile.to_dict()
	old.narrative_slice.erase("q02")
	old.narrative_slice.erase("q04")
	old.narrative_slice.version = 1
	for schema in [4,5]:
		var data := old.duplicate(true)
		if schema == 4: data.erase("narrative_slice")
		var file := FileAccess.open(PATH,FileAccess.WRITE)
		file.store_string(JSON.stringify({"schema_version":schema,"profile":data})); file.close()
		var loaded := SaveService.load_profile(PATH,false)
		check(loaded != null and loaded.narrative_slice.q02.observed_batch.is_empty(), "I old schema loads with empty Q02 facts")
		if schema == 5: check(loaded.narrative_slice.q01_exits == profile.narrative_slice.q01_exits, "I old Q01 state preserved")
		check(SaveService.save_profile(loaded,PATH) == OK, "I migrated profile saves new schema")
	var file := FileAccess.open(PATH,FileAccess.WRITE)
	file.store_string(JSON.stringify({"schema_version":6,"profile":old})); file.close()
	check(SaveService.load_profile(PATH,false) == null, "schema 6 cannot omit Q02 state")
	var invalid := NarrativeSlice.initial_state()
	invalid.q02.delivered["material.fabric"] = 1
	check(not NarrativeSlice.valid_state(invalid), "unobserved delivery state rejected")
	invalid = NarrativeSlice.initial_state()
	invalid.q02.observed_batch = "random_loot_batch"
	check(not NarrativeSlice.valid_state(invalid), "random batch cannot become story evidence")

func _cleanup() -> void:
	FlowMenu.close()
	get_tree().paused = false
	if is_instance_valid(battle): battle.free()
	SortieRuntime.clear_session()
	await get_tree().process_frame
