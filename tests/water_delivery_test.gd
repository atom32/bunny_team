extends "res://tests/waterworks_test.gd"
## Controlled component fixtures. Live combat routes are in waterworks_run.

func prepare(branch: String) -> void:
	await start();use("Battery");use("Pump");battle.area_root.get_node("Pump")._process(8)
	var name:="PublicValve" if branch=="public" else "TankerValve"
	use(name);check(battle.area_root.get_node(name).confirm_delivery(),"fixture uses actual confirmation")
	for enemy in battle.enemy_container.get_children():enemy.set_physics_process(false)
	battle.player.set_physics_process(false)

func finish_delivery_test() -> void:
	if is_instance_valid(battle):battle.free()
	SortieRuntime.clear_session();AudioDirector.shutdown_for_test()
	print("WATER_DELIVERY_TEST: %s (%d checks)"%["PASS" if failures.is_empty() else "FAIL",checks]);get_tree().quit(0 if failures.is_empty() else 1)

func _run() -> void:
	GameLanguage.set_language("zh_CN",false)
	var args:=OS.get_cmdline_user_args()
	if "--legacy-read" in args:
		check(ProfileRuntime.load_profile(PATH) and SortieRuntime.resume_saved(PATH)==OK,"actual pre-expansion binary checkpoint is accepted")
		battle=load("res://scenes/battle/battle.tscn").instantiate();battle.result_transition_enabled=false;add_child(battle)
		get_tree().paused=false
		check(not FlowMenu.is_open() and battle.session.waterworks.is_empty() and int(battle.area_root.get_meta("map_revision"))==1 and not battle.area_root.has_node("Tanker"),"old saved trip uses original signed geometry, not new truck map")
		var pump: WaterworksAction=battle.area_root.get_node("Pump")
		check(pump.remaining>5.9 and pump.remaining<6.1 and WaterworksStory.battery(battle.session)!=null,"old process remaining work and battery identity survive")
		for enemy in battle.enemy_container.get_children():enemy.set_physics_process(false)
		battle.player.set_physics_process(false)
		pump._process(pump.remaining)
		use("PublicValve");check(battle.area_root.get_node("PublicValve").confirm_delivery() and battle.session.is_mission_completed(),"legacy trip retains original immediate-valve completion")
		check(battle.area_root.get_node("PublicExit").extract(battle.session) and SortieRuntime.finalize_sortie(PATH)==OK and ProfileRuntime.get_profile().waterworks_memory=="water_public","genuine old suspended trip can finish and settle safely")
		finish_delivery_test();return
	if "--read" in args:
		check(ProfileRuntime.load_profile(PATH) and SortieRuntime.resume_saved(PATH)==OK,"separate process resumes exact pending delivery checkpoint")
		battle=load("res://scenes/battle/battle.tscn").instantiate();battle.result_transition_enabled=false;add_child(battle)
		get_tree().paused=false
		check(not FlowMenu.is_open() and battle.session.validate() and not battle.session.is_mission_completed(),"partial delivery remains incomplete and valid after restart")
		for enemy in battle.enemy_container.get_children():enemy.set_physics_process(false)
		battle.player.set_physics_process(false)
		var branch: String=battle.session.waterworks.branch
		if branch=="public":
			check(battle.area_root.get_node("Latch").current_structure_health==12,"partial latch damage survives independent process")
			battle.area_root.get_node("Latch").receive_damage(DamagePacket.new(0,0,12,battle.player,&"fixture",&"player"))
			check(battle.session.waterworks.public_fix=="shot" and battle.session.is_mission_completed(),"restored physical latch can complete exactly once")
		else:
			var truck: WaterTanker=battle.area_root.get_node("Tanker")
			check(truck.progress==2 and not truck.moving and truck.position.z== -27,"paused two-metre truck and collider survive restart")
			battle.player.position=Vector3(28,0,-31)
			check(battle.area_root.get_node("LoadingLever").interact(battle.player,battle.session).success,"resumed gate still usable")
			truck.moving=true
			for tick in 420:await get_tree().physics_frame
			check(battle.session.is_mission_completed() and truck.progress==truck.DISTANCE,"resumed actual truck completes delivery")
		finish_delivery_test();return
	var branch:="tanker" if "--tanker" in args else "public"
	await prepare(branch)
	var session: SortieSession=battle.session
	var world: Node3D=battle.area_root
	if "--write" in args:
		if branch=="public":
			world.get_node("Latch").receive_damage(DamagePacket.new(0,0,4,battle.player,&"fixture",&"player"))
			battle.player.position=Vector3(-28,0,-15)
		else:
			battle.player.position=Vector3(31.6,0,-25)
			check(world.get_node("Tanker").interact(battle.player,session).success,"write fixture releases real handbrake")
			world.get_node("Tanker")._physics_process(1);world.get_node("Tanker").moving=false
		get_tree().paused=true
		check(SortieRuntime.save_checkpoint()==OK,"persist partially played delivery for another process")
		finish_delivery_test();return
	var data:=SortieCheckpoint.session_data(session)
	for bad in [null,[],{"version":2},{"version":2,"branch":"other","public_fix":"","gate_open":false,"delivered":false}]:
		var forged:=data.duplicate(true);forged.waterworks=bad
		check(SortieCheckpoint.restore_session(forged)==null,"malformed version-two facts rejected")
	for key in ["gate_open","public_fix","delivered"]:
		var forged:=data.duplicate(true)
		forged.waterworks[key]={"branch":"tanker","gate_open":true,"public_fix":"shot","delivered":true}[key]
		check(SortieCheckpoint.restore_session(forged)==null,"inconsistent pending courtyard facts rejected: "+key)
	var snapshot:=SortieCheckpoint.capture_world(battle)
	check(SortieCheckpoint.validate_world(snapshot,battle),"fresh pending world checkpoint valid")
	for key in ["waterworks","nodes"]:
		var forged:=snapshot.duplicate(true)
		if key=="waterworks":forged.waterworks.branch="tanker"
		else:forged.nodes.Response0.has_spawned=false
		check(not SortieCheckpoint.validate_world(forged,battle),"world facts and once-only response must match committed route")
	check(not world.get_node("PublicExit").can_extract(session) and not world.get_node("TankerExit").can_extract(session),"pending route cannot use either reward exit")
	check(world.get_node("Retreat").extract(session) and SortieRuntime.finalize_sortie(PATH)==OK,"pending delivery can safely retreat")
	check(ProfileRuntime.get_profile().waterworks_memory.is_empty(),"unfinished safe retreat records no false water memory")
	battle.free();battle=null
	await prepare("tanker")
	world=battle.area_root;session=battle.session
	var truck: WaterTanker=world.get_node("Tanker")
	battle.player.position=Vector3(34,0,-29.6);await frames()
	truck.moving=true;truck._physics_process(.5)
	check(truck.blocked and truck.progress==0,"truck front query sees actual player collider and refuses to crush")
	battle.player.position=Vector3(31.6,0,-25);await frames()
	truck._physics_process(4)
	check(truck.progress==truck.GATE_STOP and not truck.moving and not session.is_mission_completed(),"closed gate physically caps progress and stops truck without reward")
	var ray:=PhysicsRayQueryParameters3D.create(Vector3(30,1.2,-29.5),Vector3(38,1.2,-29.5),4)
	check(battle.get_world_3d().direct_space_state.intersect_ray(ray).get("collider")==truck,"moved truck collider really blocks a shot across loading lane")
	battle.player.position=truck.position+Vector3.LEFT*2.4
	check(truck.interact(battle.player,session).get("message")=="Raise the loading gate before moving the truck.","nearby handbrake specifically rejects the closed gate, not range")
	finish_delivery_test()

