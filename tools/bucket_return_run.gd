extends "res://tools/story_finish_run.gd"
## Actual earned rescue -> normal BOOT -> live water route -> optional atomic scene.
const BUCKET_SCENE:="res://scenes/presentation/slice/bucket_return.tscn"

func _ready() -> void:
	get_tree().create_timer(600,true).timeout.connect(func():check(false,"bucket route deadline, no forced focus recovery");finish())
	_run.call_deferred()

func _run() -> void:
	tree=get_tree();tree.current_scene=null
	GameLanguage.set_language("en" if "--english" in OS.get_cmdline_user_args() else "zh_CN",true)
	var profile:=ProfileRuntime.get_profile()
	if "--read" in OS.get_cmdline_user_args():
		check(profile.successful_sorties==_expected_returns(8) and profile.waterworks_memory=="water_public" and profile.sortie_checkpoint.is_empty(),"independent process retains actual safe water return, no scene-only progress")
		finish();return
	check(SaveService.save_exists() and profile.successful_sorties==_expected_returns(7) and profile.maintenance_rescued and profile.waterworks_memory.is_empty(),"input is actual prior rescue, no manufactured water result")
	evidence["method"]="Actual earned seven-return profile, normal BOOT/Continue/Main Story, live water AI/ammo, physical bypass and extraction, optional debrief button, both carried-bucket choices, skip/replay/Rest; no progress or inventory grants"
	evidence["input_sha256"]=FileAccess.get_sha256(SaveService.DEFAULT_SAVE_PATH)
	if not failures.is_empty():finish();return
	tree.change_scene_to_file("res://scenes/presentation/slice/boot.tscn");await _frames(10)
	check(TranslationServer.get_locale()==("en" if "--english" in OS.get_cmdline_user_args() else "zh_CN"),"real BOOT preserves saved language")
	if tree.current_scene.opening:await _click(_button("SKIP OPENING  /  ENTER"))
	await _click(_button("CONTINUE / BASE"))
	if not await _wait_scene("res://scenes/presentation/slice/hideout.tscn"):check(false,"normal continue reaches base");finish();return
	if not await water():check(false,"actual water and bucket route incomplete")
	finish()

func return_home(exit: ExtractionPoint,_ending:=false) -> bool:
	release();var session: SortieSession=battle.session
	route_results.append({"mission":String(session.mission_id),"shots":fired,"kills":session.enemies_defeated,"health":battle.player.health})
	check(exit.interact(battle.player,session).success,"actual physical water extraction")
	if not await _wait_scene("res://scenes/result/result.tscn"):check(false,"water debrief transition");return false
	await _capture("bucket_debrief_entry")
	var entry:=tree.current_scene.find_child("WaterBucketReturn",true,false) as Button
	check(entry!=null and ProfileRuntime.get_profile().waterworks_memory.is_empty(),"optional debrief entry offered before settlement, never faked memory")
	if not entry:return false
	await _click(entry)
	if not await _wait_scene(BUCKET_SCENE):check(false,"atomic optional return scene");return false
	check(ProfileRuntime.get_profile().successful_sorties==_expected_returns(8) and ProfileRuntime.get_profile().waterworks_memory=="water_public" and ProfileRuntime.get_profile().sortie_checkpoint.is_empty(),"actual supplies and delivery are saved before presentation")
	var saved:=FileAccess.get_sha256(SaveService.DEFAULT_SAVE_PATH)
	for choice in ["rest","door"]:
		if not await phase_wait("intro"):return false
		var room=tree.current_scene
		check(room.held and room.eligible,"real walk reaches intro holding original bucket")
		await _capture("bucket_carry_"+choice)
		for i in room.PUBLIC_LINES.size():await _click(room.next_button)
		await _click(room.choices.get_node("ChoiceRest" if choice=="rest" else "ChoiceDoor"))
		if choice=="door":
			if not await phase_wait("hesitate"):return false
			check(room.held and room.actor.position.z>2.7,"actual door detour carries bucket, no teleport")
			await _capture("bucket_called_back")
			for i in room.DOOR_LINES.size():await _click(room.next_button)
		if not await phase_wait("ending"):return false
		check(room.motion.seated and not room.held and room.cup.position.is_equal_approx(room.bucket_home),"actual place and seating complete before final dialogue")
		await _capture("bucket_seated_"+choice)
		for i in room.LAST_LINES.size():await _click(room.next_button)
		check(room.phase=="done" and room.dialogue.text==tr(room.LAST_LINES[-1]),"last line retained with normal exit/replay UI")
		if choice=="rest":await _click(room.exits.get_node("ReplayBucket"))
	await _click(tree.current_scene.exits.get_node("BucketReturn"))
	if not await _wait_scene("res://scenes/presentation/slice/hideout.tscn"):check(false,"bucket ending returns to base");return false
	check(tree.current_scene.section=="Rest" and saved==FileAccess.get_sha256(SaveService.DEFAULT_SAVE_PATH),"both choices and replay leave durable profile bytes unchanged")
	await _click(tree.current_scene.find_child("OpenBucketMoment",true,false))
	if not await _wait_scene(BUCKET_SCENE):check(false,"Rest replay from earned profile");return false
	await _click(tree.current_scene.screen.find_child("SkipBucketMoment",true,false))
	if not await _wait_scene("res://scenes/presentation/slice/hideout.tscn"):check(false,"early skip safely returns to Rest");return false
	check(saved==FileAccess.get_sha256(SaveService.DEFAULT_SAVE_PATH) and FinaleStory.next_mission(ProfileRuntime.get_profile())==BlockadeStory.MISSION,"skip grants nothing and next main operation stays checkpoint")
	await _capture("bucket_rest_replay")
	return failures.is_empty()

func finish() -> void:
	if "--read" not in OS.get_cmdline_user_args():check(route_results.size()==1 and ProfileRuntime.get_profile().successful_sorties==_expected_returns(8),"complete earned bucket route required, not a partial PASS")
	release();evidence["checks"]=checks;evidence["routes"]=route_results;evidence["failures"]=failures
	var file:=FileAccess.open(out.path_join("bucket_earned.json"),FileAccess.WRITE);file.store_string(JSON.stringify(evidence,"\t"));file.close()
	AudioDirector.shutdown_for_test();print("BUCKET_EARNED_RUN: %s (%d checks)"%["PASS" if failures.is_empty() else "FAIL",checks]);tree.quit(0 if failures.is_empty() else 1)
