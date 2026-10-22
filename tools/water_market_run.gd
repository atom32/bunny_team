extends "res://tools/story_finish_run.gd"
## Real earned seventh return -> ordinary BOOT -> market -> delivery -> safe eighth.
var depot_item:=""
var market_route:="quiet"
var started_ms:=0

func _ready() -> void:
	get_tree().create_timer(900,true).timeout.connect(func():check(false,"market route deadline; no forced focus recovery");finish())
	_run.call_deferred()

func _run() -> void:
	tree=get_tree();tree.current_scene=null
	var args:=OS.get_cmdline_user_args()
	GameLanguage.set_language("en" if "--english" in args else "zh_CN",true)
	var profile:=ProfileRuntime.get_profile()
	if "--read" in args:
		check(profile.successful_sorties==_expected_returns(8) and profile.waterworks_memory=="water_public" and profile.sortie_checkpoint.is_empty(),"separate process retains real safe eighth return and water choice")
		finish();return
	if "--resume-delivery" in args:
		await _resume_delivery(profile)
		finish();return
	market_route="loud" if "--loud" in args else ("skip" if "--skip-depot" in args else "quiet")
	check(SaveService.save_exists() and profile.successful_sorties==_expected_returns(7) and profile.maintenance_rescued and profile.waterworks_memory.is_empty(),"input is an actual earned rescue profile, not manufactured unlocks")
	evidence["method"]="Actual seven-return input; ordinary BOOT/UI and controller movement, live AI/ammo/collision, optional depot, water delivery and safe return. Synthetic precise controller, NOT human playtime."
	evidence["input_sha256"]=FileAccess.get_sha256(SaveService.DEFAULT_SAVE_PATH)
	if not failures.is_empty():finish();return
	tree.change_scene_to_file("res://scenes/presentation/slice/boot.tscn");await _frames(10)
	if tree.current_scene.opening:await _click(_button("SKIP OPENING  /  ENTER"))
	await _click(_button("CONTINUE / BASE"))
	if not await _wait_scene("res://scenes/presentation/slice/hideout.tscn"):check(false,"normal continue reaches base");finish();return
	started_ms=Time.get_ticks_msec()
	if not await water():check(false,"complete market, pump and extraction journey required")
	finish()

func _resume_delivery(profile: ProfileState) -> void:
	market_route="resumed"
	var saved:Dictionary=profile.sortie_checkpoint
	check(SaveService.save_exists() and not ProfileRuntime.recovery_required and profile.successful_sorties==_expected_returns(7) and profile.maintenance_rescued and profile.waterworks_memory.is_empty() and saved.get("phase")=="battle","resume requires actual unsettled seventh-return battle checkpoint")
	if not failures.is_empty():return
	var session:Dictionary=saved.get("session",{})
	var facts:Dictionary=session.get("waterworks",{})
	check(session.get("area")=="waterworks_district" and saved.get("world",{}).get("map_revision")==3 and facts.get("branch")=="public" and not facts.get("delivered",true),"original checkpoint contains pending public delivery on market map")
	var cores:=[]
	for item in session.get("inventory",{}).get("items",[]):
		if item.definition_id=="loot.salvage_core_01" and item.instance_id not in session.get("initial_ids",[]):cores.append(item.instance_id)
	check(cores.size()==1,"checkpoint already carries one exact physically collected depot core")
	if not failures.is_empty():return
	depot_item=cores[0]
	evidence["method"]="Unedited actual failed exported checkpoint; ordinary BOOT/RESUME, live AI/ammo/collision, nearby-target interaction and safe return. No teleport, forced focus/unpause or progress edits; not human playtime."
	evidence["input_sha256"]=FileAccess.get_sha256(SaveService.DEFAULT_SAVE_PATH)
	started_ms=Time.get_ticks_msec()
	tree.change_scene_to_file("res://scenes/presentation/slice/boot.tscn");await _frames(10)
	if tree.current_scene.opening:await _click(_button("SKIP OPENING  /  ENTER"))
	await _click(_button("RESUME SORTIE"))
	if not await _wait_scene("res://scenes/battle/battle.tscn"):check(false,"ordinary saved-sortie resume reaches water battle");return
	battle=tree.current_scene;battle.player.weapon_fired.connect(func(_recoil:float):fired+=1)
	for tick in 30:await tree.physics_frame
	check(WaterworksJourney.pending(battle.session,"public") and battle.session.inventory.contains(depot_item),"resume restores actual pending delivery and same cargo without settling either")
	var world:Node3D=battle.area_root
	var wheel:=world.get_node("Bypass") as WaterDeliveryControl
	if not await walk(wheel.global_position):return
	check(use_point(wheel).success and battle.session.is_mission_completed(),"ordinary closest-target interaction operates real bypass after resume")
	if not failures.is_empty():return
	await _capture("market_resumed_bypass")
	if not await walk(world.get_node("PublicExit").global_position):return
	await return_home(world.get_node("PublicExit"))

