extends Node
const PATH := "user://q01_slice_test.json"
var checks := 0
var failures: Array[String] = []
var battle: Node3D
var session: SortieSession

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		print("CHECK FAILED: " + message)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	_schema()
	await _start()
	check(battle.hud.slice_label.text.contains("未完成"), "initial Q01 status")
	var exits := _assigned()
	var objectives := session.get_objective_summary()
	battle.area_root.route_map.expanded = true
	check(session.exit_observations.is_empty(), "opening map does not inspect plaques")
	var plaque: Node3D = exits[0].get_node("ExitPlaque")
	battle.player.global_position = plaque.global_position + Vector3(10,0,0)
	check(not plaque.interact(battle.player, session).success, "remote plaque interaction rejected")
	_observe(exits[0])
	check(session.exit_observations.size() == 1 and NarrativeSlice.status_text(ProfileRuntime.get_profile(), session).contains("一个"), "one-exit status")
	check(session.get_objective_summary() == objectives, "observations never mutate mission objectives")
	check(SortieRuntime.save_checkpoint() == OK, "A save suspended sortie")
	var durable := ProfileRuntime.get_profile().sortie_checkpoint.duplicate(true)
	var malformed_world: Dictionary = durable.world.duplicate(true)
	malformed_world.nodes = []
	check(not SortieCheckpoint.validate_world(malformed_world, battle), "G malformed world nodes rejected without bypassing fact checks")
	var bad := durable.duplicate(true)
	bad.world.exit_observations = []
	_reject_checkpoint(bad, "G world/session fact mismatch rejected before publication")
	bad = durable.duplicate(true)
	bad.session.erase("exit_observations")
	_reject_checkpoint(bad, "G new checkpoint cannot omit session facts")
	ProfileRuntime.get_profile().sortie_checkpoint = durable
	await _reload_battle()
	check(session.exit_observations.size() == 1, "A observation survives actual save/load/resume/world restore")
	check(not ProfileRuntime.get_profile().narrative_slice.settled.Q01, "A checkpoint does not settle task")
	check(session.fail(), "B death ends session")
	check(SortieRuntime.finalize_sortie(PATH) == OK and not ProfileRuntime.get_profile().narrative_slice.settled.Q01, "B death does not persist facts")
	check(ProfileRuntime.get_profile().narrative_slice.q01_exits.is_empty(), "B death leaves no permanent partial observation")
	await _start()
	exits = _assigned()
	_observe(exits[0])
	check(session.abandon(), "B abandonment ends session")
	check(SortieRuntime.finalize_sortie(PATH) == OK and not ProfileRuntime.get_profile().narrative_slice.settled.Q01, "B abandonment does not persist facts")
	await _start()
	exits = _assigned()
	_observe(exits[0])
	# A successful one-exit sortie must not combine with a later sortie.
	var retreat := _retreat(exits)
	check(retreat.extract(session), "successful partial observation extraction")
	check(SortieRuntime.finalize_sortie(PATH) == OK and ProfileRuntime.get_profile().narrative_slice.q01_exits.is_empty(), "single-exit success does not bank partial Q01 facts")
	await _start()
	exits = _assigned()
	_observe(exits[0])
	_observe(exits[1])
	check(NarrativeSlice.status_text(ProfileRuntime.get_profile(),session).contains("尚未"), "two observations remain provisional before extraction")
	check(not exits[0].get_node("ExitPlaque").interact(battle.player,session).success, "repeat plaque cannot add observations")
	var clone := SortieCheckpoint.restore_session(SortieCheckpoint.session_data(session))
	check(clone != null and clone.exit_observations == session.exit_observations, "two-fact session roundtrip")
	var malformed := SortieCheckpoint.session_data(session)
	malformed.exit_observations = ["streets_exit_0", "streets_exit_0"]
	check(SortieCheckpoint.restore_session(malformed) == null, "G duplicate facts rejected")
	var credits := ProfileRuntime.get_profile().credits
	retreat = _retreat(exits)
	check(retreat.extract(session) and not session.mission_completed, "C actual exit unchanged; mission incomplete can still extract")
	check(SortieRuntime.save_checkpoint() == OK, "result phase durable")
	var outcome := SortieRuntime.get_outcome()
	check(outcome.exit_observations == session.exit_observations and outcome.get_objective_summaries() == session.get_objective_summary(), "outcome copies facts separately from objectives")
	var result_saved := ProfileRuntime.get_profile().sortie_checkpoint.duplicate(true)
	bad = result_saved.duplicate(true)
	bad.outcome.exit_observations = [session.exit_observations[0]]
	_reject_checkpoint(bad, "G valid-but-different outcome/session facts rejected")
	bad = result_saved.duplicate(true)
	bad.session.exit_observations = [session.exit_observations[0]]
	_reject_checkpoint(bad, "G altered terminal session rejected against outcome")
	ProfileRuntime.get_profile().sortie_checkpoint = result_saved
	check(SortieRuntime.resume_saved(PATH) == OK, "strict valid result resume passes")
	check(SortieRuntime.finalize_sortie(PATH) == OK, "C candidate settlement saved")
	var profile := ProfileRuntime.get_profile()
	check(profile.narrative_slice.settled.Q01 and profile.narrative_slice.q01_exits.size() == 2, "C successful sortie persists Q01")
	check(profile.credits == credits + NarrativeSlice.Q01_REWARD, "C Q01 pays exactly once independently of incomplete mission")
	check(NarrativeSlice.status_text(profile).contains("已结算"), "settled status")
	for id in NarrativeSlice.TASK_IDS:
		if id != "Q01": check(not profile.narrative_slice.settled[id], "other task remains unimplemented: " + id)
	var expected := JSON.stringify(profile.to_dict())
	check(SortieRuntime.finalize_sortie(PATH) == OK, "E repeated return is safe")
	check(SortieOutcomeService.commit_outcome(profile,outcome) == OK and JSON.stringify(profile.to_dict()) == expected, "E duplicate outcome leaves wallet/inventory/progress unchanged")
	check(ProfileRuntime.load_profile(PATH) and JSON.stringify(ProfileRuntime.get_profile().to_dict()) == expected, "D settled profile survives disk reload")
	var candidate := ProfileState.from_dict(ProfileRuntime.get_profile().to_dict())
	check(candidate.narrative_slice == ProfileRuntime.get_profile().narrative_slice, "candidate copy retains slice fields")
	candidate.narrative_slice.q01_exits.clear()
	check(ProfileRuntime.get_profile().narrative_slice.q01_exits.size() == 2, "candidate copy does not alias task facts")
	await _cleanup()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(0.4).timeout
	for failure in failures: push_error("Q01: " + failure)
	print("Q01_SLICE_TEST: %s (%d checks)" % ["PASS" if failures.is_empty() else "FAIL", checks])
	get_tree().quit(0 if failures.is_empty() else 1)

