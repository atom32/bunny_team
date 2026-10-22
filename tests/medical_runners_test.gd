extends "res://tests/campus_chapter_test.gd"
## Explicit component placements/damage. Not a human or earned campaign run.
var checks:=0
var runners: CampusMedicalRunners
func chapter_path() -> String:
	if "--legacy-v5-read" in OS.get_cmdline_user_args():return "user://medical_legacy_v5.json"
	return "user://medical_runners_route.json" if "--route-write" in OS.get_cmdline_user_args() or "--route-read" in OS.get_cmdline_user_args() else "user://medical_runners_test.json"
func check(ok: bool,message: String) -> void:checks+=1;super.check(ok,message)
func frames(count:=3) -> void:
	for index in count:await get_tree().physics_frame
func freeze() -> void:
	battle.player.set_physics_process(false)
	for enemy in battle.enemy_container.get_children():enemy.set_physics_process(false)
	runners.set_physics_process(false)
func report() -> void:
	if is_instance_valid(battle):battle.free()
	SortieRuntime.clear_session();AudioDirector.shutdown_for_test()
	print("MEDICAL_RUNNERS_TEST: %s (%d checks)"%["PASS" if failures.is_empty() else "FAIL",checks])
	get_tree().quit(0 if failures.is_empty() else 1)
func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless" or "--capture" not in OS.get_cmdline_user_args():return
	await frames(30);await RenderingServer.frame_post_draw
	check(get_viewport().get_texture().get_image().save_png(OS.get_environment("BUNNY_EVIDENCE").path_join(name+".png"))==OK,"capture actual medical runner scene")
