class_name LootTableEntry
extends Resource

@export var definition_id: StringName
@export_range(0.001, 1000000.0, 0.001, "or_greater") var weight := 1.0
@export_range(1, 1000000, 1, "or_greater") var min_quantity := 1
@export_range(1, 1000000, 1, "or_greater") var max_quantity := 1


func validate_definition() -> bool:
	return (
		not definition_id.is_empty()
		and weight > 0.0
		and min_quantity > 0
		and max_quantity >= min_quantity
	)
