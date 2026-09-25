class_name ItemDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var icon: Texture2D
@export_range(0.0, 1000.0, 0.001, "or_greater") var weight: float = 0.0
@export_range(0, 1000000, 1, "or_greater") var base_value: int = 0
@export var item_tags := PackedStringArray()
@export var stackable := false
@export_range(1, 10000, 1, "or_greater") var max_stack := 1


func has_tag(tag: StringName) -> bool:
	return item_tags.has(String(tag))
