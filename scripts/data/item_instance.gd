class_name ItemInstance
extends RefCounted

var instance_id: String
var definition_id: StringName
var quantity: int
var durability: float


func _init(
	p_definition_id: StringName = &"",
	p_quantity: int = 1,
	p_durability: float = 100.0,
	p_instance_id: String = ""
) -> void:
	definition_id = p_definition_id
	quantity = maxi(p_quantity, 1)
	durability = clampf(p_durability, 0.0, 100.0)
	instance_id = p_instance_id if not p_instance_id.is_empty() else _generate_instance_id()


func to_dict() -> Dictionary:
	return {
		"instance_id": instance_id,
		"definition_id": String(definition_id),
		"quantity": quantity,
		"durability": durability,
	}


static func from_dict(data: Dictionary) -> ItemInstance:
	if typeof(data.get("instance_id")) != TYPE_STRING or typeof(data.get("definition_id")) != TYPE_STRING:
		return null
	var quantity_value: Variant = data.get("quantity")
	var durability_value: Variant = data.get("durability")
	if not SaveService.is_number(quantity_value) or quantity_value < 1 or quantity_value > 1000000 or floor(quantity_value) != quantity_value:
		return null
	if not SaveService.is_number(durability_value) or durability_value < 0 or durability_value > 100:
		return null
	var item := ItemInstance.new()
	item.instance_id = str(data.get("instance_id", ""))
	item.definition_id = StringName(data.get("definition_id", ""))
	item.quantity = int(data.get("quantity", 0))
	item.durability = float(data.get("durability", -1.0))
	return item


static func _generate_instance_id() -> String:
	return Crypto.new().generate_random_bytes(16).hex_encode()
