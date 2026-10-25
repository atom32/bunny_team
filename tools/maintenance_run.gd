extends "res://tests/normal_start_test.gd"
## Genuine completed-campus save, ordinary BOOT/menu, live AI and controller inputs.
## No new_profile, injected quest facts, teleport, direct damage or free supplies.
const ACTIONS := ["move_left","move_right","move_forward","move_back","aim_left","aim_right","aim_up","aim_down","fire"]
var battle: Node3D
var fired := 0

func _ready() -> void:
	get_tree().create_timer(600,true).timeout.connect(func():check(false,"normal rescue route deadline; no forced focus recovery");finish())
	super._ready()

func _axis(negative: String, positive: String, value: float) -> void:
	if value < -.01:Input.action_press(negative,-value)
	elif value > .01:Input.action_press(positive,value)

func release() -> void:
	for action in ACTIONS:Input.action_release(action)

func controls(destination: Vector3) -> void:
	release()
	var player: PlayerController = battle.player
	var gap:=destination-player.global_position;gap.y=0
	var motion:=gap.normalized() if gap.length()>.25 else Vector3.ZERO
	_axis("move_left","move_right",motion.x);_axis("move_forward","move_back",motion.z)
	var aim:=motion if motion!=Vector3.ZERO else player.aim_direction
	if battle.player_visibility.heard_remaining>0:aim=battle.player_visibility.heard_direction
	var nearest: EnemyController
	var distance:=24.0
	for enemy in battle.enemy_container.get_children():
		if enemy is MaintenanceAlarmCarrier: observe_caller(enemy)
		if not enemy is EnemyController or enemy.is_dead or not battle.player_visibility.can_see_enemy(enemy):continue
		var separation:=player.global_position.distance_to(enemy.global_position)
		if separation>=distance:continue
		var query:=PhysicsRayQueryParameters3D.create(player.global_position+Vector3.UP*1.25,enemy.global_position+Vector3.UP*1.25,6);query.exclude=[player.get_rid()]
		var hit:=player.get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty() and hit.collider==enemy:nearest=enemy;distance=separation
	if nearest:
		aim=player.global_position.direction_to(nearest.global_position);aim.y=0;aim=aim.normalized();Input.action_press("fire")
	_axis("aim_left","aim_right",aim.x);_axis("aim_up","aim_down",aim.z)
	if int(player.get_weapon_status(LoadoutState.SLOT_WEAPON_PRIMARY).get("magazine",0))==0 and player.can_reload():player.reload_weapon()

func observe_caller(enemy: MaintenanceAlarmCarrier) -> void:
	evidence["alarm_carrier"]={"spawn_key":enemy.get_meta("spawn_key"),"calls":enemy.calls_emitted,"interrupts":enemy.call_interrupts,"dead":enemy.is_dead}

func walk(target: Vector3, escort:=false) -> bool:
	var map: RID=battle.area_root.get_node("Navigation").get_navigation_map()
	var path:=PackedVector3Array()
	for tick in 600:
		await tree.physics_frame
		if NavigationServer3D.map_get_iteration_id(map)==0:continue
		path=NavigationServer3D.map_get_path(map,battle.player.global_position,target,true)
		if not path.is_empty() and path[-1].distance_to(target)<=1.2:break
	if path.is_empty() or path[-1].distance_to(target)>1.2:check(false,"navigation cannot reach "+str(target));return false
	var survivor: MaintenanceSurvivor=battle.area_root.get_node("Survivor")
	for waypoint in path:
		var reached:=false
		for tick in 1500:
			await tree.physics_frame
			if battle.player.is_dead:return false
			var gap: Vector3=waypoint-battle.player.global_position;gap.y=0
			if gap.length()<.45:reached=true;break
			var hold:=escort and survivor.global_position.distance_to(battle.player.global_position)>5.0
			controls(battle.player.global_position if hold else waypoint)
		if not reached:
			evidence["companion_stuck"]={"position":str(survivor.position),"target":str(survivor.agent.target_position),"finished":survivor.agent.is_navigation_finished(),"next":str(survivor.agent.get_next_path_position()),"path":str(survivor.agent.get_current_navigation_path())}
			var contacts:=[]
			for i in battle.player.get_slide_collision_count():
				var hit:KinematicCollision3D=battle.player.get_slide_collision(i)
				contacts.append({"collider":str(hit.get_collider().get_path()),"normal":str(hit.get_normal())})
			evidence["route_failure_state"]={"paused":tree.paused,"flow_mode":FlowMenu.mode,"focused":DisplayServer.window_is_focused() if DisplayServer.get_name()!="headless" else true,"player_physics":battle.player.is_physics_processing(),"battle_process_mode":battle.process_mode,"contacts":contacts}
			print("MAINTENANCE_ROUTE_FAILURE_STATE: ",JSON.stringify(evidence.route_failure_state))
			await _capture("maintenance_route_stuck")
			check(false,"route stuck: "+str(battle.player.global_position)+" -> "+str(waypoint)+" companion "+str(survivor.position));return false
	release();return true

