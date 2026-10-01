extends Node

var _current_session: SortieSession
var _pending_outcome: SortieOutcome
var last_error := ""


func start_sortie(request: SortieRequest, profile: ProfileState) -> SortieSession:
	last_error = ""
	if _current_session:
		last_error = "A sortie is already open. Return to base before deploying again."
		return null
	if not profile or not profile.validate() or not request or not request.validate(profile.inventory):
		last_error = "Loadout or mission data is invalid. Re-select equipment and retry."
		return null
	var weight := 0.0
	for id in request.get_initial_carried_instance_ids():
		var item := profile.inventory.get_item(id)
		weight += ContentDB.get_item(item.definition_id).weight * item.quantity
	var carried_capacity := ProfileState.DEFAULT_CARRIED_CAPACITY
	if weight > carried_capacity + 0.0001:
		last_error = "Overweight: %.1f / %.0f kg. Reduce equipment or ammunition." % [weight, carried_capacity]
		return null
	var session := SortieSession.create_from_profile(request, profile)
	if not session or not session.activate():
		last_error = "The mission could not start. Your warehouse is unchanged. Return to loadout and retry."
		return null
	_current_session = session
	_pending_outcome = null
	return session


func get_current_session() -> SortieSession:
	return _current_session


func get_outcome() -> SortieOutcome:
	if not _pending_outcome and _current_session:
		_pending_outcome = SortieOutcomeService.create_outcome(_current_session)
	return _pending_outcome


func finalize_sortie(path: String = SaveService.DEFAULT_SAVE_PATH, persist := true) -> Error:
	if not _current_session:
		return OK # Retrying navigation after a successful commit is safe.
	var outcome := get_outcome()
	if not outcome:
		return ERR_INVALID_DATA
	var profile := ProfileRuntime.get_profile()
	var candidate := ProfileState.from_dict(profile.to_dict())
	var error := SortieOutcomeService.commit_outcome(candidate, outcome)
	if error != OK:
		return error
	if outcome.mission_id == &"first_mission" and outcome.result_type == SortieOutcome.ResultType.COMPLETED and outcome.mission_completed:
		candidate.first_mission_completed = true
	if persist:
		error = SaveService.save_profile(candidate, path)
		if error != OK:
			return error
	# Publish only after durable save (or an explicit in-memory recovery choice).
	profile.inventory = candidate.inventory
	profile.loadout = candidate.loadout
	profile.first_mission_completed = candidate.first_mission_completed
	clear_session()
	return OK


func clear_session() -> void:
	_current_session = null
	_pending_outcome = null
