extends "res://tools/maintenance_run.gd"
## Real earned rescue profile -> water -> checkpoint -> core -> ending -> free play.
## Controller movement/fire and ordinary UI; no victory flags, teleport or free ammo.
var route_results: Array=[]

func _ready() -> void:
	get_tree().create_timer(1200,true).timeout.connect(func():check(false,"full story route deadline; no forced focus recovery");finish())
	_run.call_deferred()

func controls(destination: Vector3) -> void:
	super.controls(destination)
	var van:=battle.area_root.get_node_or_null("Van") as BlockadeVan
	if not van or van.destroyed or van.phase!=BlockadeVan.Phase.VENT:return
	for enemy in battle.enemy_container.get_children():
		if enemy is EnemyController and not enemy.is_dead and battle.player_visibility.can_see_enemy(enemy) and enemy.global_position.distance_to(battle.player.global_position)<9:return
	var query:=PhysicsRayQueryParameters3D.create(battle.player.global_position+Vector3.UP*1.25,van.global_position+Vector3.UP*1.25,6);query.exclude=[battle.player.get_rid()]
	var hit: Dictionary=battle.player.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or hit.collider!=van:return
	for action in ["aim_left","aim_right","aim_up","aim_down"]:Input.action_release(action)
	var aim: Vector3=battle.player.global_position.direction_to(van.global_position)
	_axis("aim_left","aim_right",aim.x);_axis("aim_up","aim_down",aim.z);Input.action_press("fire")

func walk(target: Vector3,_escort:=false) -> bool:
	var regions: Array[Node]=battle.area_root.find_children("*","NavigationRegion3D",true,false)
	var map: RID=regions[0].get_navigation_map()
	var path:=PackedVector3Array()
	# Async navigation rebuilds are not guaranteed to finish in two frames,
	# especially in a cold headless run. Wait for a genuinely reachable endpoint.
	for tick in 600:
		await tree.physics_frame
		if NavigationServer3D.map_get_iteration_id(map)==0:continue
		path=NavigationServer3D.map_get_path(map,battle.player.global_position,target,true)
		if not path.is_empty() and path[-1].distance_to(target)<=2.5:break
	if path.is_empty() or path[-1].distance_to(target)>2.5:check(false,"unreachable story route target: "+str(target)+" path="+str(path));return false
	for waypoint in path:
		var reached:=false
		for tick in 1200:
			await tree.physics_frame
			if battle.player.is_dead:return false
			var gap: Vector3=waypoint-battle.player.global_position;gap.y=0
			if gap.length()<.45:reached=true;break
			controls(waypoint)
		if not reached:
			var contacts:=[]
			for i in battle.player.get_slide_collision_count():
				var hit:KinematicCollision3D=battle.player.get_slide_collision(i)
				contacts.append({"collider":str(hit.get_collider().get_path()),"normal":str(hit.get_normal())})
			var nearby:=[]
			for enemy in battle.enemy_container.get_children():
				if enemy is EnemyController and enemy.global_position.distance_to(battle.player.global_position)<4:
					nearby.append({"node":str(enemy.get_path()),"position":str(enemy.global_position),"dead":enemy.is_dead})
			evidence["story_route_failure"]={"paused":tree.paused,"flow_mode":FlowMenu.mode,"focused":DisplayServer.window_is_focused() if DisplayServer.get_name()!="headless" else true,"player_physics":battle.player.is_physics_processing(),"position":str(battle.player.global_position),"velocity":str(battle.player.velocity),"waypoint":str(waypoint),"target":str(target),"path":str(path),"nav_iteration":NavigationServer3D.map_get_iteration_id(map),"contacts":contacts,"nearby_enemies":nearby}
			print("STORY_ROUTE_FAILURE: ",JSON.stringify(evidence.story_route_failure))
			await _capture("story_route_stuck")
			check(false,"story route stuck "+str(battle.player.position)+" -> "+str(waypoint));return false
	release();return true

func use_point(point: Node3D) -> Dictionary:
	var component: InteractionComponent=battle.player.interaction_component
	component._physics_process(0)
	if component._current_target!=point:
		check(false,"ordinary interaction selected "+str(component._current_target)+" instead of "+point.name)
		return {"success":false}
	return component.interact_with_current()