func work(name: String) -> bool:
	var action: MaintenanceAction=battle.area_root.get_node(name)
	if not await walk(action.global_position+Vector3.RIGHT):return false
	check(action.interact(battle.player,battle.session).success,"nearby normal control starts: "+name)
	for attempt in 8:
		for tick in 660:
			await tree.physics_frame
			if battle.player.is_dead:return false
			if MaintenanceStory.done(battle.session,action.objective_id):
				release()
				for sync in 4:await tree.physics_frame
				print("MAINTENANCE_RUN opened=",name," health=",battle.player.health," shots=",fired)
				return true
			controls(battle.player.global_position)
			if action.remaining<=0:break
		if action.remaining<=0:action.interact(battle.player,battle.session)
	check(false,"work never finished under actual conditions: "+name);return false

func isolate_steam() -> bool:
	if not await walk(Vector3(0,0,-8)):return false
	var steam: MaintenanceSteam=battle.area_root.get_node("Steam")
	for tick in 300:
		await tree.physics_frame;controls(battle.player.position)
		if steam.cycle_time<.15:break
	release()
	if not await walk(Vector3(0,0,-18)):return false
	var valve: Node3D=battle.area_root.get_node("SteamValve")
	if not await walk(valve.global_position+Vector3.RIGHT):return false
	var component: InteractionComponent=battle.player.interaction_component
	component._physics_process(0)
	check(component._current_target==valve,"ordinary E targets nearby physical far-side valve")
	if component._current_target!=valve:return false
	check(component.interact_with_current().success and battle.session.maintenance.steam_off,"normal valve interaction isolates the steam")
	await _capture("steam_valve_closed")
	return battle.session.maintenance.steam_off

