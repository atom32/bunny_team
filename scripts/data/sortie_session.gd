class_name SortieSession
extends RefCounted

const WEAPON_RUNTIME_STATE_SCRIPT := preload("res://scripts/data/weapon_runtime_state.gd")

enum Status {
	PREPARING,
	ACTIVE,
	COMPLETED,
	FAILED,
	ABANDONED,
}

enum ThreatLevel {
	NORMAL,
	ALERT,
}

var status := Status.PREPARING
var session_id: String
var inventory: InventoryState # Carried inventory for this sortie only.
var loadout: LoadoutState
var area_id: StringName
var mission_id: StringName
var objective_states: Array[ObjectiveState] = []
var mission_completed := false
var enemies_defeated := 0
var damage_taken := 0
var outcome_created := false
var threat_level := ThreatLevel.NORMAL
var _initial_carried_instance_ids: Array[String] = []
var _weapon_runtime_states: Dictionary = {}


func _init(
	p_inventory: InventoryState = null,
	p_loadout: LoadoutState = null,
	p_area_id: StringName = &"",
	p_mission_id: StringName = &"",
	p_session_id: String = "",
	p_initial_carried_instance_ids: Array[String] = []
) -> void:
	session_id = p_session_id if not p_session_id.is_empty() else _generate_session_id()
	inventory = p_inventory
	loadout = p_loadout
	area_id = p_area_id
	mission_id = p_mission_id
	_initial_carried_instance_ids = p_initial_carried_instance_ids.duplicate()
	_initialize_objective_states()


static func create_from_profile(request: SortieRequest, profile: ProfileState) -> SortieSession:
	if not request or not profile or not profile.validate() or not request.validate(profile.inventory):
		return null
	var inventory_snapshot := InventoryState.new(ProfileState.DEFAULT_CARRIED_CAPACITY)
	var loadout_snapshot := LoadoutState.from_dict(request.loadout.to_dict())
	var initial_carried_instance_ids := request.get_initial_carried_instance_ids()
	for instance_id in initial_carried_instance_ids:
		var source_item := profile.inventory.get_item(instance_id)
		var item_snapshot := ItemInstance.from_dict(source_item.to_dict()) if source_item else null
		if not item_snapshot or not inventory_snapshot.add_item_preserving_instance(item_snapshot):
			return null
	if not inventory_snapshot or not loadout_snapshot or not inventory_snapshot.validate() or not loadout_snapshot.validate(inventory_snapshot):
		return null
	var session := SortieSession.new(
		inventory_snapshot,
		loadout_snapshot,
		request.area_id,
		request.mission_id,
		"",
		initial_carried_instance_ids
	)
	if not session._initialize_weapon_runtime_state():
		return null
	if not session._objective_runtime_is_valid():
		return null
	return session


func get_initial_carried_instance_ids() -> Array[String]:
	return _initial_carried_instance_ids.duplicate()


func get_objective_states() -> Array[ObjectiveState]:
	var snapshots: Array[ObjectiveState] = []
	for state in objective_states:
		snapshots.append(ObjectiveState.from_dict(state.to_dict()))
	return snapshots


func get_objective_state(objective_id: StringName) -> ObjectiveState:
	for state in objective_states:
		if state.objective_id == objective_id:
			return ObjectiveState.from_dict(state.to_dict())
	return null


func get_objective_summary() -> Array[Dictionary]:
	var summaries: Array[Dictionary] = []
	for state in objective_states:
		summaries.append(state.to_dict())
	return summaries


func is_mission_completed() -> bool:
	return mission_completed


func record_enemy_defeat() -> bool:
	if status != Status.ACTIVE:
		return false
	enemies_defeated += 1
	_record_objective_progress(ObjectiveDefinition.Type.ELIMINATE)
	return true


func record_objective_interaction(objective_id: StringName) -> bool:
	return _record_objective_by_id(objective_id, ObjectiveDefinition.Type.INTERACT)


