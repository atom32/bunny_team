extends Node

const RESULT_SCRIPT := preload("res://scripts/result/result.gd")

var failures: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	_test_create_from_completed_session()
	_test_active_session_rejected()
	_test_outcome_independence()
	_test_completed_commit()
	_test_failed_commit()
	_test_abandoned_commit()
	_test_idempotent_commit()
	_test_result_finalize_integration()
	SortieRuntime.clear_session()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(0.2).timeout
	if failures.is_empty():
		print("SORTIE_OUTCOME_TEST: PASS")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("SORTIE_OUTCOME_TEST: %s" % failure)
		print("SORTIE_OUTCOME_TEST: FAIL (%d)" % failures.size())
		get_tree().quit(1)


func _test_create_from_completed_session() -> void:
	var session := _create_session()
	if not session:
		return
	session.enemies_defeated = 7
	session.damage_taken = 23
	check(session.complete(), "active session completes before outcome creation")
	var outcome := SortieOutcomeService.create_outcome(session)
	check(outcome != null, "completed session creates an outcome")
	if not outcome:
		return
	check(not outcome.outcome_id.is_empty(), "outcome has a stable business ID")
	check(outcome.session_id == session.session_id, "outcome records source session ID")
	check(outcome.area_id == session.area_id and outcome.mission_id == session.mission_id, "outcome records area and mission IDs")
	check(outcome.result_type == SortieOutcome.ResultType.COMPLETED, "outcome records completed result")
	check(outcome.inventory.to_dict() == session.inventory.to_dict(), "outcome records inventory snapshot")
	check(outcome.loadout.to_dict() == session.loadout.to_dict(), "outcome records loadout snapshot")
	check(outcome.enemies_defeated == 7 and outcome.damage_taken == 23, "outcome records combat statistics")
	var restored := SortieOutcome.from_dict(outcome.to_dict())
	check(restored != null and restored.to_dict() == outcome.to_dict(), "outcome serialization round trip preserves state")


func _test_active_session_rejected() -> void:
	var session := _create_session()
	check(session != null and SortieOutcomeService.create_outcome(session) == null, "active session cannot create an outcome")


func _test_outcome_independence() -> void:
	var session := _create_session()
	if not session:
		return
	var weapon_id := session.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY)
	var alternate_weapon := ItemInstance.new(&"weapon.smg_01", 1, 100.0, "outcome_smg_001")
	check(session.inventory.add_item(alternate_weapon), "outcome fixture adds a recovered alternate weapon")
	check(session.loadout.equip(LoadoutState.SLOT_WEAPON_PRIMARY, alternate_weapon.instance_id, session.inventory), "outcome fixture equips the recovered weapon")
	session.enemies_defeated = 3
	session.damage_taken = 9
	session.complete()
	var outcome := SortieOutcomeService.create_outcome(session)
	if not outcome:
		check(false, "completed session creates an independent outcome")
		return
	var outcome_before := outcome.to_dict()
	session.inventory.get_item(weapon_id).durability = 12.0
	session.loadout.equip(LoadoutState.SLOT_WEAPON_PRIMARY, weapon_id, session.inventory)
	session.enemies_defeated = 99
	session.damage_taken = 88
	check(outcome.to_dict() == outcome_before, "session mutations after creation do not change outcome")
	check(outcome.inventory != session.inventory and outcome.loadout != session.loadout, "outcome owns independent inventory and loadout objects")


func _test_completed_commit() -> void:
	var profile := ProfileState.create_new()
	var warehouse_size_before := profile.inventory.get_items().size()
	var uncarried_item := _find_item(profile.inventory, &"weapon.smg_01")
	var uncarried_before := uncarried_item.to_dict()
	var session := _create_session(profile)
	if not session:
		return
	var session_weapon := session.loadout.get_item(LoadoutState.SLOT_WEAPON_PRIMARY, session.inventory)
	session_weapon.durability = 61.0
	var recovered_loot := ItemInstance.new(&"loot.salvage_core_01", 1, 78.0, "completed_loot_001")
	check(session.inventory.add_item(recovered_loot), "completed fixture adds recovered loot")
	session.complete()
	var outcome := SortieOutcomeService.create_outcome(session)
	check(SortieOutcomeService.commit_outcome(profile, outcome) == OK, "completed outcome commits successfully")
	check(profile.inventory.get_items().size() == warehouse_size_before + 1, "completed commit merges recovered loot into the warehouse")
	var committed_uncarried := profile.inventory.get_item(uncarried_item.instance_id)
	check(committed_uncarried != null and committed_uncarried.to_dict() == uncarried_before, "completed commit preserves an uncarried warehouse item")
	check(profile.inventory.contains(recovered_loot.instance_id), "completed commit adds recovered loot")
	check(profile.loadout.to_dict() == outcome.loadout.to_dict(), "completed commit keeps the recovered loadout")
	check(profile.validate(), "merged warehouse and loadout validate as one profile")
	check(profile.inventory != outcome.inventory and profile.loadout != outcome.loadout, "profile does not share inventory or loadout objects with outcome")
	check(profile.inventory != session.inventory and profile.loadout != session.loadout, "profile does not share inventory or loadout objects with session")
	check(profile.inventory.get_item(session_weapon.instance_id).durability == 61.0, "carried item state is updated from the recovered snapshot")
	check(profile.inventory.get_item(session_weapon.instance_id) != outcome.inventory.get_item(session_weapon.instance_id), "profile item objects are copied from outcome")


