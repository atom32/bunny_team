extends "res://tests/first_sortie_run.gd"
## Continue a real preceding exported save. No new profile or fabricated flags.
func _ready() -> void:
	get_tree().create_timer(_deadline_seconds(),true).timeout.connect(func(): failures.append("Q01 actual continuation deadline"); _finish())
	_run.call_deferred()

func _deadline_seconds() -> float: return 300.0

func _run() -> void:
	tree=get_tree(); tree.current_scene=null
	evidence["method"]="Actual earned first-sortie/upgrade save; normal BOOT/continue/base/deploy, synthetic controls and callbacks or viewport clicks, not human acceptance"
	var profile := ProfileRuntime.get_profile()
	evidence["profile_before"]=profile.to_dict()
	check(SaveService.save_exists() and not ProfileRuntime.recovery_required and profile.first_mission_completed and profile.ar_damage_upgraded and profile.successful_sorties==1,"load actual completed first-sortie/upgrade profile")
	check(not profile.narrative_slice.settled.Q01 and profile.sortie_checkpoint.is_empty(),"Q01 unearned and no suspended sortie")
	if not failures.is_empty():_finish();return
	tree.change_scene_to_file("res://scenes/presentation/slice/boot.tscn")
	await _frames(10)
	if tree.current_scene.opening: await _click(_button("SKIP OPENING  /  ENTER"))
	await _capture("01_normal_menu")
	await _click(_button("CONTINUE / BASE"))
	if not await _wait_scene("res://scenes/presentation/slice/hideout.tscn"): _finish(); return
	await _click(tree.current_scene.find_child("NavOperations",true,false))
	await _capture("02_q01_brief")
	await _click(tree.current_scene.screen.find_child("RequestDetails",true,false))
	check(tree.current_scene.screen.get_node("ContactPanel").contact_id=="shen_yanshuang","ordinary request-details button opens Shen")
	await _capture("03_shen_request")
	await _click(tree.current_scene.find_child("NavOperations",true,false))
	await _click(_button("CONFIRM DEPLOYMENT"))
	if not await _wait_scene("res://scenes/battle/battle.tscn"): _finish(); return
	await tree.create_timer(3.0).timeout
	battle=tree.current_scene
	battle.player.weapon_fired.connect(func(_recoil:float): shots+=1)
	check(battle.session.area_id==&"street_district" and battle.session.slice_context.get("quest_id")=="Q01","normal deployment selects real Q01 context")
	var exits: Array[ExtractionPoint]=[]
	var retreat: ExtractionPoint
	for i in 4:
		var point: ExtractionPoint=battle.area_root.get_node("Exit%d"%i)
		if point.available:
			exits.append(point)
			if point.required_objective_id.is_empty(): retreat=point
	check(exits.size()==2 and retreat!=null,"two assigned exits include an ordinary retreat")
	var map: RID=battle.area_root.get_node("StreetNavigation").get_navigation_map()
	for tick in 120:
		await tree.physics_frame
		if NavigationServer3D.map_get_iteration_id(map)>0: break
	exits.sort_custom(func(a,b): return battle.player.global_position.distance_to(a.global_position)<battle.player.global_position.distance_to(b.global_position))
	for point in exits:
		var plaque: Node3D=point.get_node("ExitPlaque")
		if not await _walk(plaque.global_position,0.5): _finish(); return
		_release(); await _frames()
		check(battle.player.interaction_component._current_target==plaque,"ordinary nearest-target interaction selects plaque")
		await _tap("interact")
		check(String(point.extraction_id) in battle.session.exit_observations,"actual E reads assigned exit conditions")
		check(not profile.narrative_slice.settled.Q01,"field observations remain provisional")
		await _capture("04_plaque_"+String(point.extraction_id))
	if not await _walk(retreat.global_position,0.4): _finish(); return
	_release();await _frames();await _tap("interact")
	check(battle.session.status==SortieSession.Status.COMPLETED,"ordinary E at open retreat ends sortie")
	evidence["shots"]=shots;evidence["health"]=battle.player.health;evidence["kills"]=battle.session.enemies_defeated
	if not await _wait_scene("res://scenes/result/result.tscn"): _finish(); return
	await _capture("05_q01_debrief")
	await _click(tree.current_scene.find_child("ReturnButton",true,false))
	if not await _wait_scene("res://scenes/presentation/slice/hideout.tscn"): _finish(); return
	check(profile.narrative_slice.settled.Q01 and not profile.narrative_slice.settled.Q02 and profile.successful_sorties==2,"normal return durably earns Q01 only")
	await _click(tree.current_scene.find_child("NavOperations",true,false))
	await _click(tree.current_scene.screen.find_child("RequestDetails",true,false))
	check(tree.current_scene.screen.get_node("ContactPanel").contact_id=="tang_kui","next ordinary request-details button opens Tang")
	await _capture("06_tang_next_request")
	evidence["profile_after"]=profile.to_dict()
	_finish()

