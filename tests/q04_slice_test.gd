extends Node
const PATH := "user://q04_slice_test.json"
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
	_base(false)
	await _deploy()
	check(not session.q04_active and not battle.area_root.has_node("DeliveryReceipt"), "Q04 requires completed Q02")
	# A real schema-6/Q02 checkpoint remains strictly recoverable.
	_interact("PharmacyBatch")
	check(SortieRuntime.save_checkpoint() == OK, "legacy fixture saved")
	var old := ProfileRuntime.get_profile().to_dict()
	old.narrative_slice.erase("q04")
	old.narrative_slice.version = 2
	old.sortie_checkpoint.version = 3
	for section in ["session","world"]:
		old.sortie_checkpoint[section].erase("q04_active")
		old.sortie_checkpoint[section].erase("delivery_receipt")
	_write(6, old)
	await _reload()
	check(not session.q04_active and session.q02_active and session.pharmacy_batch == NarrativeSlice.PHARMACY_BATCH, "schema-6 legacy Q02 observation restores without fabricated Q04")
	check(session.abandon() and SortieRuntime.finalize_sortie(PATH) == OK, "legacy result remains settleable")
	await _cleanup()
	for abandon in [false, true]:
		_base()
		await _deploy()
		_interact("DeliveryReceipt")
		_interact("PharmacyBatch")
		check(session.abandon() if abandon else session.fail(), "death/abandon ends observed sortie")
		check(SortieRuntime.finalize_sortie(PATH) == OK, "failure settlement")
		var facts: Dictionary = ProfileRuntime.get_profile().narrative_slice.q04
		check(facts.receipt_id.is_empty() and facts.observed_batch.is_empty(), "death/abandon cannot persist either Q04 fact")
		await _cleanup()
	var profile := _base()
	check(NarrativeSlice.prepare_q04_submission(profile).error != OK, "Q02 historical observation cannot satisfy Q04")
	await _deploy()
	check(session.q04_active and not session.q02_active and session.pharmacy_batch.is_empty(), "Q04 fresh sortie context independent of Q02 history")
	check(battle.hud.pharmacy_information.text == NarrativeSlice.BATCH_INFORMATION and battle.hud.receipt_information.text == NarrativeSlice.RECEIPT_INFORMATION, "two fixed records displayed, same Q02 batch data")
	check(battle.area_root.get_node("DeliveryReceipt").position == NarrativeSlice.RECEIPT_POSITION, "receipt fixed in apartment interior")
	battle.area_root.route_map.expanded = true
	check(session.delivery_receipt.is_empty() and session.pharmacy_batch.is_empty(), "map does not acquire or observe evidence")
	var receipt: Node3D = battle.area_root.get_node("DeliveryReceipt")
	battle.player.global_position = receipt.global_position + Vector3(10,0,0)
	check(not receipt.interact(battle.player,session).success, "receipt requires physical proximity")
	var objectives := session.get_objective_summary()
	_interact("DeliveryReceipt")
	check(not receipt.interact(battle.player,session).success, "receipt cannot be acquired twice in one sortie")
	check(session.get_objective_summary() == objectives, "Q04 evidence stays outside objective summaries")
	check(NarrativeSlice.submit_q04(PATH).error == ERR_BUSY, "base submission blocked during sortie")
	check(SortieRuntime.save_checkpoint() == OK, "suspend with receipt saved")
	var durable := profile.sortie_checkpoint.duplicate(true)
	var bad := durable.duplicate(true)
	bad.world.delivery_receipt = ""
	_reject(bad, "world/session receipt mismatch rejected")
	bad = durable.duplicate(true)
	bad.session.erase("q04_active")
	_reject(bad, "new checkpoint missing Q04 context rejected")
	await _reload()
	check(session.delivery_receipt == NarrativeSlice.DELIVERY_RECEIPT and session.pharmacy_batch.is_empty(), "receipt survives disk reload and world restore")
	check(ProfileRuntime.get_profile().narrative_slice.q04.receipt_id.is_empty(), "checkpoint is not permanent evidence")
	var outcome := await _extract()
	profile = ProfileRuntime.get_profile()
	check(profile.narrative_slice.q04.receipt_id == NarrativeSlice.DELIVERY_RECEIPT and profile.narrative_slice.q04.observed_batch.is_empty(), "successful first sortie banks only receipt")
	check(NarrativeSlice.submit_q04(PATH).error != OK, "one fact cannot settle Q04")
	var expected := JSON.stringify(profile.to_dict())
	check(SortieOutcomeService.commit_outcome(profile,outcome) == OK and JSON.stringify(profile.to_dict()) == expected, "repeated outcome is idempotent")
	await _cleanup()
	await _deploy()
	_interact("PharmacyBatch")
	check(SortieRuntime.save_checkpoint() == OK, "suspend fresh pharmacy observation")
	await _reload()
	check(session.pharmacy_batch == NarrativeSlice.PHARMACY_BATCH, "Q04 pharmacy observation restores independently")
	await _extract(true)
	profile = ProfileRuntime.get_profile()
	check(profile.narrative_slice.q04.receipt_id == NarrativeSlice.DELIVERY_RECEIPT and profile.narrative_slice.q04.observed_batch == NarrativeSlice.PHARMACY_BATCH, "independent successful sorties accumulate both facts")
	check(not profile.narrative_slice.settled.Q04 and NarrativeSlice.prepare_q04_submission(profile).error == OK, "both facts only make base submission ready")
	var before := JSON.stringify(profile.to_dict())
	check(NarrativeSlice.submit_q04("user://no_such_q04_directory/profile.json").error != OK and JSON.stringify(profile.to_dict()) == before, "failed base save cannot publish completion or reward")
	var credits := profile.credits
	var inventory := profile.inventory.to_dict()
	var panel := CampaignPanel.new()
	panel.size = Vector2(800,474)
	panel.save_path = PATH
	add_child(panel)
	var button: Button = panel.find_child("SubmitQ04",true,false)
	check(button != null and not button.disabled, "base UI validates both facts")
	button.pressed.emit()
	await get_tree().process_frame
	check(profile.narrative_slice.settled.Q04 and profile.credits == credits + 200, "base submission settles exactly 200 credits")
	check(profile.narrative_slice.q04.log == "该批次配送记录显示已完成签收，但药房现场记录与签收数量存在差异。相关配送调度记录可进一步核对。", "fixed factual log equals approved wording")
	check(profile.inventory.to_dict() == inventory, "Q04 creates or consumes no special inventory")
	check(panel.find_child("SubmitQ02",true,false) == null, "terminal UI does not reoffer historical NPC delivery")
	check(panel.find_child("SubmitQ04",true,false) == null, "completed Q04 has no ready submission button")
	check(panel.find_children("*","Label",true,false).any(func(label): return label.text == NarrativeSlice.Q04_LOG), "completed UI retains fixed log only")
	panel.free()
	expected = JSON.stringify(profile.to_dict())
	check(NarrativeSlice.submit_q04(PATH).error != OK and JSON.stringify(profile.to_dict()) == expected, "repeated base submission cannot reward twice")
	check(SortieRuntime.finalize_sortie(PATH) == OK and JSON.stringify(profile.to_dict()) == expected, "repeat return cannot advance narrative")
	check(ProfileRuntime.load_profile(PATH) and JSON.stringify(ProfileRuntime.get_profile().to_dict()) == expected, "completed Q04 survives disk reload")
	profile = ProfileRuntime.get_profile()
	var narrative := profile.narrative_slice.duplicate(true)
	check(SupplyService.transact("buy","medical.field_dressing",1,PATH).error == OK, "hard stop preserves free procurement")
	check(DeploymentPlan.set_medical_count("medical.field_dressing",0,PATH) == OK, "hard stop preserves packing choices")
	profile.loadout.unequip(LoadoutState.SLOT_ARMOR)
	check(ProfileRuntime.save_profile(PATH) == OK and profile.validate(), "hard stop preserves loadout editing and saving")
	check(profile.narrative_slice == narrative, "base actions do not generate narrative state")
	await _cleanup()
	await _deploy()
	check(_hard_stop(profile), "HARD ASSERT: Q04 completed => no active/ready/next narrative quest generated")
	check(not battle.area_root.has_node("DeliveryReceipt") and not battle.area_root.has_node("PharmacyBatch"), "terminal chain creates no narrative world interactions")
	check(NarrativeSlice.CHAINS.A == ["Q01","Q02","Q04"] and NarrativeSlice.ENDPOINTS.A == "Q04", "Q04 remains terminal with no successor")
	check(profile.narrative_slice.settled.Q01 and profile.narrative_slice.settled.Q02, "Q01/Q02 completion preserved")
	await _extract()
	check(profile.narrative_slice == narrative, "free extraction does not regenerate narrative progress")
	await _cleanup()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(0.4).timeout
	for failure in failures: push_error("Q04: " + failure)
	print("Q04_SLICE_TEST: %s (%d checks)" % ["PASS" if failures.is_empty() else "FAIL", checks])
	get_tree().quit(0 if failures.is_empty() else 1)

