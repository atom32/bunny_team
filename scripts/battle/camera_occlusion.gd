extends Node
## Visibility changes only. Never moves or rotates the gameplay camera.
var faded: Dictionary = {}

func update_occlusion(camera: Camera3D, actor: Node3D, delta: float) -> void:
	var blocking := {}
	var world := actor.get_world_3d().direct_space_state
	for height in [0.55, 1.35, 1.8]:
		var focus: Vector3 = actor.global_position + Vector3.UP * height
		var exclude: Array[RID] = []
		if actor is CollisionObject3D: exclude.append(actor.get_rid())
		for _layer in 12:
			var query := PhysicsRayQueryParameters3D.create(camera.global_position, focus, 4)
			query.exclude = exclude
			query.collide_with_areas = true
			var hit := world.intersect_ray(query)
			if hit.is_empty(): break
			var body: Node = hit.collider
			exclude.append(hit.rid)
			for mesh in body.find_children("*", "GeometryInstance3D", true, false):
				if not mesh.is_in_group("camera_keep_visible"):
					blocking[mesh] = true
					if not faded.has(mesh): faded[mesh] = mesh.transparency
	for mesh in faded.keys():
		if not is_instance_valid(mesh):
			faded.erase(mesh)
			continue
		var original: float = faded[mesh]
		var goal := maxf(original, 0.88) if blocking.has(mesh) else original
		mesh.transparency = move_toward(mesh.transparency, goal, delta * 4.5)
		if not blocking.has(mesh) and is_equal_approx(mesh.transparency,original): faded.erase(mesh)

func _exit_tree() -> void:
	for mesh in faded:
		if is_instance_valid(mesh): mesh.transparency = faded[mesh]