func _run() -> void:
	tree=get_tree();tree.current_scene=null
	GameLanguage.set_language("en" if "--english" in OS.get_cmdline_user_args() else "zh_CN",true)
	var profile:=ProfileRuntime.get_profile()
	check(SaveService.save_exists() and not ProfileRuntime.recovery_required and profile.campus_chapter.finished,"load genuine completed-campus save, not manufactured prerequisites")
	evidence["method"]="Earned completed-campus return copied to isolated userdata; ordinary BOOT/Continue/Operations; generated controls, live AI, real ammunition and physical escort; not a human playtest"
	if "--read" in OS.get_cmdline_user_args():
		check(profile.maintenance_rescued and profile.successful_sorties==_expected_returns(7) and profile.sortie_checkpoint.is_empty(),"independent process retains actual seventh safe return and rescued companion")
		finish();return
	check(not profile.maintenance_rescued and profile.successful_sorties==_expected_returns(6) and profile.sortie_checkpoint.is_empty(),"input contains no pre-earned maintenance rescue")
	if not failures.is_empty():finish();return
	evidence["route"]="rescue_first" if "--rescue-first" in OS.get_cmdline_user_args() else "preclear"
	evidence["input_sha256"]=FileAccess.get_sha256(SaveService.DEFAULT_SAVE_PATH)
	tree.change_scene_to_file("res://scenes/presentation/slice/boot.tscn");await _frames(10)
	if tree.current_scene.opening:await _click(_button("SKIP OPENING  /  ENTER"))
	await _click(_button("CONTINUE / BASE"))
	if not await _wait_scene("res://scenes/presentation/slice/hideout.tscn"):check(false,"continue reaches base");finish();return
	# Normal paid supply transaction, never an ammo grant or a progress fixture.
	var before:=profile.credits
	var purchase:=SupplyService.transact("buy","ammo.556_standard",120)
	check(purchase.error==OK and profile.credits<before,"spend actual earned credits on standard ammunition")
	evidence["credits_spent"]=before-profile.credits
	await _click(tree.current_scene.find_child("NavOperations",true,false))
	var choices:=tree.current_scene.find_child("MissionChoice",true,false) as OptionButton
	choices.select(DeploymentPlan.STREET_MISSIONS.find(MaintenanceStory.MISSION));choices.item_selected.emit(choices.selected);await _frames(8)
	await _capture("01_operations")
	await _click(_button("CONFIRM DEPLOYMENT"))
	if not await _wait_scene("res://scenes/battle/battle.tscn"):check(false,"ordinary deployment reaches new map");finish();return
	battle=tree.current_scene;battle.player.weapon_fired.connect(func(_recoil: float):fired+=1)
	for enemy in battle.enemy_container.get_children():
		if enemy is MaintenanceAlarmCarrier:
			observe_caller(enemy)
			enemy.died.connect(func(dead):observe_caller(dead))
	for tick in 30:await tree.physics_frame
	await _capture("02_arrival")
	if not await work("Bypass"):finish();return
	var rescue_first: bool="--rescue-first" in OS.get_cmdline_user_args()
	if not rescue_first:
		if not await isolate_steam():finish();return
	if not await work("WardControl"):finish();return
	var survivor: MaintenanceSurvivor=battle.area_root.get_node("Survivor")
	if not await walk(Vector3(15,0,-8)):finish();return
	for tick in 240:await tree.physics_frame;controls(battle.player.position)
	release();await _capture("03_ward")
	check(await walk(survivor.global_position+Vector3.FORWARD),"reach real released companion")
	check(survivor.interact(battle.player,battle.session).success and survivor.waiting,"normal nearby wait command")
	var where:=survivor.position
	for tick in 50:await tree.physics_frame;controls(battle.player.position)
	check(survivor.position.distance_to(where)<.03,"normal waiting companion stays physically put")
	check(survivor.interact(battle.player,battle.session).success and not survivor.waiting,"normal follow command")
	for target in [Vector3(15,0,-7),Vector3(15,0,-1),Vector3(0,0,-3),Vector3(0,0,-8)]:
		if not await walk(target,true):finish();return
	if rescue_first:
		if not await walk(Vector3(0,0,-18)):finish();return
		for tick in 360:
			await tree.physics_frame;controls(battle.player.position)
			if survivor.steam_blocked:break
		release();check(survivor.steam_blocked and battle.area_root.get_node("Steam").warned,"live escort refuses unisolated corridor")
		await _capture("steam_safety_line")
		if not await walk(survivor.global_position+Vector3.BACK):finish();return
		check(survivor.interact(battle.player,battle.session).success and survivor.waiting,"leave companion on safe side by ordinary wait command")
		var waiting_at:=survivor.position
		if not await isolate_steam():finish();return
		check(survivor.waiting and survivor.position.distance_to(waiting_at)<.04,"live valve isolation leaves waiting companion physically in place")
		if not await walk(survivor.global_position+Vector3.BACK):finish();return
		check(survivor.interact(battle.player,battle.session).success and not survivor.waiting,"return to call companion after isolation")
	for target in [Vector3(0,0,-18),Vector3(1,0,-24)]:
		if not await walk(target,true):finish();return
	check(await work("NorthControl"),"open north shutter under live enemy pressure")
	for tick in 30:await tree.physics_frame;controls(battle.player.position)
	release();await _capture("04_north_open")
	var map=battle.area_root.get_node("MaintenanceMap").get_child(0);map.expanded=true;await _frames(3);await _capture("05_route_map");map.expanded=false
	if not await walk(Vector3(0,0,-37),true):finish();return
	for tick in 600:
		await tree.physics_frame;controls(battle.player.position)
		if MaintenanceStory.done(battle.session,&"maintenance_rescue"):break
	release();check(MaintenanceStory.done(battle.session,&"maintenance_rescue"),"companion walks through real gates to the north safe zone")
	await _capture("06_safe")
	var session: SortieSession=battle.session
	evidence["steam_facts"]=session.maintenance.duplicate(true);evidence["steam_warning"]=battle.area_root.get_node("Steam").warned;evidence["steam_followed"]=battle.area_root.get_node("Steam").followed
	evidence["shots"]=fired;evidence["kills"]=session.enemies_defeated;evidence["health"]=battle.player.health;evidence["damage"]=session.damage_taken;evidence["companion_position"]=str(survivor.position)
	check(fired>0 and session.enemies_defeated>0 and not battle.player.is_dead,"actual combat, ammunition use and survival")
	check(battle.area_root.get_node("NorthExit").interact(battle.player,session).success,"physically extract through north exit")
	if not await _wait_scene("res://scenes/result/result.tscn"):check(false,"normal result transition");finish();return
	await _capture("07_debrief")
	if not await return_from_debrief():check(false,"normal safe return to base");finish();return
	check(profile.maintenance_rescued and profile.successful_sorties==_expected_returns(7) and profile.sortie_checkpoint.is_empty(),"normal return commits rescued woman without fictional prior mission progress")
	await _capture("08_home");finish()

func return_from_debrief() -> bool:
	await _click(tree.current_scene.find_child("ReturnButton",true,false))
	return await _wait_scene("res://scenes/presentation/slice/hideout.tscn")

func finish() -> void:
	release();evidence["checks"]=checks;evidence["failures"]=failures
	var file:=FileAccess.open(out.path_join("maintenance_run.json"),FileAccess.WRITE);file.store_string(JSON.stringify(evidence,"\t"));file.close()
	AudioDirector.shutdown_for_test();print("MAINTENANCE_RUN: %s (%d checks, %d shots)"%["PASS" if failures.is_empty() else "FAIL",checks,fired]);tree.quit(0 if failures.is_empty() else 1)