func _hard_stop(profile: ProfileState) -> bool:
	if not profile.narrative_slice.settled.Q04: return false
	if not session.slice_context.is_empty() or session.q02_active or session.q04_active: return false
	if NarrativeSlice.prepare_q02_delivery(profile).error == OK or NarrativeSlice.prepare_q04_submission(profile).error == OK: return false
	for key in ["active", "ready", "next"]:
		if profile.narrative_slice.has(key) or profile.narrative_slice.q04.has(key): return false
	for id in ["Q03","Q05","Q06"]:
		if profile.narrative_slice.settled[id]: return false
	return NarrativeSlice.TASK_IDS == ["Q01","Q02","Q04","Q03","Q05","Q06"]

func _base(q02_complete := true) -> ProfileState:
	var profile := ProfileRuntime.new_profile()
	profile.first_mission_completed = true
	profile.narrative_slice.settled.Q01 = true
	profile.narrative_slice.q01_exits = ["streets_exit_0","streets_exit_1"]
	if q02_complete:
		profile.narrative_slice.settled.Q02 = true
		profile.narrative_slice.q02 = {"observed_batch":NarrativeSlice.PHARMACY_BATCH,"delivered":{"medical.field_dressing":2,"material.fabric":2},"message":NarrativeSlice.Q02_MESSAGE}
	check(profile.validate(), "Q02 base fixture valid")
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

