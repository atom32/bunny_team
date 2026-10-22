extends Node3D
## Explicit controlled fixtures, not evidence of ordinary combat completion.
const PATH := "user://maintenance_test.json"
var failures: Array[String] = []
var checks := 0
var battle: Node3D

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)

func frames(count := 4) -> void:
	for tick in count: await get_tree().physics_frame

func fixture() -> ProfileState:
	SortieRuntime.clear_session()
	var profile := ProfileRuntime.new_profile()
	profile.first_mission_completed = true
	profile.narrative_slice.settled.Q01 = true
	profile.narrative_slice.q01_exits = ["streets_exit_0", "streets_exit_1"]
	profile.narrative_slice.settled.Q02 = true
	profile.narrative_slice.q02.delivered = {"medical.field_dressing":2,"material.fabric":2}
	profile.narrative_slice.q02.message = NarrativeSlice.Q02_MESSAGE
	for key in ["relays_returned","recorder_revealed","recorder_returned","branch_disconnected","power_returned","delivered_armor","finished"]:
		profile.campus_chapter[key] = true
	profile.campus_chapter.delivered_ammo = 60
	check(profile.validate(), "explicit completed-campus unit fixture validates")
	return profile

func load_battle() -> void:
	battle = load("res://scenes/battle/battle.tscn").instantiate()
	battle.result_transition_enabled = false
	add_child(battle)
	battle.player.set_physics_process(false)
	for enemy in battle.enemy_container.get_children(): enemy.set_physics_process(false)
	await frames()

func use(name: String) -> Dictionary:
	var control: MaintenanceAction = battle.area_root.get_node(name)
	battle.player.position = control.position + Vector3.RIGHT
	await frames()
	return control.interact(battle.player, battle.session)

func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless" or "--capture" not in OS.get_cmdline_user_args(): return
	await RenderingServer.frame_post_draw
	check(get_viewport().get_texture().get_image().save_png(OS.get_environment("BUNNY_EVIDENCE").path_join(name+".png"))==OK,"native maintenance capture saved")

func _ready() -> void: _run.call_deferred()

