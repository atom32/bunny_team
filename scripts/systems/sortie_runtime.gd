extends Node

var _current_session: SortieSession
var _pending_outcome: SortieOutcome
var last_error := ""
var checkpoint_path := ""
var layout_seed := 0
var resumed_world: Dictionary = {}
var _battle: WeakRef
var _autosave_remaining := 2.0
var checkpoint_error := OK
var _save_queued := false


func start_sortie(request: SortieRequest, profile: ProfileState) -> SortieSession:
	last_error = ""
	if profile and not profile.sortie_checkpoint.is_empty():
		last_error = "Resume the suspended sortie before deploying again."
		return null
	if _current_session:
		last_error = "A sortie is already open. Return to base before deploying again."
		return null
	if not profile or not profile.validate() or not request or not request.validate(profile.inventory):
		last_error = "Loadout or mission data is invalid. Re-select equipment and retry."
		return null
	var weight := 0.0
	for id in request.get_initial_carried_instance_ids():
		var item := profile.inventory.get_item(id)
		weight += item.total_weight()
	var carried_capacity := profile.get_carried_capacity(request.loadout)
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
	candidate.sortie_checkpoint = {}
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
	profile.replace_with(candidate)
	clear_session()
	return OK


func clear_session() -> void:
	_current_session = null
	_pending_outcome = null
	checkpoint_path = ""
	layout_seed = 0
	resumed_world = {}
	_battle = null
	checkpoint_error = OK
	_save_queued = false


func begin_persistence(path := SaveService.DEFAULT_SAVE_PATH, deployment: ProfileState = null) -> Error:
	if not _current_session or ProfileRuntime.recovery_required: return ERR_INVALID_DATA
	checkpoint_path = path
	layout_seed = randi_range(1, 2147483647)
	return save_checkpoint(deployment)


func attach_battle(battle: Node) -> bool:
	if not resumed_world.is_empty():
		if not SortieCheckpoint.restore_world(resumed_world, battle):
			last_error = "The suspended world is incompatible or incomplete. The saved file has not been changed."
			return false
		resumed_world = {}
	_battle = weakref(battle)
	_autosave_remaining = 2.0
	if not checkpoint_path.is_empty() and save_checkpoint() != OK:
		FlowMenu.show_error("Could not save the initial world checkpoint. Retry saving before leaving.")
	return true


func freeze_battle() -> void:
	var battle: Node = _battle.get_ref() if _battle else null
	if is_instance_valid(battle): battle.process_mode = Node.PROCESS_MODE_DISABLED


func request_checkpoint() -> void:
	if checkpoint_path.is_empty() or _save_queued: return
	_save_queued = true
	_flush_checkpoint.call_deferred()


func _flush_checkpoint() -> void:
	_save_queued = false
	if checkpoint_path.is_empty(): return
	if save_checkpoint() != OK:
		FlowMenu.show_error("Could not save the sortie checkpoint. Retry saving before leaving.")


func _process(delta: float) -> void:
	if checkpoint_path.is_empty() or not _current_session or not _battle or not _battle.get_ref(): return
	_autosave_remaining -= delta
	if _autosave_remaining > 0: return
	_autosave_remaining = 2.0
	var error := save_checkpoint()
	if error != OK:
		FlowMenu.show_error("Could not save the sortie checkpoint. Play is paused; retry saving before leaving. Error: " + error_string(error))


func save_checkpoint(deployment: ProfileState = null) -> Error:
	if checkpoint_path.is_empty() or not _current_session: return ERR_UNAVAILABLE
	var outcome := {}
	if _current_session.status != SortieSession.Status.ACTIVE:
		var final := get_outcome()
		if not final: return ERR_INVALID_DATA
		outcome = final.to_dict()
	var world := resumed_world.duplicate(true)
	var battle: Node = _battle.get_ref() if _battle else null
	if outcome.is_empty() and is_instance_valid(battle):
		world = SortieCheckpoint.capture_world(battle)
	if not outcome.is_empty(): world = {}
	var candidate := ProfileState.from_dict((deployment if deployment else ProfileRuntime.get_profile()).to_dict())
	var phase := "result" if not outcome.is_empty() else ("deployment" if world.is_empty() else "battle")
	candidate.sortie_checkpoint = {"version": SortieCheckpoint.VERSION, "phase": phase, "seed": layout_seed, "session": SortieCheckpoint.session_data(_current_session), "world": world, "outcome": outcome}
	checkpoint_error = SaveService.save_profile(candidate, checkpoint_path)
	if checkpoint_error == OK:
		# Warehouse object identities stay stable during battle. Only the journal changes.
		if deployment: ProfileRuntime.get_profile().replace_with(candidate)
		else: ProfileRuntime.get_profile().sortie_checkpoint = candidate.sortie_checkpoint
	return checkpoint_error


