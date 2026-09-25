extends Node

const INTERACTABLE_SCENE := preload("res://scenes/world/objective_interactable.tscn")
const REACH_ZONE_SCENE := preload("res://scenes/world/objective_reach_zone.tscn")

var failures: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	_test_authored_battle_objects()
	await _test_active_world_objectives()
	_test_invalid_objective()
	_test_terminal_status_lockout()
	SortieRuntime.clear_session()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(0.2).timeout
	if failures.is_empty():
		print("OBJECTIVE_WORLD_TEST: PASS")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("OBJECTIVE_WORLD_TEST: %s" % failure)
		print("OBJECTIVE_WORLD_TEST: FAIL (%d)" % failures.size())
		get_tree().quit(1)


func _test_authored_battle_objects() -> void:
	var area := AreaLoader.instantiate_area(ContentDB.get_area_definition(&"prototype_arena"))
	var terminal := area.find_child("PrototypeTerminal", true, false) as ObjectiveInteractable
	var reach_zone := area.find_child("PrototypeSurveyZone", true, false) as ObjectiveReachZone
	check(terminal != null and terminal.objective_id == &"interact_prototype_terminal", "Battle scene authors a terminal with a stable objective ID")
	check(reach_zone != null and reach_zone.objective_id == &"reach_prototype_zone", "Battle scene authors a reach zone with a stable objective ID")
	check(reach_zone != null and reach_zone.find_child("CollisionShape3D", true, false) != null, "authored reach zone owns an Area3D collision shape")
	area.free()


func _test_active_world_objectives() -> void:
	var profile := ProfileState.create_new()
	var profile_before := profile.to_dict()
	var mission := ContentDB.get_mission(&"prototype_combat")
	var mission_before := _mission_snapshot(mission)
	var session := _create_session(profile)
	if not session:
		return

	var terminal := INTERACTABLE_SCENE.instantiate() as ObjectiveInteractable
	terminal.objective_id = &"interact_prototype_terminal"
	add_child(terminal)
	await get_tree().process_frame
	var interaction_result := terminal.interact(null, session)
	check(bool(interaction_result.get("success", false)), "authored interactable advances its matching active objective")
	var interact_state := session.get_objective_state(&"interact_prototype_terminal")
	check(interact_state != null and interact_state.progress == 1 and interact_state.status == ObjectiveState.Status.COMPLETED, "INTERACT objective completes at one of one")
	check(not bool(terminal.interact(null, session).get("success", false)), "completed interactable cannot advance again")
	check(session.get_objective_state(&"interact_prototype_terminal").progress == 1, "repeated interaction remains one of one")

	var reach_zone := REACH_ZONE_SCENE.instantiate() as ObjectiveReachZone
	reach_zone.objective_id = &"reach_prototype_zone"
	reach_zone.setup(session)
	add_child(reach_zone)
	var player_actor := Node3D.new()
	player_actor.add_to_group("player")
	add_child(player_actor)
	await get_tree().process_frame
	check(reach_zone.try_reach(player_actor), "authored Area3D zone advances its matching active objective")
	var reach_state := session.get_objective_state(&"reach_prototype_zone")
	check(reach_state != null and reach_state.progress == 1 and reach_state.status == ObjectiveState.Status.COMPLETED, "REACH objective completes at one of one")
	check(not reach_zone.try_reach(player_actor), "completed reach zone cannot advance again")
	check(session.get_objective_state(&"reach_prototype_zone").progress == 1, "repeated reach remains one of one")
	check(not session.is_mission_completed(), "completed INTERACT and REACH do not hide an incomplete ELIMINATE objective")

	for _defeat in 3:
		check(session.record_enemy_defeat(), "enemy defeat still advances ELIMINATE alongside world objectives")
	check(session.is_mission_completed(), "all three required objective types complete the mission")
	check(profile.to_dict() == profile_before, "world objective progress never mutates ProfileState")
	check(_mission_snapshot(mission) == mission_before, "world objective progress never mutates MissionDefinition")

	terminal.queue_free()
	reach_zone.queue_free()
	player_actor.queue_free()
	await get_tree().process_frame


func _test_invalid_objective() -> void:
	var profile := ProfileState.create_new()
	var session := _create_session(profile)
	if not session:
		return
	var before := session.get_objective_summary()
	check(not session.record_objective_interaction(&"does_not_exist"), "unknown interaction objective ID is rejected")
	check(not session.record_objective_reached(&"does_not_exist"), "unknown reach objective ID is rejected")
	check(not session.record_objective_interaction(&"reach_prototype_zone"), "objective ID with the wrong type is rejected")
	check(session.get_objective_summary() == before, "invalid objective calls leave every ObjectiveState unchanged")


func _test_terminal_status_lockout() -> void:
	for final_status in [SortieSession.Status.FAILED, SortieSession.Status.COMPLETED, SortieSession.Status.ABANDONED]:
		var profile := ProfileState.create_new()
		var session := _create_session(profile)
		if not session:
			continue
		match final_status:
			SortieSession.Status.FAILED:
				check(session.fail(), "status fixture enters FAILED")
			SortieSession.Status.COMPLETED:
				check(session.complete_extraction(), "status fixture enters COMPLETED")
			SortieSession.Status.ABANDONED:
				check(session.abandon(), "status fixture enters ABANDONED")
		var before := session.get_objective_summary()
		check(not session.record_objective_interaction(&"interact_prototype_terminal"), "terminal Sortie rejects interaction progress")
		check(not session.record_objective_reached(&"reach_prototype_zone"), "terminal Sortie rejects reach progress")
		check(session.get_objective_summary() == before, "terminal Sortie objective state remains unchanged")


func _create_session(profile: ProfileState) -> SortieSession:
	var session := SortieSession.create_from_profile(profile.create_sortie_request(), profile)
	check(session != null and session.activate(), "objective world fixture creates an active sortie")
	return session


func _mission_snapshot(mission: MissionDefinition) -> Array[Dictionary]:
	var snapshot: Array[Dictionary] = []
	for objective in mission.objective_definitions:
		snapshot.append({
			"objective_id": objective.objective_id,
			"objective_type": objective.objective_type,
			"target": objective.target,
			"target_id": objective.target_id,
			"required": objective.required,
		})
	return snapshot


func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