func deploy_next(wanted: StringName) -> bool:
	if not await super.deploy_next(wanted):return false
	if wanted!=WaterworksStory.MISSION:return false
	var world:=battle.area_root as Node3D
	check(battle.session.waterworks.version==3 and battle.player.position.z>85,"ordinary main-story deployment enters south market")
	await _capture("market_start")
	if not await walk(world.get_node("MarketNotice").position) or not use_point(world.get_node("MarketNotice")).success:return false
	if market_route in ["quiet","skip"]:
		for target in [Vector3(-27,0,83),Vector3(-27,0,72),Vector3(-31,0,57)]:
			if not await walk(target):return false
		if market_route=="quiet" and not use_point(world.get_node("MarketBreaker")).success:return false
		await _capture("market_west_cover")
		for target in [Vector3(-27,0,38),Vector3(17,0,38)]:
			if not await walk(target):return false
	else:
		if not await walk(Vector3(17,0,84)):return false
	if market_route=="skip":
		check(world.get_node("Market").mode==0 and not world.get_node("DepotCore").has_rolled,"optional depot genuinely skipped, no cargo or alarm benefit")
		return failures.is_empty()
	if not await walk(world.get_node("MarketShutter").position):return false
	if not use_point(world.get_node("MarketShutter")).success:return false
	var market:=world.get_node("Market") as WaterMarket
	var until:=Time.get_ticks_msec()+15000
	while market.progress<1 and not battle.player.is_dead and Time.get_ticks_msec()<until:
		await tree.physics_frame;controls(battle.player.position)
	release()
	check(market.progress==1 and market.mode==(1 if market_route=="quiet" else 2),"real shutter opens with matching circuit choice")
	check(world.get_node("MarketResponse0").has_spawned==(market_route=="loud"),"only noisy depot triggers its finite response")
	if not failures.is_empty():return false
	if not await walk(Vector3(25,0,66)) or not await walk(world.get_node("DepotCore").position):return false
	var pickup:LootPickup
	for child in world.get_node("DepotCore").get_children():
		if child is LootPickup and not child.consumed:pickup=child;break
	check(pickup!=null,"physical depot contains actual heavy salvage")
	if not pickup:return false
	depot_item=pickup.item_instance.instance_id
	if not await walk(pickup.global_position):return false
	battle.player.interaction_component._physics_process(0)
	check(battle.player.interaction_component._current_target==pickup and battle.player.interaction_component.interact_with_current().success,"ordinary interaction loads exact heavy core into carried backpack")
	await _capture("market_depot_loot")
	if not await walk(world.get_node("MarketBackBar").position) or not use_point(world.get_node("MarketBackBar")).success:return false
	# Merely reaching z<50 could take the long way out through the front shutter
	# while the async navigation update is pending. Require the actual shortcut.
	var nav:RID=world.get_node("StreetNavigation").get_navigation_map()
	var north_ready:=false
	var deadline:=Time.get_ticks_msec()+10000
	while Time.get_ticks_msec()<deadline:
		await tree.physics_frame
		var path:=NavigationServer3D.map_get_path(nav,battle.player.position,Vector3(32,0,47),true)
		var length:=0.0
		for i in range(1,path.size()):length+=path[i-1].distance_to(path[i])
		if not path.is_empty() and path[-1].distance_to(Vector3(32,0,47))<1 and length<12:north_ready=true;break
	check(north_ready,"updated navigation actually offers the short path through the raised north door")
	if not north_ready:return false
	if not await walk(Vector3(32,0,47)):return false
	check(market.back_open and battle.player.position.z<50,"ordinary controller physically crosses opened north shortcut")
	await _capture("market_north_shortcut")
	return failures.is_empty()

func return_home(exit: ExtractionPoint,_ending:=false) -> bool:
	if not await super.return_home(exit,false):return false
	var profile:=ProfileRuntime.get_profile()
	check(profile.successful_sorties==_expected_returns(8) and profile.waterworks_memory=="water_public" and profile.sortie_checkpoint.is_empty(),"water task and optional cargo settle only after actual extraction")
	if market_route!="skip":check(profile.inventory.contains(depot_item),"exact physically collected core returns to warehouse, not duplicate credit")
	await _capture("market_safe_return")
	return failures.is_empty()

func finish() -> void:
	if "--read" not in OS.get_cmdline_user_args():check(route_results.size()==1 and ProfileRuntime.get_profile().successful_sorties==_expected_returns(8),"full earned journey required, partial route is not PASS")
	release();evidence["checks"]=checks;evidence["routes"]=route_results;evidence["market_route"]=market_route;evidence["core_id"]=depot_item;evidence["synthetic_elapsed_ms_not_human"]=Time.get_ticks_msec()-started_ms;evidence["failures"]=failures
	var file:=FileAccess.open(out.path_join("water_market_earned.json"),FileAccess.WRITE);file.store_string(JSON.stringify(evidence,"\t"));file.close()
	AudioDirector.shutdown_for_test();print("WATER_MARKET_RUN: %s (%d checks)"%["PASS" if failures.is_empty() else "FAIL",checks]);tree.quit(0 if failures.is_empty() else 1)
