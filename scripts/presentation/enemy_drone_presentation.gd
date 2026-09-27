class_name KiteEnemyPresentation
extends Node3D
## Native enemy presentation. No humanoid, animation asset or player rig dependency.
const VISUAL_PATH := "res://scenes/presentation/enemies/kite_security.tscn"
# Preserve the a40b765 rifle marker/frame, not its mesh or hand/rig dependencies.
const MUZZLE_OFFSET := Vector3(0.0, 0.04, -1.48)
const WEAPON_SCALE := 0.44
const DEATH_PARTS := {
	"Chassis": "Torso", "Sensor": "Head", "PortPod": "ArmL",
	"StarboardPod": "ArmR", "Gun": "LegL", "RearPack": "LegR",
}

var enemy: Node3D
var visual: Node3D
var model: Node3D
var gun: MeshInstance3D
var weapon_presentation: Node3D
var weapon_pose_root: Node3D
var weapon_mount: Node3D
var muzzle: Marker3D
var optics: StandardMaterial3D
var elapsed := 0.0
var _rest_positions := {}
var _recoil := 0.0
var _pose_initialized := false
var _move_speed := 0.0

func _ready() -> void:
	enemy = get_parent() as Node3D
	_build_weapon_frame()
	# Load only when instantiating; editor autoload scanning precedes GLB import.
	visual = load(VISUAL_PATH).instantiate()
	add_child(visual)
	model = visual.get_node("Model")
	gun = model.find_child("Gun", true, false) as MeshInstance3D
	for part_name in DEATH_PARTS:
		var part := model.find_child(part_name, true, false) as MeshInstance3D
		_rest_positions[part_name] = part.position
		for surface in part.mesh.get_surface_count():
			var material := part.get_active_material(surface) as StandardMaterial3D
			if material and material.resource_name == "Hostile optics":
				if not optics:
					optics = material.duplicate() as StandardMaterial3D
				part.set_surface_override_material(surface, optics)
	enemy.connect("died", _on_died)
	_sync_visual(0.0)

func _build_weapon_frame() -> void:
	weapon_presentation = Node3D.new()
	weapon_presentation.name = "WeaponPresentation"
	add_child(weapon_presentation)
	weapon_pose_root = Node3D.new()
	weapon_pose_root.name = "FireReload"
	weapon_presentation.add_child(weapon_pose_root)
	weapon_mount = Node3D.new()
	weapon_mount.name = "WeaponMount"
	weapon_mount.scale = Vector3.ONE * WEAPON_SCALE
	weapon_pose_root.add_child(weapon_mount)
	muzzle = Marker3D.new()
	muzzle.name = "Muzzle"
	muzzle.position = MUZZLE_OFFSET
	weapon_mount.add_child(muzzle)

func update_visual(aim_world_point: Vector3, _move_direction: Vector3, move_speed: float, delta: float) -> void:
	_move_speed = move_speed
	# Exact enemy subset of CharacterCombatRig.update_pose at a40b765:
	# enemies never enter player reload/dodge/preview paths. Skeleton/IK followed
	# this weapon frame, not vice versa. Keep world-space filtering and -Z forward.
	var flat_target := Vector3(aim_world_point.x, global_position.y, aim_world_point.z)
	var aim_direction := global_position.direction_to(flat_target).normalized()
	if aim_direction.length_squared() < 0.01:
		aim_direction = -global_basis.z.normalized()
	_recoil = move_toward(_recoil, 0.0, delta * 10.0)
	var host_basis := global_basis.orthonormalized()
	var pose_direction := aim_direction.normalized()
	if pose_direction.length_squared() < 0.01:
		pose_direction = -host_basis.z
	pose_direction.y = 0.0
	pose_direction = pose_direction.normalized()
	var pose_position := global_position + Vector3.UP * 1.13 + pose_direction * 0.06
	pose_position -= pose_direction * (0.045 * _recoil)
	var weapon_target := aim_world_point
	if pose_position.distance_squared_to(weapon_target) < 0.25:
		weapon_target = pose_position + pose_direction * 20.0
	var weapon_direction := pose_position.direction_to(weapon_target)
	var desired_pose := Transform3D(Basis.looking_at(weapon_direction, Vector3.UP), pose_position)
	var pose_blend := 1.0 - exp(-24.0 * delta)
	if _pose_initialized:
		weapon_pose_root.global_transform = weapon_pose_root.global_transform.interpolate_with(desired_pose, pose_blend)
	else:
		weapon_pose_root.global_transform = desired_pose
	_pose_initialized = true

func fire_recoil() -> void:
	_recoil = maxf(_recoil, clampf(0.065 * 8.0, 0.35, 1.0))

func get_muzzle_position() -> Vector3:
	return muzzle.global_position

func get_muzzle_direction() -> Vector3:
	return -muzzle.global_basis.z.normalized()

func _process(delta: float) -> void:
	if is_instance_valid(enemy) and not enemy.get("is_dead") and is_instance_valid(visual):
		_sync_visual(delta)

func _sync_visual(delta: float) -> void:
	elapsed += delta
	var direction := get_muzzle_direction()
	var local_direction := global_basis.inverse() * direction
	model.rotation.y = atan2(-local_direction.x, -local_direction.z)
	var moving := _move_speed
	var bob := sin(elapsed * 2.8) * 0.012
	for part_name in DEATH_PARTS:
		if part_name == "Gun":
			continue
		var part := model.find_child(part_name, true, false) as MeshInstance3D
		part.position = _rest_positions[part_name] + Vector3.UP * bob
		if part_name in ["PortPod", "StarboardPod"]:
			part.rotation.x = lerpf(part.rotation.x, -minf(moving, 3.2) * 0.018, minf(delta * 8.0, 1.0))
	# The native marker drives both actual fire and the authored visible bore.
	gun.global_transform = Transform3D(Basis.looking_at(direction, Vector3.UP), get_muzzle_position())
	if optics:
		optics.emission_energy_multiplier = 1.6 if enemy.get("_is_telegraphing") else 0.65 + 0.06 * sin(elapsed * 2.0)

func _on_died(_actor: Node) -> void:
	# EnemyController has already built its real six-body proxy before emitting died.
	# Skin those existing bodies only; preserve their shapes, impulses, joints and timer.
	var siblings := enemy.get_parent().get_children()
	siblings.reverse()
	for candidate in siblings:
		if not candidate is RagdollProxy or candidate.has_meta("drone_visual"):
			continue
		if not candidate.global_position.is_equal_approx(enemy.global_position):
			continue
		candidate.set_meta("drone_visual", true)
		for part_name in DEATH_PARTS:
			var body := candidate.get_node(str(DEATH_PARTS[part_name])) as RigidBody3D
			body.get_node("Mesh").visible = false
			var source := model.find_child(part_name, true, false) as MeshInstance3D
			var transform_at_death := source.global_transform
			var wreck := source.duplicate() as MeshInstance3D
			wreck.material_overlay = null
			for surface in wreck.mesh.get_surface_count():
				var material := wreck.get_active_material(surface) as StandardMaterial3D
				if material and material.resource_name == "Hostile optics":
					var unpowered := material.duplicate() as StandardMaterial3D
					unpowered.emission_enabled = false
					wreck.set_surface_override_material(surface, unpowered)
			body.add_child(wreck)
			wreck.global_transform = transform_at_death
		break
