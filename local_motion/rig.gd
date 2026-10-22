extends "res://scripts/presentation/artoria_bunny/pose_adapter.gd"
## Authored relative-hand motion, scaled to this heroine, while the existing
## right-hand gun constraint and controller-owned reload timing remain intact.
var authored_reload_delta := Vector3.ZERO
var max_authored_reload_delta := 0.0
var max_weapon_fit_offset := 0.0
var _display_origin := Vector3.ZERO
var _leg_scale := 1.0
const LOCAL_LIBRARY := "res://local_motion/library.tres"
var source_clip: Animation
var gaze: SkeletonModifier3D
var motion_mode := ""
var motion_time := 0.0
var stride_mode := ""
var free_left_weight := 0.0
var free_right_weight := 0.0
var _motion_library: AnimationLibrary
var _neutral_pose := Transform3D.IDENTITY
var _has_neutral_pose := false

func _build_forward_axis_retarget() -> void:
	var names:=PackedStringArray()
	for i in display_skeleton.get_bone_count():
		var name:=display_skeleton.get_bone_name(i)
		if driver_skeleton.find_bone(name)>=0:names.append(name)
	forward_axis_retarget=load("res://local_motion/axis.gd").new()
	forward_axis_retarget.name="ForwardAxisRetarget"
	display_skeleton.add_child(forward_axis_retarget)
	forward_axis_retarget.configure(names)

func setup(driver: Skeleton3D,target: Skeleton3D,retarget: RetargetModifier3D) -> void:
	super.setup(driver,target,retarget)
	_motion_library=load(LOCAL_LIBRARY) as AnimationLibrary
	source_clip=_motion_library.get_animation(&"Reload")
	_hands.free()
	gaze=load("res://local_motion/gaze.gd").new()
	gaze.name="LocalAimGaze";gaze.rig=self;display_skeleton.add_child(gaze)
	var relax: SkeletonModifier3D=load("res://local_motion/relax.gd").new()
	relax.name="LocalUnarmedRecovery";relax.rig=self;display_skeleton.add_child(relax)
	_hands=preload("res://local_motion/hands.gd").new()
	_hands.name="BunnyGunHands"
	_hands.rig=self
	_hands.primary_target=right_hand_target
	_hands.support_target=left_hand_target
	display_skeleton.add_child(_hands)
	_display_origin=target.position
	var driver_leg:=driver.get_bone_global_rest(driver.find_bone("Character1_Hips")).origin.distance_to(driver.get_bone_global_rest(driver.find_bone("Character1_LeftFoot")).origin)
	var target_leg:=target.get_bone_global_rest(target.find_bone("Character1_Hips")).origin.distance_to(target.get_bone_global_rest(target.find_bone("Character1_LeftFoot")).origin)
	_leg_scale=target_leg/driver_leg

func update_pose(point: Vector3,direction: Vector3,dodge: float,delta: float,preview: bool) -> void:
	super.update_pose(point,direction,dodge,delta,preview)
	_neutral_pose=weapon_pose_root.global_transform;_has_neutral_pose=true
	head_aim.influence=0.0 # Rest-relative gaze modifier follows the actual aim point.
	authored_reload_delta=Vector3.ZERO
	free_left_weight=0;free_right_weight=0
	if motion_mode=="Holstered":
		free_left_weight=1;free_right_weight=1;left_arm_ik.influence=0;right_arm_ik.influence=0
		return
	if motion_mode in ["TakeGun","PutGun"]:
		var clip:=_motion_library.get_animation(motion_mode)
		var positions: PackedVector3Array=clip.get_meta("right_weapon_delta")
		var turns: Array=clip.get_meta("right_weapon_rotation")
		var phase:=clampf(motion_time/clip.length,0,1)
		var at:=phase*(positions.size()-1);var lo:=int(at);var hi:=mini(lo+1,positions.size()-1)
		var rotation: Quaternion=turns[lo].slerp(turns[hi],at-lo)
		weapon_pose_root.global_transform=Transform3D(_neutral_pose.basis*Basis(rotation),_neutral_pose.origin+_neutral_pose.basis.orthonormalized()*positions[lo].lerp(positions[hi],at-lo))
		free_left_weight=1.0 if motion_mode=="PutGun" else 1.0-smoothstep(.55,.85,phase)
		if motion_mode=="PutGun" and motion_time>=.49282077:free_right_weight=1.0
		left_arm_ik.influence=1.0-free_left_weight
		right_arm_ik.influence=1.0-free_right_weight
		right_hand_target.global_position=primary_grip.global_position
		_sync_modifier_targets()
		return
	# The source sprint leans its head forward: lower the entire rifle, not the
	# neck or individual bones, so the receiver does not cut through the face.
	if _motion_library.has_animation(&"Run") and stride_mode in ["Run","WalkRelaxed"]:
		weapon_pose_root.global_position-=Vector3.UP*(.18 if stride_mode=="Run" else .10)
		right_hand_target.global_position=primary_grip.global_position
		left_hand_target.global_position=support_grip.global_position
		_sync_modifier_targets()
	if not has_weapon() or not is_reloading():return
	var path: PackedVector3Array=source_clip.get_meta("left_reload_delta")
	var phase:=clampf(_reload_elapsed/reload_duration,0,1)
	var at:=phase*(path.size()-1)
	var lo:=mini(int(at),path.size()-1);var hi:=mini(lo+1,path.size()-1)
	# Preserve the authored reach, with a short contact blend at either end.
	var weight:=smoothstep(0,.12,phase)*(1.0-smoothstep(.86,1.0,phase))
	authored_reload_delta=path[lo].lerp(path[hi],at-lo)*weight
	max_authored_reload_delta=maxf(max_authored_reload_delta,authored_reload_delta.length())
	left_hand_target.global_position=support_grip.global_position+weapon_pose_root.global_basis.orthonormalized()*authored_reload_delta
	_hands.reload_weight=sin(phase*PI)
	_sync_modifier_targets()

func apply_skeleton_ik(delta: float) -> void:
	# Position retargeting remains disabled: never overwrite the model's bone
	# lengths. Move the display root by the authored pelvis-height displacement.
	var hip:=driver_skeleton.find_bone("Character1_Hips")
	var shift:=driver_skeleton.global_basis*(driver_skeleton.get_bone_global_pose(hip).origin-driver_skeleton.get_bone_global_rest(hip).origin)
	var parent:=display_skeleton.get_parent() as Node3D
	display_skeleton.position=_display_origin+parent.global_basis.inverse()*Vector3.UP*shift.y*_leg_scale
	if motion_mode in ["TakeGun","PutGun"]:
		var anchor: float=_motion_library.get_animation(motion_mode).get_meta("driver_vertical_anchor")
		weapon_pose_root.global_position+=Vector3.UP*(shift.y-anchor)*_leg_scale
	super.apply_skeleton_ik(delta)

func reset_presentation_pose() -> void:
	motion_mode="";free_left_weight=0;free_right_weight=0
	if _has_neutral_pose and has_weapon():
		weapon_pose_root.global_transform=_neutral_pose
		right_hand_target.global_position=primary_grip.global_position
		left_hand_target.global_position=support_grip.global_position
		_sync_modifier_targets()
