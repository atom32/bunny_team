class_name CharacterCombatRig
extends Node3D

const RIGHT_ARM := &"Character1_RightArm"
const RIGHT_FOREARM := &"Character1_RightForeArm"
const RIGHT_HAND := &"Character1_RightHand"
const LEFT_ARM := &"Character1_LeftArm"
const LEFT_FOREARM := &"Character1_LeftForeArm"
const LEFT_HAND := &"Character1_LeftHand"
const SPINE := &"Character1_Spine2"
const HEAD := &"Character1_Head"

enum UpperBodyState {
	READY,
	AIM,
	FIRE,
	RELOAD,
	DODGE,
}

var reload_duration := 0.9
var driver_skeleton: Skeleton3D
var skeleton: Skeleton3D
var display_skeleton: Skeleton3D
var weapon_pose_root: Node3D
var weapon_mount: Node3D
var equipped_weapon: Node3D
var _socket_visual: Node3D
var primary_grip: Marker3D
var support_grip: Marker3D
var reload_grip: Marker3D
var muzzle: Marker3D
var right_hand_target: Marker3D
var left_hand_target: Marker3D
var right_elbow_pole: Marker3D
var left_elbow_pole: Marker3D
var aim_target: Marker3D
var torso_aim: LookAtModifier3D
var head_aim: LookAtModifier3D
var forward_axis_retarget: ForwardAxisRetargetModifier
var right_arm_ik: TwoBoneIK3D
var left_arm_ik: TwoBoneIK3D
var _reload_elapsed := 0.0
var _reloading := false
var _recoil := 0.0
var _pose_initialized := false
var _upper_body_state := UpperBodyState.READY
var _right_hand_error := INF
var _left_hand_error := INF


func setup(driver_skeleton: Skeleton3D, target_skeleton: Skeleton3D, retarget: RetargetModifier3D) -> void:
	self.driver_skeleton = driver_skeleton
	skeleton = target_skeleton
	display_skeleton = target_skeleton
	self.driver_skeleton.modifier_callback_mode_process = Skeleton3D.MODIFIER_CALLBACK_MODE_PROCESS_MANUAL
	display_skeleton.modifier_callback_mode_process = Skeleton3D.MODIFIER_CALLBACK_MODE_PROCESS_MANUAL
	_build_pose_nodes()
	_build_forward_axis_retarget()
	_build_aim_modifiers()
	_build_arm_ik_modifiers()
	self.driver_skeleton.move_child(retarget, self.driver_skeleton.get_child_count() - 1)


func mount_weapon(weapon: Node3D) -> bool:
	clear_weapon()
	equipped_weapon = weapon
	weapon_mount.add_child(equipped_weapon)
	equipped_weapon.scale = Vector3.ONE * 0.44
	primary_grip = equipped_weapon.find_child("PrimaryGrip", true, false) as Marker3D
	support_grip = equipped_weapon.find_child("SupportGrip", true, false) as Marker3D
	reload_grip = equipped_weapon.find_child("ReloadGrip", true, false) as Marker3D
	muzzle = equipped_weapon.find_child("Muzzle", true, false) as Marker3D
	var is_complete := primary_grip != null and support_grip != null and reload_grip != null and muzzle != null
	_set_upper_body_influence(1.0 if is_complete else 0.0)
	_pose_initialized = false
	return is_complete


func track_socket_visual(weapon: Node3D) -> void:
	# Reuse the existing pose/IK targets while preserving legacy socket identity.
	# has_weapon() stays false: gameplay keeps its original muzzle/reload path.
	_socket_visual = weapon
	_socket_visual.top_level = true
	primary_grip = weapon.get_node("PrimaryGrip") as Marker3D
	support_grip = weapon.get_node("SupportGrip") as Marker3D
	reload_grip = weapon.get_node("ReloadGrip") as Marker3D
	_pose_initialized = false
	_set_upper_body_influence(1.0)


func clear_weapon() -> void:
	_socket_visual = null
	if is_instance_valid(equipped_weapon):
		weapon_mount.remove_child(equipped_weapon)
		equipped_weapon.queue_free()
	equipped_weapon = null
	primary_grip = null
	support_grip = null
	reload_grip = null
	muzzle = null
	_reloading = false
	_recoil = 0.0
	_pose_initialized = false
	_set_upper_body_influence(0.0)


