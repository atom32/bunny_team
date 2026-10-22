extends "res://tests/seat_moment_test.gd"
const SCENE:="res://scenes/presentation/slice/rescue_return.tscn"
var contact_error:=0.0
var door_clearance:=100.0
var finger_up:=1.0
var palm_facing:=1.0
var worst:={}

func until(wanted: String) -> bool:
	for tick in 3600:
		var before: Vector3=room.actor.position
		room._process(1.0/60)
		if before.distance_to(room.actor.position)>.04:check(false,"scene movement must not teleport between story beats");return false
		var start:=Vector2(room.door.position.x,room.door.position.z)
		var end: Vector3=room.door.to_global(Vector3(1.4,0,0))
		for at: Vector3 in [room.actor.position,room.guest.position]:
			var point:=Vector2(at.x,at.z)
			door_clearance=minf(door_clearance,point.distance_to(Geometry2D.get_closest_point_to_segment(point,start,Vector2(end.x,end.z))))
		if room.grip>.95:
			var sk: Skeleton3D=room.actor.character_skeleton
			var error:=sk.to_global(CONTACT.palm(sk,room.hand_side)).distance_to(room.hand_goal)
			if error>contact_error:
				worst={"phase":room.phase,"side":room.hand_side,"goal":str(room.hand_goal),"actual":str(sk.to_global(CONTACT.palm(sk,room.hand_side))),"actor":str(room.actor.position),"shoulder":str(sk.to_global(sk.get_bone_global_pose(sk.find_bone("Character1_"+room.hand_side+"Arm")).origin))}
			contact_error=maxf(contact_error,error)
			finger_up=minf(finger_up,(sk.global_basis*CONTACT.hand_frame(sk,room.hand_side).y).normalized().dot(Vector3.UP))
			var normal: Vector3=room.door.global_basis.z*(1 if room.hand_side=="Left" else -1)
			palm_facing=minf(palm_facing,(sk.global_basis*CONTACT.hand_frame(sk,room.hand_side).z).normalized().dot(normal))
		if room.phase==wanted:return true
	check(false,"physical return beat did not reach "+wanted);return false

func _run() -> void:
	capture="--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless"
	get_tree().current_scene=null;GameState.presentation_enabled=true
	GameLanguage.set_language("en" if "--english" in OS.get_cmdline_user_args() else "zh_CN",false)
	var profile:=ProfileRuntime.new_profile()
	room=load(SCENE).instantiate();get_tree().root.add_child(room);get_tree().current_scene=room;room.set_process(false)
	check(room.phase=="locked" and not room.guest.visible and not room.next_button.visible,"unearned rescue cannot invent a returned survivor")
	room.free();get_tree().current_scene=null
	var owner=load("res://tests/maintenance_test.gd").new() # Explicit fixture, not an earned campaign.
	profile=owner.fixture();owner.free()
	profile.maintenance_rescued=true
	var before:=JSON.stringify(profile.to_dict())
	room=load(SCENE).instantiate();get_tree().root.add_child(room);get_tree().current_scene=room;room.set_process(false)
	var sk: Skeleton3D=room.actor.character_skeleton
	var poses:=[]
	for i in sk.get_bone_count():poses.append([sk.get_bone_rest(i),sk.get_bone_pose_position(i),sk.get_bone_pose_scale(i)])
	check(await until("intro"),"guest actually approaches and stops while the door drifts closed")
	check(room.guest.position.z>3.3 and is_equal_approx(room.door.rotation.y,-.9),"stop remains outside the visible doorway")
	await shot("rescue_01_wait")
	for i in room.FIRST.size():await click(room.next_button)
	check(await until("crossing"),"heroine walks back around the leaf, reaches and opens it")
	check(room.grip==1 and room.actor.position.distance_to(Vector3(1.1,0,2.05))<.03,"door is held from the hinge side rather than through the actor")
	await shot("rescue_02_hold")
	check(await until("inside"),"survivor walks across the threshold before the grip is released")
	check(room.guest_walked>3.1 and room.guest.position.z<.65 and room.grip==1,"real guest displacement crosses the room while the heroine continues holding")
	await shot("rescue_03_inside")
	for i in room.INSIDE.size():await click(room.next_button)
	check(await until("ending"),"visible catch engages, hand releases, and heroine walks back inside")
	check(room.latched and room.grip==0 and is_equal_approx(room.latch.rotation.y,PI/2) and is_equal_approx(room.door.rotation.y,-1.2),"open door is left on the actual catch, not the invisible held hand")
	check(room.actor.position.distance_to(Vector3(2.9,0,.6))<.04,"heroine actually returns beside the survivor")
	check(contact_error<.06,"actual palm follows moving door/catch within six centimeters: "+str(contact_error))
	check(finger_up>.95,"holding uses a flat upward hand rather than a hanging curled wrist: "+str(finger_up))
	check(palm_facing>.95,"mirrored hand frame keeps the palm, not its back, against the leaf: "+str(palm_facing))
	check(door_clearance>.18,"both body roots remain clear of the moving leaf: "+str(door_clearance))
	for i in sk.get_bone_count():check(sk.get_bone_rest(i)==poses[i][0] and sk.get_bone_pose_position(i).is_equal_approx(poses[i][1]) and sk.get_bone_pose_scale(i).is_equal_approx(poses[i][2]),"original bone rest, translations and scales remain intact")
	await shot("rescue_04_together")
	for i in room.LAST.size():
		check(room.dialogue.get_combined_minimum_size().y<=room.dialogue.size.y,"ending text fits");await click(room.next_button)
	check(room.phase=="done" and room.dialogue.text==tr(room.LAST[-1]),"final emotional response remains beside replay and return")
	check(before==JSON.stringify(profile.to_dict()),"door scene cannot grant rewards, progress or seen flags")
	await click(room.exits.get_node("ReplayRescue"));check(room.phase=="arrival" and not room.latched,"replay resets only actors and props")
	get_tree().current_scene=null;room.free();room=null
	print("WORST_CONTACT ",worst)
	AudioDirector.shutdown_for_test()
	print("RESCUE_RETURN_TEST: %s (%d checks) contact=%f clearance=%f"%["PASS" if failures.is_empty() else "FAIL",checks,contact_error,door_clearance]);get_tree().quit(0 if failures.is_empty() else 1)