func deploy_next(wanted: StringName) -> bool:
	var profile:=ProfileRuntime.get_profile()
	check(FinaleStory.next_mission(profile)==wanted,"actual saved facts select next main operation: "+String(wanted))
	var credits:=profile.credits
	check(SupplyService.transact("buy","ammo.556_standard",120).error==OK and profile.credits<credits,"resupply spends earned credits, never grants ammunition")
	await _click(tree.current_scene.find_child("NavOverview",true,false))
	await _click(_button("CONTINUE MAIN STORY"))
	check(DeploymentPlan.selected_street_mission==wanted,"normal Continue Main Story button selects matching mission")
	await _capture(String(wanted)+"_brief")
	await _click(_button("CONFIRM DEPLOYMENT"))
	if not await _wait_scene("res://scenes/battle/battle.tscn"):check(false,"normal main-story deployment transition");return false
	battle=tree.current_scene;battle.player.weapon_fired.connect(func(_recoil: float):fired+=1)
	for tick in 30:await tree.physics_frame
	return true

func return_home(exit: ExtractionPoint,ending:=false) -> bool:
	release()
	var session: SortieSession=battle.session
	route_results.append({"mission":String(session.mission_id),"shots_total":fired,"kills":session.enemies_defeated,"damage":session.damage_taken,"health":battle.player.health,"blockade":session.blockade.duplicate(true)})
	check(exit.interact(battle.player,session).success,"physical extraction succeeds after actual mission work")
	if not await _wait_scene("res://scenes/result/result.tscn"):check(false,"real result transition");return false
	await _capture(String(session.mission_id)+"_debrief")
	await _click(tree.current_scene.find_child("ReturnButton",true,false))
	var target:="res://scenes/presentation/slice/homecoming_finale.tscn" if ending else "res://scenes/presentation/slice/hideout.tscn"
	if not await _wait_scene(target):check(false,"atomic return reaches ending or ordinary base");return false
	return true

func water() -> bool:
	if not await deploy_next(WaterworksStory.MISSION):return false
	var world: Node3D=battle.area_root
	for name in ["Battery","Decoy","Pump","PublicValve"]:
		var point: WaterworksAction=world.get_node(name)
		if not await walk(point.global_position):return false
		if not use_point(point).success:check(false,"water action rejected: "+name);return false
		if name=="Pump":
			for tick in 1800:
				await tree.physics_frame;controls(battle.player.position)
				if WaterworksStory.done(battle.session,&"water_pump") or battle.player.is_dead:break
				if point.remaining==0:use_point(point)
			check(WaterworksStory.done(battle.session,&"water_pump"),"physical installation survives live AI pressure")
		elif name=="PublicValve":
			await _click(point.choice_layer.find_child("ConfirmDelivery",true,false))
		print("STORY_FINISH water=",name," health=",battle.player.health," shots=",fired)
		release()
	var wheel:=world.get_node("Bypass") as WaterDeliveryControl
	if not await walk(wheel.position) or not use_point(wheel).success:check(false,"physical courtyard bypass failed");return false
	check(battle.session.is_mission_completed(),"actual onsite water delivery completes before extraction")
	if not await walk(world.get_node("PublicExit").global_position):return false
	if not await return_home(world.get_node("PublicExit")):return false
	check(ProfileRuntime.get_profile().waterworks_memory=="water_public","ordinary safe return persists real water branch")
	return failures.is_empty()

func checkpoint() -> bool:
	if not await deploy_next(BlockadeStory.MISSION):return false
	var world: Node3D=battle.area_root
	var van: BlockadeVan=world.get_node("Van")
	if not await approach_checkpoint(world):check(false,"normal physical checkpoint approach");return false
	for target in [world.get_node("PASwitch").position,Vector3(-9,0,-1),Vector3(0,0,1)]:
		if not await walk(target):return false
		if target==world.get_node("PASwitch").position:check(use_point(world.get_node("PASwitch")).success,"normal physical switch cuts PA without disabling weapon")
	for tick in 7200:
		await tree.physics_frame
		if van.destroyed or battle.player.is_dead:break
		var goal:=Vector3(0,0,1)
		if van.phase in [BlockadeVan.Phase.WARNING,BlockadeVan.Phase.BURST]:goal.x=-5 if van.aim_point.x>=0 else 5
		controls(goal)
	release();check(van.destroyed and not battle.player.is_dead,"live weapon fire disables actual armored truck")
	if not failures.is_empty() or not await leave_yard(world) or not await walk(world.get_node("NorthExit").position):return false
	if not await return_home(world.get_node("NorthExit")):return false
	check(ProfileRuntime.get_profile().blockade_cleared,"safe return, not vehicle damage alone, persists checkpoint victory")
	return failures.is_empty()

