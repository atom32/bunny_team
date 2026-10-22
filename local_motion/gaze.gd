extends SkeletonModifier3D
## Aim from the model's neutral facing, not an assumed bone-local -Z axis.
var rig: Node3D
var alignment := 1.0

func _process_modification_with_delta(_delta: float) -> void:
	if not is_instance_valid(rig) or not rig.has_weapon():return
	if rig.motion_mode in ["TakeGun","PutGun","Holstered","Dodge"]:return
	var sk:=get_skeleton();var index:=sk.find_bone("Character1_Head")
	var pose:=sk.get_bone_global_pose(index)
	var rest:=sk.get_bone_global_rest(index)
	var body:=rig.get_parent() as Node3D
	var neutral:=sk.global_basis.orthonormalized().inverse()*body.global_basis.orthonormalized()*Vector3.FORWARD
	var forward: Vector3=(pose.basis*rest.basis.inverse()*neutral).normalized()
	var desired: Vector3=(sk.to_local(rig.aim_target.global_position)-pose.origin).normalized()
	pose.basis=Basis(Quaternion(forward,desired))*pose.basis
	sk.set_bone_global_pose(index,pose)
	alignment=(pose.basis*rest.basis.inverse()*neutral).normalized().dot(desired)
