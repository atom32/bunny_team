class_name ProfileState
extends RefCounted

const DEFAULT_WAREHOUSE_CAPACITY := 1000.0
const DEFAULT_CARRIED_CAPACITY := 100.0
const DEFAULT_DEFINITIONS := {
	LoadoutState.SLOT_WEAPON_PRIMARY: &"weapon.assault_rifle_01",
	LoadoutState.SLOT_WEAPON_SECONDARY: &"weapon.rocket_launcher_01",
	LoadoutState.SLOT_ARMOR: &"armor.recon_shell_01",
	LoadoutState.SLOT_BACKPACK: &"equipment.field_pack_01",
}
const DEFAULT_AMMO_QUANTITIES := {
	&"ammo.556_standard": 120,
	&"ammo.rocket_standard": 4,
}

var inventory: InventoryState # Persistent warehouse inventory.
var loadout: LoadoutState


func _init(p_inventory: InventoryState = null, p_loadout: LoadoutState = null) -> void:
	inventory = p_inventory
	loadout = p_loadout


static func create_new() -> ProfileState:
	var profile := ProfileState.new(InventoryState.new(DEFAULT_WAREHOUSE_CAPACITY), LoadoutState.new())
	for definition in ContentDB.get_items():
		if definition.has_tag(&"weapon") or definition.has_tag(&"armor") or definition.has_tag(&"backpack"):
			profile.inventory.add_item(ItemInstance.new(definition.id))
	for ammo_definition_id in DEFAULT_AMMO_QUANTITIES:
		if not profile.inventory.add_item(ItemInstance.new(ammo_definition_id, DEFAULT_AMMO_QUANTITIES[ammo_definition_id])):
			push_error("Could not add default profile ammunition: %s" % ammo_definition_id)
	for slot_id in DEFAULT_DEFINITIONS:
		profile._equip_first_definition(slot_id, DEFAULT_DEFINITIONS[slot_id])
	if not profile.validate():
		push_error("New profile failed validation")
	return profile


func validate() -> bool:
	return inventory != null and loadout != null and inventory.validate() and loadout.validate(inventory)


func create_sortie_request(
	area_id: StringName = SortieRequest.PROTOTYPE_AREA_ID,
	mission_id: StringName = SortieRequest.PROTOTYPE_MISSION_ID,
	carried_item_instance_ids: Array[String] = []
) -> SortieRequest:
	if not validate() or area_id.is_empty() or mission_id.is_empty():
		return null
	var loadout_snapshot := LoadoutState.from_dict(loadout.to_dict())
	if not loadout_snapshot or not loadout_snapshot.validate(inventory):
		return null
	var request := SortieRequest.new(area_id, mission_id, loadout_snapshot)
	for instance_id in carried_item_instance_ids:
		if not request.add_carried_item(instance_id, inventory):
			return null
	return request if request.validate(inventory) else null


func to_dict() -> Dictionary:
	return {
		"inventory": inventory.to_dict(),
		"loadout": loadout.to_dict(),
	}


static func from_dict(data: Dictionary) -> ProfileState:
	var inventory_data: Variant = data.get("inventory", null)
	var loadout_data: Variant = data.get("loadout", null)
	var restored_inventory: InventoryState = null
	var restored_loadout: LoadoutState = null
	if typeof(inventory_data) == TYPE_DICTIONARY:
		restored_inventory = InventoryState.from_dict(inventory_data)
	if typeof(loadout_data) == TYPE_DICTIONARY:
		restored_loadout = LoadoutState.from_dict(loadout_data)
	return ProfileState.new(restored_inventory, restored_loadout)


func _equip_first_definition(slot_id: StringName, definition_id: StringName) -> void:
	for item in inventory.get_items():
		if item.definition_id == definition_id:
			if not loadout.equip(slot_id, item.instance_id, inventory):
				push_error("Could not equip default profile content ID: %s" % definition_id)
			return
	push_error("Default profile content ID is not owned: %s" % definition_id)
