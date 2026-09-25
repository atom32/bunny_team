extends Node

var failures: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	_test_new_profile()
	_test_profile_ownership_and_serialization()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(0.2).timeout
	if failures.is_empty():
		print("PROFILE_STATE_TEST: PASS")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("PROFILE_STATE_TEST: %s" % failure)
		print("PROFILE_STATE_TEST: FAIL (%d)" % failures.size())
		get_tree().quit(1)


func _test_new_profile() -> void:
	var profile := ProfileState.create_new()
	check(profile.inventory != null, "new profile owns an InventoryState")
	check(profile.loadout != null, "new profile owns a LoadoutState")
	check(profile.validate(), "new profile loadout references owned instances")
	for slot_id in LoadoutState.SLOT_IDS:
		var item := profile.loadout.get_item(slot_id, profile.inventory)
		check(item != null and profile.inventory.contains(item.instance_id), "%s resolves to an owned item" % slot_id)


func _test_profile_ownership_and_serialization() -> void:
	var inventory := InventoryState.new(100.0)
	var rifle := ItemInstance.new(&"weapon.assault_rifle_01", 1, 87.0, "item_001")
	var armor := ItemInstance.new(&"armor.recon_shell_01", 1, 64.0, "item_002")
	var ammo := ItemInstance.new(&"ammo.556_ap", 42, 100.0, "item_003")
	inventory.add_item(rifle)
	inventory.add_item(armor)
	inventory.add_item(ammo)
	var loadout := LoadoutState.new()
	loadout.equip(LoadoutState.SLOT_WEAPON_PRIMARY, rifle.instance_id, inventory)
	loadout.equip(LoadoutState.SLOT_ARMOR, armor.instance_id, inventory)
	var profile := ProfileState.new(inventory, loadout)
	check(profile.inventory == inventory and profile.loadout == loadout, "profile owns the supplied inventory and loadout")
	check(profile.validate(), "owned inventory and loadout form a valid profile")

	var restored := ProfileState.from_dict(profile.to_dict())
	check(restored.validate(), "serialized profile restores as valid")
	var restored_rifle := restored.inventory.get_item("item_001")
	var restored_ammo := restored.inventory.get_item("item_003")
	check(restored_rifle != null and restored_rifle.definition_id == &"weapon.assault_rifle_01", "definition ID survives profile serialization")
	check(restored_rifle != null and restored_rifle.durability == 87.0, "durability survives profile serialization")
	check(restored_ammo != null and restored_ammo.quantity == 42, "quantity survives profile serialization")
	check(restored.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY) == "item_001", "loadout instance ID survives profile serialization")
	check(ContentDB.get_weapon(restored_rifle.definition_id, false) != null, "restored definition ID resolves through ContentDB")

	var invalid_data := profile.to_dict()
	invalid_data["loadout"][String(LoadoutState.SLOT_WEAPON_PRIMARY)] = "item_999"
	var invalid_profile := ProfileState.from_dict(invalid_data)
	check(not invalid_profile.validate(), "missing loadout instance fails profile validation")
	check(not invalid_profile.inventory.contains("item_999"), "validation does not synthesize missing inventory items")


func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
