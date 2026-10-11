extends Node
var failures := 0
var walls: Array[PackedVector3Array] = []
func blocked(origin: Vector3, focus: Vector3) -> bool:
	for vertices in walls:
		for index in range(0, vertices.size(), 3):
			if Geometry3D.segment_intersects_triangle(origin, focus, vertices[index], vertices[index+1], vertices[index+2]) != null:
				return true
	return false
func _ready() -> void:
	ProfileRuntime.new_profile()
	var hub = load("res://scenes/presentation/slice/hideout.tscn").instantiate()
	add_child(hub)
	for child in hub.get_node("CompactEnvironment").get_children():
		if "Wall" in str(child.name) or "Partition" in str(child.name) or "Doorway" in str(child.name) or str(child.name).begins_with("Front_") or str(child.name).begins_with("Rear_") or str(child.name).begins_with("West_") or str(child.name).begins_with("East_") or str(child.name).begins_with("Ceiling_") or child.name == "EntranceDoor":
			for mesh in child.find_children("*", "MeshInstance3D", true, false):
				var vertices: PackedVector3Array = mesh.mesh.get_faces()
				for index in vertices.size(): vertices[index] = mesh.global_transform * vertices[index]
				walls.append(vertices)
	await get_tree().process_frame
	await get_tree().process_frame
	for start in ["Overview", "Rest", "Operations", "Workshop", "Hanger"]:
		for destination in ["Rest", "Operations", "Workshop", "Hanger", "Overview"]:
			hub.show_section(start)
			await settle(hub, start)
			for frame in 60: await get_tree().process_frame
			hub.show_section(destination)
			var occluded := 0
			for frame in 1000:
				await get_tree().process_frame
				var position: Vector3 = hub.hanger.preview_character.global_position
				for point in [Vector3(0,0.4,0), Vector3(-0.25,1.0,0), Vector3(0.25,1.0,0), Vector3(0,1.8,0)]:
					if blocked(hub.camera.global_position, position + point): occluded += 1
				if arrived(hub, destination): break
			for frame in 60: await get_tree().process_frame
			if occluded > 0:
				failures += 1
				push_error("Camera obstruction %s -> %s: %d blocked body sightlines" % [start, destination, occluded])
	hub.queue_free()
	await get_tree().process_frame
	AudioDirector.shutdown_for_test()
	print("HIDEOUT_CAMERA_TEST: ", "PASS" if failures == 0 else "FAIL")
	get_tree().quit(0 if failures == 0 else 1)

func arrived(hub, destination: String) -> bool:
	return hub.relaxed_preview.destination_section == destination and hub.relaxed_preview.phase == "idle" and not hub.relaxed_preview.equipment_blend

func settle(hub, destination: String) -> void:
	for frame in 1000:
		await get_tree().process_frame
		if arrived(hub, destination): return
	failures += 1
	push_error("Camera route setup did not arrive at " + destination)