func _run() -> void:
	GameLanguage.set_language("en" if "--english" in OS.get_cmdline_user_args() else "zh_CN", false)
	if "--read" in OS.get_cmdline_user_args() or "--link-read" in OS.get_cmdline_user_args():
		check(ProfileRuntime.load_profile(PATH) and SortieRuntime.resume_saved(PATH)==OK,"independent process resumes maintenance checkpoint")
		get_tree().paused=true # Inspect the exact durable instant before gameplay resumes.
		await load_battle()
		if "--link-read" in OS.get_cmdline_user_args():
			var companion: MaintenanceSurvivor=battle.area_root.get_node("Survivor")
			check(not FlowMenu.is_open() and companion.traversing_link and companion.link_goal.is_equal_approx(Vector3(15,0,-1)),"independent process restores actual mid-doorway destination")
			get_tree().paused=false;await frames(180)
			check(companion.position.z > -4 and not companion.traversing_link,"resumed companion walks off link without teleport or oscillation")
			await finish();return
		check(not FlowMenu.is_open() and is_equal_approx(battle.area_root.get_node("NorthControl").remaining, 5),"independent process restores exact five seconds of work")
		check(battle.area_root.get_node("Survivor").waiting and battle.area_root.get_node("Survivor").position.distance_to(Vector3(15,0,-9))<.02,"independent process restores companion position and wait command")
		await finish(); return
	var fresh := ProfileRuntime.new_profile()
	check(not DeploymentPlan.build(fresh,MaintenanceStory.MISSION).error.is_empty(),"new player cannot skip directly into sealed maintenance")
	var profile := fixture()
	var raw := profile.to_dict(); raw.erase("maintenance_rescued")
	var file := FileAccess.open("user://schema9.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"schema_version":9,"profile":raw}));file.close()
	var old := SaveService.load_profile("user://schema9.json",false)
	check(old!=null and not old.maintenance_rescued and old.campus_chapter==profile.campus_chapter,"schema 9 migration does not invent a rescued survivor or erase campus")
	file=FileAccess.open("user://invalid10.json",FileAccess.WRITE);file.store_string(JSON.stringify({"schema_version":10,"profile":raw}));file.close()
	check(SaveService.load_profile("user://invalid10.json",false)==null,"schema 10 requires its typed rescue field")
	raw=profile.to_dict();raw.maintenance_rescued="true"
	check(ProfileState.from_dict(raw)==null,"non-boolean rescue state refused")
	check(ContentDB.get_mission(MaintenanceStory.MISSION).validate_definition() and ContentDB.get_area_definition(MaintenanceStory.AREA).validate_definition(),"independent mission and area registered")
	check(DeploymentPlan.deploy(profile,MaintenanceStory.AREA,MaintenanceStory.MISSION,PATH).error==OK,"normal transactional deployment accepts completed campus fixture")
	SortieRuntime.get_current_session().maintenance={} # Explicit legacy timed-control fixture; v2 has its own tests.
	await load_battle()
	var world: Node3D = battle.area_root
	var session: SortieSession = battle.session
	var survivor: MaintenanceSurvivor = world.get_node("Survivor")
	check(not FlowMenu.is_open() and session.validate(),"new map initializes with a valid checkpoint")
	check(battle.enemy_container.get_child_count()==4,"four initial live enemies, not eight active at once")
	check(world.get_node("Retreat").can_extract(session) and not world.get_node("NorthExit").can_extract(session),"south retreat open, north rescue exit locked")
	check(not survivor.interact(battle.player,session).success,"survivor cannot be commanded through the locked ward")
	check(not (await use("WardControl")).success and not (await use("NorthControl")).success,"controls cannot be operated out of order")
	check((await use("Radio")).information==tr(MaintenanceStory.INTRO),"spawn radio conveys authored character scene")
	check((await use("Bypass")).success,"pressure work starts only at physical control")
	var bypass: MaintenanceAction = world.get_node("Bypass")
	bypass._process(2);bypass._health(bypass.observed_health-1,battle.player.max_health)
	check(bypass.remaining==0 and not MaintenanceStory.done(session,&"maintenance_bypass"),"damage interrupts without granting gate progress")
	check((await use("Bypass")).success,"interrupted work restarts")
	battle.player.position.x+=5;await frames()
	check(bypass.remaining==0,"leaving control interrupts work")
	check((await use("Bypass")).success,"returning allows fresh work")
	bypass._process(6);await frames()
	check(MaintenanceStory.done(session,&"maintenance_bypass") and world.get_node("ServiceGate").position.y==5 and world.get_node("ServiceGateLink").enabled,"completed pressure physically raises gate and enables navigation")
	var navigation: RID=world.get_node("Navigation").get_navigation_map()
	var path:=NavigationServer3D.map_get_path(navigation,Vector3(0,0,10),Vector3(11,0,-2),true)
	check(not path.is_empty() and path[-1].distance_to(Vector3(11,0,-2))<1,"actual navigation path crosses the opened service bulkhead")
	check((await use("WardControl")).success,"ward work starts after pressure")
	world.get_node("WardControl")._process(4);await frames()
	for enemy in battle.enemy_container.get_children():enemy.set_physics_process(false)
	check(MaintenanceStory.done(session,&"maintenance_release") and battle.enemy_container.get_child_count()==6,"ward release opens door and spawns exactly two one-shot enemies")
	check(not (await use("WardControl")).success and battle.enemy_container.get_child_count()==6,"release cannot duplicate enemies")
	battle.player.position=Vector3(15,0,-1)
	if "--link-write" in OS.get_cmdline_user_args():
		for tick in 180:
			await get_tree().physics_frame
			if survivor.traversing_link and survivor.position.z > -5.5:break
		get_tree().paused=true
		check(survivor.traversing_link and survivor.position.z < -3.5 and SortieRuntime.save_checkpoint()==OK,"save actual unfinished physical doorway traversal")
		check(SortieCheckpoint.validate_world(SortieCheckpoint.capture_world(battle),battle),"actual mid-link checkpoint validates before independent read")
		await finish();return
	await frames(240)
	check(survivor.position.z > -5,"companion physically follows across the opened ward doorway")
	battle.player.position=survivor.position+Vector3.RIGHT;await frames()
	check(survivor.interact(battle.player,session).success and survivor.waiting,"nearby wait command changes real companion state")
	var position_before: Vector3=survivor.position
	battle.player.position=Vector3(8,0,-8);await frames(30)
	check(survivor.position.distance_to(position_before)<.02,"waiting survivor does not follow")
	battle.player.position=survivor.position+Vector3.RIGHT;await frames()
	check(survivor.interact(battle.player,session).success and not survivor.waiting,"follow command releases waiting state")
	battle.player.position=Vector3(8,0,-8);await frames(100)
	check(survivor.position.distance_to(position_before)>.8,"navigation actually moves survivor, not only a label")
	position_before=survivor.position;battle.player.position=Vector3(-20,0,-24);await frames(30)
	check(survivor.position.distance_to(position_before)<.02,"distance greater than 12m stops following without teleport")
	# Controlled persistence fixture; deliberately not a normal-play claim.
	survivor.position=Vector3(15,0,-9);survivor.velocity=Vector3.ZERO;survivor.waiting=true;survivor.traversing_link=false;survivor.link_goal=Vector3.ZERO
	check((await use("NorthControl")).success,"north work starts after real ward release")
	var north: MaintenanceAction=world.get_node("NorthControl");north._process(3)
	get_tree().paused=true
	check(SortieRuntime.save_checkpoint()==OK,"mid-work checkpoint saves actual companion and control state")
	var saved:=SortieCheckpoint.capture_world(battle)
	check(SortieCheckpoint.validate_world(saved,battle),"legitimate suspended maintenance world validates")
	var survivor_path:=String(world.get_path_to(survivor))
	for forged in [{"position":[100,0,100]},{"waiting":7},{"velocity":[10,0,0]},{"rotation":[1,0,0]},{"traversing_link":true,"link_goal":[0,0,-31]},{"link_goal":[15,0,-1]}]:
		var corrupt:=saved.duplicate(true);corrupt.nodes[survivor_path].merge(forged,true)
		check(not SortieCheckpoint.validate_world(corrupt,battle),"invalid companion checkpoint refused: "+str(forged))
	if "--write" in OS.get_cmdline_user_args():await finish();return
	battle.free();SortieRuntime.clear_session()
	check(ProfileRuntime.load_profile(PATH) and SortieRuntime.resume_saved(PATH)==OK,"disk roundtrip resumes actual sortie")
	await load_battle();world=battle.area_root;session=battle.session;survivor=world.get_node("Survivor");north=world.get_node("NorthControl")
	check(not FlowMenu.is_open() and is_equal_approx(north.remaining,5) and survivor.waiting,"work timer and wait command survive disk roundtrip")
	get_tree().paused=false;north._process(5);await frames()
	for enemy in battle.enemy_container.get_children():enemy.set_physics_process(false)
	check(world.get_node("NorthGate").position.y==5 and battle.enemy_container.get_child_count()==8,"north shutter physically opens and spawns final two once")
	check(not session.is_mission_completed(),"open gates alone do not rescue survivor")
	var forged_session:=SortieCheckpoint.session_data(session)
	for objective in forged_session.objectives:
		if objective.objective_id=="maintenance_release":objective.status=ObjectiveState.Status.PENDING;objective.progress=0
	check(SortieCheckpoint.restore_session(forged_session)==null,"out-of-order mission facts rejected")
	battle.player.position=Vector3(0,0,-37);survivor.position=Vector3(0,0,-32);survivor.velocity=Vector3.ZERO;survivor.waiting=false
	await frames(140)
	check(MaintenanceStory.done(session,&"maintenance_rescue") and session.is_mission_completed(),"physical companion arrival, not player arrival alone, completes objective")
	check(survivor.position.distance_to(MaintenanceStory.SAFE)<2.01,"companion stops inside real safe zone")
	await capture("maintenance_survivor_safe")
	check(world.get_node("NorthExit").interact(battle.player,session).success,"north exit now permits nearby extraction")
	var outcome:=SortieRuntime.get_outcome()
	check(outcome and MaintenanceStory.returned(outcome) and not MaintenanceStory.ending(outcome).is_empty(),"real extracted rescue has matching debrief")
	var result:=ResultUI.new();result.configure(outcome);add_child(result);await frames()
	var facts:=result.find_child("ReturnFacts",true,false) as Label
	check(facts!=null and facts.text==tr(MaintenanceStory.END) and facts.get_minimum_size().y<=300,"full rescue ending fits its dedicated debrief area")
	check(result.find_child("CampaignPreview",true,false)==null,"unrelated legacy contract cannot overlap rescue ending")
	await capture("maintenance_debrief");result.free()
	check(SortieRuntime.finalize_sortie(PATH)==OK and ProfileRuntime.get_profile().maintenance_rescued,"atomic safe return records rescued survivor")
	var credits:=ProfileRuntime.get_profile().credits
	check(SortieRuntime.finalize_sortie(PATH)==OK and ProfileRuntime.get_profile().credits==credits,"retrying return does not duplicate outcome rewards")
	battle.free();SortieRuntime.clear_session();battle=null
	check(SaveService.load_profile(PATH,false).maintenance_rescued,"schema 10 rescue flag persists to disk")
	profile=fixture();check(DeploymentPlan.deploy(profile,MaintenanceStory.AREA,MaintenanceStory.MISSION,PATH).error==OK,"independent retreat fixture deploys")
	SortieRuntime.get_current_session().maintenance={} # Explicit legacy timed-control fixture; v2 has its own tests.
	await load_battle()
	check(battle.area_root.get_node("Retreat").interact(battle.player,battle.session).success and SortieRuntime.finalize_sortie(PATH)==OK and not ProfileRuntime.get_profile().maintenance_rescued,"early retreat returns safely without inventing a rescue")
	await finish()

func finish() -> void:
	if is_instance_valid(battle):battle.free()
	SortieRuntime.clear_session();get_tree().paused=false
	await frames();AudioDirector.shutdown_for_test()
	print("MAINTENANCE_TEST: %s (%d checks)"%["PASS" if failures.is_empty() else "FAIL",checks])
	get_tree().quit(0 if failures.is_empty() else 1)
