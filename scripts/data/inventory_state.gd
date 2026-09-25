class_name InventoryState
extends RefCounted

var capacity: float
var current_weight: float:
	get:
		return _calculate_weight()

var _items: Array[ItemInstance] = []


func _init(p_capacity: float = 0.0) -> void:
	capacity = maxf(p_capacity, 0.0)


func add_item(item: ItemInstance) -> bool:
	if not can_add_item(item):
		return false
	var definition := ContentDB.get_item(item.definition_id, false)
	if not definition.stackable:
		_items.append(item)
		return true
	var remaining := item.quantity
	for existing_item in _items:
		if not _can_stack(existing_item, item, definition):
			continue
		var transferred := mini(definition.max_stack - existing_item.quantity, remaining)
		existing_item.quantity += transferred
		remaining -= transferred
		if remaining == 0:
			return true
	var uses_source_instance := true
	while remaining > 0:
		var stack_quantity := mini(definition.max_stack, remaining)
		var stack_item := item if uses_source_instance else ItemInstance.new(
			item.definition_id,
			stack_quantity,
			item.durability
		)
		stack_item.quantity = stack_quantity
		_items.append(stack_item)
		uses_source_instance = false
		remaining -= stack_quantity
	return true


func add_item_preserving_instance(item: ItemInstance) -> bool:
	if not _can_add_exact_instance(item):
		return false
	_items.append(item)
	return true


func remove_item(instance_id: String) -> ItemInstance:
	for index in _items.size():
		if _items[index].instance_id == instance_id:
			return _items.pop_at(index)
	return null


func contains(instance_id: String) -> bool:
	return get_item(instance_id) != null


func get_item(instance_id: String) -> ItemInstance:
	for item in _items:
		if item.instance_id == instance_id:
			return item
	return null


func get_items() -> Array[ItemInstance]:
	return _items.duplicate()


func consume_item(instance_id: String, quantity: int) -> bool:
	if quantity <= 0:
		return false
	var item := get_item(instance_id)
	if not item or quantity > item.quantity:
		return false
	item.quantity -= quantity
	if item.quantity == 0:
		remove_item(instance_id)
	return true


func get_used_capacity() -> float:
	return current_weight


func get_remaining_capacity() -> float:
	return maxf(capacity - current_weight, 0.0)


func validate() -> bool:
	var instance_ids: Dictionary = {}
	var total_weight := 0.0
	for item in _items:
		if not item or item.instance_id.is_empty() or item.definition_id.is_empty() or item.quantity <= 0:
			return false
		if item.durability < 0.0 or item.durability > 100.0 or instance_ids.has(item.instance_id):
			return false
		var definition := ContentDB.get_item(item.definition_id, false)
		if not definition:
			return false
		if definition.stackable:
			if definition.max_stack <= 0 or item.quantity > definition.max_stack:
				return false
		elif item.quantity != 1:
			return false
		instance_ids[item.instance_id] = true
		total_weight += definition.weight * item.quantity
	return total_weight <= capacity + 0.0001


func to_dict() -> Dictionary:
	var serialized_items: Array[Dictionary] = []
	for item in _items:
		serialized_items.append(item.to_dict())
	return {
		"capacity": capacity,
		"items": serialized_items,
	}


static func from_dict(data: Dictionary) -> InventoryState:
	var serialized_items: Variant = data.get("items", null)
	var serialized_capacity: Variant = data.get("capacity", null)
	if typeof(serialized_items) != TYPE_ARRAY or serialized_capacity == null or float(serialized_capacity) < 0.0:
		return null
	var inventory := InventoryState.new(float(serialized_capacity))
	for item_data in serialized_items:
		if typeof(item_data) != TYPE_DICTIONARY:
			return null
		inventory._items.append(ItemInstance.from_dict(item_data))
	return inventory


func can_add(item: ItemInstance) -> bool:
	return can_add_item(item)


func can_add_item(item: ItemInstance) -> bool:
	if not _has_valid_identity(item):
		return false
	if contains(item.instance_id):
		return false
	var definition := ContentDB.get_item(item.definition_id, false)
	if not definition:
		return false
	if not definition.stackable and item.quantity != 1:
		return false
	return current_weight + definition.weight * item.quantity <= capacity + 0.0001


func _can_add_exact_instance(item: ItemInstance) -> bool:
	if not can_add_item(item):
		return false
	var definition := ContentDB.get_item(item.definition_id, false)
	return not definition.stackable or item.quantity <= definition.max_stack


func _has_valid_identity(item: ItemInstance) -> bool:
	return (
		item != null
		and not item.instance_id.is_empty()
		and not item.definition_id.is_empty()
		and item.quantity > 0
	)


func _can_stack(existing_item: ItemInstance, incoming_item: ItemInstance, definition: ItemDefinition) -> bool:
	return (
		existing_item.definition_id == incoming_item.definition_id
		and is_equal_approx(existing_item.durability, incoming_item.durability)
		and existing_item.quantity < definition.max_stack
	)


func _calculate_weight() -> float:
	var total := 0.0
	for item in _items:
		var definition := ContentDB.get_item(item.definition_id, false)
		if definition:
			total += definition.weight * item.quantity
	return total
