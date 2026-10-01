extends RefCounted
## Sample a real MotusMan clip onto Bunny, accounting for forward axis and A/T rest poses.
## Static presentation only; does not replace gameplay animation or imported resources.
static func apply(target: Skeleton3D, clip_name: String, sample_time: float = 0.5) -> int:
	var source := sample_source(target.get_parent(),clip_name,sample_time)
	var driver := source.find_child("Skeleton3D", true, false) as Skeleton3D
	target.reset_bone_poses()
	var desired_globals := {}
	for index in target.get_bone_count():
		var bone_name := target.get_bone_name(index)
		var src := driver.find_bone(bone_name)
		var rest := target.get_bone_global_rest(index).basis
		var reference := rest
		# MotusMan has a T reference; Bunny was authored in an A pose.
		for side in ["Left", "Right"]:
			var upper := target.find_bone("Character1_" + side + "Arm")
			var ancestor := index
			while ancestor >= 0 and ancestor != upper: ancestor = target.get_bone_parent(ancestor)
			if ancestor == upper:
				var elbow := target.find_bone("Character1_" + side + "ForeArm")
				var axis := (target.get_bone_global_rest(elbow).origin-target.get_bone_global_rest(upper).origin).normalized()
				var horizontal := Vector3.LEFT if side == "Left" else Vector3.RIGHT
				reference = Basis(Quaternion(axis,horizontal)) * rest
		var desired := reference
		if src >= 0:
			var forward := Basis(Vector3.UP, PI)
			desired = forward * driver.get_bone_global_pose(src).basis * driver.get_bone_global_rest(src).basis.inverse() * forward.inverse() * reference
		desired_globals[index] = desired
		var parent := target.get_bone_parent(index)
		var local: Basis = desired if parent < 0 else (desired_globals[parent] as Basis).inverse() * desired
		target.set_bone_pose_rotation(index, local.get_rotation_quaternion())
	print("MCO_POSE_RETARGET clip=", clip_name, " bones=",desired_globals.size())
	source.free()
	return desired_globals.size()

static func sample_source(parent: Node, clip_name: String, sample_time: float, hide_meshes := true) -> Node3D:
	var source := load("res://assets/animations/mocap_online_rifle/MotusMan_v55.fbx").instantiate() as Node3D
	parent.add_child(source)
	if hide_meshes:
		for mesh in source.find_children("*", "MeshInstance3D", true, false):
			mesh.get_parent().remove_child(mesh)
			mesh.free()
	var driver := source.find_child("Skeleton3D", true, false) as Skeleton3D
	var prefix := "Character1_" if hide_meshes else ""
	if hide_meshes:
		for index in driver.get_bone_count():
			driver.set_bone_name(index, prefix + driver.get_bone_name(index))
	var clip := load("res://assets/animations/mocap_online_rifle/" + clip_name + ".tres").duplicate(true) as Animation
	for index in range(clip.get_track_count()-1, -1, -1):
		var name := prefix + String(clip.track_get_path(index).get_subname(0))
		if driver.find_bone(name) < 0: clip.remove_track(index)
		else: clip.track_set_path(index, NodePath(".:" + name))
	var animator := AnimationPlayer.new()
	animator.root_node = NodePath("..")
	driver.add_child(animator)
	var library := AnimationLibrary.new()
	library.add_animation("Pose", clip)
	animator.add_animation_library("",library)
	animator.play("Pose")
	animator.seek(sample_time, true)
	animator.pause()
	return source
