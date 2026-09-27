extends SceneTree
var output := OS.get_environment("BUNNY_EVIDENCE")
var nodes := []
var type_counts := {}

func _initialize() -> void:
	_run.call_deferred()

func _walk(node: Node) -> void:
	var kind := node.get_class()
	type_counts[kind] = int(type_counts.get(kind, 0)) + 1
	var row := {"path": str(node.get_path()), "type": kind, "scene_file": node.scene_file_path}
	if node.get_script(): row["script"] = node.get_script().resource_path
	if node is Skeleton3D: row["bones"] = node.get_bone_count()
	if node is MeshInstance3D: row["skeleton_path"] = str(node.skeleton)
	if node is Node3D: row["visible_in_tree"] = node.is_visible_in_tree()
	nodes.append(row)
	for child in node.get_children(): _walk(child)

func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	current_scene = world
	var shared_animation_before := ResourceLoader.has_cached("res://assets/characters/unitychan_battle/animations/idle.fbx")
	var enemy = load("res://scenes/enemies/enemy.tscn").instantiate()
	world.add_child(enemy)
	enemy.set_physics_process(false)
	await process_frame
	await process_frame
	_walk(enemy)
	var adapter = enemy.presentation
	var skeletons := int(type_counts.get("Skeleton3D", 0))
	var avatar_cached := ResourceLoader.has_cached("res://assets/characters/vrm_avatar/avatar_sample_a.glb")
	var valid: bool = skeletons == 0 and not avatar_cached and adapter.muzzle.global_transform.is_finite()
	var result := {
		"scope": "Isolated production enemy instance; no oracle/debug scene loaded in this process",
		"node_count": nodes.size(), "node_types": type_counts, "nodes": nodes,
		"legacy_avatar_runtime_dependency": avatar_cached, "skeleton_count": skeletons, "bone_count": 0,
		"avatar_resource_cached": avatar_cached,
		"shared_animation_cached_before_enemy": shared_animation_before,
		"shared_animation_cached_after_enemy": ResourceLoader.has_cached("res://assets/characters/unitychan_battle/animations/idle.fbx"),
		"native_muzzle_path": str(adapter.muzzle.get_path()),
		"muzzle_position": str(adapter.get_muzzle_position()), "muzzle_direction": str(adapter.get_muzzle_direction()),
		"kite_model_path": str(adapter.visual.get_path()), "result": "PASS" if valid else "FAIL"
	}
	var f := FileAccess.open(output.path_join("native_scene_audit.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(result, "  "))
	f.close()
	print("NATIVE_SCENE_AUDIT: recorded")
	world.queue_free()
	await process_frame
	await process_frame
	root.get_node("AudioDirector").shutdown_for_test()
	await create_timer(0.2).timeout
	quit(0 if valid else 1)
