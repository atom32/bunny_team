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
	var item := ItemInstance.new()
	item.instance_id = str(data.get("instance_id", ""))
	item.definition_id = StringName(data.get("definition_id", ""))
	item.quantity = int(data.get("quantity", 0))
	item.durability = float(data.get("durability", -1.0))
	return item


static func _generate_instance_id() -> String:
	return Crypto.new().generate_random_bytes(16).hex_encode()
