extends Node
## Visibility changes only. Never moves or rotates the gameplay camera.
var faded: Dictionary = {}
var aim_cutaways: Array[Node] = []
var render_hidden: Dictionary = {}
var needs_render_cutaway := RenderingServer.get_current_rendering_method() != "forward_plus"

func update_occlusion(camera: Camera3D, actor: Node3D, delta: float) -> void:
	_clear_aim_cutaways()
	var blocking := {}
	var world := actor.get_world_3d().direct_space_state
	for height in [0.55, 1.0, 1.35, 1.8, 2.1]:
		var focus: Vector3 = actor.global_position + Vector3.UP * height
		# Orthographic sightlines are parallel, not rays from the camera centre.
		var origin := camera.project_ray_origin(camera.unproject_position(focus))
		# Decorative canopies have no physics body: query their visual bounds only.
		for mesh: MeshInstance3D in get_tree().get_nodes_in_group("camera_occluder"):
			if not mesh.is_visible_in_tree() or mesh.is_in_group("camera_keep_visible"): continue
			var inverse := mesh.global_transform.affine_inverse()
			# A small margin covers thin trim between the sampled body heights.
			if mesh.get_aabb().grow(.12).intersects_segment(inverse * origin, inverse * focus) != null:
				blocking[mesh] = 0.88
				if not faded.has(mesh): faded[mesh] = mesh.transparency
		var exclude: Array[RID] = []
		if actor is CollisionObject3D: exclude.append(actor.get_rid())
		for _layer in 12:
			var query := PhysicsRayQueryParameters3D.create(origin, focus, 4)
			query.exclude = exclude
			query.collide_with_areas = true
			var hit := world.intersect_ray(query)
			if hit.is_empty(): break
			var body: Node = hit.collider
			# Only authored overhead roofs may be ignored by mouse picking.
			# Walls still block both aiming and projectiles even when faded.
			if body.is_in_group("aim_cutaway_roof") and not body in aim_cutaways:
				body.add_to_group("active_aim_cutaway")
				aim_cutaways.append(body)
			exclude.append(hit.rid)
			for mesh in body.find_children("*", "GeometryInstance3D", true, false):
				if not mesh.is_in_group("camera_keep_visible"):
					blocking[mesh] = 1.0 if body.is_in_group("aim_cutaway_roof") else 0.88
					if not faded.has(mesh): faded[mesh] = mesh.transparency
	for mesh in faded.keys():
		if not is_instance_valid(mesh):
			faded.erase(mesh)
			continue
		var original: float = faded[mesh]
		var goal := maxf(original, float(blocking[mesh])) if blocking.has(mesh) else original
		mesh.transparency = move_toward(mesh.transparency, goal, delta * 4.5)
		if not blocking.has(mesh) and is_equal_approx(mesh.transparency,original): faded.erase(mesh)
	if needs_render_cutaway:
		# Mobile/Compatibility ignore per-instance transparency. Hide only the
		# render instance: Node visibility stays truthful for canopy queries,
		# destruction and gameplay. Never duplicate or replace shared materials.
		for mesh in blocking:
			RenderingServer.instance_set_visible(mesh.get_instance(), false)
			render_hidden[mesh] = true
		for mesh in render_hidden.keys():
			if not is_instance_valid(mesh): render_hidden.erase(mesh)
			elif not blocking.has(mesh):
				RenderingServer.instance_set_visible(mesh.get_instance(), mesh.is_visible_in_tree())
				render_hidden.erase(mesh)

func _exit_tree() -> void:
	_clear_aim_cutaways()
	for mesh in faded:
		if is_instance_valid(mesh): mesh.transparency = faded[mesh]
	for mesh in render_hidden:
		if is_instance_valid(mesh): RenderingServer.instance_set_visible(mesh.get_instance(), mesh.is_visible_in_tree())

func _clear_aim_cutaways() -> void:
	for body in aim_cutaways:
		if is_instance_valid(body): body.remove_from_group("active_aim_cutaway")
	aim_cutaways.clear()
