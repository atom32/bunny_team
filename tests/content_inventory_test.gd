extends Node

var failures: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	_test_content_db()
	_test_item_instances()
	_test_inventory()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(0.2).timeout
	if failures.is_empty():
		print("CONTENT_INVENTORY_TEST: PASS")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("CONTENT_INVENTORY_TEST: %s" % failure)
		print("CONTENT_INVENTORY_TEST: FAIL (%d)" % failures.size())
		get_tree().quit(1)


func _test_content_db() -> void:
	var rifle := ContentDB.get_weapon(&"weapon.assault_rifle_01", false)
	var ammo := ContentDB.get_ammo(&"ammo.556_ap", false)
	check(rifle != null and rifle.id == &"weapon.assault_rifle_01", "ContentDB resolves a known weapon ID")
	check(ammo != null and ammo.armor_penetration > 0.0, "ContentDB resolves a known ammo ID")
	check(not ContentDB.has_item(&"item.missing"), "ContentDB reports an unknown ID as absent")
	check(ContentDB.get_item(&"item.missing", false) == null, "unknown content lookup returns null")


func _test_item_instances() -> void:
	var rifle_a := ItemInstance.new(&"weapon.assault_rifle_01", 1, 100.0)
	var rifle_b := ItemInstance.new(&"weapon.assault_rifle_01", 1, 61.0)
	check(rifle_a.definition_id == rifle_b.definition_id, "two instances can reference the same definition")
	check(rifle_a.instance_id != rifle_b.instance_id, "item instances have independent instance IDs")
	check(rifle_a.durability == 100.0 and rifle_b.durability == 61.0, "item instances keep independent mutable state")
	var restored := ItemInstance.from_dict(rifle_b.to_dict())
	check(restored.instance_id == rifle_b.instance_id, "item instance serialization preserves instance ID")
	check(restored.definition_id == rifle_b.definition_id and restored.durability == 61.0, "item instance serialization preserves core state")


func _test_inventory() -> void:
	var inventory := InventoryState.new(5.0)
	var rifle := ItemInstance.new(&"weapon.assault_rifle_01")
	var ammo := ItemInstance.new(&"ammo.556_standard", 60)
	var launcher := ItemInstance.new(&"weapon.rocket_launcher_01")
	check(inventory.add_item(rifle), "inventory adds an item within capacity")
	check(inventory.add_item(ammo), "inventory adds a stack within capacity")
	check(ammo.quantity == 60, "inventory preserves stack quantity")
	check(is_equal_approx(inventory.current_weight, 4.92), "inventory weight includes item quantity")
	check(is_equal_approx(inventory.get_used_capacity(), 4.92), "used capacity follows definition weight and quantity")
	check(is_equal_approx(inventory.get_remaining_capacity(), 0.08), "remaining capacity is available through the inventory boundary")
	check(inventory.contains(rifle.instance_id), "inventory contains an added instance")
	check(inventory.get_item(ammo.instance_id) == ammo, "inventory looks up an item by instance ID")
	check(not inventory.can_add_item(launcher), "inventory rejects an item above capacity")
	check(not inventory.add_item(launcher), "capacity rejection leaves inventory unchanged")
	check(inventory.get_items().size() == 2, "inventory exposes its current item instances")
	check(inventory.remove_item(ammo.instance_id) == ammo, "inventory removes and returns an item instance")
	check(not inventory.contains(ammo.instance_id), "removed item is no longer contained")
	check(is_equal_approx(inventory.current_weight, 4.2), "inventory weight updates after removal")


func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