func record_objective_reached(objective_id: StringName) -> bool:
	return _record_objective_by_id(objective_id, ObjectiveDefinition.Type.REACH)


func raise_threat() -> bool:
	if status != Status.ACTIVE or threat_level != ThreatLevel.NORMAL:
		return false
	threat_level = ThreatLevel.ALERT
	return true


func get_weapon_runtime_state(weapon_instance_id: String):
	return _weapon_runtime_states.get(weapon_instance_id)


func fire_weapon(weapon_instance_id: String) -> bool:
	if status != Status.ACTIVE:
		return false
	var weapon_state: Variant = get_weapon_runtime_state(weapon_instance_id)
	return weapon_state != null and weapon_state.consume_round()


func can_reload_weapon(weapon_instance_id: String) -> bool:
	var weapon_state: Variant = get_weapon_runtime_state(weapon_instance_id)
	return status == Status.ACTIVE and weapon_state != null and weapon_state.can_reload(inventory)


func reload_weapon(weapon_instance_id: String) -> int:
	if status != Status.ACTIVE:
		return 0
	var weapon_state: Variant = get_weapon_runtime_state(weapon_instance_id)
	return weapon_state.reload(inventory) if weapon_state else 0


func get_reserve_ammo(weapon_instance_id: String) -> int:
	var weapon_state: Variant = get_weapon_runtime_state(weapon_instance_id)
	return weapon_state.get_reserve_ammo(inventory) if weapon_state else 0


func finalize_runtime_ammo() -> bool:
	if status != Status.ACTIVE:
		return false
	for weapon_state in _weapon_runtime_states.values():
		if not weapon_state.can_materialize(inventory):
			return false
	for weapon_state in _weapon_runtime_states.values():
		if not weapon_state.materialize(inventory):
			return false
	return inventory.validate()


func activate() -> bool:
	if status != Status.PREPARING or not validate() or not _initial_carried_items_are_present():
		return false
	status = Status.ACTIVE
	return true


func complete() -> bool:
	return _finish(Status.COMPLETED)


func complete_extraction() -> bool:
	return _finish(Status.COMPLETED)


func fail() -> bool:
	return _finish(Status.FAILED)


func abandon() -> bool:
	return _finish(Status.ABANDONED)


func mark_outcome_created() -> bool:
	if outcome_created or status not in [Status.COMPLETED, Status.FAILED, Status.ABANDONED]:
		return false
	outcome_created = true
	return true


func validate() -> bool:
	return (
		not session_id.is_empty()
		and inventory != null
		and loadout != null
		and not area_id.is_empty()
		and not mission_id.is_empty()
		and inventory.validate()
		and loadout.validate(inventory)
		and _initial_carried_ids_are_valid()
		and _weapon_runtime_states_are_valid()
		and _objective_runtime_is_valid()
		and threat_level in [ThreatLevel.NORMAL, ThreatLevel.ALERT]
	)


func _initialize_objective_states() -> bool:
	objective_states.clear()
	mission_completed = false
	var mission := ContentDB.get_mission(mission_id, false)
	if not mission:
		return false
	for definition in mission.objective_definitions:
		var state := ObjectiveState.create_from_definition(definition)
		if not state:
			objective_states.clear()
			return false
		objective_states.append(state)
	_refresh_mission_completed()
	return true


func _record_objective_progress(objective_type: int, target_id: StringName = &"") -> bool:
	if status != Status.ACTIVE:
		return false
	var recorded := false
	for state in objective_states:
		if state.objective_type != objective_type:
			continue
		if objective_type != ObjectiveDefinition.Type.ELIMINATE and state.target_id != target_id:
			continue
		recorded = state.record() or recorded
	if recorded:
		_refresh_mission_completed()
	return recorded


func _record_objective_by_id(objective_id: StringName, objective_type: int) -> bool:
	if status != Status.ACTIVE or objective_id.is_empty():
		return false
	for state in objective_states:
		if state.objective_id != objective_id:
			continue
		if state.objective_type != objective_type or not state.record():
			return false
		_refresh_mission_completed()
		return true
	return false


