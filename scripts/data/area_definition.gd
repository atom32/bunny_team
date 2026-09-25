class_name AreaDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export var scene: PackedScene


func validate_definition() -> bool:
	return not id.is_empty() and not display_name.is_empty() and scene != null