func _walk(at: Vector3,tolerance := .4) -> bool:
	# The normal Q01 contract now includes a physical north-gate route. Reach
	# its real outside bolt, use normal E, then approach the original plaque.
	if battle.area_root.has_node("CampusExitGate"):
		var gate: CampusExitGate=battle.area_root.get_node("CampusExitGate")
		if not gate.is_open() and at.distance_to(battle.area_root.get_node("Exit2/ExitPlaque").global_position)<.1:
			if not await _walk(gate.to_global(Vector3(0,0,2.4)),.5):return false
			_release();await _frames()
			check(battle.player.interaction_component._current_target==gate.get_node("OutsideLatch"),"normal Q01 route selects physical outside bolt")
			await _tap("interact")
			check(gate.mode==1,"normal Q01 uses actual E to clear north gate quietly")
			if not gate.is_open():return false
	var map: RID=battle.area_root.get_node("StreetNavigation").get_navigation_map()
	var path:=NavigationServer3D.map_get_path(map,battle.player.global_position,at,true)
	if path.is_empty(): failures.append("No normal navigation path to "+str(at)); return false
	for point in path:
		var reached:=false
		for tick in 1200:
			await tree.physics_frame
			if battle.player.is_dead: failures.append("Died walking");return false
			var gap: Vector3=point-battle.player.global_position;gap.y=0
			if gap.length()<0.5: reached=true;break
			_controls(point)
		if not reached:
			var contacts:=[]
			for i in battle.player.get_slide_collision_count():
				var hit=battle.player.get_slide_collision(i)
				contacts.append(str(hit.get_collider()))
			evidence["walking_failure"]={"player":str(battle.player.global_position),"waypoint":str(point),"target":str(at),"paused":tree.paused,"flow_mode":FlowMenu.mode,"contacts":contacts}
			failures.append("Actual navigation walking stuck");return false
	_release()
	var final_gap: Vector3=at-battle.player.global_position;final_gap.y=0
	if final_gap.length()>maxf(tolerance,0.8):
		evidence["navigation_clip"]={"player":str(battle.player.global_position),"target":str(at),"distance":final_gap.length(),"requested_distance":tolerance,"nearest_interaction":str(battle.player.interaction_component._current_target)}
		failures.append("Navigation clipped before real destination "+str(at));return false
	return true

func _finish() -> void:
	_release()
	evidence["checks"]=checks;evidence["failures"]=failures
	if not is_instance_valid(tree): tree=get_tree()
	evidence["paused"]=tree.paused;evidence["flow_mode"]=FlowMenu.mode
	if out.is_empty():out=OS.get_user_data_dir()
	var f:=FileAccess.open(out.path_join("campus_entry.json"),FileAccess.WRITE);f.store_string(JSON.stringify(evidence,"\t"));f.close()
	AudioDirector.shutdown_for_test()
	print("CAMPUS_ENTRY_RUN: %s (%d checks) failures=%s"%["PASS" if failures.is_empty() else "FAIL",checks,failures])
	tree.quit(0 if failures.is_empty() else 1)
