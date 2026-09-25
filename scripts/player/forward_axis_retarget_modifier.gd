class_name ForwardAxisRetargetModifier
extends SkeletonModifier3D

const FRONT_BACK_MIRROR := Basis(Vector3.RIGHT, Vector3.UP, Vector3.FORWARD)

var _bone_names := PackedStringArray()
var _bone_indices := PackedInt32Array()
var _front_back_motion_alignment := 0.0


func configure(bone_names: PackedStringArray) -> void:
	_bone_names = bone_names
	_cache_bones()


func get_front_back_motion_alignment() -> float:
	return _front_back_motion_alignment


func _skeleton_changed(_old_skeleton: Skeleton3D, _new_skeleton: Skeleton3D) -> void:
	_cache_bones()


func _process_modification_with_delta(_delta: float) -> void:
	var target := get_skeleton()
	if not target or _bone_indices.is_empty():
		return
	var source_poses: Array[Transform3D] = []
	for bone_index in _bone_indices:
		source_poses.append(target.get_bone_global_pose(bone_index))
	for pose_index in _bone_indices.size():
		var bone_index := _bone_indices[pose_index]
		var rest := target.get_bone_global_rest(bone_index)
		var model_delta := source_poses[pose_index] * rest.affine_inverse()
		var mirrored_delta := Transform3D(
			FRONT_BACK_MIRROR * model_delta.basis * FRONT_BACK_MIRROR,
			FRONT_BACK_MIRROR * model_delta.origin
		)
		var corrected_pose := mirrored_delta * rest
		target.set_bone_global_pose(bone_index, corrected_pose)
		if target.get_bone_name(bone_index) == &"Character1_LeftFoot":
			var source_z := source_poses[pose_index].origin.z - rest.origin.z
			var corrected_z := corrected_pose.origin.z - rest.origin.z
			_front_back_motion_alignment = source_z * corrected_z


func _cache_bones() -> void:
	_bone_indices.clear()
	var target := get_skeleton()
	if not target:
		return
	for bone_name in _bone_names:
		var bone_index := target.find_bone(bone_name)
		if bone_index >= 0:
			_bone_indices.append(bone_index)
