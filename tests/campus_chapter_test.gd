extends Node3D
const PATH:="user://campus_chapter_test.json"
var failures: Array[String]=[]
var battle: Node3D
func check(ok: bool,message: String) -> void:
	if not ok:failures.append(message);push_error(message)
func profile_at_batch2() -> ProfileState:
	SortieRuntime.clear_session();var profile:=ProfileRuntime.new_profile();profile.first_mission_completed=true
	profile.narrative_slice.settled.Q01=true;profile.narrative_slice.q01_exits=["streets_exit_0","streets_exit_1"]
	profile.narrative_slice.settled.Q02=true;profile.narrative_slice.q02.delivered={"medical.field_dressing":2,"material.fabric":2};profile.narrative_slice.q02.message=NarrativeSlice.Q02_MESSAGE
	check(profile.validate(),"Real Batch 1 prerequisites valid")
	return profile
func start_world() -> void:
	var profile:=ProfileRuntime.get_profile()
	check(DeploymentPlan.deploy(profile,&"street_district",&"streets_recon",PATH).error==OK,"Actual finite chapter sortie deployed")
	battle=load("res://scenes/battle/battle.tscn").instantiate();battle.result_transition_enabled=false;add_child(battle)
	battle.player.set_physics_process(false)
	for enemy in battle.enemy_container.get_children():enemy.set_physics_process(false)
	await get_tree().process_frame
func finish_world(success: bool) -> void:
	check(battle.session.complete_extraction() if success else battle.session.fail(),"Actual terminal outcome")
	check(SortieRuntime.finalize_sortie(PATH)==OK,"Chapter outcome committed atomically")
	battle.free();battle=null;await get_tree().process_frame
