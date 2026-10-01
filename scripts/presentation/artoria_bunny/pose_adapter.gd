extends CharacterCombatRig
## Game-facing adapter for the imported, clothed Bunny Suit derivative.

var _raw_pose := Transform3D.IDENTITY
var _has_raw_pose := false
var _hands: SkeletonModifier3D

func setup(driver: Skeleton3D, target: Skeleton3D, retarget: RetargetModifier3D) -> void:
	super.setup(driver, target, retarget)
	_hands = preload("res://scripts/presentation/artoria_bunny/hand_modifier.gd").new()
	_hands.name = "BunnyGunHands"
	_hands.primary_target = right_hand_target
	_hands.support_target = left_hand_target
	display_skeleton.add_child(_hands)
	_correct_equipment_frames.call_deferred()

func _correct_equipment_frames() -> void:
	for socket_name in ["Chest", "Backpack"]:
		var socket := display_skeleton.find_child(socket_name, true, false) as Node3D
		socket.transform = Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO) * socket.transform

func clear_weapon() -> void:
	super.clear_weapon()
	_has_raw_pose = false
	if _hands:
		_hands.weapon = null

func update_pose(point: Vector3, direction: Vector3, dodge: float, delta: float, preview: bool) -> void:
	if _has_raw_pose and _pose_initialized:
		weapon_pose_root.transform = _raw_pose
	super.update_pose(point, direction, dodge, delta, preview)
	if not is_instance_valid(equipped_weapon):
		return
	_hands.weapon = equipped_weapon
	_hands.reload_weight = _reload_hand_weight()
	_raw_pose = weapon_pose_root.transform
	_has_raw_pose = true
	var offset: Vector3 = Vector3(.10, .16, -.07) + equipped_weapon.pose_offset
	offset += equipped_weapon.reload_offset * _reload_hand_weight()
	weapon_pose_root.global_position += weapon_pose_root.global_basis.orthonormalized() * offset
	# This skin has shorter arms than the animation driver; keep the magazine
	# within reach while lowering/rolling the rifle for reload and dodge.
	weapon_pose_root.global_position += Vector3.UP * (.12 * _reload_pose_weight() + .06 * dodge)
	right_hand_target.global_position = primary_grip.global_position
	left_hand_target.global_position = support_grip.global_position.lerp(reload_grip.global_position, _reload_hand_weight())
	# The imported slide clip raises an arm; retain weapon contact through dodge.
	right_arm_ik.influence = 1.0
	left_arm_ik.influence = 1.0
	_sync_modifier_targets()

func validate_visual_integrity() -> bool:
	var names: Array[String] = []
	var triangles := 0
	for mesh in display_skeleton.find_children("*", "MeshInstance3D", true, false):
		if not mesh.mesh or not mesh.skin:
			continue
		names.append(String(mesh.name))
		for surface in mesh.mesh.get_surface_count():
			var arrays: Array = mesh.mesh.surface_get_arrays(surface)
			triangles += (arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
	return names.size() == 11 and triangles == 157293 and "ArtoriaLancer_Body_Runtime" in names and "Bunny_Suit_Runtime" in names and display_skeleton.get_bone_count() == 52
