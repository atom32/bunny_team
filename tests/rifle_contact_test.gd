extends Node
var failures: Array[String] = []

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var player: PlayerController = load("res://scenes/player/player.tscn").instantiate()
	player.preview_mode=true
	add_child(player)
	for tick in 4: await get_tree().physics_frame
	player.set_physics_process(false)
	player.animation_tree.active=false
	player.retarget_modifier.active=false
	for modifier in player.character_skeleton.find_children("*","SkeletonModifier3D",true,false): modifier.active=false
	var sk := player.character_skeleton
	var rifle: Node3D = load("res://assets/weapons/mocap_m4/M4_Rifle_01.fbx").instantiate()
	add_child(rifle)
	var contact := preload("res://scripts/presentation/bunny_master/rifle_contact.gd")
	for clip in ["W2_Stand_Relaxed_Idle_v2","W2_Stand_Aim_Idle_v2","W2_Stand_Aim_To_Relaxed","W2_Walk_Aim_F_Loop_IPC","W2_Jog_Aim_F_Loop_IPC"]:
		for time in [.1,.5,.9]:
			preload("res://scripts/presentation/bunny_master/rifle_pose.gd").apply(sk,clip,time)
			var upper := sk.find_bone("Character1_LeftArm")
			var lower := sk.find_bone("Character1_LeftForeArm")
			var wrist := sk.find_bone("Character1_LeftHand")
			var lengths := Vector2(sk.get_bone_global_pose(upper).origin.distance_to(sk.get_bone_global_pose(lower).origin),sk.get_bone_global_pose(lower).origin.distance_to(sk.get_bone_global_pose(wrist).origin))
			var local_positions: Array[Vector3] = []
			for bone in sk.get_bone_count(): local_positions.append(sk.get_bone_pose_position(bone))
			contact.fit(sk,rifle)
			var after := Vector2(sk.get_bone_global_pose(upper).origin.distance_to(sk.get_bone_global_pose(lower).origin),sk.get_bone_global_pose(lower).origin.distance_to(sk.get_bone_global_pose(wrist).origin))
			var error := sk.to_global(contact.palm(sk,"Left")).distance_to(rifle.global_transform*contact.SUPPORT)
			if error>.001 or after.distance_to(lengths)>.0001 or not sk.get_bone_global_pose(wrist).basis.is_finite():
				failures.append("%s at %.1f: contact %.5f length drift %.5f"%[clip,time,error,after.distance_to(lengths)])
			for bone in sk.get_bone_count():
				if sk.get_bone_pose_position(bone).distance_to(local_positions[bone])>.0001 or not sk.get_bone_global_pose(bone).basis.is_finite():
					failures.append("%s at %.1f stretched/invalid bone %s"%[clip,time,sk.get_bone_name(bone)])
	player.queue_free()
	rifle.queue_free()
	await get_tree().process_frame
	AudioDirector.shutdown_for_test()
	print("RIFLE_CONTACT_TEST failures=",failures)
	print("RIFLE_CONTACT_TEST ", "PASS" if failures.is_empty() else "FAIL")
	get_tree().quit(0 if failures.is_empty() else 1)
