class_name RagdollProxy
extends Node3D

const PARTS := [
	["Torso", Vector3(0.0, 1.25, 0.0), Vector3(0.55, 0.72, 0.3), 3.0],
	["Head", Vector3(0.0, 1.9, 0.0), Vector3(0.38, 0.38, 0.38), 1.0],
	["ArmL", Vector3(-0.47, 1.25, 0.0), Vector3(0.2, 0.7, 0.2), 0.8],
	["ArmR", Vector3(0.47, 1.25, 0.0), Vector3(0.2, 0.7, 0.2), 0.8],
	["LegL", Vector3(-0.2, 0.48, 0.0), Vector3(0.24, 0.82, 0.26), 1.2],
	["LegR", Vector3(0.2, 0.48, 0.0), Vector3(0.24, 0.82, 0.26), 1.2],
]


func build(primary_color: Color, impulse: Vector3) -> void:
	var bodies: Dictionary = {}
	for definition in PARTS:
		var color := primary_color if definition[0] == "Torso" else primary_color.lightened(0.18)
		bodies[definition[0]] = _make_part(definition[0], definition[1], definition[2], definition[3], color, impulse)
	_connect_parts(bodies)
	var timer := Timer.new()
	timer.name = "CleanupTimer"
	timer.one_shot = true
	timer.wait_time = 8.0
	add_child(timer)
	timer.timeout.connect(queue_free)
	timer.start()


func _make_part(
	part_name: String,
	part_position: Vector3,
	size: Vector3,
	mass: float,
	color: Color,
	impulse: Vector3
) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.name = part_name
	body.position = part_position
	body.mass = mass
	body.collision_layer = 0
	body.collision_mask = 4
	body.linear_velocity = impulse + Vector3(randf_range(-0.6, 0.6), randf_range(0.4, 1.2), randf_range(-0.6, 0.6))
	body.angular_velocity = Vector3(randf_range(-3.0, 3.0), randf_range(-3.0, 3.0), randf_range(-3.0, 3.0))
	add_child(body)
	VisualFactory.box(body, size, Vector3.ZERO, color, "Mesh")
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	return body


func _connect_parts(bodies: Dictionary) -> void:
	_add_joint("Neck", Vector3(0.0, 1.63, 0.0), bodies.Torso, bodies.Head)
	_add_joint("ShoulderL", Vector3(-0.33, 1.45, 0.0), bodies.Torso, bodies.ArmL)
	_add_joint("ShoulderR", Vector3(0.33, 1.45, 0.0), bodies.Torso, bodies.ArmR)
	_add_joint("HipL", Vector3(-0.18, 0.85, 0.0), bodies.Torso, bodies.LegL)
	_add_joint("HipR", Vector3(0.18, 0.85, 0.0), bodies.Torso, bodies.LegR)


func _add_joint(joint_name: String, joint_position: Vector3, a: RigidBody3D, b: RigidBody3D) -> void:
	var joint := ConeTwistJoint3D.new()
	joint.name = joint_name
	joint.position = joint_position
	add_child(joint)
	joint.node_a = joint.get_path_to(a)
	joint.node_b = joint.get_path_to(b)