func _interact(name: String) -> void:
	var node: Node3D = battle.area_root.get_node(name)
	battle.player.global_position = node.global_position
	battle.player.interaction_component._current_target = null
	check(battle.player.interaction_component.interact_with_current().success, "actual nearest interaction: " + name)

func _reload() -> void:
	battle.free()
	SortieRuntime.clear_session()
	check(ProfileRuntime.load_profile(PATH), "load profile from disk")
	check(SortieRuntime.resume_saved(PATH) == OK, "resume durable sortie")
	session = SortieRuntime.get_current_session()
	get_tree().paused = false
	await _make_battle()

func _extract(test_save_failure := false) -> SortieOutcome:
	for exit in battle.area_root.find_children("*","ExtractionPoint",true,false):
		if exit.available and exit.required_objective_id.is_empty():
			check(exit.extract(session), "actual legal extraction")
			break
	check(SortieRuntime.save_checkpoint() == OK, "save pending result")
	var outcome := SortieRuntime.get_outcome()
	var durable := ProfileRuntime.get_profile().sortie_checkpoint.duplicate(true)
	var bad := durable.duplicate(true)
	bad.outcome.delivery_receipt = "" if not session.delivery_receipt.is_empty() else NarrativeSlice.DELIVERY_RECEIPT
	_reject(bad, "strict Session/Outcome receipt consistency")
	ProfileRuntime.get_profile().sortie_checkpoint = durable
	check(SortieRuntime.resume_saved(PATH) == OK, "valid result restored")
	if test_save_failure:
		var before := JSON.stringify(ProfileRuntime.get_profile().to_dict())
		check(SortieRuntime.finalize_sortie("user://no_such_q04_directory/profile.json") != OK and JSON.stringify(ProfileRuntime.get_profile().to_dict()) == before, "failed outcome save cannot publish observation")
	check(SortieRuntime.finalize_sortie(PATH) == OK, "successful candidate save/publish")
	return outcome

func _reject(saved: Dictionary, message: String) -> void:
	SortieRuntime.clear_session()
	ProfileRuntime.get_profile().sortie_checkpoint = saved
	check(SortieRuntime.resume_saved(PATH) == ERR_INVALID_DATA and not SortieRuntime.get_current_session(), message)

func _write(schema: int, data: Dictionary) -> void:
	var file := FileAccess.open(PATH,FileAccess.WRITE)
	file.store_string(JSON.stringify({"schema_version":schema,"profile":data})); file.close()

func _migration() -> void:
	var profile := _base()
	var old := profile.to_dict()
	old.narrative_slice.erase("q04")
	old.narrative_slice.version = 2
	_write(6,old)
	var loaded := SaveService.load_profile(PATH,false)
	check(loaded != null and loaded.narrative_slice.q04.receipt_id.is_empty() and loaded.narrative_slice.q04.observed_batch.is_empty(), "schema 6 migrates without invented Q04 facts")
	check(loaded.narrative_slice.q02 == profile.narrative_slice.q02 and loaded.credits == profile.credits and loaded.inventory.to_dict() == profile.inventory.to_dict() and loaded.campaign == profile.campaign, "migration preserves Q02, wallet, warehouse and campaign")
	check(SaveService.save_profile(loaded,PATH) == OK, "migrated state saves new schema")
	_write(7,old)
	check(SaveService.load_profile(PATH,false) == null, "new schema cannot omit Q04 fields")
	var invalid := NarrativeSlice.initial_state()
	invalid.q04.receipt_id = NarrativeSlice.DELIVERY_RECEIPT
	check(not NarrativeSlice.valid_state(invalid), "Q04 cannot have facts before Q02 completion")
	invalid = profile.narrative_slice.duplicate(true)
	invalid.q04.receipt_id = "random_delivery"
	check(not NarrativeSlice.valid_state(invalid), "unrelated receipt cannot become evidence")
	check(not NarrativeSlice.valid_q04(true,"random_delivery",&"street_district"), "unknown session receipt rejected")
	invalid = profile.narrative_slice.duplicate(true)
	invalid.q04.observed_batch = "MED-OTHER"
	check(not NarrativeSlice.valid_state(invalid), "another batch's pharmacy record cannot satisfy Q04")
	var pharmacy_only := ProfileState.from_dict(profile.to_dict())
	pharmacy_only.narrative_slice.q04.observed_batch = NarrativeSlice.PHARMACY_BATCH
	check(pharmacy_only.validate() and NarrativeSlice.prepare_q04_submission(pharmacy_only).error != OK, "pharmacy record alone cannot settle Q04")

func _cleanup() -> void:
	FlowMenu.close()
	get_tree().paused = false
	if is_instance_valid(battle): battle.free()
	SortieRuntime.clear_session()
	await get_tree().process_frame