func _test_failed_commit() -> void:
	_test_non_completed_commit(false)


func _test_abandoned_commit() -> void:
	_test_non_completed_commit(true)


func _test_non_completed_commit(abandoned: bool) -> void:
	var profile := ProfileState.create_new()
	var before := profile.to_dict()
	var session := _create_session(profile)
	if not session:
		return
	var weapon := session.loadout.get_item(LoadoutState.SLOT_WEAPON_PRIMARY, session.inventory)
	weapon.durability = 35.0
	var finished := session.abandon() if abandoned else session.fail()
	check(finished, "active session reaches requested non-completed state")
	var outcome := SortieOutcomeService.create_outcome(session)
	check(SortieOutcomeService.commit_outcome(profile, outcome) == OK, "non-completed outcome commit returns success")
	check(profile.to_dict() == before, "failed or abandoned outcome leaves profile unchanged")


func _test_idempotent_commit() -> void:
	var profile := ProfileState.create_new()
	var warehouse_size_before := profile.inventory.get_items().size()
	var session := _create_session(profile)
	if not session:
		return
	var weapon := session.loadout.get_item(LoadoutState.SLOT_WEAPON_PRIMARY, session.inventory)
	weapon.durability = 47.0
	var recovered_loot := ItemInstance.new(&"loot.salvage_core_01", 1, 100.0, "idempotent_loot_001")
	check(session.inventory.add_item(recovered_loot), "idempotent fixture adds recovered loot")
	session.complete()
	var outcome := SortieOutcomeService.create_outcome(session)
	check(SortieOutcomeService.commit_outcome(profile, outcome) == OK, "first completed outcome commit succeeds")
	var first_snapshot := profile.to_dict()
	check(SortieOutcomeService.commit_outcome(profile, outcome) == OK, "repeated completed outcome commit succeeds")
	var second_snapshot := profile.to_dict()
	check(first_snapshot == second_snapshot, "repeated commit produces identical profile state")
	check(profile.inventory.get_items().size() == warehouse_size_before + 1, "repeated commit does not duplicate recovered inventory entries")


func _test_result_finalize_integration() -> void:
	var save_path := "user://sortie_outcome_test_%d.json" % OS.get_process_id()
	_cleanup_save(save_path)
	SortieRuntime.clear_session()
	var profile := ProfileRuntime.new_profile()
	var warehouse_size_before := profile.inventory.get_items().size()
	var uncarried_item := _find_item(profile.inventory, &"weapon.smg_01")
	var request := profile.create_sortie_request()
	var session := SortieRuntime.start_sortie(request, profile)
	check(session != null, "runtime starts integration sortie")
	if not session:
		_cleanup_save(save_path)
		return
	var weapon := session.loadout.get_item(LoadoutState.SLOT_WEAPON_PRIMARY, session.inventory)
	weapon.durability = 73.0
	var recovered_loot := ItemInstance.new(&"loot.salvage_core_01", 1, 66.0, "result_loot_001")
	check(session.inventory.add_item(recovered_loot), "result integration adds recovered loot")
	session.enemies_defeated = 4
	session.damage_taken = 11
	session.complete()
	var expected_loadout := session.loadout.to_dict()
	var result_flow := RESULT_SCRIPT.new()
	var finalize_error := result_flow.finalize_sortie(save_path)
	result_flow.free()
	check(finalize_error == OK, "result finalize creates, commits, and saves outcome")
	check(ProfileRuntime.get_profile() == profile, "profile runtime retains its single profile owner")
	check(profile.inventory.get_items().size() == warehouse_size_before + 1, "result finalize preserves warehouse contents and adds recovered loot")
	check(profile.inventory.contains(uncarried_item.instance_id) and profile.inventory.contains(recovered_loot.instance_id), "result finalize keeps uncarried and recovered items")
	check(profile.loadout.to_dict() == expected_loadout and profile.validate(), "result finalize commits a valid recovered loadout")
	var restored := SaveService.load_profile(save_path, false)
	check(restored != null and restored.to_dict() == profile.to_dict(), "saved finalized profile loads with identical state")
	check(SortieRuntime.get_current_session() == null, "result finalize clears session only after successful save")
	_cleanup_save(save_path)


func _create_session(profile: ProfileState = null) -> SortieSession:
	var source_profile := profile if profile else ProfileState.create_new()
	var request := source_profile.create_sortie_request(&"prototype_arena", &"prototype_combat")
	var session := SortieSession.create_from_profile(request, source_profile)
	check(session != null and session.activate(), "test fixture creates an active sortie session")
	return session


func _find_item(inventory: InventoryState, definition_id: StringName) -> ItemInstance:
	for item in inventory.get_items():
		if item.definition_id == definition_id:
			return item
	return null


func _cleanup_save(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
