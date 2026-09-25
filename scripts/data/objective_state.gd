class_name ObjectiveState
extends RefCounted

enum Status {
	PENDING,
	ACTIVE,
	COMPLETED,
}

var objective_id: StringName
var objective_type: int
var status: int
var progress: int
var target: int
var target_id: StringName
var required: bool


func _init(
	p_objective_id: StringName = &"",
	p_objective_type: int = -1,
	p_status: int = Status.PENDING,
	p_progress: int = 0,
	p_target: int = 1,
	p_target_id: StringName = &"",
	p_required: bool = true
) -> void:
	objective_id = p_objective_id
	objective_type = p_objective_type
	status = p_status
	progress = p_progress
	target = p_target
	target_id = p_target_id
	required = p_required


static func create_from_definition(definition: ObjectiveDefinition) -> ObjectiveState:
	if not definition or not definition.validate_definition():
		return null
	return ObjectiveState.new(
		definition.objective_id,
		definition.objective_type,
		Status.ACTIVE,
		0,
		definition.target,
		definition.target_id,
		definition.required
	)


func record(amount: int = 1) -> bool:
	if status != Status.ACTIVE or amount <= 0:
		return false
	progress = mini(progress + amount, target)
	if progress >= target:
		status = Status.COMPLETED
	return true


func matches_definition(definition: ObjectiveDefinition) -> bool:
	return (
		definition != null
		and objective_id == definition.objective_id
		and objective_type == definition.objective_type
		and target == definition.target
		and target_id == definition.target_id
		and required == definition.required
	)


func validate() -> bool:
	if (
		objective_id.is_empty()
		or objective_type not in [ObjectiveDefinition.Type.ELIMINATE, ObjectiveDefinition.Type.INTERACT, ObjectiveDefinition.Type.REACH]
		or status not in [Status.PENDING, Status.ACTIVE, Status.COMPLETED]
		or target <= 0
		or progress < 0
		or progress > target
	):
		return false
	if objective_type != ObjectiveDefinition.Type.ELIMINATE and target_id.is_empty():
		return false
	if status == Status.PENDING:
		return progress == 0
	if status == Status.COMPLETED:
		return progress == target
	return progress < target


func to_dict() -> Dictionary:
	return {
		"objective_id": String(objective_id),
		"objective_type": objective_type,
		"status": status,
		"progress": progress,
		"target": target,
		"target_id": String(target_id),
		"required": required,
	}


static func from_dict(data: Dictionary) -> ObjectiveState:
	var state := ObjectiveState.new(
		StringName(data.get("objective_id", "")),
		int(data.get("objective_type", -1)),
		int(data.get("status", -1)),
		int(data.get("progress", -1)),
		int(data.get("target", -1)),
		StringName(data.get("target_id", "")),
		bool(data.get("required", true))
	)
	return state if state.validate() else null
