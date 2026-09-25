extends Node

var failures: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	_test_sortie_carries_only_loadout()
	_test_completed_merge_and_save()
	_test_non_completed_outcomes()
	_test_invalid_commit_is_atomic()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(0.2).timeout
	if failures.is_empty():
		print("CARRIED_INVENTORY_TEST: PASS")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("CARRIED_INVENTORY_TEST: %s" % failure)
		print("CARRIED_INVENTORY_TEST: FAIL (%d)" % failures.size())
		get_tree().quit(1)


func _test_sortie_carries_only_loadout() -> void:
	var profile := ProfileState.create_new()
	var profile_before := profile.to_dict()
	var request := profile.create_sortie_request()
	var session := SortieSession.create_from_profile(request, profile)
	check(session != null, "valid warehouse and loadout create a sortie")
	if not session:
		return
	var carried_ids := profile.loadout.get_equipped_instance_ids()
	check(profile.inventory.get_items().size() > session.inventory.get_items().size(), "warehouse remains larger than carried inventory")
	check(session.inventory.get_items().size() == carried_ids.size(), "sortie inventory contains exactly the loadout instances")
	var expected_capacity := 0.0
	for instance_id in carried_ids:
		var profile_item := profile.inventory.get_item(instance_id)
		var sortie_item := session.inventory.get_item(instance_id)
		check(sortie_item != null and sortie_item != profile_item, "carried instance is a deep copy")
		check(sortie_item != null and sortie_item.instance_id == profile_item.instance_id, "carried copy preserves its business instance ID")
		var definition := ContentDB.get_item(profile_item.definition_id, false)
		expected_capacity += definition.weight * profile_item.quantity
	var uncarried_weapon := _find_item(profile.inventory, &"weapon.smg_01")
	check(uncarried_weapon != null and not session.inventory.contains(uncarried_weapon.instance_id), "uncarried warehouse weapon is absent from the sortie")
	check(is_equal_approx(session.inventory.get_used_capacity(), expected_capacity), "sortie capacity counts carried instances only")
	check(session.activate(), "carried inventory fixture activates")
	var used_before_loot := session.inventory.get_used_capacity()
	var loot := LootPickup.new()
	var recovered := ItemInstance.new(&"loot.salvage_core_01", 1, 100.0, "carried_capacity_loot")
	loot.setup(recovered)
	check(loot.try_pickup(session) == LootPickup.PickupResult.SUCCESS, "loot pickup enters carried inventory")
	check(is_equal_approx(session.inventory.get_used_capacity(), used_before_loot + 6.0), "loot increases carried capacity by its definition weight")
	check(profile.to_dict() == profile_before, "creating and changing carried inventory leaves warehouse unchanged")
	loot.free()