func operate(name: String) -> bool:
	var point: FinaleControl=battle.area_root.get_node(name)
	var sweep: FinaleSweep=battle.area_root.get_node("Sweep")
	var wait_at:=point.position+Vector3.RIGHT*.7
	if name=="MasterStop":wait_at=Vector3(3.5,0,-25)
	if not await walk(wait_at):return false
	if name not in ["Bridge","Radio"]:
		for tick in 1500:
			await tree.physics_frame;controls(battle.player.position)
			if sweep.phase==FinaleSweep.Phase.COOLING and sweep.remaining>1.5:break
		release()
		if name=="MasterStop" and not await walk(point.position+Vector3.RIGHT*.7):return false
	var response:=use_point(point)
	check(response.success,"real cooling-window circuit operation: "+name)
	await _capture("core_"+name)
	print("STORY_FINISH core=",name," phase=",sweep.phase," health=",battle.player.health," shots=",fired)
	return response.success

func core() -> bool:
	if not await deploy_next(FinaleStory.MISSION):return false
	if not await operate("Radio") or not await operate("Bridge"):return false
	if not await walk(Vector3(-17,0,10)) or not await operate("LeftFeed"):return false
	# Return along the outer aisle and cross south of the live sweep; no teleport.
	for target in [Vector3(-17,0,9),Vector3(17,0,9),Vector3(17,0,-19)]:
		if not await walk(target):return false
	if not await operate("RightFeed"):return false
	if not await walk(Vector3(17,0,-25)) or not await operate("MasterStop"):return false
	var world: Node3D=battle.area_root
	check(FinaleStory.done(battle.session,FinaleStory.STOP) and world.get_node("ShelterLamp").visible,"shutdown keeps actual shelter lamp on")
	var map=world.get_node("CoreMap").get_child(0);map.expanded=true;await _frames(3);await _capture("core_map");map.expanded=false
	if not await walk(world.get_node("NorthExit").position):return false
	return await return_home(world.get_node("NorthExit"),true)

func phase_wait(value: String) -> bool:
	for tick in 1800:
		await tree.physics_frame
		if tree.current_scene.phase==value:return true
	check(false,"ending did not reach phase: "+value);return false

func ending() -> void:
	var profile:=ProfileRuntime.get_profile()
	check(profile.maintenance_closed and profile.successful_sorties==10 and profile.sortie_checkpoint.is_empty(),"final safe return durably completes main story before presentation")
	# First normal entry may be skipped; its result must not be lost.
	await _click(tree.current_scene.screen.find_child("SkipSeatMoment",true,false))
	if not await _wait_scene("res://scenes/presentation/slice/hideout.tscn"):check(false,"early ending skip returns safely");return
	check(profile.maintenance_closed and tree.current_scene.section=="Rest","skip keeps earned ending and opens ordinary Rest")
	var before:=FileAccess.get_sha256(SaveService.DEFAULT_SAVE_PATH)
	await _click(tree.current_scene.find_child("ReplayHomecoming",true,false))
	if not await _wait_scene("res://scenes/presentation/slice/homecoming_finale.tscn"):check(false,"real replay action opens ending");return
	if not await phase_wait("intro"):return
	var room=tree.current_scene
	check(room.motion.seated and room.guest.visible,"normal ending stages original heroine and actual survivor")
	await _capture("ending_two_actors")
	for i in room.HOME_INTRO.size():await _click(room.next_button)
	await _click(room.choices.get_node("ChoiceRise"))
	if not await phase_wait("hesitate"):return
	check(not room.motion.seated,"normal choice actually stands to make room")
	for i in room.HOME_WAIT.size():await _click(room.next_button)
	if not await phase_wait("ending"):return
	for i in room.HOME_END.size():await _click(room.next_button)
	check(room.phase=="done" and room.dialogue.text==tr(room.HOME_END[-1]),"normal subtitle clicks retain final line")
	await _capture("ending_table")
	await _click(room.exits.get_node("HomeCredits"));await _capture("ending_end_card")
	check(room.end_card.visible,"normal credits button shows actual end card")
	await _click(room.exits.get_node("SeatReturn"))
	if not await _wait_scene("res://scenes/presentation/slice/hideout.tscn"):check(false,"ending returns to free play");return
	check(before==FileAccess.get_sha256(SaveService.DEFAULT_SAVE_PATH),"full ending, choice, credits and return leave earned profile bytes unchanged")
	check(FinaleStory.next_mission(profile).is_empty() and profile.maintenance_closed,"completed main story does not fabricate another mandatory chapter")
	await _capture("free_play")

