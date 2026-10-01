extends SkeletonModifier3D
## Fit palms, not wrists, to authored weapon contact markers.
var weapon: Node3D
var primary_target: Node3D
var support_target: Node3D
var reload_weight := 0.0
const CONTACT := preload("res://scripts/presentation/bunny_master/rifle_contact.gd")

func _process_modification_with_delta(_delta: float) -> void:
	if not is_instance_valid(weapon) or not is_instance_valid(primary_target) or not is_instance_valid(support_target): return
	var sk := get_skeleton()
	var weapon_basis := sk.global_basis.orthonormalized().inverse()*weapon.global_basis.orthonormalized()
	for side in ["Right","Left"]:
		var prefix: String = "Character1_"+side+"Hand"
		var wrist := sk.find_bone(prefix)
		var rest := sk.get_bone_global_rest(wrist)
		var middle := sk.get_bone_global_rest(sk.find_bone(prefix+"Middle1")).origin
		var index := sk.get_bone_global_rest(sk.find_bone(prefix+"Index1")).origin
		var pinky := sk.get_bone_global_rest(sk.find_bone(prefix+"Pinky1")).origin
		var fingers := rest.origin.direction_to(middle)
		var rest_frame := CONTACT.frame(fingers,(index-pinky).normalized().cross(fingers))
		var goal_fingers := Vector3(0,.25,-1).normalized() if side=="Right" else Vector3(.75,0,-.66).normalized()
		var goal_normal := Vector3.LEFT if side=="Right" else Vector3.DOWN
		var local_frame := CONTACT.frame(goal_fingers,goal_normal)
		if side=="Left":
			local_frame=Basis(local_frame.get_rotation_quaternion().slerp(CONTACT.frame(Vector3(.95,-.3,0).normalized(),Vector3.FORWARD).get_rotation_quaternion(),reload_weight))
		var goal_frame := weapon_basis*local_frame
		var hand_basis := goal_frame*rest_frame.inverse()*rest.basis
		var palm_local := rest.affine_inverse()*rest.origin.lerp(middle,.55)
		var target := primary_target if side=="Right" else support_target
		var wrist_target := sk.to_local(target.global_position)-hand_basis*palm_local
		CONTACT.solve_arm(sk,side,wrist_target,hand_basis)
		var hand := sk.get_bone_global_pose(wrist)
		for finger in ["Index","Middle","Ring","Pinky","Thumb"]:
			var parent_pose := hand
			var parent_rest := rest
			for joint in range(1,4):
				var bone := sk.find_bone(prefix+finger+str(joint))
				var bone_rest := sk.get_bone_global_rest(bone)
				var posed := parent_pose*parent_rest.affine_inverse()*bone_rest
				var degrees: float = [25.0,65.0,45.0][joint-1]
				if finger=="Index" and side=="Right": degrees=[0.0,5.0,5.0][joint-1]
				if finger=="Thumb": degrees=[10.0,20.0,15.0][joint-1]
				posed.basis=Basis(goal_frame.x,deg_to_rad(degrees if side=="Right" else -degrees))*posed.basis
				sk.set_bone_global_pose(bone,posed)
				parent_pose=posed
				parent_rest=bone_rest
		if side=="Right" and weapon.primary_thumb_contact!=Vector3.ZERO:
			var first := sk.find_bone(prefix+"Thumb1")
			var second := sk.find_bone(prefix+"Thumb2")
			var third := sk.find_bone(prefix+"Thumb3")
			var thumb := sk.get_bone_global_pose(third)
			var rest_third := sk.get_bone_global_rest(third)
			var rest_direction := rest_third.basis.inverse()*(rest_third.origin-sk.get_bone_global_rest(second).origin).normalized()
			var basis := Basis(Quaternion((thumb.basis*rest_direction).normalized(),weapon_basis*Vector3(0,-.1,-1).normalized()))*thumb.basis
			CONTACT.solve_chain(sk,first,second,third,sk.to_local(weapon.global_transform*weapon.primary_thumb_contact),basis)
		if side=="Left" and weapon.support_finger_contacts.size()==4:
			for finger_index in 4:
				var finger: String = ["Index","Middle","Ring","Pinky"][finger_index]
				var first := sk.find_bone(prefix+finger+"1")
				var second := sk.find_bone(prefix+finger+"2")
				var third := sk.find_bone(prefix+finger+"3")
				var pose := sk.get_bone_global_pose(third)
				var rest_third := sk.get_bone_global_rest(third)
				var rest_direction := rest_third.basis.inverse()*(rest_third.origin-sk.get_bone_global_rest(second).origin).normalized()
				var closed_basis := Basis(Quaternion((pose.basis*rest_direction).normalized(),weapon_basis*Vector3.DOWN))*pose.basis
				var target_position := sk.to_local(weapon.global_transform*weapon.support_finger_contacts[finger_index])
				var basis := Basis(pose.basis.get_rotation_quaternion().slerp(closed_basis.get_rotation_quaternion(),1.0-reload_weight))
				CONTACT.solve_chain(sk,first,second,third,pose.origin.lerp(target_position,1.0-reload_weight),basis)
		if side=="Left" and weapon.support_thumb_contact!=Vector3.ZERO:
			var thumb1 := sk.find_bone(prefix+"Thumb1")
			var thumb2 := sk.find_bone(prefix+"Thumb2")
			var thumb3 := sk.find_bone(prefix+"Thumb3")
			var thumb := sk.get_bone_global_pose(thumb3)
			var contact_target := sk.to_local(weapon.global_transform*weapon.support_thumb_contact)
			CONTACT.solve_chain(sk,thumb1,thumb2,thumb3,thumb.origin.lerp(contact_target,1.0-reload_weight),thumb.basis)
