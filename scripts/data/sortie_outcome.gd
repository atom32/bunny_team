class_name SortieOutcome
extends RefCounted

enum ResultType {
	COMPLETED,
	FAILED,
	ABANDONED,
}

var outcome_id: String
var session_id: String
var result_type: int
var area_id: StringName
var mission_id: StringName
var mission_completed: bool
var objective_summaries: Array[Dictionary] = []
var inventory: InventoryState # Recovered carried inventory at sortie end.
var loadout: LoadoutState
var enemies_defeated: int
var damage_taken: int
var initial_carried_instance_ids: Array[String] = []


func _init(
	p_session_id: String = "",
	p_result_type: int = -1,
	p_area_id: StringName = &"",
	p_mission_id: StringName = &"",
	p_inventory: InventoryState = null,
	p_loadout: LoadoutState = null,
	p_enemies_defeated: int = 0,
	p_damage_taken: int = 0,
	p_outcome_id: String = "",
	p_initial_carried_instance_ids: Array[String] = [],
	p_mission_completed: bool = false,
	p_objective_summaries: Array[Dictionary] = []
) -> void:
	outcome_id = p_outcome_id if not p_outcome_id.is_empty() else _generate_outcome_id()
	session_id = p_session_id
	result_type = p_result_type
	area_id = p_area_id
	mission_id = p_mission_id
	mission_completed = p_mission_completed
	for summary in p_objective_summaries:
		objective_summaries.append(summary.duplicate(true))
	inventory = p_inventory
	loadout = p_loadout
	enemies_defeated = p_enemies_defeated
	damage_taken = p_damage_taken
	initial_carried_instance_ids = p_initial_carried_instance_ids.duplicate()


static func create_from_session(session: SortieSession) -> SortieOutcome:
	if not session or session.outcome_created or not session.validate():
		return null
	var outcome_result_type := _result_type_from_status(session.status)
	if outcome_result_type < 0:
		return null
	var inventory_snapshot: InventoryState
	var loadout_snapshot: LoadoutState
	if outcome_result_type == ResultType.COMPLETED:
		inventory_snapshot = InventoryState.from_dict(session.inventory.to_dict())
		loadout_snapshot = LoadoutState.from_dict(session.loadout.to_dict())
	else:
		# Failed and abandoned sorties recover no carried ItemInstances.
		inventory_snapshot = InventoryState.new(session.inventory.capacity)
		loadout_snapshot = LoadoutState.new()
	var outcome := SortieOutcome.new(
		session.session_id,
		outcome_result_type,
		session.area_id,
		session.mission_id,
		inventory_snapshot,
		loadout_snapshot,
		session.enemies_defeated,
		session.damage_taken,
		"",
		session.get_initial_carried_instance_ids(),
		session.status == SortieSession.Status.COMPLETED and session.is_mission_completed(),
		session.get_objective_summary()
	)
	if not outcome.validate() or not session.mark_outcome_created():
		return null
	return outcome


func validate() -> bool:
	return (
		not outcome_id.is_empty()
		and not session_id.is_empty()
		and result_type in [ResultType.COMPLETED, ResultType.FAILED, ResultType.ABANDONED]
		and not area_id.is_empty()
		and not mission_id.is_empty()
		and _objective_summaries_are_valid()
		and inventory != null
		and loadout != null
		and inventory.validate()
		and loadout.validate(inventory)
		and enemies_defeated >= 0
		and damage_taken >= 0
		and _initial_carried_ids_are_valid()
	)


func to_dict() -> Dictionary:
	return {
		"outcome_id": outcome_id,
		"session_id": session_id,
		"result_type": result_type,
		"area_id": String(area_id),
		"mission_id": String(mission_id),
		"mission_completed": mission_completed,
		"objective_summaries": get_objective_summaries(),
		"inventory": inventory.to_dict(),
		"loadout": loadout.to_dict(),
		"enemies_defeated": enemies_defeated,
		"damage_taken": damage_taken,
		"initial_carried_instance_ids": initial_carried_instance_ids.duplicate(),
	}


static func from_dict(data: Dictionary) -> SortieOutcome:
	var inventory_data: Variant = data.get("inventory", null)
	var loadout_data: Variant = data.get("loadout", null)
	var initial_carried_data: Variant = data.get("initial_carried_instance_ids", null)
	var objective_summary_data: Variant = data.get("objective_summaries", null)
	var serialized_outcome_id := str(data.get("outcome_id", ""))
	if (
		serialized_outcome_id.is_empty()
		or typeof(inventory_data) != TYPE_DICTIONARY
		or typeof(loadout_data) != TYPE_DICTIONARY
		or typeof(initial_carried_data) != TYPE_ARRAY
		or typeof(objective_summary_data) != TYPE_ARRAY
	):
		return null
	var restored_initial_ids: Array[String] = []
	for instance_id in initial_carried_data:
		restored_initial_ids.append(str(instance_id))
	var restored_objective_summaries: Array[Dictionary] = []
	for summary in objective_summary_data:
		if typeof(summary) != TYPE_DICTIONARY:
			return null
		restored_objective_summaries.append(summary.duplicate(true))
	var outcome := SortieOutcome.new(
		str(data.get("session_id", "")),
		int(data.get("result_type", -1)),
		StringName(data.get("area_id", "")),
		StringName(data.get("mission_id", "")),
		InventoryState.from_dict(inventory_data),
		LoadoutState.from_dict(loadout_data),
		int(data.get("enemies_defeated", -1)),
		int(data.get("damage_taken", -1)),
		serialized_outcome_id,
		restored_initial_ids,
		bool(data.get("mission_completed", false)),
		restored_objective_summaries
	)
	return outcome if outcome.validate() else null


func get_objective_summaries() -> Array[Dictionary]:
	var snapshots: Array[Dictionary] = []
	for summary in objective_summaries:
		snapshots.append(summary.duplicate(true))
	return snapshots


func _objective_summaries_are_valid() -> bool:
	var mission := ContentDB.get_mission(mission_id, false)
	if not mission or objective_summaries.size() != mission.objective_definitions.size():
		return false
	var states_by_id: Dictionary = {}
	for summary in objective_summaries:
		var state := ObjectiveState.from_dict(summary)
		if not state or states_by_id.has(state.objective_id):
			return false
		states_by_id[state.objective_id] = state
	var all_required_completed := true
	for definition in mission.objective_definitions:
		var state := states_by_id.get(definition.objective_id) as ObjectiveState
		if not state or not state.matches_definition(definition):
			return false
		if definition.required and state.status != ObjectiveState.Status.COMPLETED:
			all_required_completed = false
	if result_type != ResultType.COMPLETED:
		return not mission_completed
	return mission_completed == all_required_completed


func _initial_carried_ids_are_valid() -> bool:
	var seen_ids: Dictionary = {}
	for instance_id in initial_carried_instance_ids:
		if instance_id.is_empty() or seen_ids.has(instance_id):
			return false
		seen_ids[instance_id] = true
	return true


static func _result_type_from_status(status: SortieSession.Status) -> int:
	match status:
		SortieSession.Status.COMPLETED:
			return ResultType.COMPLETED
		SortieSession.Status.FAILED:
			return ResultType.FAILED
		SortieSession.Status.ABANDONED:
			return ResultType.ABANDONED
	return -1


static func _generate_outcome_id() -> String:
	return Crypto.new().generate_random_bytes(16).hex_encode()