func _test_completed_merge_and_save() -> void:
	var save_path := "user://carried_inventory_test_%d.json" % OS.get_process_id()
	_cleanup_save(save_path)
	var profile := ProfileState.create_new()
	var warehouse_only := ItemInstance.new(&"loot.salvage_core_01", 1, 91.0, "warehouse_only_001")
	check(profile.inventory.add_item(warehouse_only), "warehouse fixture accepts an uncarried item")
	var original_ids := _instance_ids(profile.inventory)
	var original_count := profile.inventory.get_items().size()
	var session := _create_active_session(profile)
	if not session:
		_cleanup_save(save_path)
		return
	check(not session.inventory.contains(warehouse_only.instance_id), "warehouse-only item is not deployed")
	var carried_weapon := session.loadout.get_item(LoadoutState.SLOT_WEAPON_PRIMARY, session.inventory)
	carried_weapon.durability = 52.0
	var recovered_loot := ItemInstance.new(&"loot.salvage_core_01", 1, 74.0, "recovered_loot_001")
	var pickup := LootPickup.new()
	pickup.setup(recovered_loot)
	check(pickup.try_pickup(session) == LootPickup.PickupResult.SUCCESS, "sortie collects new recovered loot")
	pickup.free()
	check(session.complete_extraction(), "active sortie completes through extraction semantics")
	var outcome := SortieOutcomeService.create_outcome(session)
	check(outcome != null, "completed carried inventory creates an outcome")
	check(SortieOutcomeService.commit_outcome(profile, outcome) == OK, "recovered carried inventory commits to warehouse")
	check(profile.inventory.get_items().size() == original_count + 1, "warehouse merge preserves originals and adds one recovered item")
	for instance_id in original_ids:
		check(profile.inventory.contains(instance_id), "warehouse merge preserves original instance %s" % instance_id)
	check(profile.inventory.contains(recovered_loot.instance_id), "warehouse merge adds recovered loot instance")
	check(profile.inventory.get_item(carried_weapon.instance_id).durability == 52.0, "warehouse merge updates carried item state")
	check(_has_unique_instance_ids(profile.inventory), "warehouse merge keeps every instance ID unique")
	check(profile.loadout.validate(profile.inventory) and profile.validate(), "warehouse merge leaves all loadout references valid")
	check(profile.inventory != outcome.inventory and profile.inventory != session.inventory, "committed warehouse does not share inventory objects with outcome or session")
	check(SaveService.save_profile(profile, save_path) == OK, "merged warehouse saves")
	var restored := SaveService.load_profile(save_path, false)
	check(restored != null and restored.to_dict() == profile.to_dict(), "saved warehouse, carried state, loot, loadout, and capacity round trip")
	_cleanup_save(save_path)


func _test_non_completed_outcomes() -> void:
	for abandoned in [false, true]:
		var profile := ProfileState.create_new()
		var before := profile.to_dict()
		var session := _create_active_session(profile)
		if not session:
			continue
		check(session.inventory.add_item(ItemInstance.new(&"loot.salvage_core_01", 1, 100.0)), "non-completed fixture changes carried inventory")
		check(session.abandon() if abandoned else session.fail(), "non-completed fixture reaches terminal status")
		var outcome := SortieOutcomeService.create_outcome(session)
		check(SortieOutcomeService.commit_outcome(profile, outcome) == OK, "non-completed outcome commit returns success")
		check(profile.to_dict() == before, "failed and abandoned sorties leave warehouse unchanged")


func _test_invalid_commit_is_atomic() -> void:
	var profile := ProfileState.create_new()
	var before := profile.to_dict()
	var session := _create_active_session(profile)
	if not session:
		return
	check(session.complete_extraction(), "invalid commit fixture completes extraction")
	var outcome := SortieOutcomeService.create_outcome(session)
	outcome.loadout = LoadoutState.from_dict({String(LoadoutState.SLOT_WEAPON_PRIMARY): "missing_instance"})
	check(SortieOutcomeService.commit_outcome(profile, outcome) != OK, "invalid recovered loadout rejects the commit")
	check(profile.to_dict() == before, "rejected commit leaves warehouse and loadout untouched")


func _create_active_session(profile: ProfileState) -> SortieSession:
	var session := SortieSession.create_from_profile(profile.create_sortie_request(), profile)
	check(session != null and session.activate(), "test fixture creates an active carried inventory session")
	return session


func _find_item(inventory: InventoryState, definition_id: StringName) -> ItemInstance:
	for item in inventory.get_items():
		if item.definition_id == definition_id:
			return item
	return null


func _instance_ids(inventory: InventoryState) -> Array[String]:
	var result: Array[String] = []
	for item in inventory.get_items():
		result.append(item.instance_id)
	return result


func _has_unique_instance_ids(inventory: InventoryState) -> bool:
	var instance_ids: Dictionary = {}
	for item in inventory.get_items():
		if instance_ids.has(item.instance_id):
			return false
		instance_ids[item.instance_id] = true
	return true


func _cleanup_save(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
