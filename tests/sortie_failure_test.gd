extends Node3D

const BATTLE_SCENE := preload("res://scenes/battle/battle.tscn")
const LOOT_PICKUP_SCENE := preload("res://scenes/world/loot_pickup.tscn")
const EXTRACTION_POINT_SCENE := preload("res://scenes/world/extraction_point.tscn")

var failures: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	_test_failed_sortie_data_boundary()
	_test_completed_path_regression()
	await _test_player_death_integration()
	SortieRuntime.clear_session()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(0.2).timeout
	if failures.is_empty():
		print("SORTIE_FAILURE_TEST: PASS")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("SORTIE_FAILURE_TEST: %s" % failure)
		print("SORTIE_FAILURE_TEST: FAIL (%d)" % failures.size())
		get_tree().quit(1)


func _test_failed_sortie_data_boundary() -> void:
	var fixture := _create_fixture(80)
	var profile: ProfileState = fixture.profile
	var session: SortieSession = fixture.session
	var weapon_id: String = fixture.weapon_id
	var profile_before := profile.to_dict()
	for _round in 10:
		check(session.fire_weapon(weapon_id), "failure fixture consumes an available magazine round")
	var weapon_state: Variant = session.get_weapon_runtime_state(weapon_id)
	check(weapon_state.magazine_ammo == 20 and session.get_reserve_ammo(weapon_id) == 80, "failure fixture has magazine 20 and reserve 80")
	var recovered_loot := ItemInstance.new(&"loot.salvage_core_01", 1, 100.0, "failed_sortie_loot")
	check(session.inventory.add_item(recovered_loot), "failure fixture picks up sortie-only loot")
	check(profile.to_dict() == profile_before, "fire and loot leave warehouse unchanged before death")

	check(session.fail(), "ACTIVE session transitions to FAILED")
	check(session.status == SortieSession.Status.FAILED, "session records FAILED status")
	check(not session.fail(), "repeated fail transition is rejected")
	check(not session.complete_extraction(), "FAILED session cannot extract")
	check(not session.complete(), "FAILED session cannot complete")
	check(not session.abandon(), "FAILED session cannot abandon")

	var failed_magazine: int = weapon_state.magazine_ammo
	var failed_inventory := session.inventory.to_dict()
	check(not session.fire_weapon(weapon_id), "FAILED session cannot fire")
	check(session.reload_weapon(weapon_id) == 0, "FAILED session cannot reload")
	check(weapon_state.magazine_ammo == failed_magazine and session.inventory.to_dict() == failed_inventory, "failed fire and reload leave runtime ammo unchanged")
	check(weapon_state.magazine_ammo == 20 and session.get_reserve_ammo(weapon_id) == 80, "death does not materialize magazine ammunition")

	var blocked_pickup := LOOT_PICKUP_SCENE.instantiate() as LootPickup
	blocked_pickup.setup(ItemInstance.new(&"loot.salvage_core_01", 1, 100.0, "blocked_failed_loot"))
	check(blocked_pickup.try_pickup(session) == LootPickup.PickupResult.INVALID_SESSION, "FAILED session cannot pick up loot")
	blocked_pickup.free()
	var extraction_point := EXTRACTION_POINT_SCENE.instantiate() as ExtractionPoint
	check(not extraction_point.extract(session), "FAILED session is rejected by extraction point")
	extraction_point.free()

	var outcome := SortieOutcomeService.create_outcome(session)
	check(outcome != null and outcome.result_type == SortieOutcome.ResultType.FAILED, "FAILED session creates a FAILED outcome")
	if not outcome:
		return
	check(outcome.inventory.get_items().is_empty(), "FAILED outcome contains no recovered ItemInstances")
	check(outcome.loadout.to_dict().is_empty(), "FAILED outcome contains no recovered loadout")
	check(outcome.initial_carried_instance_ids == session.get_initial_carried_instance_ids(), "FAILED outcome retains initial carried IDs for audit only")
	check(SortieOutcome.from_dict(outcome.to_dict()).to_dict() == outcome.to_dict(), "FAILED outcome serialization preserves empty recovery state")
	check(SortieOutcomeService.create_outcome(session) == null, "same FAILED session cannot create a second outcome")

	check(SortieOutcomeService.commit_outcome(profile, outcome) == OK, "FAILED outcome commit succeeds as a no-op")
	check(profile.to_dict() == profile_before, "FAILED commit preserves warehouse byte-for-byte")
	check(not profile.inventory.contains(recovered_loot.instance_id), "sortie loot is lost and never enters warehouse")
	var first_commit := profile.to_dict()
	check(SortieOutcomeService.commit_outcome(profile, outcome) == OK, "repeated FAILED commit remains valid")
	check(profile.to_dict() == first_commit, "repeated FAILED commit remains idempotent")


