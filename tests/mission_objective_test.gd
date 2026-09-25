extends Node

var failures: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	_test_definition_resolution()
	_test_eliminate_runtime()
	_test_early_extraction()
	_test_failed_outcome()
	_test_inventory_and_ammo_regression()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(0.2).timeout
	if failures.is_empty():
		print("MISSION_OBJECTIVE_TEST: PASS")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("MISSION_OBJECTIVE_TEST: %s" % failure)
		print("MISSION_OBJECTIVE_TEST: FAIL (%d)" % failures.size())
		get_tree().quit(1)


func _test_definition_resolution() -> void:
	var mission := ContentDB.get_mission(&"prototype_combat", false)
	check(mission != null and mission.validate_definition(), "prototype mission resolves through ContentDB")
	if not mission:
		return
	check(mission.display_name == "Prototype Combat", "mission exposes authored display content")
	check(mission.objective_definitions.size() == 3, "prototype mission owns eliminate, interact, and reach definitions")
	var objective := mission.objective_definitions[0]
	check(objective.objective_type == ObjectiveDefinition.Type.ELIMINATE and objective.target == 3, "prototype mission defines eliminate three enemies")
	check(mission.objective_definitions[1].objective_type == ObjectiveDefinition.Type.INTERACT and mission.objective_definitions[1].target == 1, "prototype mission defines one terminal interaction")
	check(mission.objective_definitions[2].objective_type == ObjectiveDefinition.Type.REACH and mission.objective_definitions[2].target == 1, "prototype mission defines one authored reach zone")


func _test_eliminate_runtime() -> void:
	var session := _create_session()
	if not session:
		return
	var objective := session.get_objective_state(&"eliminate_prototype_enemies")
	check(objective != null and objective.status == ObjectiveState.Status.ACTIVE, "session creates an active ObjectiveState")
	check(objective != null and objective.progress == 0 and objective.target == 3, "new eliminate objective starts at zero of three")
	check(not session.is_mission_completed(), "new sortie mission is incomplete")
	check(session.record_enemy_defeat(), "first enemy defeat is recorded by the session")
	objective = session.get_objective_state(&"eliminate_prototype_enemies")
	check(objective.progress == 1 and objective.status == ObjectiveState.Status.ACTIVE, "enemy defeat advances objective to one of three")
	check(session.record_enemy_defeat() and session.record_enemy_defeat(), "remaining enemy defeats are recorded")
	objective = session.get_objective_state(&"eliminate_prototype_enemies")
	check(objective.progress == 3 and objective.status == ObjectiveState.Status.COMPLETED, "target progress completes the objective")
	check(not session.is_mission_completed(), "completed eliminate objective does not bypass other required objectives")
	check(session.record_objective_interaction(&"interact_prototype_terminal"), "terminal interaction records through SortieSession")
	check(session.record_objective_reached(&"reach_prototype_zone"), "reach zone records through SortieSession")
	check(session.is_mission_completed(), "all required objectives complete the mission")


func _test_early_extraction() -> void:
	var session := _create_session()
	if not session:
		return
	check(session.record_enemy_defeat(), "early extraction fixture records one defeat")
	check(not session.is_mission_completed(), "one of three defeats leaves mission incomplete")
	check(session.complete_extraction(), "mission-incomplete sortie may still extract")
	check(session.status == SortieSession.Status.COMPLETED, "early extraction completes the sortie")
	check(not session.is_mission_completed(), "extraction does not auto-complete objectives")
	var outcome := SortieOutcomeService.create_outcome(session)
	check(outcome != null and outcome.result_type == SortieOutcome.ResultType.COMPLETED, "early extraction creates a completed sortie outcome")
	check(outcome != null and not outcome.mission_completed, "completed sortie outcome independently records mission incomplete")
	if outcome:
		var summaries := outcome.get_objective_summaries()
		check(summaries.size() == 3 and summaries[0]["progress"] == 1, "outcome preserves all objective summaries and one-of-three eliminate progress")
		session.objective_states[0].progress = 3
		summaries[0]["progress"] = 2
		check(outcome.get_objective_summaries()[0]["progress"] == 1, "outcome objective summary is independent from session and caller mutations")
		check(SortieOutcome.from_dict(outcome.to_dict()).to_dict() == outcome.to_dict(), "objective outcome summary serializes independently")


func _test_failed_outcome() -> void:
	var session := _create_session()
	if not session:
		return
	session.record_enemy_defeat()
	check(session.fail(), "objective fixture can end in FAILED")
	check(not session.is_mission_completed(), "failed sortie is never marked mission complete")
	var outcome := SortieOutcomeService.create_outcome(session)
	check(outcome != null and outcome.result_type == SortieOutcome.ResultType.FAILED, "death creates failed outcome alongside objective summary")
	check(outcome != null and not outcome.mission_completed, "failed outcome records mission incomplete")
	check(outcome != null and outcome.get_objective_summaries()[0]["progress"] == 1, "failed outcome preserves progress for result presentation")


func _test_inventory_and_ammo_regression() -> void:
	var profile := ProfileState.create_new()
	var ammo := _find_item(profile.inventory, &"ammo.556_standard")
	var request := profile.create_sortie_request(&"prototype_arena", &"prototype_combat", [ammo.instance_id])
	var session := SortieSession.create_from_profile(request, profile)
	check(session != null and session.activate(), "regression fixture creates active sortie with ammunition")
	if not session:
		return
	var weapon_id := session.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY)
	for _shot in 5:
		check(session.fire_weapon(weapon_id), "objective runtime does not block weapon fire")
	check(session.reload_weapon(weapon_id) == 5, "objective runtime preserves reserve-to-magazine reload")
	var loot := LootPickup.new()
	var recovered_item := ItemInstance.new(&"loot.salvage_core_01", 1, 100.0, "mission_regression_loot")
	loot.setup(recovered_item)
	check(loot.try_pickup(session) == LootPickup.PickupResult.SUCCESS, "objective runtime preserves sortie loot pickup")
	loot.free()
	for _defeat in 3:
		session.record_enemy_defeat()
	check(session.record_objective_interaction(&"interact_prototype_terminal"), "regression fixture completes authored interaction objective")
	check(session.record_objective_reached(&"reach_prototype_zone"), "regression fixture completes authored reach objective")
	check(session.is_mission_completed() and session.complete_extraction(), "completed objectives still extract through existing ammo finalization")
	var outcome := SortieOutcomeService.create_outcome(session)
	check(outcome != null and outcome.mission_completed, "completed extraction outcome records mission complete")
	check(outcome != null and ammo.instance_id in outcome.initial_carried_instance_ids, "outcome keeps initial carried identity with mission summary")
	check(SortieOutcomeService.commit_outcome(profile, outcome) == OK, "mission outcome preserves existing inventory commit")
	check(profile.inventory.contains(recovered_item.instance_id) and profile.inventory.contains(ammo.instance_id), "committed warehouse contains recovered loot and ammunition")
	check(profile.validate(), "mission commit leaves profile and loadout valid")


func _create_session() -> SortieSession:
	var profile := ProfileState.create_new()
	var session := SortieSession.create_from_profile(profile.create_sortie_request(), profile)
	check(session != null and session.activate(), "mission fixture creates active sortie")
	return session


func _find_item(inventory: InventoryState, definition_id: StringName) -> ItemInstance:
	for item in inventory.get_items():
		if item.definition_id == definition_id:
			return item
	return null


func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
