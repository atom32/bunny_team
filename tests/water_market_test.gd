extends "res://tests/waterworks_test.gd"
## Component fixtures, not a human or a live-combat route. Teleports deliberate.

func finish_market() -> void:
	if is_instance_valid(battle):battle.free()
	SortieRuntime.clear_session();AudioDirector.shutdown_for_test()
	print("WATER_MARKET_TEST: %s (%d checks)"%["PASS" if failures.is_empty() else "FAIL",checks])
	get_tree().quit(0 if failures.is_empty() else 1)

func operate(name: String) -> Dictionary:
	var point:Node3D=battle.area_root.get_node(name)
	battle.player.position=point.position+Vector3.RIGHT*.8
	return point.interact(battle.player,battle.session)

func reachable(nav: RID,from: Vector3,target: Vector3) -> bool:
	var deadline:=Time.get_ticks_msec()+10000
	while Time.get_ticks_msec()<deadline:
		if NavigationServer3D.map_get_iteration_id(nav)>0:
			var path:=NavigationServer3D.map_get_path(nav,from,target,true)
			if not path.is_empty() and path[-1].distance_to(target)<1:return true
		await get_tree().create_timer(.05).timeout
	print("MARKET_NAV_FAIL iteration=",NavigationServer3D.map_get_iteration_id(nav)," from=",from," target=",target," closest=",NavigationServer3D.map_get_closest_point(nav,target))
	return false

