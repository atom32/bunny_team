extends "res://tests/seat_moment_test.gd"
## Controlled scene fixtures; earned normal-menu entry is checked separately.
var metrics: Array=[]

func advance_until(wanted: String) -> bool:
	var error:=0.0;var length_error:=0.0;var continuity:=0.0
	var sk: Skeleton3D=room.actor.character_skeleton
	for tick in 2400:
		var old: Vector3=room.actor.position;room._process(1.0/60)
		continuity=maxf(continuity,old.distance_to(room.actor.position))
		if room.held and room.grip_weight>.999 and not room.bucket_goals.is_empty():
			for side in ["Right","Left"]:error=maxf(error,sk.to_global(CONTACT.palm(sk,side)).distance_to(room.bucket_goals[side]))
		for bone in sk.get_bone_count():
			var parent:=sk.get_bone_parent(bone)
			if parent>=0:length_error=maxf(length_error,absf(sk.get_bone_global_pose(bone).origin.distance_to(sk.get_bone_global_pose(parent).origin)-sk.get_bone_rest(bone).origin.length()))
		if room.phase==wanted:
			check(error<.04,"both real palms remain on side handles while carrying / "+wanted+" max="+str(error))
			check(length_error<.0001 and continuity<.06,"no bone stretch or actor teleport / "+wanted)
			metrics.append({"phase":wanted,"palm_error":error,"bone_length_error":length_error,"max_position_step":continuity})
			return true
	check(false,"scene failed to reach "+wanted+" from "+str(room.phase));return false

func lines(count: int) -> void:
	for i in count:
		check(room.dialogue.get_combined_minimum_size().y<=room.dialogue.size.y,"subtitle fits current language")
		await click(room.next_button)

func _run() -> void:
	capture="--capture" in OS.get_cmdline_user_args()
	GameLanguage.set_language("en" if "--english" in OS.get_cmdline_user_args() else "zh_CN",false)
	get_tree().current_scene=null
	var profile:=ProfileRuntime.new_profile();GameState.presentation_enabled=true
	room=load("res://scenes/presentation/slice/bucket_return.tscn").instantiate();get_tree().root.add_child(room);room.set_process(false)
	check(not room.eligible and room.phase=="locked" and not room.held,"fresh profile cannot invent a safe water return")
	room.free();room=null
	for water in ["water_public","water_tanker"]:
		# Explicit previous-return fixture, not an earned-route claim.
		profile.first_mission_completed=true;profile.waterworks_memory=water
		for choice in ["rest","door"]:
			var before:=JSON.stringify(profile.to_dict());var saved:=FileAccess.get_sha256(SaveService.DEFAULT_SAVE_PATH)
			room=load("res://scenes/presentation/slice/bucket_return.tscn").instantiate();get_tree().root.add_child(room);get_tree().current_scene=room;room.set_process(false)
			var sk: Skeleton3D=room.actor.character_skeleton
			var rests:=[];var positions:=[];var scales:=[]
			for bone in sk.get_bone_count():rests.append(sk.get_bone_rest(bone));positions.append(sk.get_bone_pose_position(bone));scales.append(sk.get_bone_pose_scale(bone))
			check(room.eligible and room.cup.get_node("WaterSurface").visible==(water=="water_public"),"earned branch selects matching visible prop, not new supplies")
			if not await advance_until("intro"):_finish();return
			await shot("bucket_"+water+"_"+choice+"_carry")
			check(room.actor.position.distance_to(Vector3(3.7,0,2.8))>1,"real carry approach travels from entrance")
			await lines(room.PUBLIC_LINES.size())
			check(room.phase=="choice" and room.held,"choice waits with bucket held")
			var carried_height: float=room.cup.position.y
			await click(room.choices.get_node("ChoiceRest" if choice=="rest" else "ChoiceDoor"))
			if choice=="door":
				if not await advance_until("hesitate"):_finish();return
				check(room.actor.position.z>2.7 and room.held,"teasing choice actually walks back toward door carrying bucket")
				await shot("bucket_"+water+"_door_wait")
				await lines(room.DOOR_LINES.size())
			if not await advance_until("ending"):_finish();return
			check(carried_height-room.cup.position.y>.07,"placement actually lowers the bucket onto support, not a stationary hold")
			check(not room.held and room.motion.seated and room.cup.position.is_equal_approx(room.bucket_home),"both choices place bucket on stool then actually sit")
			check(is_equal_approx(room.cup.position.y-.17,room.bucket_home.y-.195+.025),"bucket bottom is supported by actual stool top")
			await shot("bucket_"+water+"_"+choice+"_seated")
			for bone in sk.get_bone_count():check(sk.get_bone_rest(bone)==rests[bone] and sk.get_bone_pose_position(bone).is_equal_approx(positions[bone]) and sk.get_bone_pose_scale(bone).is_equal_approx(scales[bone]),"original rest, local translations and scales preserved")
			await lines(room.LAST_LINES.size())
			check(room.phase=="done" and room.dialogue.text==tr(room.LAST_LINES[-1]),"final callback remains visible beside exit and replay")
			check(before==JSON.stringify(profile.to_dict()) and saved==FileAccess.get_sha256(SaveService.DEFAULT_SAVE_PATH),"carry, detour and rest never grant cargo or mutate profile/save")
			await click(room.exits.get_node("ReplayBucket"));check(room.phase=="approach" and room.held,"replay resets presentation only")
			get_tree().paused=true;room.set_process(true);var frozen: float=room.phase_elapsed;await get_tree().process_frame;check(room.phase_elapsed==frozen,"normal pause freezes carry scene");get_tree().paused=false;room.set_process(false)
			get_tree().current_scene=null;room.free();room=null
	var hub=load("res://scenes/presentation/slice/hideout.tscn").instantiate();get_tree().root.add_child(hub);get_tree().current_scene=hub;hub.show_section("Rest")
	await get_tree().process_frame
	check(hub.find_child("OpenBucketMoment",true,false)!=null,"safe water return exposes ordinary Rest replay entry")
	await click(hub.find_child("OpenBucketMoment",true,false))
	check(await _wait("res://scenes/presentation/slice/bucket_return.tscn"),"real Rest button opens the physical scene")
	room=get_tree().current_scene
	await click(room.screen.find_child("SkipBucketMoment",true,false))
	check(await _wait("res://scenes/presentation/slice/hideout.tscn") and get_tree().current_scene.section=="Rest","early skip returns safely to quarters")
	_finish()

func _finish() -> void:
	var out:=OS.get_environment("BUNNY_EVIDENCE")
	if not out.is_empty():
		var file:=FileAccess.open(out.path_join("bucket_return.json"),FileAccess.WRITE);file.store_string(JSON.stringify({"scope":"controlled fixture, original heroine, side-handle contact and normal viewport UI; not human acceptance","checks":checks,"metrics":metrics,"failures":failures},"\t"));file.close()
	AudioDirector.shutdown_for_test();print("BUCKET_RETURN_TEST: %s (%d checks)"%["PASS" if failures.is_empty() else "FAIL",checks]);get_tree().quit(0 if failures.is_empty() else 1)