func _ready() -> void:
	if "--read" in OS.get_cmdline_user_args():
		var loaded:=SaveService.load_profile(PATH,false)
		check(loaded!=null and loaded.campus_chapter.finished and loaded.campus_chapter.delivered_ammo==60,"Fresh process reads exact completed schema 8 chapter")
		AudioDirector.shutdown_for_test()
		print("CAMPUS_CHAPTER_READ: ","PASS" if failures.is_empty() else "FAIL")
		get_tree().quit(0 if failures.is_empty() else 1);return
	var profile:=profile_at_batch2();await start_world()
	# Failure/retry fixture: real work and pickup, then a failed extraction.
	for name in ["CampusRelayOffice","CampusRelayRepair"]:
		var point:=battle.area_root.get_node(name) as CampusAction
		battle.player.global_position=point.global_position+Vector3.RIGHT
		point.interact(battle.player,battle.session);point._process(12.0)
	var lost:=battle.area_root.get_node("ExperimentRecorder") as CampusAction
	battle.player.global_position=lost.global_position+Vector3.RIGHT
	check(lost.interact(battle.player,battle.session).success,"Retry fixture picks up actual unique recorder")
	var lost_id: String=battle.session.campus.recorder_instance
	var credits:=profile.credits
	await finish_world(false)
	check(profile.campus_chapter.recorder_revealed and not profile.campus_chapter.relays_returned and not profile.campus_chapter.recorder_returned and not profile.inventory.contains(lost_id) and profile.credits==credits,"Death preserves read knowledge but loses device and grants no chapter reward")
	check(CampusChapter.initial_facts(profile,&"street_district").stage=="relay","Unreturned relay work and recorder can be retried at fixed sites")
	# Start a new independent fixture; this is test setup, not free replacement gear.
	profile=profile_at_batch2();await start_world()
	check(battle.hud.slice_label.visible,"Actual chapter objective is visible in battle HUD")
	check(battle.session.campus.stage=="relay","New narrative starts at relays, not retired Q04")
	for name in ["CampusRelayOffice","CampusRelayRepair"]:
		var point:=battle.area_root.get_node(name) as CampusAction
		battle.player.global_position=point.global_position+Vector3.RIGHT
		check(point.interact(battle.player,battle.session).success,"Real relay work starts")
		point._process(1.0)
		point._health_changed(point.observed_health-.1,100)
		check(point.remaining==0,"Even fractional damage cancels relay work")
		point.interact(battle.player,battle.session)
		battle.player.global_position+=Vector3(10,0,0);point._process(1.0)
		check(point.remaining==0,"Leaving the interaction radius cancels relay work")
		battle.player.global_position=point.global_position+Vector3.RIGHT
		point.interact(battle.player,battle.session);point._process(4.0)
		var saved:=SortieCheckpoint.capture_world(battle)
		check(SortieCheckpoint.validate_world(saved,battle) and SortieCheckpoint.restore_world(saved,battle),"Partial chapter work restores to actual actor/session")
		check(point.remaining==8.0,"Saved timer does not restart")
		point._process(8.0)
	check(battle.session.campus.relays.size()==2 and not profile.campus_chapter.relays_returned,"Field work is not a settled base reward")
	var recorder:=battle.area_root.get_node("ExperimentRecorder") as CampusAction
	battle.player.global_position=recorder.global_position+Vector3.RIGHT
	var read:=recorder.interact(battle.player,battle.session)
	check(read.success and read.information.contains("Military") and read.information.contains("L-02A"),"Recorder immediately reveals project and branch log without decryption")
	check(not recorder.interact(battle.player,battle.session).success,"Unique recorder cannot be acquired twice")
	var item_id: String=battle.session.campus.recorder_instance
	check(battle.session.inventory.contains(item_id),"Real story device occupies carried inventory")
	var world:=SortieCheckpoint.capture_world(battle)
	check(SortieCheckpoint.restore_world(world,battle),"Picked recorder/facts/hidden device restore without duplicate")
	await finish_world(true)
	check(profile.campus_chapter.relays_returned and profile.campus_chapter.recorder_returned and not profile.inventory.contains(item_id),"One extraction can settle relay and recorder; device archived to contact record")
	check(CampusChapter.stage(profile.campus_chapter)=="power","Returned device produces engineering branch plan")
	await start_world()
	var control:=battle.area_root.get_node("L02BranchControl") as CampusAction
	battle.player.global_position=control.global_position+Vector3.RIGHT
	check(not control.confirm_power(),"Cannot bypass the explicit branch choice")
	check(control.interact(battle.player,battle.session).success and is_instance_valid(control.choice_layer),"Branch choice opens explicit real UI")
	control.choice_layer.get_node("PowerChoice").find_child("CancelBranch",true,false).pressed.emit()
	check(not battle.session.campus.power_cut and control.remaining==0,"Decline has no hidden branch or punishment")
	control.interact(battle.player,battle.session)
	control.choice_layer.get_node("PowerChoice").find_child("ConfirmBranch",true,false).pressed.emit()
	control._process(2.0)
	world=SortieCheckpoint.capture_world(battle)
	check(SortieCheckpoint.restore_world(world,battle) and control.remaining==4,"Confirmed partial branch work restores")
	control._process(4.0)
	check(battle.session.campus.power_cut and control.get_node("BranchBLight").light_energy==0 and control.get_node("BranchALight").light_energy>0,"Experimental indication switches off while shelter indication stays on")
	check(not control.get_node("ExperimentDisplay").material_override.emission_enabled,"Actual experiment device screen also goes dark")
	world=SortieCheckpoint.capture_world(battle)
	check(SortieCheckpoint.restore_world(world,battle) and control.get_node("BranchBLight").light_energy==0,"Actual branch visuals/facts survive suspended-world restore")
	# Commit a failed copy, preserving physical power but no task reward.
	var failed_session:=SortieCheckpoint.restore_session(SortieCheckpoint.session_data(battle.session))
	failed_session.fail()
	var failed_outcome:=SortieOutcome.create_from_session(failed_session)
	var failed_profile:=ProfileState.from_dict(profile.to_dict())
	var before_power_reward:=failed_profile.credits
	check(SortieOutcomeService.commit_outcome(failed_profile,failed_outcome)==OK and failed_profile.campus_chapter.branch_disconnected and not failed_profile.campus_chapter.power_returned and failed_profile.credits==before_power_reward,"Death after a real cut retains physical power state but not extraction reward")
	var retry:=CampusChapter.initial_facts(failed_profile,&"street_district")
	check(retry.stage=="power" and retry.power_cut and retry.power_confirmed,"Retry never silently restores experiment power; can finish by extracting")
	var published:=failed_profile.to_dict()
	check(SortieOutcomeService.commit_outcome(failed_profile,failed_outcome)==OK and failed_profile.to_dict()==published,"Repeated failed-result commit is idempotent")
	await finish_world(true)
	check(profile.campus_chapter.power_returned and not profile.campus_chapter.finished,"Power mission settles once but does not grant free final supplies")
	var worn:=profile.loadout.get_equipped_instance_id(LoadoutState.SLOT_ARMOR)
	var spare:=ItemInstance.new(&"armor.recon_shell_01");profile.inventory.add_item(spare)
	var before:=profile.to_dict()
	check(CampusChapter.submit_delivery("user://missing_chapter_dir/profile.json").error!=OK and profile.to_dict()==before,"Failed delivery save does not consume armor/ammo")
	check(CampusChapter.submit_delivery(PATH).error==OK,"Actual base delivery consumes available spare armor and ammo")
	check(profile.inventory.contains(worn) and not profile.inventory.contains(spare.instance_id),"Currently equipped armor never taken")
	check(profile.campus_chapter.delivered_armor and profile.campus_chapter.delivered_ammo==60,"Exact required quantities persisted")
	before=profile.to_dict()
	check(CampusChapter.submit_delivery(PATH).error!=OK and profile.to_dict()==before,"Double submission cannot take a second armor or ammo stack")
	await start_world();await finish_world(true)
	check(profile.campus_chapter.finished and SaveService.load_profile(PATH,false).campus_chapter.finished,"Final campus extraction closes chapter in real save")
	check(DeploymentPlan.STREET_MISSIONS.has(&"streets_recon"),"Free sorties remain available")
	SortieRuntime.clear_session();AudioDirector.shutdown_for_test();await get_tree().create_timer(.3).timeout
	print("CAMPUS_CHAPTER_TEST: ","PASS" if failures.is_empty() else "FAIL")
	get_tree().quit(0 if failures.is_empty() else 1)
