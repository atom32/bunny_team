extends "res://scripts/presentation/artoria_bunny/hand_modifier.gd"
## Fit after torso modifiers have evaluated, before the final palm solve.
var rig: Node3D

func _process_modification_with_delta(delta: float) -> void:
	# A newly mounted rifle has not received its first controller pose yet.
	# Do not fit its temporary model-origin transform to the standing wrists.
	if not is_instance_valid(rig) or not rig._has_neutral_pose:return
	var saved:={}
	var weights:={"Left":0.0,"Right":0.0}
	if is_instance_valid(rig):weights={"Left":rig.free_left_weight,"Right":rig.free_right_weight}
	var skeleton:=get_skeleton()
	for side: String in weights:
		if weights[side]<=0:continue
		for i in skeleton.get_bone_count():
			var name:=String(skeleton.get_bone_name(i))
			if name.begins_with("Character1_"+side+"Hand") or name in ["Character1_"+side+"Shoulder","Character1_"+side+"Arm","Character1_"+side+"ForeArm"]:
				saved[i]={"position":skeleton.get_bone_pose_position(i),"rotation":skeleton.get_bone_pose_rotation(i),"scale":skeleton.get_bone_pose_scale(i),"weight":weights[side]}
	if weights.Left>=1 and weights.Right>=1:return
	if is_instance_valid(rig) and rig.has_weapon():
		var sk:=get_skeleton()
		var original: Vector3=rig.weapon_pose_root.global_position
		for iteration in 8:
			var adjusted:=false
			for side in ["Right","Left"]:
				if weights[side]>=1:continue
				var arm:=sk.find_bone("Character1_"+side+"Arm")
				var forearm:=sk.find_bone("Character1_"+side+"ForeArm")
				var hand:=sk.find_bone("Character1_"+side+"Hand")
				var shoulder:=sk.to_global(sk.get_bone_global_pose(arm).origin)
				var reach:=shoulder.distance_to(sk.to_global(sk.get_bone_global_pose(forearm).origin))+sk.to_global(sk.get_bone_global_pose(forearm).origin).distance_to(sk.to_global(sk.get_bone_global_pose(hand).origin))-.065
				var goal: Vector3=rig.primary_grip.global_position if side=="Right" else rig.support_grip.global_position+rig.weapon_pose_root.global_basis.orthonormalized()*rig.authored_reload_delta
				var gap:=goal-shoulder
				if gap.length()>reach:
					rig.weapon_pose_root.global_position-=gap.normalized()*(gap.length()-reach)
					adjusted=true
			if not adjusted:break
		rig.max_weapon_fit_offset=maxf(rig.max_weapon_fit_offset,original.distance_to(rig.weapon_pose_root.global_position))
		rig.right_hand_target.global_position=rig.primary_grip.global_position
		rig.left_hand_target.global_position=rig.support_grip.global_position+rig.weapon_pose_root.global_basis.orthonormalized()*rig.authored_reload_delta
	super._process_modification_with_delta(delta)
	for i: int in saved:
		var frame: Dictionary=saved[i]
		skeleton.set_bone_pose_position(i,frame.position)
		skeleton.set_bone_pose_rotation(i,skeleton.get_bone_pose_rotation(i).slerp(frame.rotation,frame.weight))
		skeleton.set_bone_pose_scale(i,frame.scale)