func _test_completed_path_regression() -> void:
	var fixture := _create_fixture(120)
	var profile: ProfileState = fixture.profile
	var session: SortieSession = fixture.session
	var weapon_id: String = fixture.weapon_id
	for _round in 10:
		session.fire_weapon(weapon_id)
	check(session.complete_extraction(), "completed regression still extracts successfully")
	check(_total_ammo(session.inventory, &"ammo.556_standard") == 140, "completed extraction still materializes remaining magazine ammo")
	var outcome := SortieOutcomeService.create_outcome(session)
	check(outcome != null and outcome.result_type == SortieOutcome.ResultType.COMPLETED, "completed regression creates recovered outcome")
	check(SortieOutcomeService.commit_outcome(profile, outcome) == OK, "completed regression commits recovery")
	check(_total_ammo(profile.inventory, &"ammo.556_standard") == 140, "completed regression updates warehouse ammo")


func _test_player_death_integration() -> void:
	SortieRuntime.clear_session()
	var profile := ProfileRuntime.new_profile()
	var ammo := _find_item(profile.inventory, &"ammo.556_standard")
	var carried_ids: Array[String] = [ammo.instance_id]
	var session := SortieRuntime.start_sortie(profile.create_sortie_request(&"prototype_arena", &"prototype_combat", carried_ids), profile)
	var battle := BATTLE_SCENE.instantiate()
	add_child(battle)
	for _frame in 5:
		await get_tree().process_frame
	battle.result_transition_enabled = false
	var player := battle.find_child("Player", true, false) as PlayerController
	check(player != null and session.status == SortieSession.Status.ACTIVE, "death integration starts with active player and session")
	if player:
		player.take_damage(player.max_health + 1.0)
		await get_tree().process_frame
		check(player.is_dead, "lethal health damage marks player dead")
		check(session.status == SortieSession.Status.FAILED, "player death transitions active session to FAILED")
		check(battle.ending, "battle enters terminal state after player death")
		check(not player.debug_fire_once(), "dead player cannot fire")
	battle.queue_free()
	await get_tree().process_frame
	SortieRuntime.clear_session()


func _create_fixture(reserve_quantity: int) -> Dictionary:
	var profile := ProfileState.create_new()
	var ammo := _find_item(profile.inventory, &"ammo.556_standard")
	ammo.quantity = reserve_quantity
	var carried_ids: Array[String] = [ammo.instance_id]
	var session := SortieSession.create_from_profile(profile.create_sortie_request(&"prototype_arena", &"prototype_combat", carried_ids), profile)
	check(session != null and session.activate(), "failure fixture creates an active sortie")
	return {
		"profile": profile,
		"session": session,
		"weapon_id": profile.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY),
	}


func _find_item(inventory: InventoryState, definition_id: StringName) -> ItemInstance:
	for item in inventory.get_items():
		if item.definition_id == definition_id:
			return item
	return null


func _total_ammo(inventory: InventoryState, definition_id: StringName) -> int:
	var total := 0
	for item in inventory.get_items():
		if item.definition_id == definition_id:
			total += item.quantity
	return total


func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
