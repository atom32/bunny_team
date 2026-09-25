class_name HumanoidRetargetVisual
extends Node3D

const CHARACTER_SCENE := preload("res://assets/characters/vrm_avatar/avatar_sample_a.glb")
const ANIMATION_SOURCE_SCENE := preload("res://assets/characters/unitychan_battle/animations/idle.fbx")
const ASSAULT_RIFLE_SCENE := preload("res://scenes/weapons/assault_rifle.tscn")
const ANIMATION_SCENES := {
	&"Idle_Gun": preload("res://assets/characters/unitychan_battle/animations/idle.fbx"),
	&"Walk": preload("res://assets/characters/unitychan_battle/animations/walk.fbx"),
	&"Run": preload("res://assets/characters/unitychan_battle/animations/run.fbx"),
}
const BONE_RENAMES := {
	&"J_Bip_C_Hips": &"Character1_Hips",
	&"J_Bip_C_Spine": &"Character1_Spine",
	&"J_Bip_C_Chest": &"Character1_Spine1",
	&"J_Bip_C_UpperChest": &"Character1_Spine2",
	&"J_Bip_C_Neck": &"Character1_Neck",
	&"J_Bip_C_Head": &"Character1_Head",
	&"J_Bip_L_Shoulder": &"Character1_LeftShoulder",
	&"J_Bip_L_UpperArm": &"Character1_LeftArm",
	&"J_Bip_L_LowerArm": &"Character1_LeftForeArm",
	&"J_Bip_L_Hand": &"Character1_LeftHand",
	&"J_Bip_R_Shoulder": &"Character1_RightShoulder",
	&"J_Bip_R_UpperArm": &"Character1_RightArm",
	&"J_Bip_R_LowerArm": &"Character1_RightForeArm",
	&"J_Bip_R_Hand": &"Character1_RightHand",
	&"J_Bip_L_UpperLeg": &"Character1_LeftUpLeg",
	&"J_Bip_L_LowerLeg": &"Character1_LeftLeg",
	&"J_Bip_L_Foot": &"Character1_LeftFoot",
	&"J_Bip_L_ToeBase": &"Character1_LeftToeBase",
	&"J_Bip_R_UpperLeg": &"Character1_RightUpLeg",
	&"J_Bip_R_LowerLeg": &"Character1_RightLeg",
	&"J_Bip_R_Foot": &"Character1_RightFoot",
	&"J_Bip_R_ToeBase": &"Character1_RightToeBase",
}

var animation_source_model: Node3D
var animation_source_skeleton: Skeleton3D
var character_model: Node3D
var character_skeleton: Skeleton3D
var animation_player: AnimationPlayer
var animation_tree: AnimationTree
var locomotion_playback: AnimationNodeStateMachinePlayback
var retarget_modifier: RetargetModifier3D
var combat_rig: CharacterCombatRig
var weapon_visual: Node3D
var movement_direction := Vector3.ZERO
var aim_direction := Vector3.FORWARD
var animation_paused := false
var animation_speed_scale := 1.0
var _forced_locomotion := &""
var _locomotion_state := &"Idle"


func _ready() -> void:
	_build_character()
	_apply_enemy_palette()
	_add_enemy_armor_accents()
	_mount_weapon()


func update_visual(aim_world_point: Vector3, move_direction: Vector3, move_speed: float, delta: float) -> void:
	movement_direction = move_direction.normalized() if move_direction.length_squared() > 0.01 else Vector3.ZERO
	var flat_target := Vector3(aim_world_point.x, global_position.y, aim_world_point.z)
	aim_direction = global_position.direction_to(flat_target).normalized()
	if aim_direction.length_squared() < 0.01:
		aim_direction = -global_basis.z.normalized()
	_update_locomotion(move_speed)
	var animation_delta := 0.0 if animation_paused else delta * animation_speed_scale
	if animation_tree:
		animation_tree.advance(animation_delta)
	if combat_rig:
		combat_rig.update_pose(aim_world_point, aim_direction, 0.0, delta, false)
	if animation_source_skeleton:
		animation_source_skeleton.advance(delta)
	if combat_rig:
		combat_rig.apply_skeleton_ik(delta)


func set_debug_locomotion(state: StringName) -> void:
	_forced_locomotion = state
	_set_locomotion_state(state)


func clear_debug_locomotion() -> void:
	_forced_locomotion = &""


func set_animation_paused(is_paused: bool) -> void:
	animation_paused = is_paused


func set_animation_speed(speed_scale: float) -> void:
	animation_speed_scale = clampf(speed_scale, 0.05, 2.0)


func fire_recoil() -> void:
	if combat_rig:
		combat_rig.fire_recoil(0.065)


func get_muzzle_position() -> Vector3:
	return combat_rig.get_muzzle_position() if combat_rig else global_position + Vector3.UP * 1.2


func get_muzzle_direction() -> Vector3:
	return combat_rig.get_muzzle_direction() if combat_rig else -global_basis.z.normalized()


func get_forward_axis_motion_alignment() -> float:
	return combat_rig.get_forward_axis_motion_alignment() if combat_rig else 0.0


