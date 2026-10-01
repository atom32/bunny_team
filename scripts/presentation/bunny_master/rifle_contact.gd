extends RefCounted
## Pose-specific weapon frame and analytic arm fit; keeps original limb lengths.
const PRIMARY := Vector3(.024, -.015, -.025)
const SUPPORT := Vector3(0, .055, .24)

static func palm(sk: Skeleton3D, side: String) -> Vector3:
	var wrist := sk.get_bone_global_pose(sk.find_bone("Character1_"+side+"Hand")).origin
	var knuckle := sk.get_bone_global_pose(sk.find_bone("Character1_"+side+"HandMiddle1")).origin
	return wrist.lerp(knuckle,.55)

static func hand_frame(sk: Skeleton3D, side: String) -> Basis:
	var prefix := "Character1_"+side+"Hand"
	var wrist := sk.get_bone_global_pose(sk.find_bone(prefix)).origin
	var middle := sk.get_bone_global_pose(sk.find_bone(prefix+"Middle1")).origin
	var index := sk.get_bone_global_pose(sk.find_bone(prefix+"Index1")).origin
	var pinky := sk.get_bone_global_pose(sk.find_bone(prefix+"Pinky1")).origin
	return frame(wrist.direction_to(middle),(index-pinky).normalized().cross(wrist.direction_to(middle)))

static func frame(fingers: Vector3, normal: Vector3) -> Basis:
	var across := fingers.cross(normal).normalized()
	return Basis(across,fingers.normalized(),across.cross(fingers).normalized())

static func fit(sk: Skeleton3D, weapon: Node3D) -> void:
	var expected_right := frame(Vector3(0,.25,1).normalized(),Vector3.RIGHT)
	var orientation := hand_frame(sk,"Right")*expected_right.inverse()
	weapon.global_basis=sk.global_basis.orthonormalized()*orientation*.9
	weapon.global_position=sk.to_global(palm(sk,"Right"))-weapon.global_basis*PRIMARY
	var wrist_index := sk.find_bone("Character1_LeftHand")
	var hand := sk.get_bone_global_pose(wrist_index)
	var palm_local := hand.affine_inverse()*palm(sk,"Left")
	var left_frame := orientation*frame(Vector3(-.75,0,.66).normalized(),Vector3.DOWN)
	var hand_basis := left_frame*hand_frame(sk,"Left").inverse()*hand.basis
	var wrist_target := sk.to_local(weapon.global_transform*SUPPORT)-hand_basis*palm_local
	solve_arm(sk,"Left",wrist_target,hand_basis)
	for finger in ["Middle","Ring","Pinky"]:
		for joint in range(1,4):
			var bone := sk.find_bone("Character1_LeftHand"+finger+str(joint))
			var pose := sk.get_bone_global_pose(bone)
			pose.basis=Basis(left_frame.x,deg_to_rad(-[15.0,20.0,10.0][joint-1]))*pose.basis
			sk.set_bone_global_pose(bone,pose)
	var thumb1 := sk.find_bone("Character1_LeftHandThumb1")
	var thumb2 := sk.find_bone("Character1_LeftHandThumb2")
	var thumb3 := sk.find_bone("Character1_LeftHandThumb3")
	var thumb := sk.get_bone_global_pose(thumb3)
	# Bring the thumb pad onto the rail side instead of leaving the demo's open gap.
	var thumb_target := thumb.origin+sk.global_basis.inverse()*weapon.global_basis*Vector3(-.012,-.005,-.008)
	solve_chain(sk,thumb1,thumb2,thumb3,thumb_target,thumb.basis)
	print("MCO_CONTACT primary_error=",sk.to_global(palm(sk,"Right")).distance_to(weapon.global_transform*PRIMARY)," support_error=",sk.to_global(palm(sk,"Left")).distance_to(weapon.global_transform*SUPPORT))

static func solve_arm(sk: Skeleton3D, side: String, target: Vector3, hand_basis: Basis) -> void:
	var upper := sk.find_bone("Character1_"+side+"Arm")
	var lower := sk.find_bone("Character1_"+side+"ForeArm")
	var wrist := sk.find_bone("Character1_"+side+"Hand")
	solve_chain(sk,upper,lower,wrist,target,hand_basis)

static func solve_chain(sk: Skeleton3D, upper: int, lower: int, wrist: int, target: Vector3, hand_basis: Basis) -> void:
	var arm := sk.get_bone_global_pose(upper)
	var elbow := sk.get_bone_global_pose(lower)
	var hand := sk.get_bone_global_pose(wrist)
	var upper_length := arm.origin.distance_to(elbow.origin)
	var lower_length := elbow.origin.distance_to(hand.origin)
	var direction := arm.origin.direction_to(target)
	var distance := clampf(arm.origin.distance_to(target),absf(upper_length-lower_length)+.0001,upper_length+lower_length-.0001)
	var pole := elbow.origin-arm.origin
	pole=(pole-direction*pole.dot(direction)).normalized()
	var along := (upper_length*upper_length-lower_length*lower_length+distance*distance)/(2*distance)
	var height := sqrt(maxf(0,upper_length*upper_length-along*along))
	var desired_elbow := arm.origin+direction*along+pole*height
	arm.basis=Basis(Quaternion(arm.origin.direction_to(elbow.origin),arm.origin.direction_to(desired_elbow)))*arm.basis
	sk.set_bone_global_pose(upper,arm)
	elbow=sk.get_bone_global_pose(lower)
	hand=sk.get_bone_global_pose(wrist)
	elbow.basis=Basis(Quaternion(elbow.origin.direction_to(hand.origin),elbow.origin.direction_to(arm.origin+direction*distance)))*elbow.basis
	sk.set_bone_global_pose(lower,elbow)
	hand=sk.get_bone_global_pose(wrist)
	hand.basis=hand_basis
	sk.set_bone_global_pose(wrist,hand)
