class_name LootTableEntry
extends Resource

@export var definition_id: StringName
@export_range(0.001, 1000000.0, 0.001, "or_greater") var weight := 1.0
@export_range(1, 1000000, 1, "or_greater") var min_quantity := 1
@export_range(1, 1000000, 1, "or_greater") var max_quantity := 1
## Authored conversions use the existing instance fitting slot, not a rarity buff.
@export var fitting := ""


func validate_definition() -> bool:
	return (
		not definition_id.is_empty()
		and weight > 0.0
		and min_quantity > 0
		and max_quantity >= min_quantity
		and WeaponFitting.OPTIONS.has(fitting)
		and (fitting.is_empty() or (min_quantity == 1 and max_quantity == 1))
	)
