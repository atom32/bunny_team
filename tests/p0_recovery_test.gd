extends Node
var failures: Array[String] = []
var path := "user://p0_recovery.json"

func _ready() -> void:
	await get_tree().process_frame
	_test_malformed_saves()
	_test_atomic_save_and_recovery()
	_test_load_and_ammo()
	_test_finalize_retry()
	SortieRuntime.clear_session()
	ProfileRuntime.new_profile()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(0.2).timeout
	for failure in failures:
		push_error(failure)
	print("P0_RECOVERY_TEST: " + ("PASS" if failures.is_empty() else "FAIL"))
	get_tree().quit(0 if failures.is_empty() else 1)

func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)

func _write(data: Variant) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func _test_malformed_saves() -> void:
	var source := ProfileState.create_new().to_dict()
	for value in [null, [], {}, "1", true, 1.5]:
		_write({"schema_version": value, "profile": source})
		check(SaveService.load_profile(path, false) == null, "Hostile schema type rejected")
	for value in [null, {}, [], "100", true, -1, 1e30]:
		var data := source.duplicate(true)
		data.inventory.capacity = value
		_write({"schema_version": 1, "profile": data})
		check(SaveService.load_profile(path, false) == null, "Hostile capacity rejected")
	for key in ["quantity", "durability", "instance_id", "definition_id"]:
		for value in [null, [], {}, true]:
			var data := source.duplicate(true)
			data.inventory.items[0][key] = value
			_write({"schema_version": 1, "profile": data})
			check(SaveService.load_profile(path, false) == null, "Hostile item field rejected: " + key)
	var data := source.duplicate(true)
	data.loadout.weapon_primary = []
	_write({"schema_version": 1, "profile": data})
	check(SaveService.load_profile(path, false) == null, "Hostile loadout ID rejected")

func _test_atomic_save_and_recovery() -> void:
	var profile := ProfileState.create_new()
	check(SaveService.save_profile(profile, path) == OK, "Valid profile saved atomically")
	check(SaveService.save_profile(profile, path) == OK, "Second save rotates backup")
	check(SaveService.load_profile(path + ".bak", false).to_dict() == profile.to_dict(), "Backup is valid previous profile")
	var good_backup := FileAccess.get_file_as_string(path + ".bak")
	_write({"broken": true})
	var broken := FileAccess.get_file_as_string(path)
	ProfileRuntime.initialize(path)
	check(ProfileRuntime.recovery_required and ProfileRuntime.get_profile().validate(), "Bad save supplies safe preview profile and requires explicit recovery")
	check(ProfileRuntime.save_profile(path) == ERR_FILE_CORRUPT and FileAccess.get_file_as_string(path) == broken, "Fallback cannot overwrite bad save")
	check(ProfileRuntime.recover_profile(true) == OK, "Backup recovery succeeds")
	check(not ProfileRuntime.recovery_required and SaveService.load_profile(path, false) != null, "Recovered save reopens")
	check(FileAccess.get_file_as_string(path + ".bak") == good_backup, "Bad primary did not replace good backup")
	var directory := DirAccess.open("user://")
	var archived := false
	for file in directory.get_files():
		if file.begins_with("p0_recovery.json.recovery-") and FileAccess.get_file_as_string("user://" + file) == broken:
			archived = true
	check(archived, "Corrupt original archived byte-for-byte")
	var original := FileAccess.get_file_as_string(path)
	profile.inventory.capacity = -1
	check(SaveService.save_profile(profile, path) != OK and FileAccess.get_file_as_string(path) == original, "Rejected save leaves primary untouched")