func _schema() -> void:
	var old := ProfileState.create_new().to_dict()
	old.erase("narrative_slice")
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"schema_version":4,"profile":old})); file.close()
	var migrated := SaveService.load_profile(PATH,false)
	check(migrated != null and migrated.narrative_slice == NarrativeSlice.initial_state(), "F schema 4 loads with empty fixed task container")
	check(migrated.inventory.to_dict() == ProfileState.from_dict(old).inventory.to_dict() and migrated.campaign == old.campaign, "F migration preserves warehouse and legacy campaign")
	check(SaveService.save_profile(migrated,PATH) == OK and SaveService.load_profile(PATH,false) != null, "F migrated profile saves in new schema")
	file = FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"schema_version":5,"profile":old})); file.close()
	check(SaveService.load_profile(PATH,false) == null, "new schema missing slice rejected")
	var invalid := NarrativeSlice.initial_state()
	invalid.settled.Q02 = true
	check(not NarrativeSlice.valid_state(invalid), "unimplemented task cannot be silently completed")
	check(NarrativeSlice.ENDPOINTS == {"A":"Q04","B":"Q06"}, "fixed independent endpoints")

func _start() -> void:
	await _cleanup()
	var profile := ProfileRuntime.new_profile()
	profile.first_mission_completed = true
	var deployed := DeploymentPlan.deploy(profile,&"street_district",&"streets_recon",PATH)
	check(deployed.error == OK, "production deployment")
	session = SortieRuntime.get_current_session()
	await _make_battle()

func _make_battle() -> void:
	battle = load("res://scenes/battle/battle.tscn").instantiate()
	battle.result_transition_enabled = false
	add_child(battle)
	await get_tree().process_frame
	get_tree().paused = true
	check(session.slice_context.exit_conditions.size() == 2, "context binds only two assigned exits")

func _assigned() -> Array:
	return battle.area_root.find_children("*","ExtractionPoint",true,false).filter(func(exit): return exit.available)

func _retreat(exits: Array) -> ExtractionPoint:
	for exit in exits:
		if exit.required_objective_id.is_empty(): return exit
	return null

func _observe(exit: ExtractionPoint) -> void:
	var plaque: Node3D = exit.get_node("ExitPlaque")
	battle.player.global_position = plaque.global_position
	battle.player.interaction_component._current_target = null
	check(battle.player.interaction_component.interact_with_current().success, "actual nearest plaque interaction: " + String(exit.extraction_id))

func _reject_checkpoint(saved: Dictionary, message: String) -> void:
	SortieRuntime.clear_session()
	ProfileRuntime.get_profile().sortie_checkpoint = saved
	check(SortieRuntime.resume_saved(PATH) == ERR_INVALID_DATA and SortieRuntime.get_current_session() == null, message)

func _reload_battle() -> void:
	battle.free()
	SortieRuntime.clear_session()
	check(ProfileRuntime.load_profile(PATH), "load suspended profile")
	check(SortieRuntime.resume_saved(PATH) == OK, "resume suspended session")
	session = SortieRuntime.get_current_session()
	get_tree().paused = false
	await _make_battle()

func _cleanup() -> void:
	FlowMenu.close()
	get_tree().paused = false
	if is_instance_valid(battle): battle.free()
	SortieRuntime.clear_session()
	await get_tree().process_frame
