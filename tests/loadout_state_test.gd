extends Node

var failures: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	_test_loadout_state()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(0.2).timeout
	if failures.is_empty():
		print("LOADOUT_STATE_TEST: PASS")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("LOADOUT_STATE_TEST: %s" % failure)
		print("LOADOUT_STATE_TEST: FAIL (%d)" % failures.size())
		get_tree().quit(1)


func _test_loadout_state() -> void:
	var inventory := InventoryState.new(100.0)
	var rifle_a := ItemInstance.new(&"weapon.assault_rifle_01", 1, 100.0, "item_001")
	var rifle_b := ItemInstance.new(&"weapon.assault_rifle_01", 1, 61.0, "item_002")
	var ammo := ItemInstance.new(&"ammo.556_ap", 60, 100.0, "item_003")
	var armor := ItemInstance.new(&"armor.recon_shell_01", 1, 84.0, "item_004")
	check(inventory.add_item(rifle_a), "test inventory owns rifle A")
	check(inventory.add_item(rifle_b), "test inventory owns rifle B")
	check(inventory.add_item(ammo), "test inventory owns ammunition")
	check(inventory.add_item(armor), "test inventory owns armor")

	var loadout := LoadoutState.new()
	check(loadout.equip(LoadoutState.SLOT_WEAPON_PRIMARY, rifle_a.instance_id, inventory), "loadout equips a concrete weapon instance")
	check(loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY) == "item_001", "weapon slot stores the instance ID")
	check(loadout.get_item(LoadoutState.SLOT_WEAPON_PRIMARY, inventory) == rifle_a, "loadout resolves the selected ItemInstance through inventory")
	check(rifle_a.definition_id == rifle_b.definition_id and rifle_a.instance_id != rifle_b.instance_id, "same definition keeps distinct owned instances")
	check(loadout.is_equipped(rifle_a.instance_id) and not loadout.is_equipped(rifle_b.instance_id), "loadout selection is instance-specific")

	check(not loadout.equip(LoadoutState.SLOT_WEAPON_PRIMARY, "item_999", inventory), "missing instance is rejected")
	check(loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY) == "item_001", "failed equip keeps the previous selection")
	check(not loadout.equip(LoadoutState.SLOT_WEAPON_PRIMARY, ammo.instance_id, inventory), "definition type mismatch is rejected")
	check(not loadout.equip(LoadoutState.SLOT_ARMOR, rifle_a.instance_id, inventory), "one instance cannot occupy an incompatible second slot")

	check(loadout.unequip(LoadoutState.SLOT_WEAPON_PRIMARY), "unequip reports a removed selection")
	check(not loadout.has_slot(LoadoutState.SLOT_WEAPON_PRIMARY), "unequip clears the slot")
	check(loadout.equip(LoadoutState.SLOT_WEAPON_PRIMARY, rifle_a.instance_id, inventory), "weapon can be equipped again")
	check(loadout.equip(LoadoutState.SLOT_WEAPON_PRIMARY, rifle_b.instance_id, inventory), "slot accepts a replacement instance")
	check(loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY) == "item_002", "replacement is the only selected weapon instance")
	check(loadout.equip(LoadoutState.SLOT_ARMOR, armor.instance_id, inventory), "armor equips in the armor slot")
	check(loadout.validate(inventory), "valid loadout matches inventory ownership and slot types")

	var restored := LoadoutState.from_dict(loadout.to_dict())
	check(restored.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY) == "item_002", "serialization preserves weapon instance identity")
	check(restored.get_equipped_instance_id(LoadoutState.SLOT_ARMOR) == "item_004", "serialization preserves armor instance identity")
	check(restored.validate(inventory), "deserialized loadout validates against the owning inventory")


func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
