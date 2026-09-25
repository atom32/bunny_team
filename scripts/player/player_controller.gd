class_name PlayerController
extends CharacterBody3D

signal health_changed(current: float, maximum: float)
signal died
signal weapon_fired(recoil_strength: float)
signal ammo_changed(magazine: int, magazine_capacity: int, reserve: int)
signal weapon_switched(slot_id: StringName)

const ROCKET_SCENE := preload("res://scenes/weapons/rocket_projectile.tscn")
const RAGDOLL_SCENE := preload("res://scenes/player/ragdoll_proxy.tscn")
const CHARACTER_SCENE := preload("res://assets/characters/vrm_avatar/avatar_sample_a.glb")
const CHARACTER_ANIMATION_SOURCE_SCENE := preload("res://assets/characters/unitychan_battle/animations/idle.fbx")
const BODY_VISUAL_SCALE := Vector3.ONE
const CHARACTER_ANIMATION_SCENES := {
	&"Idle_Gun": preload("res://assets/characters/unitychan_battle/animations/idle.fbx"),
	&"Walk": preload("res://assets/characters/unitychan_battle/animations/walk.fbx"),
	&"Run": preload("res://assets/characters/unitychan_battle/animations/run.fbx"),
	&"Run_Shoot": preload("res://assets/characters/unitychan_battle/animations/run.fbx"),
	&"Dodge": preload("res://assets/characters/unitychan_battle/animations/slide.fbx"),
}
const CHARACTER_BONE_RENAMES := {
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

@export var preview_mode := false

var max_health := 260.0
var health := 260.0
var base_speed := 7.8
var acceleration := 52.0
var deceleration := 66.0
var dodge_speed := 18.5
var dodge_duration := 0.16
var dodge_cooldown := 0.62

var aim_direction := Vector3.FORWARD
var aim_world_point := Vector3.ZERO
var is_dead := false
var body_visual: Node3D
var equipment_root: Node3D
var weapon_root: Node3D
var equipped_weapon_visual: Node3D
var weapon_instance: ItemInstance
var active_weapon_slot: StringName = LoadoutState.SLOT_WEAPON_PRIMARY
var armor_instance: ItemInstance
var backpack_instance: ItemInstance
var weapon_data: WeaponDefinition
var armor_data: EquipmentDefinition
var backpack_data: EquipmentDefinition
var character_model: Node3D
var animation_source_model: Node3D
var animation_source_skeleton: Skeleton3D
var animation_player: AnimationPlayer
var animation_tree: AnimationTree
var locomotion_playback: AnimationNodeStateMachinePlayback
var character_skeleton: Skeleton3D
var retarget_modifier: RetargetModifier3D
var combat_rig: CharacterCombatRig
var interaction_component: InteractionComponent
var player_marker: MeshInstance3D
var _shot_cooldown := 0.0
var _dodge_time := 0.0
var _dodge_cooldown_time := 0.0
var _dodge_direction := Vector3.ZERO
var _visual_time := 0.0
var _recoil_tween: Tween
var _fire_queued := false
var _move_direction := Vector3.ZERO
var _initial_inventory: InventoryState
var _initial_loadout: LoadoutState
var _initial_session: SortieSession
var _weapon_instances_by_slot: Dictionary = {}


func configure_loadout(inventory: InventoryState, loadout: LoadoutState) -> void:
	_initial_inventory = inventory
	_initial_loadout = loadout


func configure_sortie(session: SortieSession) -> void:
	_initial_session = session
	configure_loadout(session.inventory, session.loadout)


func _ready() -> void:
	name = "Player"
	add_to_group("player")
	_build_collision()
	_build_character()
	if _initial_inventory and _initial_loadout:
		equip_loadout(_initial_inventory, _initial_loadout)
	aim_world_point = global_position + Vector3.UP * 1.25 + aim_direction * 30.0
	if preview_mode:
		collision_layer = 0
		collision_mask = 0
		set_physics_process(false)
	else:
		_build_player_marker()
		if _initial_session:
			interaction_component = InteractionComponent.new()
			interaction_component.name = "InteractionComponent"
			add_child(interaction_component)
			interaction_component.setup(self, _initial_session)


func _process(delta: float) -> void:
	_visual_time += delta
	if preview_mode and body_visual:
		body_visual.rotation.y += delta * 0.22
		_animate_stride(delta)
		if animation_tree:
			animation_tree.advance(delta)
		if combat_rig:
			combat_rig.update_pose(aim_world_point, aim_direction, 0.0, delta, true)
		if animation_source_skeleton:
			animation_source_skeleton.advance(delta)
		if combat_rig:
			combat_rig.apply_skeleton_ik(delta)
	if player_marker:
		var pulse := 1.0 + sin(_visual_time * 4.5) * 0.055
		player_marker.scale = Vector3(pulse, 1.0, pulse)


func _unhandled_input(event: InputEvent) -> void:
	if not preview_mode and event.is_action_pressed("fire"):
		_fire_queued = true
	if not preview_mode and event.is_action_pressed("reload"):
		reload_weapon()
	if not preview_mode and event.is_action_pressed("switch_weapon"):
		toggle_weapon()


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_shot_cooldown = maxf(_shot_cooldown - delta, 0.0)
	_dodge_cooldown_time = maxf(_dodge_cooldown_time - delta, 0.0)
	_update_aim(delta)
	_update_movement(delta)
	_animate_stride(delta)
	if animation_tree:
		animation_tree.advance(delta)
	if combat_rig:
		var dodge_weight := clampf(_dodge_time / dodge_duration, 0.0, 1.0) if dodge_duration > 0.0 else 0.0
		combat_rig.update_pose(aim_world_point, aim_direction, dodge_weight, delta, false)
	if animation_source_skeleton:
		animation_source_skeleton.advance(delta)
	if combat_rig:
		combat_rig.apply_skeleton_ik(delta)
	if Input.is_action_pressed("fire") or _fire_queued:
		_try_fire()
	_fire_queued = false


func equip_loadout(inventory: InventoryState, loadout: LoadoutState) -> void:
	_weapon_instances_by_slot.clear()
	for slot_id in LoadoutState.WEAPON_SLOT_IDS:
		var item := loadout.get_item(slot_id, inventory)
		if item:
			_weapon_instances_by_slot[slot_id] = item
	var initial_slot := LoadoutState.SLOT_WEAPON_PRIMARY
	if not _weapon_instances_by_slot.has(initial_slot):
		initial_slot = LoadoutState.SLOT_WEAPON_SECONDARY
	_activate_weapon_slot(initial_slot)
	equip_armor_instance(loadout.get_item(LoadoutState.SLOT_ARMOR, inventory))
	equip_backpack_instance(loadout.get_item(LoadoutState.SLOT_BACKPACK, inventory))


func equip_weapon_instance(item: ItemInstance) -> bool:
	var weapon := ContentDB.get_weapon(item.definition_id, false) if item else null
	if not weapon:
		return false
	_equip_weapon_definition(weapon)
	weapon_instance = item
	_weapon_instances_by_slot[active_weapon_slot] = item
	_emit_ammo_changed()
	return true


func switch_weapon(slot_id: StringName) -> bool:
	if (
		preview_mode
		or not _initial_session
		or _initial_session.status != SortieSession.Status.ACTIVE
		or slot_id not in LoadoutState.WEAPON_SLOT_IDS
	):
		return false
	if slot_id == active_weapon_slot:
		return true
	if not _initial_loadout or not _initial_inventory or not _initial_loadout.has_slot(slot_id):
		return false
	var item := _initial_loadout.get_item(slot_id, _initial_inventory)
	if not item or not _initial_inventory.contains(item.instance_id) or not ContentDB.get_weapon(item.definition_id, false):
		return false
	if not _initial_session.get_weapon_runtime_state(item.instance_id):
		return false
	if not _activate_weapon_slot(slot_id):
		return false
	weapon_switched.emit(active_weapon_slot)
	return true


func toggle_weapon() -> bool:
	var target_slot := (
		LoadoutState.SLOT_WEAPON_SECONDARY
		if active_weapon_slot == LoadoutState.SLOT_WEAPON_PRIMARY
		else LoadoutState.SLOT_WEAPON_PRIMARY
	)
	return switch_weapon(target_slot)


func get_weapon_instance(slot_id: StringName = &"") -> ItemInstance:
	var resolved_slot := active_weapon_slot if slot_id.is_empty() else slot_id
	return _weapon_instances_by_slot.get(resolved_slot) as ItemInstance


func get_weapon_definition(slot_id: StringName = &"") -> WeaponDefinition:
	var item := get_weapon_instance(slot_id)
	return ContentDB.get_weapon(item.definition_id, false) if item else null


func get_weapon_status(slot_id: StringName) -> Dictionary:
	var item := get_weapon_instance(slot_id)
	var definition := get_weapon_definition(slot_id)
	var state: Variant = _initial_session.get_weapon_runtime_state(item.instance_id) if _initial_session and item else null
	return {
		"slot_id": slot_id,
		"display_name": definition.display_name if definition else "UNARMED",
		"magazine": state.magazine_ammo if state else 0,
		"magazine_capacity": state.magazine_capacity if state else 0,
		"reserve": _initial_session.get_reserve_ammo(item.instance_id) if _initial_session and item and state else 0,
	}


func _activate_weapon_slot(slot_id: StringName) -> bool:
	var item := _weapon_instances_by_slot.get(slot_id) as ItemInstance
	var definition := ContentDB.get_weapon(item.definition_id, false) if item else null
	if not item or not definition:
		return false
	active_weapon_slot = slot_id
	weapon_instance = item
	_equip_weapon_definition(definition)
	_emit_ammo_changed()
	return true


func equip_armor_instance(item: ItemInstance) -> bool:
	var armor := ContentDB.get_item(item.definition_id, false) as EquipmentDefinition if item else null
	if not armor or not armor.has_tag(&"armor"):
		return false
	_equip_armor_definition(armor)
	armor_instance = item
	return true


func equip_backpack_instance(item: ItemInstance) -> bool:
	var backpack := ContentDB.get_item(item.definition_id, false) as EquipmentDefinition if item else null
	if not backpack or not backpack.has_tag(&"backpack"):
		return false
	_equip_backpack_definition(backpack)
	backpack_instance = item
	return true


func equip_weapon(weapon: WeaponDefinition) -> void:
	weapon_instance = null
	_equip_weapon_definition(weapon)
	_emit_ammo_changed()


func _equip_weapon_definition(weapon: WeaponDefinition) -> void:
	weapon_data = weapon
	_clear_weapon_sockets()
	equipped_weapon_visual = _attach_equipment(weapon)


func equip_armor(armor: EquipmentDefinition) -> void:
	armor_instance = null
	_equip_armor_definition(armor)


func _equip_armor_definition(armor: EquipmentDefinition) -> void:
	armor_data = armor
	_clear_socket(armor.socket_name)
	_attach_equipment(armor)


func equip_backpack(backpack: EquipmentDefinition) -> void:
	backpack_instance = null
	_equip_backpack_definition(backpack)


func _equip_backpack_definition(backpack: EquipmentDefinition) -> void:
	backpack_data = backpack
	_clear_socket(backpack.socket_name)
	_attach_equipment(backpack)


func receive_damage(packet: DamagePacket) -> float:
	if is_dead or preview_mode:
		return 0.0
	var applied_damage := packet.base_damage
	health = maxf(health - applied_damage, 0.0)
	velocity += packet.knockback_impulse
	AudioDirector.play_sfx(&"player_hurt", 0.0, 0.04)
	health_changed.emit(health, max_health)
	CombatEffects.hit(get_tree().current_scene, global_position + Vector3.UP * 1.25, Color("ff5568"))
	var tween := create_tween()
	tween.tween_property(body_visual, "rotation:z", 0.13, 0.06)
	tween.tween_property(body_visual, "rotation:z", 0.0, 0.13)
	if health <= 0.0:
		_die(packet.knockback_impulse)
	return applied_damage


func take_damage(amount: float, knockback_impulse: Vector3 = Vector3.ZERO) -> void:
	# Compatibility entry point for existing debug helpers; gameplay attacks deliver DamagePacket.
	receive_damage(DamagePacket.new(amount, 0.0, 0.0, null, &"debug.scalar", &"", global_position, Vector3.ZERO, knockback_impulse))


func debug_fire_once() -> bool:
	_shot_cooldown = 0.0
	return _try_fire()


func debug_reload_once() -> void:
	if _get_weapon_runtime_state():
		reload_weapon()
	elif combat_rig:
		combat_rig.start_reload()


func can_reload() -> bool:
	return (
		_initial_session != null
		and weapon_instance != null
		and _initial_session.can_reload_weapon(weapon_instance.instance_id)
	)


func reload_weapon() -> bool:
	if not can_reload():
		return false
	var loaded_rounds := _initial_session.reload_weapon(weapon_instance.instance_id)
	if loaded_rounds <= 0:
		return false
	if combat_rig:
		combat_rig.start_reload()
	AudioDirector.play_sfx(&"reload")
	_emit_ammo_changed()
	return true


func get_magazine_ammo() -> int:
	var weapon_state: Variant = _get_weapon_runtime_state()
	return weapon_state.magazine_ammo if weapon_state else 0


func get_magazine_capacity() -> int:
	var weapon_state: Variant = _get_weapon_runtime_state()
	return weapon_state.magazine_capacity if weapon_state else 0


func get_reserve_ammo() -> int:
	if not _initial_session or not weapon_instance:
		return 0
	return _initial_session.get_reserve_ammo(weapon_instance.instance_id)


func _build_collision() -> void:
	collision_layer = 1
	collision_mask = 6
	var shape := CapsuleShape3D.new()
	shape.radius = 0.36
	shape.height = 1.85
	var collision := CollisionShape3D.new()
	collision.name = "Hitbox"
	collision.position.y = 0.93
	collision.shape = shape
	add_child(collision)


func _build_player_marker() -> void:
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.46
	ring_mesh.outer_radius = 0.56
	player_marker = MeshInstance3D.new()
	player_marker.name = "PlayerMarker"
	player_marker.mesh = ring_mesh
	player_marker.position.y = 0.055
	player_marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	player_marker.material_override = VisualFactory.material(Color("36dce8"), 0.1, 0.2, Color("42f5ff"), 3.6)
	add_child(player_marker)


func _build_character() -> void:
	body_visual = Node3D.new()
	body_visual.name = "Body"
	body_visual.scale = BODY_VISUAL_SCALE
	body_visual.rotation.y = 0.0
	add_child(body_visual)

	animation_source_model = CHARACTER_ANIMATION_SOURCE_SCENE.instantiate() as Node3D
	animation_source_model.name = "AnimationSource"
	_set_mesh_visibility(animation_source_model, false)
	animation_source_skeleton = animation_source_model.find_child("Skeleton3D", true, false) as Skeleton3D

	character_model = CHARACTER_SCENE.instantiate() as Node3D
	character_model.name = "CombatAvatarModel"
	var bundled_melee_weapon := character_model.find_child("Wep", true, false)
	if bundled_melee_weapon:
		_set_mesh_visibility(bundled_melee_weapon, false)
	character_skeleton = character_model.find_child("Skeleton3D", true, false) as Skeleton3D
	if character_skeleton:
		_rename_character_bones(character_skeleton)
	if animation_source_skeleton and character_skeleton:
		var old_parent := character_skeleton.get_parent()
		var imported_transform := character_skeleton.transform
		old_parent.remove_child(character_skeleton)
		_clear_owner_recursive(character_skeleton)
		retarget_modifier = RetargetModifier3D.new()
		retarget_modifier.name = "CharacterRetarget"
		retarget_modifier.profile = _create_shared_bone_profile(animation_source_skeleton, character_skeleton)
		retarget_modifier.set_position_enabled(false)
		retarget_modifier.set_scale_enabled(false)
		retarget_modifier.rotation.y = 0.0
		animation_source_skeleton.add_child(retarget_modifier)
		retarget_modifier.add_child(character_skeleton)
		character_skeleton.transform = imported_transform
	body_visual.add_child(animation_source_model)
	body_visual.add_child(character_model)
	if animation_source_skeleton:
		animation_player = _build_character_animation_player(animation_source_skeleton)
		_build_locomotion_tree()

	equipment_root = Node3D.new()
	equipment_root.name = "EquipmentRoot"
	body_visual.add_child(equipment_root)

	weapon_root = Node3D.new()
	weapon_root.name = "WeaponRoot"
	body_visual.add_child(weapon_root)
	if character_skeleton:
		combat_rig = CharacterCombatRig.new()
		combat_rig.name = "UpperBodyAim"
		body_visual.add_child(combat_rig)
		combat_rig.setup(animation_source_skeleton, character_skeleton, retarget_modifier)
	if character_skeleton:
		_add_bone_socket(character_skeleton, "Chest", &"Character1_Spine2", Vector3(0.0, 0.0, -0.16))
		_add_bone_socket(character_skeleton, "ShoulderL", &"Character1_LeftShoulder", Vector3.ZERO)
		_add_bone_socket(character_skeleton, "ShoulderR", &"Character1_Spine2", Vector3(-0.2, 0.02, -0.11), Vector3(78.0, 0.0, -12.0))
		_add_bone_socket(character_skeleton, "Backpack", &"Character1_Spine2", Vector3(0.0, -0.06, 0.16))
		_add_bone_socket(character_skeleton, "HipL", &"Character1_Hips", Vector3(-0.12, -0.05, 0.0))
		_add_bone_socket(character_skeleton, "HipR", &"Character1_Hips", Vector3(0.12, -0.05, 0.0))
		_add_bone_socket(character_skeleton, "HandL", &"Character1_LeftHand", Vector3.ZERO)
		_add_bone_socket(character_skeleton, "HandR", &"Character1_Spine2", Vector3(0.18, -0.08, -0.12), Vector3(58.0, -28.0, 0.0))
	else:
		_add_socket(equipment_root, "Chest", Vector3(0.0, 1.28, -0.16))
		_add_socket(equipment_root, "ShoulderL", Vector3(-0.38, 1.48, -0.01))
		_add_socket(equipment_root, "ShoulderR", Vector3(0.38, 1.48, -0.01))
		_add_socket(equipment_root, "Backpack", Vector3(0.0, 1.27, 0.2))
		_add_socket(equipment_root, "HipL", Vector3(-0.23, 0.91, 0.0))
		_add_socket(equipment_root, "HipR", Vector3(0.23, 0.91, 0.0))
		_add_socket(weapon_root, "HandL", Vector3(-0.42, 1.13, -0.15))
		_add_socket(weapon_root, "HandR", Vector3(0.42, 1.13, -0.15))
	var shoulder_socket := _find_socket(&"ShoulderR")
	if shoulder_socket and not character_skeleton:
		shoulder_socket.position = Vector3(0.38, 1.54, -0.05)

	var ragdoll_marker := Node3D.new()
	ragdoll_marker.name = "Ragdoll"
	add_child(ragdoll_marker)


func _add_socket(parent: Node3D, socket_name: String, socket_position: Vector3) -> void:
	var socket := Node3D.new()
	socket.name = socket_name
	socket.position = socket_position
	parent.add_child(socket)


func _add_bone_socket(
	parent: Skeleton3D,
	socket_name: String,
	bone_name: StringName,
	socket_position: Vector3,
	socket_rotation_degrees: Vector3 = Vector3.ZERO
) -> void:
	var attachment := BoneAttachment3D.new()
	attachment.name = "%sAttachment" % socket_name
	attachment.bone_name = bone_name
	parent.add_child(attachment)
	var socket := Node3D.new()
	socket.name = socket_name
	socket.position = socket_position
	socket.rotation_degrees = socket_rotation_degrees
	attachment.add_child(socket)


func _set_mesh_visibility(root: Node, is_visible: bool) -> void:
	for node in root.find_children("*", "MeshInstance3D", true, false):
		(node as MeshInstance3D).visible = is_visible


func _clear_owner_recursive(root: Node) -> void:
	root.owner = null
	for child in root.get_children():
		_clear_owner_recursive(child)


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
			if CHARACTER_BONE_RENAMES.has(imported_name):
				runtime_skin.set_bind_name(bind_index, CHARACTER_BONE_RENAMES[imported_name])
	for imported_name: StringName in CHARACTER_BONE_RENAMES:
		var bone_index := target.find_bone(imported_name)
		if bone_index >= 0:
			target.set_bone_name(bone_index, CHARACTER_BONE_RENAMES[imported_name])


func _build_character_animation_player(skeleton: Skeleton3D) -> AnimationPlayer:
	var player := AnimationPlayer.new()
	player.name = "CharacterAnimationPlayer"
	player.root_node = NodePath("..")
	skeleton.add_child(player)
	var library := AnimationLibrary.new()
	for animation_name: StringName in CHARACTER_ANIMATION_SCENES:
		var animation_scene: PackedScene = CHARACTER_ANIMATION_SCENES[animation_name]
		var animation_root := animation_scene.instantiate()
		var imported_player := animation_root.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if imported_player:
			var imported_animation := imported_player.get_animation(&"Take 001")
			if imported_animation:
				var animation := imported_animation.duplicate(true) as Animation
				_remove_import_bind_pose(animation)
				_retarget_animation_tracks(animation, skeleton)
				animation.loop_mode = Animation.LOOP_PINGPONG if animation_name == &"Idle_Gun" else Animation.LOOP_LINEAR
				library.add_animation(animation_name, animation)
		animation_root.free()
	player.add_animation_library(&"", library)
	return player


func _build_locomotion_tree() -> void:
	animation_tree = AnimationTree.new()
	animation_tree.name = "AnimationTree"
	body_visual.add_child(animation_tree)
	animation_tree.anim_player = animation_tree.get_path_to(animation_player)
	var state_machine := AnimationNodeStateMachine.new()
	var states: Array[StringName] = [&"Idle", &"Walk", &"Run", &"Dodge"]
	var animations := {
		&"Idle": &"Idle_Gun",
		&"Walk": &"Walk",
		&"Run": &"Run",
		&"Dodge": &"Dodge",
	}
	for state_index in states.size():
		var animation_node := AnimationNodeAnimation.new()
		animation_node.animation = animations[states[state_index]]
		state_machine.add_node(states[state_index], animation_node, Vector2(160.0 * state_index, 0.0))
	for from_state in states:
		for to_state in states:
			if from_state == to_state:
				continue
			var transition := AnimationNodeStateMachineTransition.new()
			transition.xfade_time = 0.12 if to_state != &"Dodge" else 0.06
			state_machine.add_transition(from_state, to_state, transition)
	animation_tree.tree_root = state_machine
	animation_tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	animation_tree.active = true
	locomotion_playback = animation_tree.get("parameters/playback") as AnimationNodeStateMachinePlayback
	locomotion_playback.start(&"Idle")


func _remove_import_bind_pose(animation: Animation) -> void:
	# The Unity FBX clips contain a bind-pose key at t=0 followed by the real
	# first frame at 1/30 s. Leaving it in makes every loop visibly snap.
	for track_index in animation.get_track_count():
		if animation.track_get_key_count(track_index) < 2:
			continue
		var first_time := animation.track_get_key_time(track_index, 0)
		var second_time := animation.track_get_key_time(track_index, 1)
		if first_time <= 0.001 and second_time > 0.001 and second_time <= 0.04:
			animation.track_remove_key(track_index, 0)
			animation.track_set_key_time(track_index, 0, 0.0)


func _retarget_animation_tracks(animation: Animation, skeleton: Skeleton3D) -> void:
	for track_index in range(animation.get_track_count() - 1, -1, -1):
		var imported_path := animation.track_get_path(track_index)
		if imported_path.get_subname_count() == 0:
			animation.remove_track(track_index)
			continue
		var bone_name := imported_path.get_subname(imported_path.get_subname_count() - 1)
		if skeleton.find_bone(bone_name) < 0:
			animation.remove_track(track_index)
			continue
		animation.track_set_path(track_index, NodePath(".:%s" % bone_name))


func _attach_equipment(data: EquipmentDefinition) -> Node3D:
	if not data.scene:
		push_error("Missing equipment scene for %s" % data.id)
		return null
	var instance := data.scene.instantiate() as Node3D
	if data is WeaponDefinition and data.uses_combat_rig and combat_rig:
		if not combat_rig.mount_weapon(instance):
			push_error("Weapon is missing combat grip markers: %s" % data.id)
		instance.set_meta("equipment_id", data.id)
		return instance
	var socket := _find_socket(data.socket_name)
	if not socket:
		push_error("Missing equipment socket for %s" % data.id)
		instance.queue_free()
		return null
	socket.add_child(instance)
	instance.set_meta("equipment_id", data.id)
	if data is WeaponDefinition:
		instance.scale = Vector3.ONE * 0.44
		if combat_rig:
			combat_rig.track_socket_visual(instance)
	elif data.socket_name == &"Chest":
		instance.scale = Vector3.ONE * 0.48
	elif data.socket_name == &"Backpack":
		instance.scale = Vector3.ONE * 0.46
	else:
		instance.scale = Vector3.ONE * 0.52
	return instance


func _find_socket(socket_name: StringName) -> Node3D:
	return body_visual.find_child(String(socket_name), true, false) as Node3D


func _clear_socket(socket_name: StringName) -> void:
	var socket := _find_socket(socket_name)
	if not socket:
		return
	for child in socket.get_children():
		socket.remove_child(child)
		child.queue_free()


func _clear_weapon_sockets() -> void:
	if combat_rig:
		combat_rig.clear_weapon()
	_clear_socket(&"HandL")
	_clear_socket(&"HandR")
	_clear_socket(&"ShoulderR")


func _update_aim(delta: float) -> void:
	var stick := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	var camera := get_viewport().get_camera_3d()
	if stick.length() > 0.25:
		var right := camera.global_basis.x if camera else Vector3.RIGHT
		var forward := -camera.global_basis.z if camera else Vector3.FORWARD
		right.y = 0.0
		forward.y = 0.0
		aim_direction = (right.normalized() * stick.x + forward.normalized() * -stick.y).normalized()
		var aim_range := weapon_data.weapon_range if weapon_data else 30.0
		aim_world_point = global_position + Vector3.UP * 1.25 + aim_direction * aim_range
	else:
		if camera:
			aim_world_point = _world_aim_point(camera, get_viewport().get_mouse_position())
			var flat_target := Vector3(aim_world_point.x, global_position.y, aim_world_point.z)
			if flat_target.distance_to(global_position) > 0.3:
				aim_direction = global_position.direction_to(flat_target).normalized()


func _world_aim_point(camera: Camera3D, screen_position: Vector2) -> Vector3:
	var ray_origin := camera.project_ray_origin(screen_position)
	var ray_direction := camera.project_ray_normal(screen_position)
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_direction * 1000.0, 6)
	query.exclude = [get_rid()]
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if not result.is_empty():
		return result.position
	var ground_intersection = Plane(Vector3.UP, 0.0).intersects_ray(ray_origin, ray_direction)
	return ground_intersection if ground_intersection != null else aim_world_point


