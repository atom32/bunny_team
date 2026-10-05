extends Node3D
var checks:=0
var failures:Array[String]=[]
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures.append(message)
func _ready()->void:
	await get_tree().process_frame
	var p:=ProfileRuntime.new_profile()
	var result:=DeploymentPlan.deploy(p,&"street_district",&"streets_recon","user://exit_choice.json",false)
	var session:SortieSession=result.session
	var battle=load("res://scenes/battle/battle.tscn").instantiate()
	battle.loot_seed=907;add_child(battle);battle.result_transition_enabled=false
	battle.player.set_physics_process(false)
	for enemy in battle.enemy_container.get_children():enemy.set_physics_process(false)
	await get_tree().physics_frame
	var area=battle.area_root
	var rng:=RandomNumberGenerator.new();rng.seed=1207
	var free_exit:ExtractionPoint
	var locked:ExtractionPoint
	for index in 6:
		var spawn=area.get_node("StreetSpawn%d"%index)
		area.configure_sortie_layout(spawn,rng)
		var open_count:=0
		var locked_count:=0
		var disabled:=0
		for exit in area.find_children("*","ExtractionPoint",true,false):
			if not exit.available:
				disabled+=1
				check(not exit.can_extract(session),"unassigned exit stays unavailable")
			elif exit.can_extract(session):open_count+=1;free_exit=exit
			else:locked_count+=1;locked=exit
		check(open_count==1 and locked_count==1 and disabled==2,"every spawn has one guaranteed retreat and one conditional assigned route")
		check(free_exit.position.distance_to(spawn.position)>=locked.position.distance_to(spawn.position),"free route is no nearer than records route")
	check(not locked.interact(battle.player,session).success and session.status==SortieSession.Status.ACTIVE,"locked exit rejects actual interaction without settling sortie")
	check(locked.get_interaction_prompt(battle.player,session)=="LOCKED / RECOVER RECORDS FIRST","nearby prompt states requirement instead of hiding the interaction")
	var before:=SortieCheckpoint.session_data(session)
	var clone:=SortieCheckpoint.restore_session(before)
	check(not locked.can_extract(clone) and free_exit.can_extract(clone),"session restoration preserves locked/open distinction")
	# Exercise early retreat on a separate presentation node: emitting a clone's
	# outcome through the live Battle signal would spuriously show extraction UI.
	var retreat:=ExtractionPoint.new()
	retreat.available=free_exit.available
	retreat.required_objective_id=free_exit.required_objective_id
	check(retreat.extract(clone) and not clone.mission_completed,"retreat succeeds without pretending mission was completed")
	retreat.free()
	if "--capture" in OS.get_cmdline_user_args():await capture(area,"locked")
	var terminal: RecordsTerminal = area.get_node("StreetTerminal")
	battle.player.global_position = terminal.global_position + Vector3(0,0,1)
	check(terminal.interact(battle.player,session).success,"actual assigned records terminal starts work")
	check(not locked.can_extract(session),"starting download alone does not unlock records exit")
	terminal.tick(8)
	check(not session.mission_completed and locked.can_extract(session),"records alone unlock route; opposite survey is not secretly required")
	clone=SortieCheckpoint.restore_session(SortieCheckpoint.session_data(session))
	check(locked.can_extract(clone),"completed records survive restore and unlock same route")
	if "--capture" in OS.get_cmdline_user_args():await capture(area,"unlocked")
	check(locked.extract(session),"records route completes real extraction")
	check(not locked.extract(session),"second extraction cannot settle again")
	check(SortieRuntime.finalize_sortie("user://exit_choice.json")==OK,"normal result settlement retains existing outcome pipeline")
	check(not ProfileRuntime.get_profile().inventory.get_items().is_empty(),"successful early extraction returns carried equipment")
	battle.free();SortieRuntime.clear_session();AudioDirector.shutdown_for_test()
	await get_tree().create_timer(.4).timeout
	for f in failures:push_error("EXIT_CHOICES: "+f)
	print("EXIT_CHOICE_TEST: %s (%d checks)"%["PASS" if failures.is_empty() else "FAIL",checks])
	get_tree().quit(0 if failures.is_empty() else 1)
func capture(area:Node3D,label:String)->void:
	area.route_map.expanded=true
	for locale in ["en","zh_CN"]:
		GameLanguage.set_language(locale,false)
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(OS.get_environment("BUNNY_EVIDENCE").path_join(label+"_"+locale+".png"))
