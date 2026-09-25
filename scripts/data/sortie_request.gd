class_name SortieRequest
extends RefCounted

const PROTOTYPE_AREA_ID := &"prototype_arena"
const PROTOTYPE_MISSION_ID := &"prototype_combat"

var area_id: StringName
var mission_id: StringName
var loadout: LoadoutState
var carried_item_instance_ids: Array[String] = []


func _init(
	p_area_id: StringName = PROTOTYPE_AREA_ID,
	p_mission_id: StringName = PROTOTYPE_MISSION_ID,
	p_loadout: LoadoutState = null,
	p_carried_item_instance_ids: Array[String] = []
) -> void:
	area_id = p_area_id
	mission_id = p_mission_id
	loadout = p_loadout
	carried_item_instance_ids = p_carried_item_instance_ids.duplicate()


func validate(source_inventory: InventoryState) -> bool:
	if (
		area_id.is_empty()
		or mission_id.is_empty()
		or ContentDB.get_area_definition(area_id, false) == null
		or ContentDB.get_mission(mission_id, false) == null
		or not source_inventory
		or not source_inventory.validate()
		or not loadout
		or not loadout.validate(source_inventory)
	):
		return false
	var seen_ids: Dictionary = {}
	for instance_id in carried_item_instance_ids:
		if (
			instance_id.is_empty()
			or seen_ids.has(instance_id)
			or loadout.is_equipped(instance_id)
			or not _is_valid_carried_item(instance_id, source_inventory)
		):
			return false
		seen_ids[instance_id] = true
	return true


func add_carried_item(instance_id: String, source_inventory: InventoryState) -> bool:
	if (
		instance_id.is_empty()
		or not source_inventory
		or instance_id in carried_item_instance_ids
		or (loadout and loadout.is_equipped(instance_id))
		or not _is_valid_carried_item(instance_id, source_inventory)
	):
		return false
	carried_item_instance_ids.append(instance_id)
	return true


func remove_carried_item(instance_id: String) -> bool:
	if instance_id not in carried_item_instance_ids:
		return false
	carried_item_instance_ids.erase(instance_id)
	return true


func get_initial_carried_instance_ids() -> Array[String]:
	var instance_ids: Array[String] = []
	if loadout:
		instance_ids.append_array(loadout.get_equipped_instance_ids())
	instance_ids.append_array(carried_item_instance_ids)
	return instance_ids


func _is_valid_carried_item(instance_id: String, source_inventory: InventoryState) -> bool:
	var item := source_inventory.get_item(instance_id)
	return (
		item != null
		and item.quantity > 0
		and ContentDB.get_item(item.definition_id, false) != null
	)
