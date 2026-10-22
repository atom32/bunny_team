extends "res://tests/streets_combat_run.gd"
## Real movement, interactions, AI, damage and ammunition. One fixed route, not a human first-hour test.
var interrupted := 0

func press_interact() -> void:
	for pressed in [true,false]:
		var event:=InputEventAction.new();event.action="interact";event.pressed=pressed
		Input.parse_input_event(event)
		await get_tree().process_frame

func shot(name: String) -> void:
	if DisplayServer.get_name()=="headless" or "--capture" not in OS.get_cmdline_user_args(): return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_environment("BUNNY_EVIDENCE").path_join(name+".png"))

func _run() -> void:
	GameLanguage.set_language("zh_CN",false)
	var profile:=ProfileRuntime.new_profile()
	if DeploymentPlan.deploy(profile,&"street_district",&"streets_recon","user://records_isolation_run.json").error!=OK:
		push_error("Finite route deployment failed");get_tree().quit(1);return
	SortieRuntime.layout_seed=907
	battle=load("res://scenes/battle/battle.tscn").instantiate();battle.loot_seed=907;battle.result_transition_enabled=false;add_child(battle)
	battle.player.weapon_fired.connect(func(_recoil: float):fired+=1)
	var starts:={}
	for enemy in battle.enemy_container.get_children(): starts[enemy]=enemy.global_position
	var area: Node3D=battle.area_root
	var box: RecordsIsolator=area.get_node("RecordsIsolator")
	var terminal: RecordsTerminal=area.get_node("StreetTerminal")
	var alarm: RecordsAlarm=terminal.get_node("RecordsAlarm")
	for _tick in 45: await get_tree().physics_frame
	print("RECORDS_ISOLATION_RUN seed=",SortieRuntime.layout_seed," task=",area.task_index," spawn=",area.selected_spawn," box=",box.position)
	if not await _walk(box.global_position+Vector3(0,0,-1.2)): failures.append("Cannot survive/reach physical bell box")
	if failures.is_empty():
		for action in ACTIONS:Input.action_release(action)
		await get_tree().physics_frame
		await press_interact()
		if alarm.isolation_remaining<=0:failures.append("Generated interaction did not start cabinet work")
		for tick in 1800:
			await get_tree().physics_frame
			if battle.player.is_dead or alarm.phase==RecordsAlarm.Phase.ISOLATED:break
			_controls(battle.player.global_position)
			if alarm.isolation_remaining==0:
				interrupted+=1;await press_interact()
		if alarm.phase!=RecordsAlarm.Phase.ISOLATED:failures.append("Could not finish isolation under real combat")
		await shot("isolation_run_box")
	if failures.is_empty() and not await _walk(terminal.global_position):failures.append("Cannot reach powered records terminal")
	if failures.is_empty():
		for action in ACTIONS:Input.action_release(action)
		await get_tree().physics_frame
		await press_interact();await press_interact()
		if not terminal.urgent:failures.append("Generated second interaction did not choose fast uplink")
		for tick in 1800:
			await get_tree().physics_frame
			if battle.player.is_dead or battle.session.get_objective_state(&"streets_terminal").status==ObjectiveState.Status.COMPLETED:break
			_controls(battle.player.global_position)
			if terminal.remaining==0:
				interrupted+=1;await press_interact();await press_interact()
		if battle.session.get_objective_state(&"streets_terminal").status!=ObjectiveState.Status.COMPLETED:failures.append("Real records did not finish")
		if alarm.phase!=RecordsAlarm.Phase.ISOLATED:failures.append("Uplink incorrectly rang the disconnected bell")
		await shot("isolation_run_records")
	var targets: Array[Node3D]=[area.get_node("StreetSurvey")]
	for exit in area.find_children("*","ExtractionPoint",true,false):
		if exit.can_extract(battle.session):targets.append(exit);break
	for target in targets:
		if not failures.is_empty():break
		if not await _walk(target.global_position):failures.append("Cannot survive/reach "+target.name);break
		for action in ACTIONS:Input.action_release(action)
		await get_tree().physics_frame
		await press_interact()
	if not battle.session.is_mission_completed() or battle.session.status!=SortieSession.Status.COMPLETED:failures.append("Survey and actual extraction incomplete")
	var moved:=0
	for enemy in starts:
		if not is_instance_valid(enemy) or enemy.global_position.distance_to(starts[enemy])>1:moved+=1
	if fired<=0 or moved<=0 or battle.session.enemies_defeated<=0:failures.append("No verified live combat in route")
	if failures.is_empty() and SortieRuntime.finalize_sortie("user://records_isolation_run.json")!=OK:failures.append("Real extraction settlement failed")
	print("RECORDS_ISOLATION_RUN hp=",battle.player.health," shots=",fired," kills=",battle.session.enemies_defeated," moved=",moved," interruptions=",interrupted," failures=",failures)
	for action in ACTIONS:Input.action_release(action)
	battle.free();SortieRuntime.clear_session();AudioDirector.shutdown_for_test()
	print("RECORDS_ISOLATION_RUN: ","PASS" if failures.is_empty() else "FAIL")
	get_tree().quit(0 if failures.is_empty() else 1)
