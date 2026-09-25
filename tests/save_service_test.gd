extends Node

var failures: Array[String] = []
var test_path := "user://profile_save_test_%s.json" % OS.get_process_id()


func _ready() -> void:
	await get_tree().process_frame
	_remove_test_save()
	_test_save_round_trip()
	_test_schema_and_validation_failures()
	_remove_test_save()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(0.2).timeout
	if failures.is_empty():
		print("SAVE_SERVICE_TEST: PASS")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("SAVE_SERVICE_TEST: %s" % failure)
		print("SAVE_SERVICE_TEST: FAIL (%d)" % failures.size())
		get_tree().quit(1)


func _test_save_round_trip() -> void:
	var profile := ProfileState.create_new()
	var weapon := profile.loadout.get_item(LoadoutState.SLOT_WEAPON_PRIMARY, profile.inventory)
	weapon.durability = 73.0
	var ammo := ItemInstance.new(&"ammo.556_ap", 37, 100.0, "saved_ammo_001")
	check(profile.inventory.add_item(ammo), "test ammunition fits in profile inventory")
	check(SaveService.save_profile(profile, test_path) == OK, "SaveService writes a valid profile")

	var file := FileAccess.open(test_path, FileAccess.READ)
	var envelope: Variant = JSON.parse_string(file.get_as_text()) if file else null
	check(typeof(envelope) == TYPE_DICTIONARY and int(envelope.get("schema_version", -1)) == 1, "save envelope contains schema_version 1")
	var restored := SaveService.load_profile(test_path, false)
	check(restored != null and restored.validate(), "SaveService loads a valid profile")
	var restored_weapon := restored.inventory.get_item(weapon.instance_id) if restored else null
	var restored_ammo := restored.inventory.get_item("saved_ammo_001") if restored else null
	check(restored_weapon != null and restored_weapon.durability == 73.0, "save round trip preserves durability and instance ID")
	check(restored_ammo != null and restored_ammo.quantity == 37, "save round trip preserves quantity")
	check(restored != null and restored.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY) == weapon.instance_id, "save round trip preserves loadout instance reference")
	check(restored_weapon != null and ContentDB.get_weapon(restored_weapon.definition_id, false) != null, "loaded item definition resolves through ContentDB")


func _test_schema_and_validation_failures() -> void:
	_write_envelope({"schema_version": 99, "profile": ProfileState.create_new().to_dict()})
	check(SaveService.load_profile(test_path, false) == null, "unsupported schema version fails explicitly")
	var invalid_profile_data := ProfileState.create_new().to_dict()
	invalid_profile_data["loadout"][String(LoadoutState.SLOT_WEAPON_PRIMARY)] = "item_999"
	_write_envelope({"schema_version": 1, "profile": invalid_profile_data})
	check(SaveService.load_profile(test_path, false) == null, "invalid loadout reference is rejected during load")


func _write_envelope(envelope: Dictionary) -> void:
	var file := FileAccess.open(test_path, FileAccess.WRITE)
	if not file:
		failures.append("test could not open its temporary save path")
		return
	file.store_string(JSON.stringify(envelope, "\t"))


func _remove_test_save() -> void:
	if FileAccess.file_exists(test_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))


func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