func update_pose(
	aim_world_point: Vector3,
	aim_direction: Vector3,
	dodge_weight: float,
	delta: float,
	preview_mode: bool
) -> void:
	if not has_weapon() and not is_instance_valid(_socket_visual):
		return
	_update_reload(delta)
	_recoil = move_toward(_recoil, 0.0, delta * 10.0)
	_update_upper_body_state(dodge_weight)

	var host := get_parent() as Node3D
	var host_basis := host.global_basis.orthonormalized()
	var pose_direction := -host_basis.z if preview_mode else aim_direction.normalized()
	if pose_direction.length_squared() < 0.01:
		pose_direction = -host_basis.z
	pose_direction.y = 0.0
	pose_direction = pose_direction.normalized()
	var host_right := host_basis.x.normalized()
	var body_origin := host.global_position
	var reload_weight := _reload_pose_weight()
	var reload_hand_weight := _reload_hand_weight()

	var pose_position := body_origin + Vector3.UP * 1.13 + pose_direction * 0.06
	pose_position += host_right * 0.055 * reload_weight
	pose_position += Vector3.DOWN * (0.14 * reload_weight + 0.07 * dodge_weight)
	pose_position -= pose_direction * (0.045 * _recoil + 0.025 * dodge_weight)
	var weapon_target := pose_position + pose_direction * 20.0 if preview_mode else aim_world_point
	if pose_position.distance_squared_to(weapon_target) < 0.25:
		weapon_target = pose_position + pose_direction * 20.0
	var weapon_direction := pose_position.direction_to(weapon_target)
	var pose_basis := Basis.looking_at(weapon_direction, Vector3.UP)
	pose_basis = pose_basis * Basis(Vector3.FORWARD, 0.32 * reload_weight - 0.1 * dodge_weight)
	var desired_pose := Transform3D(pose_basis, pose_position)
	var pose_blend := 1.0 - exp(-24.0 * delta)
	if _pose_initialized:
		weapon_pose_root.global_transform = weapon_pose_root.global_transform.interpolate_with(desired_pose, pose_blend)
	else:
		weapon_pose_root.global_transform = desired_pose

	if is_instance_valid(_socket_visual):
		_socket_visual.global_transform = weapon_pose_root.global_transform * Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.44), Vector3.ZERO)

	aim_target.global_position = body_origin + Vector3.UP * 1.12 + pose_direction * 12.0
	right_elbow_pole.global_position = body_origin + Vector3.UP * 1.02 + host_right * 0.52 - pose_direction * 0.03
	left_elbow_pole.global_position = body_origin + Vector3.UP * 1.02 - host_right * 0.52 + pose_direction * 0.04

	var right_goal := primary_grip.global_transform
	var left_goal := support_grip.global_transform.interpolate_with(reload_grip.global_transform, reload_hand_weight)
	var hand_blend := 1.0 - exp(-38.0 * delta)
	if _pose_initialized:
		right_hand_target.global_transform = right_hand_target.global_transform.interpolate_with(right_goal, hand_blend)
		left_hand_target.global_transform = left_hand_target.global_transform.interpolate_with(left_goal, hand_blend)
	else:
		right_hand_target.global_transform = right_goal
		left_hand_target.global_transform = left_goal
	_pose_initialized = true
	_sync_modifier_targets()

	var override_weight := 1.0 - dodge_weight * 0.35
	torso_aim.influence = 0.58 * override_weight
	head_aim.influence = 0.34 * override_weight
	right_arm_ik.influence = override_weight
	left_arm_ik.influence = override_weight


func apply_skeleton_ik(delta: float) -> void:
	if not display_skeleton:
		return
	# Socket-mounted weapons still need the retargeted idle pose evaluated.
	display_skeleton.advance(delta)


func fire_recoil(strength: float) -> void:
	_recoil = maxf(_recoil, clampf(strength * 8.0, 0.35, 1.0))
	if equipped_weapon and equipped_weapon.has_method("flash"):
		equipped_weapon.flash()


