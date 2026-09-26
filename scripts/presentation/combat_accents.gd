extends RefCounted
## Visual-only geometry. No state writes, physics, extra lights or RNG calls.
const FLASH := preload("res://resources/vfx/combat_flash.gdshader")

static func quad(parent: Node, size: Vector2, color: Color, shape: int, label: String) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	var mesh := QuadMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := ShaderMaterial.new()
	material.shader = FLASH
	material.set_shader_parameter("tint", color)
	material.set_shader_parameter("shape", shape)
	# Explicit value also exposes the tween property on the headless renderer.
	material.set_shader_parameter("opacity", 1.0)
	node.material_override = material
	parent.add_child(node)
	return node

static func muzzle(root: Node3D, color: Color, intensity: float) -> void:
	# Crossed forward jets remain visible from top-down and side cameras.
	for angle in [0.0, PI * 0.5]:
		var jet := quad(root, Vector2(0.34, 0.68) * intensity, color, 0, "DirectionalFlash")
		jet.basis = Basis(Vector3.BACK, angle) * Basis(Vector3.RIGHT, PI * 0.5)
		jet.position.z = -0.29 * intensity

static func smoke(parent: Node, position: Vector3, radius: float, duration: float, label: String) -> void:
	var puff := SoftSmoke.create(parent, position, radius, Color(0.48, 0.53, 0.57, 0.24), label)
	var mat := puff.material_override as StandardMaterial3D
	var tween := puff.create_tween().set_parallel(true)
	tween.tween_property(puff, "scale", Vector3.ONE * 2.4, duration)
	tween.tween_property(puff, "position:y", position.y + radius * 1.3, duration)
	tween.tween_property(mat, "albedo_color:a", 0.0, duration)
	tween.chain().tween_callback(puff.queue_free)

static func impact(parent: Node, position: Vector3, color: Color, intensity: float) -> MeshInstance3D:
	var flash := quad(parent, Vector2.ONE * 0.66 * intensity, color, 1, "HitEffect")
	flash.position = position
	var camera := parent.get_viewport().get_camera_3d()
	if camera:
		flash.global_basis = camera.global_basis
	smoke(parent, position, 0.16 * intensity, 0.25 * intensity, "ImpactSmoke")
	var mat := flash.material_override as ShaderMaterial
	flash.create_tween().tween_property(mat, "shader_parameter/opacity", 0.0, 0.15)
	return flash

static func dodge(parent: Node, position: Vector3, direction: Vector3) -> void:
	var forward := Vector3(direction.x, 0, direction.z).normalized()
	if forward.is_zero_approx():
		return
	var side := forward.cross(Vector3.UP)
	for sign_value in [-1.0, 1.0]:
		var streak := quad(parent, Vector2(0.30, 1.55), Color("59cddbcc"), 2, "DodgeStreak")
		streak.position = position - forward * 0.65 + side * sign_value * 0.32
		streak.position.y = 0.08
		streak.basis = Basis(side, forward, Vector3.UP)
		var mat := streak.material_override as ShaderMaterial
		var tween := streak.create_tween()
		tween.tween_property(mat, "shader_parameter/opacity", 0.0, 0.22)
		tween.tween_callback(streak.queue_free)