func _test_load_and_ammo() -> void:
	var profile := ProfileState.create_new()
	check(profile.inventory.add_item(ItemInstance.new(&"ammo.556_standard", 20000)), "Large warehouse ammo fixture")
	var before := profile.to_dict()
	var plan := DeploymentPlan.build(profile)
	check(plan.ammo_ids.size() <= 3 and plan.weight < 100, "Automatic plan bounds ammunition even with 20,000 warehouse rounds")
	var request := profile.create_sortie_request(SortieRequest.PROTOTYPE_AREA_ID, SortieRequest.PROTOTYPE_MISSION_ID, plan.ammo_ids)
	var session := SortieRuntime.start_sortie(request, profile)
	check(session != null, "Bounded plan creates session")
	check(SortieRuntime.start_sortie(request, profile) == null and SortieRuntime.get_current_session() == session, "Duplicate start cannot replace live session")
	check(profile.to_dict() == before, "Plan and session leave warehouse untouched")
	var weapon_id := session.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY)
	var total_before: int = session.get_reserve_ammo(weapon_id) + session.get_weapon_runtime_state(weapon_id).magazine_ammo
	var weight_before := session.inventory.current_weight
	check(session.fire_weapon(weapon_id), "One shot fires")
	check(is_equal_approx(session.inventory.current_weight, weight_before - ContentDB.get_ammo(&"ammo.556_standard").weight), "Magazine rounds count toward weight")
	check(session.reload_weapon(weapon_id) == 1, "Reload transfers fired round")
	# Fill all remaining usable capacity, with no space beyond the reserved magazines.
	var loot := ItemInstance.new(&"loot.salvage_core_01")
	session.inventory.capacity = session.inventory.current_weight + ContentDB.get_item(loot.definition_id).weight
	check(session.inventory.add_item(loot), "Cargo fills to exact capacity")
	check(session.complete_extraction(), "Full cargo with two loaded magazines extracts")
	check(_quantity(session.inventory, &"ammo.556_standard") == total_before - 1, "Extraction obeys ammo conservation")
	var outcome := SortieRuntime.get_outcome()
	profile.inventory.capacity = profile.inventory.current_weight
	check(SortieOutcomeService.commit_outcome(profile, outcome) == OK, "Full warehouse expands to accept extracted cargo")
	check(profile.inventory.contains(loot.instance_id), "Overflow recovery keeps loot")
	SortieRuntime.clear_session()
	# Explicit oversized requests get an error without touching warehouse or session.
	var ids: Array[String] = []
	for item in profile.inventory.get_items():
		if item.definition_id == &"ammo.556_standard": ids.append(item.instance_id)
	request = profile.create_sortie_request(SortieRequest.PROTOTYPE_AREA_ID, SortieRequest.PROTOTYPE_MISSION_ID, ids)
	check(SortieRuntime.start_sortie(request, profile) == null and SortieRuntime.last_error.begins_with("Overweight"), "Oversized explicit request is recoverable")

func _test_finalize_retry() -> void:
	var profile := ProfileRuntime.new_profile()
	var original := profile.to_dict()
	var session := SortieRuntime.start_sortie(profile.create_sortie_request(), profile)
	check(session.inventory.add_item(ItemInstance.new(&"loot.salvage_core_01", 1, 100, "retry_loot")), "Retry fixture loot")
	check(session.complete_extraction(), "Retry fixture extraction")
	check(SortieRuntime.finalize_sortie("user://missing-folder/profile.json") != OK, "Unwritable destination reports error")
	check(profile.to_dict() == original and SortieRuntime.get_current_session() == session, "Failed save publishes nothing and retains session")
	check(SortieRuntime.finalize_sortie(path) == OK, "Retry succeeds")
	check(profile.inventory.contains("retry_loot") and SortieRuntime.get_current_session() == null, "Successful retry publishes once and clears session")
	var committed := profile.to_dict()
	check(SortieRuntime.finalize_sortie(path) == OK and profile.to_dict() == committed, "Retry after successful finalize remains safe")

func _quantity(inventory: InventoryState, id: StringName) -> int:
	var result := 0
	for item in inventory.get_items():
		if item.definition_id == id: result += item.quantity
	return result
