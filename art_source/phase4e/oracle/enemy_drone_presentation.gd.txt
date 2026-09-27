extends Node3D
## Visible-only skin. The original rig remains the authoritative hitscan driver.
const VISUAL_PATH := "res://scenes/presentation/enemies/kite_security.tscn"
const DEATH_PARTS := {
	"Chassis": "Torso", "Sensor": "Head", "PortPod": "ArmL",
	"StarboardPod": "ArmR", "Gun": "LegL", "RearPack": "LegR",
}

var enemy: EnemyController
var legacy: HumanoidRetargetVisual
var visual: Node3D
var model: Node3D
var gun: MeshInstance3D
var optics: StandardMaterial3D
var elapsed := 0.0
var _rest_positions := {}

func _ready() -> void:
	_install.call_deferred()

func _install() -> void:
	enemy = get_parent() as EnemyController
	if not enemy or not enemy.humanoid_visual:
		return
	legacy = enemy.humanoid_visual
	# Hide rendering, not evaluation, markers, animation or the firing contract.
	legacy.animation_source_model.visible = false
	legacy.character_model.visible = false
	legacy.weapon_visual.visible = false
	# Defer resource loading until scene use; fresh editor autoload scanning must
	# not require a GLB that the import queue has not processed yet.
	visual = load(VISUAL_PATH).instantiate()
	legacy.add_child(visual)
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
	enemy.died.connect(_on_died)
	_sync_visual(0.0)

func _process(delta: float) -> void:
	if is_instance_valid(enemy) and not enemy.is_dead and is_instance_valid(visual):
		_sync_visual(delta)

func _sync_visual(delta: float) -> void:
	elapsed += delta
	var direction := legacy.get_muzzle_direction()
	var local_direction := legacy.global_basis.inverse() * direction
	model.rotation.y = atan2(-local_direction.x, -local_direction.z)
	var moving := Vector2(enemy.velocity.x, enemy.velocity.z).length()
	var bob := sin(elapsed * 2.8) * 0.012
	for part_name in DEATH_PARTS:
		if part_name == "Gun":
			continue
		var part := model.find_child(part_name, true, false) as MeshInstance3D
		part.position = _rest_positions[part_name] + Vector3.UP * bob
		if part_name in ["PortPod", "StarboardPod"]:
			part.rotation.x = lerpf(part.rotation.x, -minf(moving, 3.2) * 0.018, minf(delta * 8.0, 1.0))
	# Authored gun origin is its bore. Never move/reparent the gameplay Muzzle.
	gun.global_transform = Transform3D(Basis.looking_at(direction, Vector3.UP), legacy.get_muzzle_position())
	if optics:
		optics.emission_energy_multiplier = 1.6 if enemy._is_telegraphing else 0.65 + 0.06 * sin(elapsed * 2.0)

func _on_died(_actor: EnemyController) -> void:
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