func _refresh_mission_completed() -> void:
	mission_completed = _all_required_objectives_completed()


func _all_required_objectives_completed() -> bool:
	var required_count := 0
	for state in objective_states:
		if not state.required:
			continue
		required_count += 1
		if state.status != ObjectiveState.Status.COMPLETED:
			return false
	return required_count > 0


func _objective_runtime_is_valid() -> bool:
	var mission := ContentDB.get_mission(mission_id, false)
	if not mission or not mission.validate_definition() or objective_states.size() != mission.objective_definitions.size():
		return false
	var seen_ids: Dictionary = {}
	for state in objective_states:
		var definition := mission.get_objective(state.objective_id)
		if not state.validate() or not state.matches_definition(definition) or seen_ids.has(state.objective_id):
			return false
		seen_ids[state.objective_id] = true
	if status in [Status.FAILED, Status.ABANDONED]:
		return not mission_completed
	return mission_completed == _all_required_objectives_completed()


func _initialize_weapon_runtime_state() -> bool:
	_weapon_runtime_states.clear()
	for slot_id in LoadoutState.WEAPON_SLOT_IDS:
		if not loadout.has_slot(slot_id):
			continue
		var weapon_item := loadout.get_item(slot_id, inventory)
		var weapon_definition := ContentDB.get_weapon(weapon_item.definition_id, false) if weapon_item else null
		if not weapon_definition:
			return false
		var ammo_definition_id := weapon_definition.get_runtime_ammo_definition_id()
		if ammo_definition_id.is_empty() or weapon_definition.magazine_capacity <= 0:
			continue
		if not ContentDB.get_ammo(ammo_definition_id, false):
			return false
		var initial_magazine := weapon_definition.magazine_capacity if _inventory_has_ammo(ammo_definition_id) else 0
		_weapon_runtime_states[weapon_item.instance_id] = WEAPON_RUNTIME_STATE_SCRIPT.new(
			weapon_item.instance_id,
			ammo_definition_id,
			weapon_definition.magazine_capacity,
			initial_magazine,
			weapon_definition.id
		)
	return true


func _inventory_has_ammo(ammo_definition_id: StringName) -> bool:
	for item in inventory.get_items():
		if item.definition_id == ammo_definition_id and item.quantity > 0:
			return true
	return false


func _weapon_runtime_states_are_valid() -> bool:
	for weapon_instance_id in _weapon_runtime_states:
		var weapon_state = _weapon_runtime_states[weapon_instance_id]
		var weapon_item := inventory.get_item(weapon_instance_id)
		var weapon_definition := ContentDB.get_weapon(weapon_item.definition_id, false) if weapon_item else null
		if (
			not weapon_state
			or not weapon_state.validate()
			or not weapon_definition
			or weapon_state.weapon_definition_id != weapon_definition.id
			or weapon_state.ammo_definition_id != weapon_definition.get_runtime_ammo_definition_id()
			or weapon_state.magazine_capacity != weapon_definition.magazine_capacity
		):
			return false
	return true


func _initial_carried_ids_are_valid() -> bool:
	var seen_ids: Dictionary = {}
	for instance_id in _initial_carried_instance_ids:
		if instance_id.is_empty() or seen_ids.has(instance_id):
			return false
		seen_ids[instance_id] = true
	return true


func _initial_carried_items_are_present() -> bool:
	for instance_id in _initial_carried_instance_ids:
		if not inventory.contains(instance_id):
			return false
	return true


func _finish(final_status: Status) -> bool:
	if status != Status.ACTIVE:
		return false
	if final_status == Status.COMPLETED and not finalize_runtime_ammo():
		return false
	if final_status in [Status.FAILED, Status.ABANDONED]:
		mission_completed = false
	status = final_status
	return true


static func _generate_session_id() -> String:
	return Crypto.new().generate_random_bytes(16).hex_encode()
