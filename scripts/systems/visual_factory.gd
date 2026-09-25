class_name VisualFactory
extends RefCounted


static func material(
	color: Color,
	metallic: float = 0.0,
	roughness: float = 0.75,
	emission: Color = Color.TRANSPARENT,
	emission_energy: float = 0.0
) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.metallic = metallic
	result.roughness = roughness
	if emission_energy > 0.0:
		result.emission_enabled = true
		result.emission = emission
		result.emission_energy_multiplier = emission_energy
	return result


static func box(
	parent: Node,
	size: Vector3,
	position: Vector3,
	color: Color,
	node_name: String = "Box"
) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = position
	instance.material_override = material(color)
	parent.add_child(instance)
	return instance


static func sphere(
	parent: Node,
	radius: float,
	position: Vector3,
	color: Color,
	node_name: String = "Sphere"
) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = position
	instance.material_override = material(color)
	parent.add_child(instance)
	return instance


static func cylinder(
	parent: Node,
	radius: float,
	height: float,
	position: Vector3,
	color: Color,
	node_name: String = "Cylinder"
) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = position
	instance.material_override = material(color)
	parent.add_child(instance)
	return instance


static func static_box(
	parent: Node,
	size: Vector3,
	position: Vector3,
	color: Color,
	node_name: String = "StaticBox"
) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
	body.collision_layer = 4
	body.collision_mask = 0
	parent.add_child(body)
	box(body, size, Vector3.ZERO, color, "Mesh")
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	return body


static func add_world_environment(parent: Node, background: Color) -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = background
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("66645f")
	environment.ambient_light_energy = 0.8
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world := WorldEnvironment.new()
	world.environment = environment
	parent.add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-52.0, -35.0, 0.0)
	light.light_color = Color(0.88, 0.93, 1.0)
	light.light_energy = 1.25
	light.shadow_enabled = true
	parent.add_child(light)
