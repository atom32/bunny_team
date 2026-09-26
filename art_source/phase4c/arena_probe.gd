extends SceneTree
var folder := OS.get_environment("BUNNY_EVIDENCE")
var checks := {}

func _initialize() -> void:
	_run.call_deferred()

func fingerprint(node: Node, rows: Array) -> void:
	if node is CollisionShape3D:
		rows.append([node.get_class(),node.global_transform,node.disabled,node.shape.get_class(),
			node.shape.size if node.shape is BoxShape3D else node.shape.get_debug_mesh().get_aabb(),
			node.get_parent().collision_layer,node.get_parent().collision_mask])
	if node is NavigationRegion3D:
		var polygons := []
		for i in node.navigation_mesh.get_polygon_count():
			polygons.append(node.navigation_mesh.get_polygon(i))
		rows.append([node.get_class(),node.global_transform,node.navigation_mesh.vertices,polygons])
	for child in node.get_children(): fingerprint(child,rows)

func _run() -> void:
	var baseline := UrbanArena.new()
	root.add_child(baseline)
	var before := []
	fingerprint(baseline,before)
	baseline.queue_free()
	await process_frame
	var arena = load("res://scenes/battle/urban_arena.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	await process_frame
	var after := []
	fingerprint(arena,after)
	checks["collision_and_navigation_identical"] = before == after
	var presentation = arena.get_node("UrbanDefensePresentation")
	checks["eight_existing_barriers_skinned"] = presentation.original_meshes.size()==8 and presentation.get_child_count()==8
	checks["no_presentation_physics"] = presentation.find_children("*","CollisionObject3D",true,false).is_empty() and presentation.find_children("*","CollisionShape3D",true,false).is_empty()
	checks["shell_fits_original_collision"] = true
	for mesh in presentation.find_children("*","MeshInstance3D",true,false):
		var dimensions: Vector3 = mesh.mesh.get_aabb().size
		checks["shell_fits_original_collision"] = checks["shell_fits_original_collision"] and dimensions.x<=2.8 and dimensions.y<=.9 and dimensions.z<=.58
	var f := FileAccess.open(folder.path_join("arena_contract.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"physics_navigation_record_count":before.size(),
		"before_sha256":var_to_bytes(before).hex_encode().sha256_text(),
		"after_sha256":var_to_bytes(after).hex_encode().sha256_text()},"  "))
	print(checks)
	root.get_node("AudioDirector").shutdown_for_test()
	quit(1 if checks.values().has(false) else 0)
