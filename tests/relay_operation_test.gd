extends Node3D
const PATH := "user://relay_operation.json"
var checks := 0
var failures: Array[String] = []
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
func _ready() -> void:
	await get_tree().process_frame
	if "--read" in OS.get_cmdline_user_args():
		await read_saved();return
	var profile := ProfileRuntime.new_profile()
	profile.first_mission_completed = true
	profile.campaign.stage = 4
	var result := DeploymentPlan.deploy(profile,&"street_district",&"streets_relay",PATH)
	check(result.error == OK,"new operation deploys via existing durable deployment")
	SortieRuntime.layout_seed = 907
	var battle = load("res://scenes/battle/battle.tscn").instantiate()
	add_child(battle);battle.result_transition_enabled = false
	battle.player.set_physics_process(false)
	for enemy in battle.enemy_container.get_children(): enemy.set_physics_process(false)
	var a: RelayStation = battle.area_root.get_node("RelayOffice")
	var b: RelayStation = battle.area_root.get_node("RelayRepair")
	a.set_process(false);b.set_process(false)
	await get_tree().physics_frame
	var nav: RID = battle.area_root.get_node("StreetNavigation").get_navigation_map()
	for tick in 60:
		await get_tree().create_timer(.05).timeout
		NavigationServer3D.map_force_update(nav)
		if not NavigationServer3D.map_get_path(nav,battle.player.position,a.position,true).is_empty(): break
	for spawn in battle.area_root.SPAWNS:
		for relay in [a,b]:
			var path := NavigationServer3D.map_get_path(nav,spawn,relay.position,true)
			check(not path.is_empty() and path[-1].distance_to(relay.position)<1.5,"all six spawns reach both repair stations through existing navigation")
	check(battle.session.mission_id == &"streets_relay","session owns selected mission")
	check(not battle.area_root.get_node("StreetSurvey").visible,"irrelevant survey presentation hidden")
	check(not a.interact(battle.player,battle.session).success,"cannot start field work remotely")
	battle.player.global_position = a.global_position + Vector3(0,0,1)
	check(a.interact(battle.player,battle.session).success and a.remaining == 12,"nearby repair starts timed work")
	check(not a.interact(battle.player,battle.session).success,"repeat interaction cannot reset active timer")
	a.tick(3)
	get_tree().paused = true;a.tick(10)
	check(a.remaining == 9,"pause preserves repair remaining time")
	get_tree().paused = false
	battle.player.global_position += Vector3(4,0,0);a.tick(.1)
	check(a.remaining == 0 and not battle.session.mission_completed,"leaving cancels, never completes")
	battle.player.global_position = a.global_position + Vector3(0,0,1)
	a.interact(battle.player,battle.session)
	battle.player.take_damage(10)
	a.tick(.1)
	check(a.remaining == 0,"actual damage interrupts field work")
	a.interact(battle.player,battle.session)
	var before_damage: int = battle.session.damage_taken
	battle.player.take_damage(.1)
	check(a.remaining == 0 and battle.session.damage_taken == before_damage,"fractional damage interrupts without relying on rounded mission counter")
	a.interact(battle.player,battle.session);a.tick(4.5)
	check(SortieRuntime.save_checkpoint() == OK,"partial repair durably saves")
	SortieRuntime.checkpoint_path = "" # Preserve partial work for separate reader.
	var saved := SortieCheckpoint.capture_world(battle)
	check(SortieCheckpoint.validate_world(saved,battle),"complete world accepts repair state")
	var bad := saved.duplicate(true);bad.nodes.RelayOffice.remaining = 13.0
	check(not SortieCheckpoint.restore_world(bad,battle) and a.remaining == 7.5,"invalid duration rejects without mutation")
	a.tick(1)
	check(SortieCheckpoint.restore_world(saved,battle) and a.remaining == 7.5,"world restore binds actor/session and resumes exact remaining time")
	a.tick(7.5)
	check(battle.session.get_objective_state(&"relay_office").status == ObjectiveState.Status.COMPLETED,"first relay finishes through objective API")
	check(not battle.session.mission_completed,"one station is not a completed operation")
	check(not a.interact(battle.player,battle.session).success,"completed station cannot farm completion")
	battle.player.global_position = b.global_position + Vector3(0,0,1)
	check(b.interact(battle.player,battle.session).success,"second station accepts independent work")
	b.tick(12)
	check(battle.session.mission_completed,"two relays complete operation without optional records")
	check(battle.session.get_objective_state(&"streets_terminal").status != ObjectiveState.Status.COMPLETED,"completion does not fabricate recovered records")
	var exits: Array[Node] = battle.area_root.find_children("*","ExtractionPoint",true,false)
	var retreat: ExtractionPoint
	for exit in exits:
		if exit.can_extract(battle.session): retreat = exit
	check(retreat != null,"unconditional retreat remains available")
	check(retreat.extract(battle.session),"completed operation uses existing extraction")
	check(SortieRuntime.finalize_sortie("user://relay_settled.json") == OK,"normal result settles operation")
	check(profile.campaign.progress == 1,"successful repair contributes once to final base contract")
	var settled := profile.to_dict()
	check(SortieRuntime.finalize_sortie("user://relay_settled.json") == OK and profile.to_dict() == settled,"idempotent repeat cannot duplicate progress, credits or items")
	battle.free();await finish()

func read_saved() -> void:
	var profile := SaveService.load_profile(PATH,false)
	check(profile != null,"second process loads repair checkpoint")
	if not profile: await finish();return
	ProfileRuntime._profile = profile
	check(SortieRuntime.resume_saved(PATH) == OK,"separate process resumes relay mission")
	var battle = load("res://scenes/battle/battle.tscn").instantiate()
	add_child(battle);battle.result_transition_enabled = false
	battle.player.set_physics_process(false)
	for enemy in battle.enemy_container.get_children(): enemy.set_physics_process(false)
	var a: RelayStation = battle.area_root.get_node("RelayOffice")
	a.set_process(false)
	check(a.remaining == 7.5 and a.actor == battle.player and a.session == battle.session,"timer and actual actor/session binding restore")
	a.tick(7.5)
	check(battle.session.get_objective_state(&"relay_office").status == ObjectiveState.Status.COMPLETED,"resumed field work completes exactly once")
	check(not battle.session.mission_completed,"other station remains required after restart")
	battle.free();await finish()

func finish() -> void:
	SortieRuntime.clear_session();AudioDirector.shutdown_for_test()
	await get_tree().create_timer(.4).timeout
	for failure in failures: push_error("RELAY_OPERATION: "+failure)
	print("RELAY_OPERATION_TEST: %s (%d checks)" % ["PASS" if failures.is_empty() else "FAIL",checks])
	get_tree().quit(0 if failures.is_empty() else 1)
