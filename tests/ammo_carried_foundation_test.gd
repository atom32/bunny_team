extends Node

var failures: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	_test_initial_carried_snapshot()
	_test_stack_and_consume()
	_test_outcome_commit_uses_initial_snapshot()
	_test_extracted_ammo_save_round_trip()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(0.2).timeout
	if failures.is_empty():
		print("AMMO_CARRIED_FOUNDATION_TEST: PASS")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("AMMO_CARRIED_FOUNDATION_TEST: %s" % failure)
		print("AMMO_CARRIED_FOUNDATION_TEST: FAIL (%d)" % failures.size())
		get_tree().quit(1)


func _test_initial_carried_snapshot() -> void:
	var profile := ProfileState.create_new()
	var ammo_ap := ItemInstance.new(&"ammo.556_ap", 60, 100.0, "initial_ammo_ap")
	var ammo_standard := ItemInstance.new(&"ammo.556_standard", 20, 100.0, "initial_ammo_standard")
	check(profile.inventory.add_item(ammo_ap), "warehouse accepts AP ammunition")
	check(profile.inventory.add_item(ammo_standard), "warehouse accepts standard ammunition")
	var carried_ids: Array[String] = [ammo_ap.instance_id, ammo_standard.instance_id]
	var request := profile.create_sortie_request(&"prototype_arena", &"prototype_combat", carried_ids)
	check(request != null and request.validate(profile.inventory), "profile creates a request with explicit carried ammunition")
	if not request:
		return
	check(not request.add_carried_item(ammo_ap.instance_id, profile.inventory), "request rejects duplicate explicit carried IDs")
	check(not request.add_carried_item("missing_item", profile.inventory), "request rejects an unknown carried ID")
	var equipped_weapon_id := profile.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY)
	check(not request.add_carried_item(equipped_weapon_id, profile.inventory), "request does not duplicate a loadout item as explicit cargo")
	var expected_ids := profile.loadout.get_equipped_instance_ids()
	expected_ids.append_array(carried_ids)
	var session := SortieSession.create_from_profile(request, profile)
	check(session != null, "valid request creates a sortie with explicit cargo")
	if not session:
		return
	check(_same_id_set(session.get_initial_carried_instance_ids(), expected_ids), "session records loadout and explicit cargo as its initial carried set")
	check(session.inventory.get_items().size() == expected_ids.size(), "session inventory contains only the initial carried set")
	for instance_id in expected_ids:
		var profile_item := profile.inventory.get_item(instance_id)
		var session_item := session.inventory.get_item(instance_id)
		check(session_item != null and session_item != profile_item, "carried item %s is a deep copy" % instance_id)
	var session_ammo := session.inventory.get_item(ammo_ap.instance_id)
	session_ammo.quantity = 41
	check(profile.inventory.get_item(ammo_ap.instance_id).quantity == 60, "sortie ammunition mutation does not alter warehouse ammunition")


func _test_stack_and_consume() -> void:
	var inventory := InventoryState.new(10.0)
	var ammo_a := ItemInstance.new(&"ammo.556_ap", 60, 100.0, "stack_ammo_a")
	var ammo_b := ItemInstance.new(&"ammo.556_ap", 20, 100.0, "stack_ammo_b")
	check(inventory.add_item(ammo_a), "first ammunition stack is accepted")
	check(inventory.add_item(ammo_b), "matching ammunition merges into an existing stack")
	check(inventory.get_items().size() == 1 and ammo_a.quantity == 80, "60 plus 20 ammunition produces one stack of 80")
	check(not inventory.contains(ammo_b.instance_id), "fully merged incoming stack does not create a duplicate instance")
	var ammo_c := ItemInstance.new(&"ammo.556_ap", 60, 100.0, "stack_ammo_c")
	check(inventory.add_item(ammo_c), "ammunition above max stack splits successfully")
	check(inventory.get_items().size() == 2 and _total_quantity(inventory, &"ammo.556_ap") == 140, "stack overflow produces 120 and 20 rounds")
	check(ammo_a.quantity == 120 and inventory.get_item(ammo_c.instance_id).quantity == 20, "split stacks respect the definition max stack")
	check(inventory.consume_item(ammo_a.instance_id, 10) and ammo_a.quantity == 110, "consume subtracts a valid quantity")
	check(inventory.consume_item(ammo_a.instance_id, 110) and not inventory.contains(ammo_a.instance_id), "consuming the remaining quantity removes the stack")
	var before_invalid_consume := inventory.to_dict()
	check(not inventory.consume_item(ammo_c.instance_id, 21), "consume rejects a quantity larger than the stack")
	check(inventory.to_dict() == before_invalid_consume, "failed consume leaves inventory unchanged")
	check(not inventory.consume_item(ammo_c.instance_id, 0), "consume rejects non-positive quantities")