func resume_saved(path := SaveService.DEFAULT_SAVE_PATH) -> Error:
	if _current_session: return ERR_BUSY
	var saved: Dictionary = ProfileRuntime.get_profile().sortie_checkpoint
	if not SortieCheckpoint.integer(saved.get("version"), 1, SortieCheckpoint.VERSION) or not SortieCheckpoint.integer(saved.get("seed"), 1, 2147483647): return ERR_INVALID_DATA
	for key in ["session", "world", "outcome"]:
		if typeof(saved.get(key)) != TYPE_DICTIONARY: return ERR_INVALID_DATA
	if saved.version >= 2:
		for key in ["slice_context", "exit_observations"]:
			if not saved.session.has(key): return ERR_INVALID_DATA
			if saved.get("phase") == "battle" and not saved.world.has(key): return ERR_INVALID_DATA
			if saved.get("phase") == "result" and not saved.outcome.has(key): return ERR_INVALID_DATA
	if saved.version >= 3:
		for key in ["q02_active", "pharmacy_batch"]:
			if not saved.session.has(key): return ERR_INVALID_DATA
			if saved.get("phase") == "battle" and not saved.world.has(key): return ERR_INVALID_DATA
			if saved.get("phase") == "result" and not saved.outcome.has(key): return ERR_INVALID_DATA
	if saved.version >= 4:
		for key in ["q04_active", "delivery_receipt"]:
			if not saved.session.has(key): return ERR_INVALID_DATA
			if saved.get("phase") == "battle" and not saved.world.has(key): return ERR_INVALID_DATA
			if saved.get("phase") == "result" and not saved.outcome.has(key): return ERR_INVALID_DATA
	var restored := SortieCheckpoint.restore_session(saved.session)
	if not restored: return ERR_INVALID_DATA
	if saved.get("phase") not in ["deployment", "battle", "result"]: return ERR_INVALID_DATA
	if saved.phase == "battle" and not NarrativeSlice.world_matches(saved.world, restored): return ERR_INVALID_DATA
	if restored.status == SortieSession.Status.ACTIVE:
		if saved.phase == "result" or (saved.phase == "battle" and saved.world.is_empty()): return ERR_INVALID_DATA
		if saved.phase == "deployment" and (not saved.world.is_empty() or restored.enemies_defeated != 0 or restored.damage_taken != 0 or restored.threat_level != SortieSession.ThreatLevel.NORMAL): return ERR_INVALID_DATA
	elif saved.phase != "result" or not saved.world.is_empty(): return ERR_INVALID_DATA
	var final: SortieOutcome
	if restored.status != SortieSession.Status.ACTIVE:
		final = SortieOutcome.from_dict(saved.outcome)
		if not final or final.session_id != restored.session_id: return ERR_INVALID_DATA
		# Compare all result fields with the session; retain the already durable outcome ID.
		var expected := SortieOutcome.create_from_session(restored)
		if not expected: return ERR_INVALID_DATA
		expected.outcome_id = final.outcome_id
		# JSON numbers deserialize as floats, including objective summaries.
		if JSON.parse_string(JSON.stringify(expected.to_dict())) != JSON.parse_string(JSON.stringify(final.to_dict())): return ERR_INVALID_DATA
	elif not saved.outcome.is_empty(): return ERR_INVALID_DATA
	for id in restored.get_initial_carried_instance_ids():
		if not ProfileRuntime.get_profile().inventory.contains(id): return ERR_INVALID_DATA
	_current_session = restored
	_pending_outcome = final
	checkpoint_path = path
	layout_seed = int(saved.seed)
	resumed_world = saved.world.duplicate(true)
	return OK
