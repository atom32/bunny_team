class_name LootTableDefinition
extends Resource

@export var table_id: StringName
@export var entries: Array[LootTableEntry] = []


func validate_definition() -> bool:
	if table_id.is_empty() or entries.is_empty():
		return false
	for entry in entries:
		if not entry or not entry.validate_definition():
			return false
	return true