func start_reload() -> bool:
	if not has_weapon() or _reloading:
		return false
	_reloading = true
	_reload_elapsed = 0.0
	return true


func is_reloading() -> bool:
	return _reloading


func get_upper_body_state_name() -> StringName:
	return UpperBodyState.keys()[_upper_body_state]


func uses_modifier_ik() -> bool:
	return right_arm_ik is TwoBoneIK3D and left_arm_ik is TwoBoneIK3D


func uses_model_forward_axis() -> bool:
	return (
		torso_aim.forward_axis == LookAtModifier3D.BONE_AXIS_MINUS_Z
		and head_aim.forward_axis == LookAtModifier3D.BONE_AXIS_MINUS_Z
	)


func uses_forward_axis_correction() -> bool:
	return forward_axis_retarget is ForwardAxisRetargetModifier


func get_forward_axis_motion_alignment() -> float:
	return forward_axis_retarget.get_front_back_motion_alignment() if forward_axis_retarget else 0.0


func has_weapon() -> bool:
	return is_instance_valid(equipped_weapon) and primary_grip != null and support_grip != null and muzzle != null


func get_muzzle_position() -> Vector3:
	return muzzle.global_position if muzzle else global_position


func get_muzzle_direction() -> Vector3:
	return -muzzle.global_basis.z.normalized() if muzzle else -global_basis.z.normalized()


func get_hand_error(hand_name: StringName) -> float:
	return _right_hand_error if hand_name == &"right" else _left_hand_error


func _build_pose_nodes() -> void:
	weapon_pose_root = Node3D.new()
	weapon_pose_root.name = "FireReload"
	add_child(weapon_pose_root)
	weapon_mount = Node3D.new()
	weapon_mount.name = "WeaponMount"
	weapon_pose_root.add_child(weapon_mount)

	aim_target = _marker("AimTarget", self)
	right_hand_target = _marker("RightHandTarget", self)
	left_hand_target = _marker("LeftHandTarget", self)
	right_elbow_pole = _marker("RightElbowPole", self)
	left_elbow_pole = _marker("LeftElbowPole", self)


func _build_aim_modifiers() -> void:
	torso_aim = _look_modifier("TorsoAim", SPINE, deg_to_rad(65.0), deg_to_rad(28.0), 0.58)
	head_aim = _look_modifier("HeadAim", HEAD, deg_to_rad(78.0), deg_to_rad(34.0), 0.34)


func _build_forward_axis_retarget() -> void:
	var bone_names := PackedStringArray()
	for bone_index in display_skeleton.get_bone_count():
		var bone_name := display_skeleton.get_bone_name(bone_index)
		if driver_skeleton.find_bone(bone_name) >= 0:
			bone_names.append(bone_name)
	forward_axis_retarget = ForwardAxisRetargetModifier.new()
	forward_axis_retarget.name = "ForwardAxisRetarget"
	display_skeleton.add_child(forward_axis_retarget)
	forward_axis_retarget.configure(bone_names)


func _build_arm_ik_modifiers() -> void:
	right_arm_ik = _arm_ik_modifier(
		"RightArmIK",
		RIGHT_ARM,
		RIGHT_FOREARM,
		RIGHT_HAND,
		right_hand_target,
		right_elbow_pole,
		SkeletonModifier3D.SECONDARY_DIRECTION_PLUS_Z
	)
	left_arm_ik = _arm_ik_modifier(
		"LeftArmIK",
		LEFT_ARM,
		LEFT_FOREARM,
		LEFT_HAND,
		left_hand_target,
		left_elbow_pole,
		SkeletonModifier3D.SECONDARY_DIRECTION_MINUS_Z
	)
	_set_upper_body_influence(0.0)