func _run() -> void:
	GameLanguage.set_language("en" if "--english" in OS.get_cmdline_user_args() else "zh_CN",false)
	var args:=OS.get_cmdline_user_args()
	if "--read" in args or "--v2-read" in args:
		check(ProfileRuntime.load_profile(PATH) and SortieRuntime.resume_saved(PATH)==OK,"independent process resumes the actually written checkpoint")
		battle=load("res://scenes/battle/battle.tscn").instantiate();battle.result_transition_enabled=false;add_child(battle)
		check(not FlowMenu.is_open(),"actual signed world restores without incompatible-world recovery")
		for enemy in battle.enemy_container.get_children():enemy.set_physics_process(false)
		battle.player.set_physics_process(false)
		if "--v2-read" in args:
			check(battle.session.waterworks.version==2 and not battle.area_root.has_node("Market") and battle.area_root.get_meta("map_revision")==2,"previous binary v2 checkpoint retains the old map and node set")
			check(battle.area_root.get_node("Latch").current_structure_health==12 and battle.session.waterworks.branch=="public","old partial latch damage and pending delivery survive")
			finish_market();return
		var market:WaterMarket=battle.area_root.get_node("Market")
		check(market.mode==2 and not market.isolated and is_equal_approx(market.progress,.37) and not market.back_open,"partial noisy opening resumes exactly, not a fresh depot")
		check(battle.area_root.get_node("MarketResponse0").has_spawned and battle.area_root.get_node("MarketResponse1").has_spawned,"once-only response facts restored")
		market._physics_process(3)
		check(market.progress==1 and battle.area_root.get_node("DepotCore").has_rolled,"resumed physical opening rolls actual cache once")
		check(operate("MarketBackBar").success and market.back_open,"restored player can open the inner north bar")
		finish_market();return
	await start()
	var world:Node3D=battle.area_root
	var market:WaterMarket=world.get_node("Market")
	check(battle.session.waterworks.version==3 and world.get_meta("map_revision")==3,"new deployments use expanded map, not old suspended trips")
	check(battle.player.position.z>85 and world.get_node("Retreat").position.z>85,"new start and safe retreat are physically south of market")
	check(battle.enemy_container.get_child_count()==13,"five market enemies plus eight existing district enemies; no infinite waves")
	check(not world.get_node("DepotCore").enabled and not world.get_node("DepotCore").has_rolled,"depot value is not rolled or interactable through a closed shutter")
	check(world.get_node("PublicGate/DoorBody/CollisionShape3D").shape.size.is_equal_approx(Vector3(.6,2.8,6)) and world.get_node("LoadingGate/DoorBody/CollisionShape3D").shape.size.is_equal_approx(Vector3(6,3.4,.6)),"per-parent resources keep courtyard and loading-gate collision dimensions distinct")
	check(not market.operate("shutter",battle.player,battle.session,world.get_node("MarketShutter")).success,"remote interaction cannot open depot")
	var nav:RID=world.get_node("StreetNavigation").get_navigation_map()
	for target in [Vector3(-27,0,83),Vector3(-31,0,57),Vector3(17,0,83),Vector3(19,0,69),world.get_node("Battery").position,world.get_node("Retreat").position]:
		check(await reachable(nav,battle.player.position,target),"reachable authored market route target: "+str(target))
	var before:=SortieCheckpoint.capture_world(battle)
	check(SortieCheckpoint.validate_world(before,battle),"closed depot world checkpoint validates")
	var ray:=PhysicsRayQueryParameters3D.create(Vector3(19,1.2,66),Vector3(25,1.2,66),4)
	check(battle.get_world_3d().direct_space_state.intersect_ray(ray).get("collider")==world.get_node("Market/FrontGate/DoorBody"),"closed depot shutter is an actual shot-blocking collider")
	check(operate("MarketNotice").success and not battle.session.is_mission_completed(),"route notice awards no mission progress")
	if "--write" in args:
		check(operate("MarketShutter").success,"actual local switch starts noisy opening")
		for enemy in battle.enemy_container.get_children():enemy.set_physics_process(false)
		market._physics_process(.37*2.2)
		get_tree().paused=true
		check(SortieRuntime.save_checkpoint()==OK,"partial real opening durably saved for separate process")
		finish_market();return
	check(operate("MarketBreaker").success and market.isolated,"west route actually disconnects bell")
	check(not operate("MarketBreaker").success,"breaker cannot duplicate a benefit")
	check(operate("MarketShutter").success and market.mode==1,"isolated circuit opens quiet route")
	check(not world.get_node("MarketResponse0").has_spawned and battle.enemy_container.get_child_count()==13,"quiet route adds no alarm wave")
	market._physics_process(1.1)
	check(is_equal_approx(market.progress,.5) and not world.get_node("Market/FrontLink").enabled and not world.get_node("DepotCore").enabled,"half-raised shutter has not unlocked navigation or cargo")
	market._physics_process(2)
	await frames()
	check(market.progress==1 and world.get_node("Market/FrontLink").enabled,"physical shutter and nav link open together")
	check(battle.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(),"raised shutter actually clears the former shot barrier")
	check(await reachable(nav,Vector3(19,0,66),Vector3(39,0,71)),"opened front link gives a real navigation route into depot")
	var core:LootSpawnPoint=world.get_node("DepotCore")
	check(core.has_rolled and core.get_child_count()>0,"depot generates its actual fixed-value cargo")
	var pickup:LootPickup
	for child in core.get_children():
		if child is LootPickup:pickup=child;break
	check(pickup!=null and pickup.item_instance.definition_id==&"loot.salvage_core_01" and pickup.item_instance.total_weight()==6,"reward is actual six-kilo existing salvage, not free credits")
	var old_capacity:float=battle.session.inventory.capacity
	battle.session.inventory.capacity=battle.session.inventory.get_used_capacity()+5
	battle.player.position=pickup.global_position
	check(not pickup.interact(battle.player,battle.session).success and not pickup.consumed,"full backpack leaves heavy salvage in the world")
	battle.session.inventory.capacity=old_capacity
	var id:=pickup.item_instance.instance_id
	check(pickup.interact(battle.player,battle.session).success and battle.session.inventory.contains(id),"legal pickup places exact generated item in carried inventory")
	check(not pickup.interact(battle.player,battle.session).success,"consumed core cannot be duplicated")
	market.apply_progress();market.apply_progress()
	var core_left:=0
	for child in core.get_children():
		if child is LootPickup and not child.consumed and not child.is_queued_for_deletion():core_left+=1
	check(core_left==0,"refresh never rerolls looted depot core")
	check(not market.back_open and not world.get_node("Market/NorthLink").enabled,"inside shortcut remains barred until physically operated")
	check(operate("MarketBackBar").success and market.back_open and world.get_node("Market/NorthLink").enabled,"inside bar opens real north shortcut")
	# Controlled starting fixture, then real input/capsule movement across the door.
	# No teleport, direct damage, AI disable or victory assignment in the live routes.
	battle.player.position=Vector3(32,0,55)
	battle.player.set_physics_process(true)
	var until:=Time.get_ticks_msec()+5000
	Input.action_press("move_forward")
	while battle.player.position.z>48 and Time.get_ticks_msec()<until:await get_tree().physics_frame
	Input.action_release("move_forward")
	battle.player.set_physics_process(false)
	check(battle.player.position.z<49 and absf(battle.player.position.x-32)<.5,"ordinary movement capsule physically crosses the raised north door")
	var saved:=SortieCheckpoint.capture_world(battle)
	check(SortieCheckpoint.validate_world(saved,battle),"open, partly looted depot validates alongside exact inventory")
	for field in ["mode","progress","isolated","back_open","reinforcement","cache"]:
		var bad:=saved.duplicate(true)
		match field:
			"mode":bad.nodes.Market.mode=2
			"progress":bad.nodes.Market.progress=.5
			"isolated":bad.nodes.Market.isolated=false
			"back_open":bad.nodes.Market.progress=0
			"reinforcement":bad.nodes.MarketResponse0.has_spawned=true
			"cache":bad.nodes.DepotCore.has_rolled=false
		check(not SortieCheckpoint.validate_world(bad,battle),"inconsistent depot snapshot rejected: "+field)
	await capture("market_depot_open")
	check(not battle.session.is_mission_completed() and battle.session.waterworks.branch.is_empty(),"optional depot cannot complete or select water delivery")
	check(world.get_node("Retreat").can_extract(battle.session),"safe retreat remains available without depot or delivery")
	check(world.get_node("Retreat").extract(battle.session) and SortieRuntime.finalize_sortie(PATH)==OK,"optional salvage can be physically extracted without finishing the water job")
	check(ProfileRuntime.get_profile().inventory.contains(id) and ProfileRuntime.get_profile().waterworks_memory.is_empty(),"retreat keeps exact recovered cargo but grants no false delivery memory")
	finish_market()
