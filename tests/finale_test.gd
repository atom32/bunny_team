extends "res://tests/maintenance_test.gd"
## Controlled fixtures prove mechanics and persistence, not ordinary completion.
const CORE_PATH:="user://finale_test.json"

func core_fixture() -> ProfileState:
	var profile:=fixture()
	var sandbox:=ProfileState.create_new();sandbox.blockade_cleared=true
	check(sandbox.validate() and not FinaleStory.available(sandbox),"legacy sandbox victory remains savable without pretending its tutorial or finale was completed")
	profile.maintenance_rescued=true;profile.blockade_cleared=true;profile.waterworks_memory="water_public"
	check(profile.validate(),"explicit finale prerequisite fixture validates")
	return profile

func core_use(name: String) -> Dictionary:
	var point: FinaleControl=battle.area_root.get_node(name)
	battle.player.position=point.position+Vector3.RIGHT;await frames()
	return point.interact(battle.player,battle.session)

func _run() -> void:
	GameLanguage.set_language("en" if "--english" in OS.get_cmdline_user_args() else "zh_CN",false)
	if "--read" in OS.get_cmdline_user_args():
		check(ProfileRuntime.load_profile(CORE_PATH) and SortieRuntime.resume_saved(CORE_PATH)==OK,"independent process resumes actual core checkpoint")
		get_tree().paused=true;await load_battle()
		var sweep: FinaleSweep=battle.area_root.get_node("Sweep")
		check(not FlowMenu.is_open() and sweep.phase==FinaleSweep.Phase.WARNING and is_equal_approx(sweep.remaining,.8) and sweep.lane==2,"independent process restores exact warning lane and timer")
		await finish();return
	var profile:=fixture()
	check(FinaleStory.next_mission(profile)==WaterworksStory.MISSION and not FinaleStory.available(profile),"campus completion leads to water rather than inventing a finale unlock")
	profile.waterworks_memory="water_public";check(FinaleStory.next_mission(profile)==BlockadeStory.MISSION,"real water return leads to checkpoint")
	profile.blockade_cleared=true;check(FinaleStory.next_mission(profile)==MaintenanceStory.MISSION,"checkpoint then leads to the caller")
	profile.maintenance_rescued=true;check(FinaleStory.next_mission(profile)==FinaleStory.MISSION and FinaleStory.available(profile),"all three actual facts lead to the backup core")
	var old:=profile.to_dict();old.erase("blockade_cleared");old.erase("maintenance_closed")
	var file:=FileAccess.open("user://legacy10.json",FileAccess.WRITE);file.store_string(JSON.stringify({"schema_version":10,"profile":old}));file.close()
	var migrated:=SaveService.load_profile("user://legacy10.json",false)
	check(migrated!=null and migrated.maintenance_rescued and not migrated.blockade_cleared and not migrated.maintenance_closed,"schema 10 keeps rescued survivor but does not guess old unrecorded victories")
	file=FileAccess.open("user://invalid11.json",FileAccess.WRITE);file.store_string(JSON.stringify({"schema_version":11,"profile":old}));file.close()
	check(SaveService.load_profile("user://invalid11.json",false)==null,"schema 11 requires both typed story facts")
	old=profile.to_dict();old.maintenance_closed=true;old.blockade_cleared=false
	var bad:=ProfileState.from_dict(old);check(bad!=null and not bad.validate(),"inconsistent completed ending refused")
	profile=core_fixture()
	check(DeploymentPlan.deploy(profile,FinaleStory.AREA,FinaleStory.MISSION,CORE_PATH).error==OK,"new final operation deploys through normal transaction")
	await load_battle()
	var world: Node3D=battle.area_root;var session: SortieSession=battle.session
	var sweep: FinaleSweep=world.get_node("Sweep")
	check(not FlowMenu.is_open() and session.validate() and battle.enemy_container.get_child_count()==4,"new room starts with four real enemies and a valid journal")
	check(world.get_node("Retreat").can_extract(session) and not world.get_node("NorthExit").can_extract(session),"south retreat open before any work; north closed")
	check(not (await core_use("LeftFeed")).success and not (await core_use("MasterStop")).success,"cannot sacrifice shelter power or skip feeds")
	check((await core_use("Bridge")).success and FinaleStory.done(session,FinaleStory.BRIDGE),"nearby bridge connects actual shelter circuit")
	check(is_equal_approx(world.get_node("ShelterBridge").rotation.y,PI/2) and world.get_node("ShelterLamp").visible,"bridge arm moves while shelter lamp stays lit")
	sweep.phase=FinaleSweep.Phase.WARNING;sweep.remaining=1;sweep.lane=0;sweep.refresh()
	check(not (await core_use("LeftFeed")).success,"live feed refuses operation before blue window")
	var health: float=battle.player.health
	battle.player.position=Vector3(-8,0,-9);sweep._apply_arc()
	check(battle.player.health==health,"warning alone does not apply arc damage")
	sweep.phase=FinaleSweep.Phase.SWEEP;sweep.remaining=1.25;sweep.hit_cooldown=0;sweep.refresh();sweep._apply_arc()
	check(battle.player.health<health and session.damage_taken>0 and sweep.actual_hits==1,"live moving bar uses actual player armor, damage signal and sortie accounting")
	health=battle.player.health;sweep._apply_arc();check(battle.player.health==health,"arc cooldown prevents per-frame damage spam")
	battle.player.position.x=-4;sweep.hit_cooldown=0;sweep._apply_arc()
	check(battle.player.health==health,"lateral movement outside marked lane avoids actual discharge")
	sweep.phase=FinaleSweep.Phase.WARNING;sweep.remaining=.8;sweep.lane=2;sweep.cycle=0;sweep.hit_cooldown=0;sweep.refresh()
	get_tree().paused=true;await frames(10)
	check(is_equal_approx(sweep.remaining,.8),"pause freezes exact telegraph timer")
	check(SortieRuntime.save_checkpoint()==OK,"save persists actual warning and circuit facts")
	var saved:=SortieCheckpoint.capture_world(battle);check(SortieCheckpoint.validate_world(saved,battle),"legitimate core world validates")
	var path:=String(world.get_path_to(sweep))
	for values in [{"phase":9},{"remaining":20},{"lane":3},{"hit_cooldown":2},{"phase":4,"remaining":0}]:
		var corrupt:=saved.duplicate(true);corrupt.nodes[path].merge(values,true);check(not SortieCheckpoint.validate_world(corrupt,battle),"contradictory core checkpoint refused: "+str(values))
	if "--write" in OS.get_cmdline_user_args():await finish();return
	battle.free();SortieRuntime.clear_session()
	check(ProfileRuntime.load_profile(CORE_PATH) and SortieRuntime.resume_saved(CORE_PATH)==OK,"core suspension resumes through actual saved file")
	await load_battle();world=battle.area_root;session=battle.session;sweep=world.get_node("Sweep")
	check(not FlowMenu.is_open() and is_equal_approx(sweep.remaining,.8) and FinaleStory.done(session,FinaleStory.BRIDGE),"warning and bridge survive disk roundtrip without changing layout signature")
	get_tree().paused=false;sweep.phase=FinaleSweep.Phase.COOLING;sweep.remaining=4.5;sweep.refresh()
	check((await core_use("RightFeed")).success and battle.enemy_container.get_child_count()==6,"either feed can be first; first isolation spawns two only")
	for enemy in battle.enemy_container.get_children():enemy.set_physics_process(false)
	check(not (await core_use("RightFeed")).success and battle.enemy_container.get_child_count()==6,"same circuit cannot duplicate reinforcement")
	check((await core_use("LeftFeed")).success and battle.enemy_container.get_child_count()==6,"second feed does not duplicate first response")
	check(sweep.enabled_lanes(session)==[1] and not session.is_mission_completed(),"both side lanes become safe but work alone is not the final stop")
	var forged:=SortieCheckpoint.session_data(session)
	for state in forged.objectives:
		if state.objective_id==String(FinaleStory.BRIDGE):state.status=ObjectiveState.Status.PENDING;state.progress=0
	check(SortieCheckpoint.restore_session(forged)==null,"unprotected shelter plus isolated feeds cannot deserialize as a valid sortie")
	check((await core_use("MasterStop")).success,"actual final stop operates in cooling window after both feeds")
	check(session.is_mission_completed() and sweep.phase==FinaleSweep.Phase.OFF and not world.get_node("BackupLamp").visible and world.get_node("ShelterLamp").visible,"backup machinery stays stopped without blacking out shelter")
	check(world.get_node("NorthGate").position.y==5 and world.get_node("NorthLink").enabled and battle.enemy_container.get_child_count()==8,"final stop opens physical exit and finite last response")
	for enemy in battle.enemy_container.get_children():enemy.set_physics_process(false)
	battle.player.position=Vector3(0,0,-32);await frames()
	await capture("core_stopped")
	check(world.get_node("NorthExit").interact(battle.player,session).success,"north exit completes real extracted sortie")
	check(SortieRuntime.finalize_sortie(CORE_PATH)==OK and ProfileRuntime.get_profile().maintenance_closed,"atomic safe return records completed local crisis")
	check(FinaleStory.next_mission(ProfileRuntime.get_profile()).is_empty() and not FinaleStory.at_base(ProfileRuntime.get_profile()).is_empty(),"finished main story offers free play, not a fabricated next chapter")
	var money:=ProfileRuntime.get_profile().credits;check(SortieRuntime.finalize_sortie(CORE_PATH)==OK and ProfileRuntime.get_profile().credits==money,"retrying terminal return remains idempotent")
	await finish()

func finish() -> void:
	if is_instance_valid(battle):battle.free()
	SortieRuntime.clear_session();get_tree().paused=false;await frames();AudioDirector.shutdown_for_test()
	print("FINALE_TEST: %s (%d checks)"%["PASS" if failures.is_empty() else "FAIL",checks]);get_tree().quit(0 if failures.is_empty() else 1)