func _ready() -> void:
	await get_tree().process_frame
	GameLanguage.set_language("en" if "--english" in OS.get_cmdline_user_args() else "zh_CN",false)
	if "--legacy-v5-read" in OS.get_cmdline_user_args():
		check(ProfileRuntime.load_profile(chapter_path()) and SortieRuntime.resume_saved(chapter_path())==OK,"accept actual old-code map5 medical checkpoint")
		var before:=ProfileRuntime.get_profile().to_dict()
		battle=load("res://scenes/battle/battle.tscn").instantiate();battle.result_transition_enabled=false;add_child(battle)
		battle.player.set_physics_process(false)
		for enemy in battle.enemy_container.get_children():enemy.set_physics_process(false)
		check(not FlowMenu.is_open() and battle.session.q02_active and battle.area_root.get_meta("map_revision")==5,"old medical map preserves its signed layout")
		check(not battle.area_root.has_node("CampusMedicalRunners"),"old medical outing never gains today's carrier or extra enemies")
		check(SortieCheckpoint.validate_world(SortieCheckpoint.capture_world(battle),battle),"old world remains strictly checkpointable")
		var after:=ProfileRuntime.get_profile().to_dict()
		for key in ["inventory","credits","successful_sorties","narrative_slice"]:check(before[key]==after[key],"old save reading invents no progress or resources: "+key)
		report();return
	if "--read" in OS.get_cmdline_user_args() or "--route-read" in OS.get_cmdline_user_args():
		check(ProfileRuntime.load_profile(chapter_path()) and SortieRuntime.resume_saved(chapter_path())==OK,"separate process accepts real signed module checkpoint")
		battle=load("res://scenes/battle/battle.tscn").instantiate();battle.result_transition_enabled=false;add_child(battle)
		runners=battle.area_root.get_node("CampusMedicalRunners");freeze()
		if FlowMenu.is_open():print("MEDICAL_RESTORE_DIAGNOSTIC ",SortieRuntime.last_error)
		if "--route-read" in OS.get_cmdline_user_args():
			check(not FlowMenu.is_open() and runners.phase==CampusMedicalRunners.Phase.LEAVING and runners.route_index==2,"actual middle-of-route phase and waypoint survive independent process")
			check(is_instance_valid(runners.carrier) and runners.carrier.movement_duty.is_valid(),"restored carrier is rebound to route, not ordinary home patrol")
			check(runners.carrier.position.distance_to(runners.get_node("Carrier").position)>15,"restored physical carrier is not teleported back to its start")
			check(SortieCheckpoint.validate_world(SortieCheckpoint.capture_world(battle),battle),"restored route snapshot remains strictly valid")
			report();return
		check(not FlowMenu.is_open() and runners.phase==CampusMedicalRunners.Phase.DROPPED,"dropped state restored, no new carrier")
		check(not is_instance_valid(runners.carrier),"dead carrier is not respawned on read")
		var quantities:={}
		for name in ["Dressings","Linen"]:
			for item in runners.get_node(name).get_children():
				if item is LootPickup:
					var key:=String(item.item_instance.definition_id)
					quantities[key]=quantities.get(key,0)+item.item_instance.quantity
		check(quantities=={"medical.field_dressing":2,"material.fabric":2},"exact unclaimed physical supplies survive independent read")
		check(SortieCheckpoint.validate_world(SortieCheckpoint.capture_world(battle),battle),"restored module can be strictly captured again")
		report();return
	# Legal Q02 profile fixture; no claim that these milestones were earned here.
	SortieRuntime.clear_session();var profile:=ProfileRuntime.new_profile();profile.first_mission_completed=true
	profile.narrative_slice.settled.Q01=true;profile.narrative_slice.q01_exits=["streets_exit_0","streets_exit_1"]
	check(profile.validate(),"declared Q02 fixture is valid without settling Q02")
	check(DeploymentPlan.deploy(profile,&"street_district",&"streets_recon",chapter_path()).error==OK,"ordinary deployment creates active medical context")
	battle=load("res://scenes/battle/battle.tscn").instantiate();battle.result_transition_enabled=false;add_child(battle)
	runners=battle.area_root.get_node("CampusMedicalRunners");freeze();await frames()
	check(battle.area_root.get_meta("map_revision")==6 and SortieCheckpoint.VERSION==6 and SaveService.SCHEMA_VERSION==11,"only new Q02 map changes, not profile/checkpoint schema")
	check(runners.phase==CampusMedicalRunners.Phase.PACKING and is_instance_valid(runners.carrier) and is_instance_valid(runners.escort),"one finite carrier and one escort spawn")
	check(runners.carrier.movement_duty.is_valid() and runners.escort.movement_duty.is_valid(),"both real enemies receive authored duties")
	check(runners.carrier.presentation.model.has_node("MedicalBag") and not runners.carrier.has_node("MedicalBag"),"white bag follows observed model rotation, not hidden gameplay root")
	var tag:=runners.carrier.presentation.get_node("MedicalBagTag") as Label3D
	var bag:=runners.carrier.presentation.model.get_node("MedicalBag") as MeshInstance3D
	check(tag.text==TranslationServer.translate("MED BAG"),"only the observed carrier receives the short localized bag marker")
	runners.carrier.presentation.hide()
	check(not tag.is_visible_in_tree(),"bag marker cannot reveal an unobserved enemy")
	for name in ["Dressings","Linen"]:
		var cache:=runners.get_node(name) as LootSpawnPoint
		check(not cache.enabled and not cache.has_rolled and cache.get_child_count()==0,"no pickup or bonus spawns before interception: "+name)
	var before: Dictionary=battle.session.inventory.to_dict()
	battle.player.position=runners.get_node("Carrier").position+Vector3(0,0,5);runners._physics_process(0)
	check(runners.phase==CampusMedicalRunners.Phase.LEAVING and runners.introduced,"approaching clinic starts physical departure, not a remote countdown")
	check(battle.session.inventory.to_dict()==before,"hearing the event grants no supplies")
	var carrier:=runners.carrier
	carrier.ensure_awareness();carrier.awareness.state=EnemyAwareness.State.PATROL
	check(carrier._movement_goal(0)==runners.get_node("Route/ClinicDoor").global_position,"unalerted carrier goes to first physical route point")
	carrier.awareness.state=EnemyAwareness.State.COMBAT;carrier.awareness.last_known=Vector3(45,0,45)
	check(carrier._movement_goal(0)==carrier.awareness.last_known,"visible-contact combat overrides carrier duty normally")
	carrier.awareness.state=EnemyAwareness.State.PATROL
	var world:=SortieCheckpoint.capture_world(battle)
	check(SortieCheckpoint.validate_world(world,battle),"leaving world validates with ordinary enemies and no free items")
	await capture("medical_carrier")
	# Actual route geometry queried after the asynchronous nav publication.
	var map: RID=battle.area_root.get_node("StreetNavigation").get_navigation_map()
	for tick in 600:
		await get_tree().physics_frame
		if NavigationServer3D.map_get_iteration_id(map)>0:break
	var start:=carrier.position
	for point in runners.get_node("Route").get_children():
		var path:=PackedVector3Array()
		for tick in 600:
			await get_tree().physics_frame
			path=NavigationServer3D.map_get_path(map,start,point.position,true)
			if not path.is_empty() and path[-1].distance_to(point.position)<.8:break
		if path.is_empty() or path[-1].distance_to(point.position)>=.8:print("MEDICAL_NAV ",point.name," start=",start," target=",point.position," closest=",NavigationServer3D.map_get_closest_point(map,point.position)," path=",path)
		check(not path.is_empty() and path[-1].distance_to(point.position)<.8,"authored carrier waypoint is genuinely reachable: "+point.name)
		start=point.position
	if "--escape" in OS.get_cmdline_user_args() or "--route-write" in OS.get_cmdline_user_args():
		# Geometry fixture: no target observation; authored enemy physics/nav are live.
		battle.player.position=Vector3(50,0,50)
		carrier.set_physics_process(true);runners.escort.set_physics_process(true);runners.set_physics_process(true)
		var kills: int=battle.session.enemies_defeated
		var furthest:=0.0;var origin:=carrier.position
		for tick in 18000:
			await get_tree().physics_frame
			if is_instance_valid(carrier):furthest=maxf(furthest,carrier.position.distance_to(origin))
			if "--route-write" in OS.get_cmdline_user_args() and runners.route_index==2:
				freeze()
				check(SortieRuntime.save_checkpoint()==OK,"persist actual middle-of-route physical movement without fabricating waypoint or position")
				report();return
			if runners.phase==CampusMedicalRunners.Phase.ESCAPED:break
		if runners.phase!=CampusMedicalRunners.Phase.ESCAPED:
			var contacts:=[]
			for index in carrier.get_slide_collision_count():contacts.append(str(carrier.get_slide_collision(index).get_collider()))
			print("MEDICAL_ROUTE_STUCK ",JSON.stringify({"position":str(carrier.position),"route_index":runners.route_index,"goal":str(runners._carrier_goal()),"contacts":contacts,"paused":get_tree().paused}))
		check(runners.phase==CampusMedicalRunners.Phase.ESCAPED and furthest>25,"real enemy physics traverses authored clinic-to-gate route without teleport")
		check(battle.session.enemies_defeated==kills,"carrier departure grants no kill credit")
		check(not runners.get_node("Dressings").has_rolled and not runners.get_node("Linen").has_rolled,"escaped supplies do not spawn or reward")
		check(SortieCheckpoint.validate_world(SortieCheckpoint.capture_world(battle),battle),"escaped world remains strictly restorable")
		report();return
	# Declared direct damage fixture, separately from normal live-AI earned route.
	var packet:=DamagePacket.new(1000,1000);carrier.receive_damage(packet);await frames()
	check(runners.phase==CampusMedicalRunners.Phase.DROPPED and not is_instance_valid(carrier),"actual death signal drops the physical medical bag once")
	check(not is_instance_valid(tag) and not is_instance_valid(bag),"dead presentation retains neither live-carrier marker nor a duplicate visual bag")
	check(battle.session.inventory.to_dict()==before,"kill alone does not place supplies into carried inventory")
	world=SortieCheckpoint.capture_world(battle)
	check(SortieCheckpoint.validate_world(world,battle),"dropped supplies and absent carrier agree in strict world snapshot")
	for name in ["Dressings","Linen"]:
		var cache:=runners.get_node(name) as LootSpawnPoint
		var count:=0
		for pickup in cache.get_children():
			if not pickup is LootPickup:continue
			count+=pickup.item_instance.quantity
			check(pickup._item_is_valid(),"physical drop respects original stackability: "+name)
		check(cache.has_rolled and count==2,"exactly two units in each physical cache: "+name)
		var crate:=cache.get_node("LootContainer") as SliceLootContainer
		check(crate.scale.is_equal_approx(Vector3.ONE*.6) and not crate.get_node("WorldTag").visible,"compact physical drop has no overlapping world label: "+name)
	var bad: Dictionary=world.duplicate(true);bad.nodes.CampusMedicalRunners.phase=CampusMedicalRunners.Phase.ESCAPED
	check(not SortieCheckpoint.validate_world(bad,battle),"reject escaped carrier with already issued physical supplies before mutation")
	bad=world.duplicate(true);bad.nodes["CampusMedicalRunners/Dressings"].has_rolled=false
	check(not SortieCheckpoint.validate_world(bad,battle),"reject reset drop marker that could reroll supplies")
	await capture("medical_dropped")
	if "--write" in OS.get_cmdline_user_args():
		check(SortieRuntime.save_checkpoint()==OK,"actual signed dropped checkpoint written")
		report();return
	for name in ["Dressings","Linen"]:
		for pickup in runners.get_node(name).get_children():
			if not pickup is LootPickup:continue
			check(pickup.try_pickup(battle.session)==LootPickup.PickupResult.SUCCESS,"ordinary capacity-checked pickup adds supplies: "+name)
	await frames()
	check(battle.session.inventory.to_dict()!=before and not profile.narrative_slice.settled.Q02,"physical pickup does not auto-settle base medical delivery")
	check(SortieCheckpoint.validate_world(SortieCheckpoint.capture_world(battle),battle),"consumed drop does not regenerate supplies on capture")
	report()