func _run() -> void:
	tree=get_tree();tree.current_scene=null
	GameLanguage.set_language("en" if "--english" in OS.get_cmdline_user_args() else "zh_CN",true)
	var profile:=ProfileRuntime.get_profile()
	check(SaveService.save_exists() and not ProfileRuntime.recovery_required,"load actual earned profile without manufactured progress")
	if "--read" in OS.get_cmdline_user_args():
		check(profile.maintenance_closed and profile.blockade_cleared and profile.maintenance_rescued and profile.waterworks_memory=="water_public" and profile.successful_sorties==10 and profile.sortie_checkpoint.is_empty(),"independent process retains ten earned safe returns and complete local crisis")
		finish();return
	check(profile.successful_sorties==_expected_returns(7) and profile.maintenance_rescued and not profile.blockade_cleared and not profile.maintenance_closed and profile.waterworks_memory.is_empty(),"real prior rescue is migrated without invented water, checkpoint or finale")
	if not failures.is_empty():finish();return
	evidence["method"]="Actual earned schema10 rescue return; normal BOOT/continue/main-story buttons; real water battery/delivery, live truck fight, moving-arc core, physical extraction, automatic ending/skip/replay/credits/free play; not human acceptance"
	evidence["input_sha256"]=FileAccess.get_sha256(SaveService.DEFAULT_SAVE_PATH)
	tree.change_scene_to_file("res://scenes/presentation/slice/boot.tscn");await _frames(10)
	check(TranslationServer.get_locale()==("en" if "--english" in OS.get_cmdline_user_args() else "zh_CN"),"saved language preference survives real BOOT")
	if tree.current_scene.opening:await _click(_button("SKIP OPENING  /  ENTER"))
	await _click(_button("CONTINUE / BASE"))
	if not await _wait_scene("res://scenes/presentation/slice/hideout.tscn"):check(false,"normal continue reaches base");finish();return
	if not await water() or not await checkpoint() or not await core():finish();return
	await ending();finish()

func finish() -> void:
	if "--read" not in OS.get_cmdline_user_args():check(route_results.size()==3 and ProfileRuntime.get_profile().maintenance_closed,"complete route must actually finish all three operations and ending")
	release();evidence["checks"]=checks;evidence["failures"]=failures;evidence["routes"]=route_results;evidence["shots"]=fired
	var file:=FileAccess.open(out.path_join("story_finish.json"),FileAccess.WRITE);file.store_string(JSON.stringify(evidence,"\t"));file.close()
	AudioDirector.shutdown_for_test();print("STORY_FINISH_RUN: %s (%d checks, %d shots)"%["PASS" if failures.is_empty() else "FAIL",checks,fired]);tree.quit(0 if failures.is_empty() else 1)

func approach_checkpoint(world: Node3D) -> bool:
	if battle.session.blockade.is_empty():return true
	if "--street" in OS.get_cmdline_user_args():
		if not await walk(Vector3(0,0,27)):return false
		var chain:=world.get_node("StreetChain") as BlockadeStreetChain
		for tick in 600:
			await get_tree().physics_frame
			if chain.destroyed:break
			if battle.player.is_dead:return false
			controls(battle.player.position)
			var query:=PhysicsRayQueryParameters3D.create(battle.player.position+Vector3.UP*1.25,chain.position,4)
			var hit:=world.get_world_3d().direct_space_state.intersect_ray(query)
			if not hit.is_empty() and hit.collider==chain:
				for action in ["aim_left","aim_right","aim_up","aim_down"]:Input.action_release(action)
				var aim: Vector3=battle.player.position.direction_to(chain.position);aim.y=0;aim=aim.normalized()
				_axis("aim_left","aim_right",aim.x);_axis("aim_up","aim_down",aim.z);Input.action_press("fire")
		release()
		if not chain.destroyed or not battle.session.blockade.alarm:return false
		await _capture("checkpoint_chain_entry")
		return await walk(Vector3(0,0,17))
	for point in [Vector3(-7,0,41),Vector3(-18,0,41)]:
		if not await walk(point):return false
	release()
	var light:=world.get_node("Searchlight") as BlockadeSearchlight
	for tick in 600:
		await get_tree().physics_frame
		if light.sweep_time>.9 and light.sweep_time<2.1:break
	if not await walk(world.get_node("ServiceLever").position):return false
	release()
	if not use_point(world.get_node("ServiceLever")).success:return false
	await _capture("checkpoint_quiet_shutter")
	if battle.session.blockade.alarm:failures.append("Quiet cover/timing route was detected");return false
	return await walk(Vector3(-15,0,17))

func leave_yard(world: Node3D) -> bool:
	if battle.session.blockade.is_empty():return true
	if not battle.session.blockade.van_down or battle.session.is_mission_completed():return false
	await _capture("checkpoint_wreck_not_finished")
	if not await walk(world.get_node("EscapeLever").position):return false
	release()
	if not use_point(world.get_node("EscapeLever")).success:return false
	for tick in 600:
		await get_tree().physics_frame
		if battle.player.is_dead:return false
		if battle.session.blockade.escape_open:break
		controls(battle.player.position)
	release();await _capture("checkpoint_north_shutter_open")
	return battle.session.blockade.escape_open and battle.session.is_mission_completed()
