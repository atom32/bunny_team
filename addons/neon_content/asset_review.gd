@tool
extends RefCounted
## Inspect native model data without running arbitrary scene scripts or animation events.
static func has_scripts(scene: PackedScene) -> bool:
	return _state_has_scripts(scene.get_state())

static func _state_has_scripts(state: SceneState) -> bool:
	var base := state.get_base_scene_state()
	if base and _state_has_scripts(base): return true
	for index in state.get_node_count():
		var nested := state.get_node_instance(index)
		if nested and has_scripts(nested): return true
		for property in state.get_node_property_count(index):
			if state.get_node_property_name(index, property) == &"script" and state.get_node_property_value(index, property): return true
	return false

static func inspect(scene: PackedScene) -> Dictionary:
	var report := {"pass": false, "errors": [], "warnings": [], "meshes": 0, "surfaces": 0, "vertices": 0, "triangles": 0, "materials": [], "skeletons": [], "clips": []}
	if not scene or has_scripts(scene):
		report.errors.append("Select an imported model or script-free wrapper; gameplay/@tool scripts are not executed")
		return report
	var instance := scene.instantiate()
	var root := instance as Node3D
	if not root:
		report.errors.append("Model root is not Node3D")
		instance.free()
		return report
	var bounds := AABB(); var first := true; var materials := {}
	var meshes := root.find_children("*", "MeshInstance3D", true, false)
	if root is MeshInstance3D: meshes.push_front(root)
	for mesh: MeshInstance3D in meshes:
		if not mesh.mesh: continue
		report.meshes += 1; report.surfaces += mesh.mesh.get_surface_count()
		var transform := mesh.transform
		var parent := mesh.get_parent()
		while parent and parent != root:
			if parent is Node3D: transform = parent.transform * transform
			parent = parent.get_parent()
		if mesh != root: transform = root.transform * transform
		var box: AABB = transform * mesh.get_aabb()
		bounds = box if first else bounds.merge(box); first = false
		for surface in mesh.mesh.get_surface_count():
			var arrays := mesh.mesh.surface_get_arrays(surface)
			if not arrays.is_empty():
				report.vertices += arrays[Mesh.ARRAY_VERTEX].size()
				var indices = arrays[Mesh.ARRAY_INDEX]
				report.triangles += (indices.size() if indices != null and not indices.is_empty() else arrays[Mesh.ARRAY_VERTEX].size()) / 3
			var material := mesh.get_active_material(surface)
			if not material: report.warnings.append("No active material: " + String(root.get_path_to(mesh)))
			elif not materials.has(material): materials[material] = {"type": material.get_class(), "path": material.resource_path, "name": material.resource_name}
	var skeletons := root.find_children("*", "Skeleton3D", true, false)
	if root is Skeleton3D: skeletons.push_front(root)
	for skeleton: Skeleton3D in skeletons:
		var bones := []
		for index in skeleton.get_bone_count():
			var rest := skeleton.get_bone_rest(index)
			bones.append({"name": String(skeleton.get_bone_name(index)), "parent": skeleton.get_bone_parent(index), "rest_position": [rest.origin.x, rest.origin.y, rest.origin.z]})
		report.skeletons.append({"path": String(root.get_path_to(skeleton)), "bones": bones})
	for player: AnimationPlayer in root.find_children("*", "AnimationPlayer", true, false):
		for name in player.get_animation_list(): report.clips.append(clip_report(player.get_animation(name), name))
	report.materials = materials.values()
	report.bounds = {"position": [bounds.position.x, bounds.position.y, bounds.position.z], "size": [bounds.size.x, bounds.size.y, bounds.size.z]}
	report.pass = report.meshes > 0
	root.free()
	return report

static func clip_report(animation: Animation, name: StringName) -> Dictionary:
	var tracks := []; var positional_gap := 0.0; var angular_gap := 0.0
	for index in animation.get_track_count():
		var count := animation.track_get_key_count(index)
		var type := animation.track_get_type(index)
		var track := {"path": String(animation.track_get_path(index)), "type": type, "keys": count}
		if count > 1 and type == Animation.TYPE_POSITION_3D:
			var start: Vector3 = animation.track_get_key_value(index, 0); var end: Vector3 = animation.track_get_key_value(index, count - 1)
			track.delta = [end.x-start.x, end.y-start.y, end.z-start.z]
			positional_gap = maxf(positional_gap, start.distance_to(end))
		if count > 1 and type == Animation.TYPE_ROTATION_3D:
			var start: Quaternion = animation.track_get_key_value(index, 0); var end: Quaternion = animation.track_get_key_value(index, count - 1)
			angular_gap = maxf(angular_gap, start.angle_to(end))
		tracks.append(track)
	return {"name": String(name), "duration": animation.length, "loop": animation.loop_mode, "tracks": tracks, "max_position_loop_gap": positional_gap, "max_rotation_loop_gap_degrees": rad_to_deg(angular_gap)}

static func safe_copy(animation: Animation) -> Animation:
	var copy := animation.duplicate(true) as Animation
	for index in copy.get_track_count():
		if copy.track_get_type(index) not in [Animation.TYPE_POSITION_3D, Animation.TYPE_ROTATION_3D, Animation.TYPE_SCALE_3D, Animation.TYPE_BLEND_SHAPE]: copy.track_set_enabled(index, false)
	return copy