func _arm_ik_modifier(
	modifier_name: String,
	root_bone: StringName,
	middle_bone: StringName,
	end_bone: StringName,
	target: Marker3D,
	pole: Marker3D,
	pole_direction: SkeletonModifier3D.SecondaryDirection
) -> TwoBoneIK3D:
	var modifier := TwoBoneIK3D.new()
	modifier.name = modifier_name
	display_skeleton.add_child(modifier)
	modifier.setting_count = 1
	modifier.set_root_bone_name(0, String(root_bone))
	modifier.set_middle_bone_name(0, String(middle_bone))
	modifier.set_end_bone_name(0, String(end_bone))
	modifier.set_target_node(0, modifier.get_path_to(target))
	modifier.set_pole_node(0, modifier.get_path_to(pole))
	modifier.set_pole_direction(0, pole_direction)
	modifier.influence = 0.0
	modifier.modification_processed.connect(_on_arm_ik_processed.bind(modifier, end_bone, target, modifier_name))
	return modifier


func _on_arm_ik_processed(
	modifier: TwoBoneIK3D,
	end_bone: StringName,
	target: Marker3D,
	modifier_name: String
) -> void:
	var modifier_skeleton := modifier.get_skeleton()
	var bone_index := modifier_skeleton.find_bone(end_bone)
	var hand_position := modifier_skeleton.to_global(modifier_skeleton.get_bone_global_pose(bone_index).origin)
	var error := hand_position.distance_to(target.global_position)
	if modifier_name == "RightArmIK":
		_right_hand_error = error
	else:
		_left_hand_error = error


func _look_modifier(
	modifier_name: String,
	bone_name: StringName,
	yaw_limit: float,
	pitch_limit: float,
	weight: float
) -> LookAtModifier3D:
	var modifier := LookAtModifier3D.new()
	modifier.name = modifier_name
	modifier.bone_name = String(bone_name)
	modifier.forward_axis = LookAtModifier3D.BONE_AXIS_MINUS_Z
	modifier.primary_rotation_axis = Vector3.AXIS_Y
	modifier.use_secondary_rotation = true
	modifier.relative = true
	modifier.origin_from = LookAtModifier3D.ORIGIN_FROM_SPECIFIC_BONE
	modifier.origin_bone_name = String(bone_name)
	modifier.use_angle_limitation = true
	modifier.symmetry_limitation = true
	modifier.primary_limit_angle = yaw_limit
	modifier.secondary_limit_angle = pitch_limit
	modifier.duration = 0.08
	modifier.influence = weight
	skeleton.add_child(modifier)
	modifier.target_node = modifier.get_path_to(aim_target)
	return modifier


func _set_upper_body_influence(weight: float) -> void:
	if torso_aim:
		torso_aim.influence = 0.58 * weight
	if head_aim:
		head_aim.influence = 0.34 * weight
	if right_arm_ik:
		right_arm_ik.influence = weight
	if left_arm_ik:
		left_arm_ik.influence = weight


func _update_reload(delta: float) -> void:
	if not _reloading:
		return
	_reload_elapsed += delta
	if _reload_elapsed >= reload_duration:
		_reload_elapsed = reload_duration
		_reloading = false


func _update_upper_body_state(dodge_weight: float) -> void:
	if dodge_weight > 0.01:
		_upper_body_state = UpperBodyState.DODGE
	elif _reloading:
		_upper_body_state = UpperBodyState.RELOAD
	elif _recoil > 0.08:
		_upper_body_state = UpperBodyState.FIRE
	else:
		_upper_body_state = UpperBodyState.AIM


func _reload_pose_weight() -> float:
	if not _reloading:
		return 0.0
	return sin(clampf(_reload_elapsed / reload_duration, 0.0, 1.0) * PI)


func _reload_hand_weight() -> float:
	if not _reloading:
		return 0.0
	var progress := clampf(_reload_elapsed / reload_duration, 0.0, 1.0)
	if progress < 0.22:
		return smoothstep(0.0, 0.22, progress)
	if progress < 0.68:
		return 1.0
	return 1.0 - smoothstep(0.68, 1.0, progress)


func _marker(marker_name: String, parent: Node) -> Marker3D:
	var marker := Marker3D.new()
	marker.name = marker_name
	marker.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	parent.add_child(marker)
	return marker


func _sync_modifier_targets() -> void:
	for marker in [aim_target, right_hand_target, left_hand_target, right_elbow_pole, left_elbow_pole]:
		marker.reset_physics_interpolation()