func get_locomotion_state() -> StringName:
	return _locomotion_state


func _build_character() -> void:
	animation_source_model = ANIMATION_SOURCE_SCENE.instantiate() as Node3D
	animation_source_model.name = "EnemyAnimationSource"
	_set_mesh_visibility(animation_source_model, false)
	animation_source_skeleton = animation_source_model.find_child("Skeleton3D", true, false) as Skeleton3D

	character_model = CHARACTER_SCENE.instantiate() as Node3D
	character_model.name = "EnemyVRMModel"
	var bundled_weapon := character_model.find_child("Wep", true, false)
	if bundled_weapon:
		_set_mesh_visibility(bundled_weapon, false)
	character_skeleton = character_model.find_child("Skeleton3D", true, false) as Skeleton3D
	if character_skeleton:
		_rename_character_bones(character_skeleton)
	if animation_source_skeleton and character_skeleton:
		var old_parent := character_skeleton.get_parent()
		var imported_transform := character_skeleton.transform
		old_parent.remove_child(character_skeleton)
		_clear_owner_recursive(character_skeleton)
		retarget_modifier = RetargetModifier3D.new()
		retarget_modifier.name = "EnemyRetarget"
		retarget_modifier.profile = _create_shared_bone_profile(animation_source_skeleton, character_skeleton)
		retarget_modifier.set_position_enabled(false)
		retarget_modifier.set_scale_enabled(false)
		animation_source_skeleton.add_child(retarget_modifier)
		retarget_modifier.add_child(character_skeleton)
		character_skeleton.transform = imported_transform
	add_child(animation_source_model)
	add_child(character_model)
	if animation_source_skeleton:
		animation_player = _build_animation_player(animation_source_skeleton)
		_build_locomotion_tree()
	if character_skeleton:
		combat_rig = CharacterCombatRig.new()
		combat_rig.name = "EnemyCombatRig"
		add_child(combat_rig)
		combat_rig.setup(animation_source_skeleton, character_skeleton, retarget_modifier)


func _mount_weapon() -> void:
	if not combat_rig:
		return
	weapon_visual = ASSAULT_RIFLE_SCENE.instantiate() as Node3D
	weapon_visual.name = "EnemyAssaultRifle"
	if not combat_rig.mount_weapon(weapon_visual):
		push_error("Enemy assault rifle is missing combat grip markers")
		return
	_recolor_weapon()


func _build_animation_player(source_skeleton: Skeleton3D) -> AnimationPlayer:
	var result := AnimationPlayer.new()
	result.name = "EnemyAnimationPlayer"
	result.root_node = NodePath("..")
	source_skeleton.add_child(result)
	var library := AnimationLibrary.new()
	for animation_name: StringName in ANIMATION_SCENES:
		var animation_scene: PackedScene = ANIMATION_SCENES[animation_name]
		var animation_root := animation_scene.instantiate()
		var imported_player := animation_root.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if imported_player:
			var imported_animation := imported_player.get_animation(&"Take 001")
			if imported_animation:
				var animation := imported_animation.duplicate(true) as Animation
				_remove_import_bind_pose(animation)
				_retarget_animation_tracks(animation, source_skeleton)
				animation.loop_mode = Animation.LOOP_PINGPONG if animation_name == &"Idle_Gun" else Animation.LOOP_LINEAR
				library.add_animation(animation_name, animation)
		animation_root.free()
	result.add_animation_library(&"", library)
	return result


func _build_locomotion_tree() -> void:
	animation_tree = AnimationTree.new()
	animation_tree.name = "EnemyAnimationTree"
	add_child(animation_tree)
	animation_tree.anim_player = animation_tree.get_path_to(animation_player)
	var state_machine := AnimationNodeStateMachine.new()
	var states := {
		&"Idle": &"Idle_Gun",
		&"Walk": &"Walk",
		&"Run": &"Run",
	}
	var state_index := 0
	for state_name: StringName in states:
		var animation_node := AnimationNodeAnimation.new()
		animation_node.animation = states[state_name]
		state_machine.add_node(state_name, animation_node, Vector2(180.0 * state_index, 0.0))
		state_index += 1
	for from_state: StringName in states:
		for to_state: StringName in states:
			if from_state == to_state:
				continue
			var transition := AnimationNodeStateMachineTransition.new()
			transition.xfade_time = 0.14
			state_machine.add_transition(from_state, to_state, transition)
	animation_tree.tree_root = state_machine
	animation_tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	animation_tree.active = true
	locomotion_playback = animation_tree.get("parameters/playback") as AnimationNodeStateMachinePlayback
	locomotion_playback.start(&"Idle")


func _update_locomotion(move_speed: float) -> void:
	if not _forced_locomotion.is_empty():
		_set_locomotion_state(_forced_locomotion)
		return
	var next_state := &"Idle"
	if move_speed > 2.0:
		next_state = &"Run"
	elif move_speed > 0.2:
		next_state = &"Walk"
	_set_locomotion_state(next_state)


