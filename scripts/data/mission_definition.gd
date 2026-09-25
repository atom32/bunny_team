class_name MissionDefinition
extends Resource

@export var mission_id: StringName
@export var display_name: String
@export_multiline var description: String
@export var objective_definitions: Array[ObjectiveDefinition] = []


func validate_definition() -> bool:
	if mission_id.is_empty() or display_name.is_empty() or objective_definitions.is_empty():
		return false
	var objective_ids: Dictionary = {}
	var has_required_objective := false
	for objective in objective_definitions:
		if not objective or not objective.validate_definition() or objective_ids.has(objective.objective_id):
			return false
		objective_ids[objective.objective_id] = true
		has_required_objective = has_required_objective or objective.required
	return has_required_objective


func get_objective(objective_id: StringName) -> ObjectiveDefinition:
	for objective in objective_definitions:
		if objective.objective_id == objective_id:
			return objective
	return null