func _test_outcome_commit_uses_initial_snapshot() -> void:
	var profile := ProfileState.create_new()
	var ammo := ItemInstance.new(&"ammo.556_ap", 60, 100.0, "commit_ammo")
	check(profile.inventory.add_item(ammo), "commit fixture owns carried ammunition")
	var carried_ids: Array[String] = [ammo.instance_id]
	var session := SortieSession.create_from_profile(profile.create_sortie_request(&"prototype_arena", &"prototype_combat", carried_ids), profile)
	check(session != null and session.activate(), "commit fixture starts an active sortie")
	if not session:
		return
	var initial_ids := session.get_initial_carried_instance_ids()
	check(session.complete(), "commit fixture completes its sortie")
	var outcome := SortieOutcomeService.create_outcome(session)
	check(outcome != null and _same_id_set(outcome.initial_carried_instance_ids, initial_ids), "outcome preserves the session initial carried set")
	if not outcome:
		return
	var session_ids_copy := session.get_initial_carried_instance_ids()
	session_ids_copy.clear()
	check(_same_id_set(outcome.initial_carried_instance_ids, initial_ids), "outcome initial carried set is independent from session data")
	var warehouse_smg := _find_item(profile.inventory, &"weapon.smg_01")
	check(profile.loadout.equip(LoadoutState.SLOT_WEAPON_PRIMARY, warehouse_smg.instance_id, profile.inventory), "test changes current profile loadout after sortie creation")
	check(SortieOutcomeService.commit_outcome(profile, outcome) == OK, "completed outcome commits after profile loadout changes")
	check(profile.inventory.contains(warehouse_smg.instance_id), "commit preserves a warehouse item selected only after sortie creation")
	check(profile.inventory.contains(ammo.instance_id) and profile.inventory.get_item(ammo.instance_id).quantity == 60, "commit recovers explicitly carried ammunition")
	var first_commit := profile.to_dict()
	check(SortieOutcomeService.commit_outcome(profile, outcome) == OK, "repeated snapshot commit succeeds")
	check(profile.to_dict() == first_commit, "repeated commit remains idempotent with explicit cargo")


func _test_extracted_ammo_save_round_trip() -> void:
	var save_path := "user://ammo_carried_foundation_%d.json" % OS.get_process_id()
	_cleanup_save(save_path)
	var profile := ProfileState.create_new()
	var carried_ammo := ItemInstance.new(&"ammo.556_ap", 60, 100.0, "extracted_ammo")
	var warehouse_only_ammo := ItemInstance.new(&"ammo.556_standard", 10, 100.0, "warehouse_only_ammo")
	check(profile.inventory.add_item(carried_ammo), "extraction fixture owns carried ammunition")
	check(profile.inventory.add_item(warehouse_only_ammo), "extraction fixture owns warehouse-only ammunition")
	var carried_ids: Array[String] = [carried_ammo.instance_id]
	var session := SortieSession.create_from_profile(profile.create_sortie_request(&"prototype_arena", &"prototype_combat", carried_ids), profile)
	check(session != null and session.activate(), "extraction fixture starts an active sortie")
	if not session:
		_cleanup_save(save_path)
		return
	var pickup_ammo := ItemInstance.new(&"ammo.556_ap", 20, 100.0, "pickup_ammo")
	check(session.inventory.add_item(pickup_ammo), "picked-up ammunition enters carried inventory")
	check(session.inventory.get_item(carried_ammo.instance_id).quantity == 80, "picked-up ammunition merges with carried ammunition")
	check(profile.inventory.get_item(carried_ammo.instance_id).quantity == 60, "ammunition pickup leaves warehouse state unchanged")
	check(session.complete_extraction(), "extraction completes the active sortie")
	var outcome := SortieOutcomeService.create_outcome(session)
	check(SortieOutcomeService.commit_outcome(profile, outcome) == OK, "extracted ammunition commits to warehouse")
	check(profile.inventory.get_item(carried_ammo.instance_id).quantity == 80, "warehouse receives the recovered ammunition quantity")
	check(profile.inventory.contains(warehouse_only_ammo.instance_id), "warehouse-only ammunition remains after commit")
	check(_has_unique_instance_ids(profile.inventory), "warehouse instance IDs remain unique after ammunition merge")
	check(profile.validate(), "profile remains valid after extracting stacked ammunition")
	check(SaveService.save_profile(profile, save_path) == OK, "extracted ammunition profile saves")
	var restored := SaveService.load_profile(save_path, false)
	check(restored != null and restored.to_dict() == profile.to_dict(), "save/load preserves carried, warehouse-only, and looted ammunition")
	_cleanup_save(save_path)


func _find_item(inventory: InventoryState, definition_id: StringName) -> ItemInstance:
	for item in inventory.get_items():
		if item.definition_id == definition_id:
			return item
	return null


func _same_id_set(left: Array[String], right: Array[String]) -> bool:
	if left.size() != right.size():
		return false
	for instance_id in left:
		if instance_id not in right:
			return false
	return true


func _total_quantity(inventory: InventoryState, definition_id: StringName) -> int:
	var total := 0
	for item in inventory.get_items():
		if item.definition_id == definition_id:
			total += item.quantity
	return total


func _has_unique_instance_ids(inventory: InventoryState) -> bool:
	var seen_ids: Dictionary = {}
	for item in inventory.get_items():
		if seen_ids.has(item.instance_id):
			return false
		seen_ids[item.instance_id] = true
	return true


func _cleanup_save(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
