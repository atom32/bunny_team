class_name ObjectiveDefinition
extends Resource

enum Type {
	ELIMINATE,
	INTERACT,
	REACH,
}

@export var objective_id: StringName
@export var display_name: String
@export_enum("Eliminate", "Interact", "Reach") var objective_type: int = Type.ELIMINATE
@export_range(1, 100000, 1, "or_greater") var target: int = 1
@export var target_id: StringName
@export var required := true


func validate_definition() -> bool:
	if (
		objective_id.is_empty()
		or display_name.is_empty()
		or objective_type not in [Type.ELIMINATE, Type.INTERACT, Type.REACH]
		or target <= 0
	):
		return false
	return objective_type == Type.ELIMINATE or not target_id.is_empty()
