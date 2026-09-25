class_name WeaponRuntimeState
extends RefCounted

var weapon_instance_id: String
var weapon_definition_id: StringName
var ammo_definition_id: StringName
var magazine_capacity: int
var magazine_ammo: int


func _init(
	p_weapon_instance_id: String = "",
	p_ammo_definition_id: StringName = &"",
	p_magazine_capacity: int = 0,
	p_magazine_ammo: int = 0,
	p_weapon_definition_id: StringName = &""
) -> void:
	weapon_instance_id = p_weapon_instance_id
	weapon_definition_id = p_weapon_definition_id
	ammo_definition_id = p_ammo_definition_id
	magazine_capacity = maxi(p_magazine_capacity, 0)
	magazine_ammo = clampi(p_magazine_ammo, 0, magazine_capacity)


func validate() -> bool:
	return (
		not weapon_instance_id.is_empty()
		and not ammo_definition_id.is_empty()
		and magazine_capacity > 0
		and magazine_ammo >= 0
		and magazine_ammo <= magazine_capacity
		and ContentDB.get_ammo(ammo_definition_id, false) != null
		and (weapon_definition_id.is_empty() or ContentDB.get_weapon(weapon_definition_id, false) != null)
	)


func can_fire() -> bool:
	return magazine_ammo > 0


func consume_round() -> bool:
	if not can_fire():
		return false
	magazine_ammo -= 1
	return true


func get_reserve_ammo(inventory: InventoryState) -> int:
	if not inventory:
		return 0
	var total := 0
	for item in inventory.get_items():
		if item.definition_id == ammo_definition_id:
			total += item.quantity
	return total


func can_reload(inventory: InventoryState) -> bool:
	return magazine_ammo < magazine_capacity and get_reserve_ammo(inventory) > 0


func reload(inventory: InventoryState) -> int:
	if not can_reload(inventory):
		return 0
	var rounds_to_load := mini(magazine_capacity - magazine_ammo, get_reserve_ammo(inventory))
	var remaining := rounds_to_load
	var consume_plan: Array[Dictionary] = []
	for item in inventory.get_items():
		if item.definition_id != ammo_definition_id:
			continue
		var consume_quantity := mini(item.quantity, remaining)
		consume_plan.append({"instance_id": item.instance_id, "quantity": consume_quantity})
		remaining -= consume_quantity
		if remaining == 0:
			break
	if remaining != 0:
		return 0
	for operation in consume_plan:
		if not inventory.consume_item(operation.instance_id, operation.quantity):
			return 0
	magazine_ammo += rounds_to_load
	return rounds_to_load


func can_materialize(inventory: InventoryState) -> bool:
	if magazine_ammo == 0:
		return true
	return inventory != null and inventory.can_add_item(ItemInstance.new(ammo_definition_id, magazine_ammo))


func materialize(inventory: InventoryState) -> bool:
	if magazine_ammo == 0:
		return true
	if not can_materialize(inventory):
		return false
	var recovered_ammo := ItemInstance.new(ammo_definition_id, magazine_ammo)
	if not inventory.add_item(recovered_ammo):
		return false
	magazine_ammo = 0
	return true