func _update_movement(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var right := camera.global_basis.x if camera else Vector3.RIGHT
	var forward := -camera.global_basis.z if camera else Vector3.FORWARD
	right.y = 0.0
	forward.y = 0.0
	var move_direction := (right.normalized() * input_vector.x + forward.normalized() * -input_vector.y).normalized()
	_move_direction = move_direction

	if Input.is_action_just_pressed("dodge") and _dodge_cooldown_time <= 0.0:
		_dodge_direction = move_direction if move_direction != Vector3.ZERO else aim_direction
		_dodge_time = dodge_duration
		_dodge_cooldown_time = dodge_cooldown
		AudioDirector.play_sfx(&"dodge", 0.0, 0.035)
		CombatEffects.dodge_pulse(get_tree().current_scene, global_position + Vector3.UP * 0.05, _dodge_direction)
		body_visual.scale = BODY_VISUAL_SCALE * Vector3(0.9, 1.06, 0.9)
		var dodge_tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		dodge_tween.tween_property(body_visual, "scale", BODY_VISUAL_SCALE, dodge_duration)

	if _dodge_time > 0.0:
		_dodge_time -= delta
		velocity.x = _dodge_direction.x * dodge_speed
		velocity.z = _dodge_direction.z * dodge_speed
	else:
		var movement_bonus := 0.0
		if armor_data:
			movement_bonus += armor_data.movement_modifier
		if backpack_data:
			movement_bonus += backpack_data.movement_modifier
		if weapon_data:
			movement_bonus += weapon_data.movement_modifier
		var movement_speed := maxf(base_speed + movement_bonus, 4.5)
		if Input.is_action_pressed("precision_walk"):
			movement_speed *= 0.5
		var target_velocity := move_direction * movement_speed
		var rate := acceleration if move_direction != Vector3.ZERO else deceleration
		var horizontal := Vector3(velocity.x, 0.0, velocity.z).move_toward(target_velocity, rate * delta)
		velocity.x = horizontal.x
		velocity.z = horizontal.z

	if not is_on_floor():
		velocity.y -= 24.0 * delta
	else:
		velocity.y = -0.1
	var locomotion_direction := _dodge_direction if _dodge_time > 0.0 else move_direction
	var target_rotation := _combat_facing_rotation(locomotion_direction)
	var facing_speed := 14.0 if _dodge_time > 0.0 else 10.5
	rotation.y = lerp_angle(rotation.y, target_rotation, 1.0 - exp(-facing_speed * delta))
	move_and_slide()


func _combat_facing_rotation(locomotion_direction: Vector3) -> float:
	var aim_rotation := atan2(-aim_direction.x, -aim_direction.z)
	if not combat_rig or not combat_rig.has_weapon() or locomotion_direction.length_squared() < 0.01:
		return aim_rotation
	var locomotion_rotation := atan2(-locomotion_direction.x, -locomotion_direction.z)
	var aim_offset := wrapf(aim_rotation - locomotion_rotation, -PI, PI)
	var upper_body_limit := deg_to_rad(52.0)
	return aim_rotation - clampf(aim_offset, -upper_body_limit, upper_body_limit)


func _try_fire() -> bool:
	if not weapon_data or _shot_cooldown > 0.0 or is_dead or (combat_rig and combat_rig.is_reloading()):
		return false
	var weapon_state: Variant = _get_weapon_runtime_state()
	if weapon_state and not _initial_session.fire_weapon(weapon_instance.instance_id):
		return false
	if _initial_session and weapon_instance and not weapon_state:
		return false
	_shot_cooldown = 1.0 / weapon_data.fire_rate
	var muzzle_position := combat_rig.get_muzzle_position() if combat_rig and combat_rig.has_weapon() else global_position + Vector3.UP * 1.25 + aim_direction * 0.55
	var shot_direction := _shot_direction_from(muzzle_position)
	AudioDirector.play_weapon(weapon_data.id)
	CombatEffects.muzzle_flash(get_tree().current_scene, muzzle_position, shot_direction, weapon_data.tracer_color, weapon_data.muzzle_scale)
	_apply_weapon_recoil(shot_direction)
	if weapon_data.action_type == &"projectile":
		var rocket := ROCKET_SCENE.instantiate()
		get_tree().current_scene.add_child(rocket)
		rocket.global_position = muzzle_position
		rocket.setup(self, shot_direction, weapon_data)
	else:
		_fire_hitscan(muzzle_position, shot_direction)
	weapon_fired.emit(weapon_data.recoil_strength)
	_emit_ammo_changed()
	return true


func _get_weapon_runtime_state():
	if not _initial_session or not weapon_instance:
		return null
	return _initial_session.get_weapon_runtime_state(weapon_instance.instance_id)


func _emit_ammo_changed() -> void:
	var weapon_state: Variant = _get_weapon_runtime_state()
	if weapon_state:
		ammo_changed.emit(weapon_state.magazine_ammo, weapon_state.magazine_capacity, get_reserve_ammo())


func _shot_direction_from(from: Vector3) -> Vector3:
	if from.distance_squared_to(aim_world_point) > 0.01:
		return from.direction_to(aim_world_point)
	return aim_direction


func _fire_hitscan(from: Vector3, shot_direction: Vector3) -> void:
	var to := from + shot_direction * weapon_data.weapon_range
	var query := PhysicsRayQueryParameters3D.create(from, to, 6)
	query.exclude = [get_rid()]
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	var hit_position := to
	if not result.is_empty():
		hit_position = result.position
		AudioDirector.play_sfx(&"impact", -1.0, 0.08)
		var target := result.collider as Node
		if target and target.has_method("receive_damage"):
			var armor_damage_modifier := armor_data.damage_modifier if armor_data else 0.0
			var packet := DamagePacket.new(
				weapon_data.damage + armor_damage_modifier,
				weapon_data.armor_penetration,
				weapon_data.structure_damage,
				self,
				weapon_data.id,
				&"player",
				hit_position,
				result.normal,
				shot_direction * weapon_data.knockback
			)
			target.receive_damage(packet)
			CombatEffects.hit(get_tree().current_scene, hit_position, weapon_data.tracer_color, weapon_data.impact_scale)
	CombatEffects.tracer(get_tree().current_scene, from, hit_position, weapon_data.tracer_color, weapon_data.tracer_width)


func _apply_weapon_recoil(shot_direction: Vector3) -> void:
	if combat_rig and combat_rig.has_weapon():
		combat_rig.fire_recoil(weapon_data.recoil_strength)
		return
	if _recoil_tween and _recoil_tween.is_valid():
		_recoil_tween.kill()
	var local_recoil := global_basis.inverse() * (-shot_direction * weapon_data.recoil_strength * 0.65)
	body_visual.position = local_recoil
	body_visual.rotation.z = weapon_data.recoil_strength * 0.12
	_recoil_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_recoil_tween.tween_property(body_visual, "position", Vector3.ZERO, 0.1 + weapon_data.recoil_strength * 0.18)
	_recoil_tween.tween_property(body_visual, "rotation:z", 0.0, 0.12)


func _animate_stride(_delta: float) -> void:
	if not locomotion_playback:
		return
	var speed := Vector2(velocity.x, velocity.z).length()
	var next_state: StringName = &"Idle"
	if _dodge_time > 0.0:
		next_state = &"Dodge"
	elif speed > 0.4:
		if Input.is_action_pressed("precision_walk"):
			next_state = &"Walk"
		else:
			next_state = &"Run"
	if locomotion_playback.get_current_node() != next_state:
		locomotion_playback.travel(next_state)


func _die(impulse: Vector3) -> void:
	is_dead = true
	var collision := get_node("Hitbox") as CollisionShape3D
	collision.set_deferred("disabled", true)
	body_visual.visible = false
	var ragdoll := RAGDOLL_SCENE.instantiate() as RagdollProxy
	get_parent().add_child(ragdoll)
	ragdoll.global_position = global_position
	ragdoll.build(Color("dce8eb"), impulse + -aim_direction * 2.0)
	died.emit()
