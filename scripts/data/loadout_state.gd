class_name LoadoutState
extends RefCounted

const SLOT_WEAPON_PRIMARY := &"weapon_primary"
const SLOT_WEAPON_SECONDARY := &"weapon_secondary"
const SLOT_ARMOR := &"armor"
const SLOT_BACKPACK := &"backpack"
const WEAPON_SLOT_IDS := [SLOT_WEAPON_PRIMARY, SLOT_WEAPON_SECONDARY]
const SLOT_IDS := [SLOT_WEAPON_PRIMARY, SLOT_WEAPON_SECONDARY, SLOT_ARMOR, SLOT_BACKPACK]

var _slots: Dictionary = {}


func equip(slot_id: StringName, instance_id: String, inventory: InventoryState) -> bool:
	if slot_id not in SLOT_IDS or instance_id.is_empty() or not inventory:
		return false
	var item := inventory.get_item(instance_id)
	if not item or not _is_compatible(slot_id, item):
		return false
	for equipped_slot in _slots:
		if equipped_slot != slot_id and _slots[equipped_slot] == instance_id:
			return false
	_slots[slot_id] = instance_id
	return true


func unequip(slot_id: StringName) -> bool:
	return _slots.erase(slot_id)


func get_equipped_instance_id(slot_id: StringName) -> String:
	return str(_slots.get(slot_id, ""))


func get_item(slot_id: StringName, inventory: InventoryState) -> ItemInstance:
	if not inventory:
		return null
	return inventory.get_item(get_equipped_instance_id(slot_id))


func has_slot(slot_id: StringName) -> bool:
	return _slots.has(slot_id)


func is_equipped(instance_id: String) -> bool:
	return instance_id in _slots.values()


func get_equipped_instance_ids() -> Array[String]:
	var instance_ids: Array[String] = []
	for slot_id in SLOT_IDS:
		var instance_id := get_equipped_instance_id(slot_id)
		if not instance_id.is_empty():
			instance_ids.append(instance_id)
	return instance_ids


func validate(inventory: InventoryState) -> bool:
	if not inventory:
		return false
	var equipped_instances: Dictionary = {}
	for slot_id in _slots:
		if slot_id not in SLOT_IDS:
			return false
		var instance_id := str(_slots[slot_id])
		var item := inventory.get_item(instance_id)
		if not item or equipped_instances.has(instance_id) or not _is_compatible(slot_id, item):
			return false
		equipped_instances[instance_id] = true
	return true


func to_dict() -> Dictionary:
	var data := {}
	for slot_id in SLOT_IDS:
		if _slots.has(slot_id):
			data[String(slot_id)] = str(_slots[slot_id])
	return data


static func from_dict(data: Dictionary) -> LoadoutState:
	var loadout := LoadoutState.new()
	for serialized_slot in data:
		var slot_id := StringName(serialized_slot)
		if slot_id not in SLOT_IDS:
			return null
		var instance_id := str(data[serialized_slot])
		if not instance_id.is_empty():
			loadout._slots[slot_id] = instance_id
	return loadout


func _is_compatible(slot_id: StringName, item: ItemInstance) -> bool:
	var definition := ContentDB.get_item(item.definition_id, false)
	match slot_id:
		SLOT_WEAPON_PRIMARY, SLOT_WEAPON_SECONDARY:
			return definition is WeaponDefinition
		SLOT_ARMOR:
			return definition is EquipmentDefinition and not definition is WeaponDefinition and definition.has_tag(&"armor")
		SLOT_BACKPACK:
			return definition is EquipmentDefinition and not definition is WeaponDefinition and definition.has_tag(&"backpack")
	return false
