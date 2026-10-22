extends "res://tests/maintenance_test.gd"
## Controlled hazard/escort fixtures. Ordinary input completion is maintenance_run.
const JOURNEY_PATH:="user://maintenance_journey_test.json"

func load_battle() -> void:
	await super.load_battle()
	if battle.area_root.has_node("Steam"):battle.area_root.get_node("Steam").set_physics_process(false)

func finish_journey() -> void:
	if is_instance_valid(battle):battle.free()
	SortieRuntime.clear_session();get_tree().paused=false
	await frames();AudioDirector.shutdown_for_test()
	print("MAINTENANCE_JOURNEY_TEST: %s (%d checks)"%["PASS" if failures.is_empty() else "FAIL",checks])
	get_tree().quit(0 if failures.is_empty() else 1)

func _run() -> void:
	var args:=OS.get_cmdline_user_args()
	GameLanguage.set_language("en" if "--english" in args else "zh_CN",false)
	if "--legacy-read" in args:
		check(ProfileRuntime.load_profile(JOURNEY_PATH) and SortieRuntime.resume_saved(JOURNEY_PATH)==OK,"new code accepts genuine old-code maintenance checkpoint")
		get_tree().paused=true;await load_battle()
		check(not FlowMenu.is_open() and battle.session.maintenance.is_empty() and int(battle.area_root.get_meta("map_revision"))==1 and not battle.area_root.has_node("Steam"),"genuine signed v1 retains original map, not new chamber")
		check(is_equal_approx(battle.area_root.get_node("NorthControl").remaining,5) and battle.area_root.get_node("Survivor").waiting,"old five-second work remainder and companion wait survive")
		battle.area_root.get_node("NorthControl")._process(5)
		check(MaintenanceStory.done(battle.session,&"maintenance_gate") and battle.area_root.get_node("NorthGate").position.y==5,"old timed control still completes under old rules")
		await finish_journey();return
	if "--read" in args:
		check(ProfileRuntime.load_profile(JOURNEY_PATH) and SortieRuntime.resume_saved(JOURNEY_PATH)==OK,"independent process resumes signed steam corridor")
		get_tree().paused=true
		await load_battle()
		var steam: MaintenanceSteam=battle.area_root.get_node("Steam")
		check(not FlowMenu.is_open() and int(battle.area_root.get_meta("map_revision"))==2,"v2 snapshot restores v2 geometry")
		check(is_equal_approx(steam.cycle_time,3.4) and is_equal_approx(steam.hit_cooldown,.3),"exact hot-cycle phase and hit cooldown survive disk")
		check(steam.warned and not steam.followed and not steam.isolated(),"one-shot warning persists without falsely closing steam")
		check(battle.area_root.get_node("Survivor").waiting and battle.area_root.get_node("Survivor").position.z> -9.65,"actual wait command and safe position persist")
		check(battle.area_root.get_node("Steam/Jets").visible,"hot-state visuals reconstituted, not stale serialized nodes")
		await finish_journey();return
	check(DeploymentPlan.deploy(fixture(),MaintenanceStory.AREA,MaintenanceStory.MISSION,JOURNEY_PATH).error==OK,"normal v2 deployment accepts explicit campus fixture")
	SortieRuntime.get_current_session().maintenance.version=2 # Explicit preserved v2 journey fixture.
	await load_battle()
	var world: Node3D=battle.area_root
	var session: SortieSession=battle.session
	var steam: MaintenanceSteam=world.get_node("Steam")
	var survivor: MaintenanceSurvivor=world.get_node("Survivor")
	check(session.maintenance=={"version":2,"steam_off":false} and session.validate(),"fresh mission uses typed optional v2 facts")
	check(int(world.get_meta("map_revision"))==2 and world.get_node("ChamberWall0Body").collision_layer==4,"new corridor has real blocking geometry")
	check(world.get_node("Bypass/TerminalPedestal").mesh!=world.get_node("WardControl/TerminalPedestal").mesh,"same child names have distinct authored mesh resources")
	check(not world.get_node("NorthControl").interact(battle.player,session).success,"north shutter cannot skip bypass, ward or isolation")
	check(not world.get_node("SteamValve").interact(battle.player,session).success,"valve cannot be operated remotely")
	check((await use("Bypass")).success and MaintenanceStory.done(session,&"maintenance_bypass") and world.get_node("Bypass").remaining==0,"new bypass opens instantly; no replacement long work timer")
	check(world.get_node("ServiceGate").position.y==5 and world.get_node("ServiceGateLink").enabled,"instant unlatch opens the real collider and nav link")
	battle.player.position=Vector3(0,0,-13);await frames()
	var query:=PhysicsRayQueryParameters3D.create(Vector3(0,1,-13),Vector3(9,1,-13),4)
	check(not world.get_world_3d().direct_space_state.intersect_ray(query).is_empty(),"player cannot sidestep through east steam wall")
	var hp: float=battle.player.health
	steam.cycle_time=0;steam._physics_process(0)
	check(battle.player.health==hp and world.get_node("Steam/Safe").visible and not world.get_node("Steam/Jets").visible,"clear window gives visible safe crossing without damage")
	steam.cycle_time=2.5;steam._physics_process(0)
	check(battle.player.health==hp and world.get_node("Steam/Warning").visible,"pressure warning precedes heat without damage")
	await capture("maintenance_steam_warning")
	steam.cycle_time=3.3;steam._physics_process(0)
	var hit: float=6*(1-battle.player.get_protection())
	check(is_equal_approx(battle.player.health,hp-hit) and world.get_node("Steam/Jets").visible,"hot steam applies actual armor-adjusted six-base damage")
	await capture("maintenance_steam_hot")
	steam._physics_process(.2)
	check(is_equal_approx(battle.player.health,hp-hit),"hot damage is rate limited, not applied every frame")
	battle.player.position=Vector3(0,0,-8);await frames()
	steam.hit_cooldown=0;steam._physics_process(0)
	check(is_equal_approx(battle.player.health,hp-hit),"outside the marked chamber no steam damage is applied")
	check((await use("WardControl")).success and MaintenanceStory.done(session,&"maintenance_release") and world.get_node("WardControl").remaining==0,"ward release is also immediate")
	for enemy in battle.enemy_container.get_children():enemy.set_physics_process(false)
	check(battle.enemy_container.get_child_count()==6 and not (await use("WardControl")).success,"ward release spawns exactly two once")
	# Controlled starting position; movement to the safety line is real follower physics.
	survivor.position=Vector3(0,0,-8);survivor.velocity=Vector3.ZERO;survivor.traversing_link=false;survivor.link_goal=Vector3.ZERO;survivor.repath=0
	battle.player.position=Vector3(0,0,-18)
	await frames(180)
	check(survivor.position.z> -9.65 and survivor.position.z< -9.2 and survivor.steam_blocked,"real follower stops before hot corridor, even during clear window")
	check(steam.warned and not survivor.waiting and survivor.collision_layer==0,"safety stop is not a manual wait or shootable escort-health mechanic")
	var at: Vector3=survivor.position
	await frames(40)
	check(survivor.position.distance_to(at)<.04,"follower does not creep across the safety line")
	battle.player.position=survivor.position+Vector3.RIGHT;await frames()
	check(survivor.interact(battle.player,session).success and survivor.waiting,"explicit wait still works at safety line")
	steam.cycle_time=3.4;steam.hit_cooldown=.3;steam.refresh()
	get_tree().paused=true
	check(SortieRuntime.save_checkpoint()==OK,"hot-cycle and waiting-survivor checkpoint commits")
	var saved:=SortieCheckpoint.capture_world(battle)
	check(SortieCheckpoint.validate_world(saved,battle),"legitimate full steam world validates")
	for patch in [{"cycle_time":4.8},{"cycle_time":-1},{"hit_cooldown":.6},{"warned":7},{"followed":true}]:
		var invalid:=saved.duplicate(true);invalid.nodes.Steam.merge(patch,true)
		check(not SortieCheckpoint.validate_world(invalid,battle),"forged steam state refused: "+str(patch))
	var invalid:=saved.duplicate(true);invalid.nodes.Survivor.position=[0,0,-13]
	check(not SortieCheckpoint.validate_world(invalid,battle),"cannot restore escort inside an unisolated hazard")
	invalid=saved.duplicate(true);invalid.nodes.Bypass.remaining=1
	check(not SortieCheckpoint.validate_world(invalid,battle),"new immediate controls reject forged remaining work")
	if "--write" in args:await finish_journey();return
	get_tree().paused=false
	battle.player.position=world.get_node("SteamValve").position+Vector3.RIGHT;await frames()
	check(world.get_node("SteamValve").interact(battle.player,session).success and steam.isolated(),"actual nearby far-side valve permanently isolates steam")
	steam.cycle_time=3.3;hp=battle.player.health;steam._physics_process(0)
	check(steam.hit_cooldown==0 and not world.get_node("Steam/Jets").visible and battle.player.health==hp,"isolated pipe stops all heat visuals and damage")
	check(survivor.waiting and not steam.followed,"closing valve does not cancel explicit wait or teleport companion")
	battle.player.position=survivor.position+Vector3.RIGHT;await frames()
	check(survivor.interact(battle.player,session).success and not survivor.waiting,"player must return and call waiting survivor")
	battle.player.position=Vector3(0,0,-18);await frames(180)
	check(survivor.position.z< -15.5 and steam.followed,"real follower traverses isolated corridor and emits one follow beat")
	check((await use("NorthControl")).success and MaintenanceStory.done(session,&"maintenance_gate") and world.get_node("NorthControl").remaining==0,"isolated route unlocks instantaneous north shutter")
	for enemy in battle.enemy_container.get_children():enemy.set_physics_process(false)
	check(battle.enemy_container.get_child_count()==8 and not session.is_mission_completed(),"finite final pair activates but gates alone do not rescue")
	var data:=SortieCheckpoint.session_data(session);data.maintenance.steam_off=false
	check(SortieCheckpoint.restore_session(data)==null,"north-open session cannot claim steam still live")
	check(world.get_node("Retreat").can_extract(session),"south retreat remains open after every step")
	await capture("maintenance_steam_isolated")
	await finish_journey()