func _set_locomotion_state(next_state: StringName) -> void:
	if not locomotion_playback or _locomotion_state == next_state:
		return
	_locomotion_state = next_state
	locomotion_playback.travel(next_state)


func _create_shared_bone_profile(source: Skeleton3D, target: Skeleton3D) -> SkeletonProfile:
	var shared_bones: Array[StringName] = []
	for bone_index in source.get_bone_count():
		var bone_name := source.get_bone_name(bone_index)
		if target.find_bone(bone_name) >= 0:
			shared_bones.append(bone_name)
	var profile := SkeletonProfile.new()
	profile.bone_size = shared_bones.size()
	for bone_index in shared_bones.size():
		profile.set_bone_name(bone_index, shared_bones[bone_index])
	return profile


func _rename_character_bones(target: Skeleton3D) -> void:
	for node in target.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		if not mesh_instance.skin:
			continue
		var runtime_skin := mesh_instance.skin.duplicate() as Skin
		mesh_instance.skin = runtime_skin
		for bind_index in runtime_skin.get_bind_count():
			var imported_name := runtime_skin.get_bind_name(bind_index)
			if BONE_RENAMES.has(imported_name):
				runtime_skin.set_bind_name(bind_index, BONE_RENAMES[imported_name])
	for imported_name: StringName in BONE_RENAMES:
		var bone_index := target.find_bone(imported_name)
		if bone_index >= 0:
			target.set_bone_name(bone_index, BONE_RENAMES[imported_name])


func _remove_import_bind_pose(animation: Animation) -> void:
	for track_index in animation.get_track_count():
		if animation.track_get_key_count(track_index) < 2:
			continue
		var first_time := animation.track_get_key_time(track_index, 0)
		var second_time := animation.track_get_key_time(track_index, 1)
		if first_time <= 0.001 and second_time > 0.001 and second_time <= 0.04:
			animation.track_remove_key(track_index, 0)
			animation.track_set_key_time(track_index, 0, 0.0)


func _retarget_animation_tracks(animation: Animation, source_skeleton: Skeleton3D) -> void:
	for track_index in range(animation.get_track_count() - 1, -1, -1):
		var imported_path := animation.track_get_path(track_index)
		if imported_path.get_subname_count() == 0:
			animation.remove_track(track_index)
			continue
		var bone_name := imported_path.get_subname(imported_path.get_subname_count() - 1)
		if source_skeleton.find_bone(bone_name) < 0:
			animation.remove_track(track_index)
			continue
		animation.track_set_path(track_index, NodePath(".:%s" % bone_name))


func _apply_enemy_palette() -> void:
	for node in character_model.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		var tint := Color("a83448")
		var tint_weight := 0.5
		if mesh_instance.name == "Face":
			tint = Color("d8b1aa")
			tint_weight = 0.12
		elif mesh_instance.name == "Hair":
			tint = Color("351f2b")
			tint_weight = 0.72
		for surface_index in mesh_instance.mesh.get_surface_count():
			var source_material := mesh_instance.get_active_material(surface_index)
			if source_material is BaseMaterial3D:
				var material := source_material.duplicate() as BaseMaterial3D
				material.albedo_color = material.albedo_color.lerp(tint, tint_weight)
				mesh_instance.set_surface_override_material(surface_index, material)


func _recolor_weapon() -> void:
	for node in weapon_visual.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		var source_material := mesh_instance.material_override
		if source_material is BaseMaterial3D:
			var material := source_material.duplicate() as BaseMaterial3D
			material.albedo_color = material.albedo_color.lerp(Color("c92f4b"), 0.48)
			if material.emission_enabled:
				material.emission = Color("ff3657")
			mesh_instance.material_override = material


func _add_enemy_armor_accents() -> void:
	_add_bone_accent(
		"EnemyChestPlate",
		&"Character1_Spine2",
		Vector3(0.0, -0.045, -0.155),
		Vector3(0.38, 0.3, 0.055),
		Color("a8203c")
	)
	_add_bone_accent(
		"EnemyVisor",
		&"Character1_Head",
		Vector3(0.0, 0.015, -0.115),
		Vector3(0.22, 0.075, 0.035),
		Color("ff3657")
	)


func _add_bone_accent(
	accent_name: String,
	bone_name: StringName,
	accent_position: Vector3,
	size: Vector3,
	color: Color
) -> void:
	if not character_skeleton or character_skeleton.find_bone(bone_name) < 0:
		return
	var attachment := BoneAttachment3D.new()
	attachment.name = "%sAttachment" % accent_name
	attachment.bone_name = bone_name
	character_skeleton.add_child(attachment)
	var accent := VisualFactory.box(attachment, size, accent_position, color, accent_name)
	accent.material_override = VisualFactory.material(color, 0.55, 0.22, Color("ff294e"), 1.5)


func _set_mesh_visibility(root: Node, is_visible: bool) -> void:
	for node in root.find_children("*", "MeshInstance3D", true, false):
		(node as MeshInstance3D).visible = is_visible


func _clear_owner_recursive(root: Node) -> void:
	root.owner = null
	for child in root.get_children():
		_clear_owner_recursive(child)
