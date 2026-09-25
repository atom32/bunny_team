extends Node

const LOOT_PICKUP_SCENE := preload("res://scenes/world/loot_pickup.tscn")
const EXTRACTION_POINT_SCENE := preload("res://scenes/world/extraction_point.tscn")

var failures: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	_test_capacity_calculation()
	await _test_pickup_success_and_profile_isolation()
	await _test_pickup_capacity_rejection()
	_test_extraction_and_persistence()
	SortieRuntime.clear_session()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(0.2).timeout
	if failures.is_empty():
		print("EXTRACTION_VERTICAL_SLICE_TEST: PASS")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("EXTRACTION_VERTICAL_SLICE_TEST: %s" % failure)
		print("EXTRACTION_VERTICAL_SLICE_TEST: FAIL (%d)" % failures.size())
		get_tree().quit(1)


func _test_capacity_calculation() -> void:
	var inventory := InventoryState.new(5.0)
	check(is_zero_approx(inventory.get_used_capacity()), "empty inventory uses zero capacity")
	check(is_equal_approx(inventory.get_remaining_capacity(), 5.0), "empty inventory exposes all remaining capacity")
	var rifle := ItemInstance.new(&"weapon.assault_rifle_01", 1, 100.0, "capacity_rifle")
	check(inventory.add_item(rifle), "item within capacity is accepted")
	check(is_equal_approx(inventory.get_used_capacity(), 4.2), "added item consumes definition weight times quantity")
	check(is_equal_approx(inventory.get_remaining_capacity(), 0.8), "remaining capacity updates after add")


func _test_pickup_success_and_profile_isolation() -> void:
	var profile := ProfileState.create_new()
	var profile_before := profile.to_dict()
	var session := _create_session(profile)
	if not session:
		return
	var loot := LOOT_PICKUP_SCENE.instantiate() as LootPickup
	var item := ItemInstance.new(&"loot.salvage_core_01", 1, 84.0, "pickup_success_001")
	loot.setup(item)
	add_child(loot)
	await get_tree().process_frame
	check(loot.try_pickup(session) == LootPickup.PickupResult.SUCCESS, "pickup succeeds when sortie inventory has capacity")
	check(loot.consumed and session.inventory.contains(item.instance_id), "successful pickup moves the concrete item instance into sortie inventory")
	check(profile.to_dict() == profile_before, "pickup never mutates profile inventory")
	await get_tree().process_frame
	check(not is_instance_valid(loot), "successful pickup is removed from the world")


func _test_pickup_capacity_rejection() -> void:
	var inventory := InventoryState.new(4.2)
	check(inventory.add_item(ItemInstance.new(&"weapon.assault_rifle_01", 1, 100.0, "full_rifle")), "capacity fixture fills inventory exactly")
	var session := SortieSession.new(inventory, LoadoutState.new(), &"prototype_arena", &"prototype_combat")
	check(session.activate(), "capacity fixture session activates")
	var before := inventory.to_dict()
	var loot := LOOT_PICKUP_SCENE.instantiate() as LootPickup
	loot.setup(ItemInstance.new(&"loot.salvage_core_01", 1, 100.0, "pickup_full_001"))
	add_child(loot)
	await get_tree().process_frame
	check(loot.try_pickup(session) == LootPickup.PickupResult.CAPACITY_FULL, "pickup reports capacity rejection")
	check(not loot.consumed and is_instance_valid(loot), "capacity rejection leaves pickup in the world")
	check(inventory.to_dict() == before, "capacity rejection leaves inventory unchanged")
	loot.queue_free()
	await get_tree().process_frame


func _test_extraction_and_persistence() -> void:
	var save_path := "user://extraction_vertical_slice_test_%d.json" % OS.get_process_id()
	_cleanup_save(save_path)
	var profile := ProfileState.create_new()
	var uncarried_item := _find_item(profile.inventory, &"weapon.smg_01")
	var uncarried_before := uncarried_item.to_dict()
	var session := _create_session(profile)
	if not session:
		return
	var loot := LootPickup.new()
	var extracted_item := ItemInstance.new(&"loot.salvage_core_01", 1, 72.0, "extracted_loot_001")
	loot.setup(extracted_item)
	check(loot.try_pickup(session) == LootPickup.PickupResult.SUCCESS, "extraction fixture collects loot into sortie inventory")
	check(not profile.inventory.contains(extracted_item.instance_id), "collected loot remains absent from profile before extraction")
	loot.free()
	var extraction := EXTRACTION_POINT_SCENE.instantiate() as ExtractionPoint
	add_child(extraction)
	check(extraction.extract(session), "active session extracts successfully")
	check(session.status == SortieSession.Status.COMPLETED, "extraction transitions active session to completed")
	check(not extraction.extract(session), "completed session cannot extract twice")
	var outcome := SortieOutcomeService.create_outcome(session)
	check(outcome != null, "successful extraction creates one completed outcome")
	check(SortieOutcomeService.create_outcome(session) == null, "same session cannot create a second outcome")
	check(SortieOutcomeService.commit_outcome(profile, outcome) == OK, "completed extraction outcome commits")
	check(profile.inventory.contains(extracted_item.instance_id), "committed profile contains extracted loot")
	var committed_uncarried := profile.inventory.get_item(uncarried_item.instance_id)
	check(committed_uncarried != null and committed_uncarried.to_dict() == uncarried_before, "completed extraction preserves uncarried warehouse items")
	check(profile.validate(), "completed extraction leaves warehouse loadout valid")
	var committed_snapshot := profile.to_dict()
	check(SortieOutcomeService.commit_outcome(profile, outcome) == OK, "same outcome remains safe to commit idempotently")
	check(profile.to_dict() == committed_snapshot, "idempotent retry does not duplicate extracted loot")
	check(SaveService.save_profile(profile, save_path) == OK, "profile with extracted loot saves")
	var restored := SaveService.load_profile(save_path, false)
	check(restored != null and restored.inventory.contains(extracted_item.instance_id), "saved extracted loot survives profile reload")
	check(restored != null and restored.inventory.contains(uncarried_item.instance_id), "saved uncarried warehouse item survives profile reload")
	extraction.queue_free()
	_cleanup_save(save_path)


func _create_session(profile: ProfileState) -> SortieSession:
	var request := profile.create_sortie_request()
	var session := SortieSession.create_from_profile(request, profile)
	check(session != null and session.activate(), "test fixture creates active sortie session")
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
