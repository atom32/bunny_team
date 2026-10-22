extends "res://scripts/player/forward_axis_retarget_modifier.gd"
## The old per-bone global-transform reflection also moved each joint origin.
## With the new hunched poses that compressed UpperChest by 4.5cm. Reflect
## rotations only, then rebuild the hierarchy with the target's rest offsets.
func _process_modification_with_delta(_delta: float) -> void:
	var sk:=get_skeleton()
	if not sk or _bone_indices.is_empty():return
	var originals: Array[Transform3D]=[]
	for i in sk.get_bone_count():originals.append(sk.get_bone_global_pose(i))
	for i in _bone_indices:
		var rest:=sk.get_bone_global_rest(i)
		var delta:=originals[i].basis*rest.basis.inverse()
		var desired:=FRONT_BACK_MIRROR*delta*FRONT_BACK_MIRROR*rest.basis
		var parent:=sk.get_bone_parent(i)
		var local:=desired if parent<0 else sk.get_bone_global_pose(parent).basis.inverse()*desired
		sk.set_bone_pose_position(i,sk.get_bone_rest(i).origin)
		sk.set_bone_pose_rotation(i,local.orthonormalized().get_rotation_quaternion())
		if sk.get_bone_name(i)==&"Character1_LeftFoot":
			_front_back_motion_alignment=(originals[i].origin.z-rest.origin.z)*(sk.get_bone_global_pose(i).origin.z-rest.origin.z)
