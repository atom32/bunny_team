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
	var enemy = load("res://scenes/enemies/enemy.tscn").instantiate()
	world.add_child(enemy)
	enemy.set_physics_process(false)
	await process_frame
	await process_frame
	_walk(enemy)
	var visual = enemy.humanoid_visual
	var muzzle = visual.combat_rig.muzzle
	var kite = enemy.get_node("EnemyDronePresentation")
	var result := {
		"scope": "Read-only instance of unchanged production enemy; no candidate or migration",
		"node_count": nodes.size(), "node_types": type_counts, "nodes": nodes,
		"legacy_avatar_runtime_dependency": true,
		"legacy_character_scene": visual.character_model.scene_file_path,
		"avatar_resource_cached": ResourceLoader.has_cached("res://assets/characters/vrm_avatar/avatar_sample_a.glb"),
		"legacy_model_hidden": not visual.character_model.visible,
		"legacy_muzzle_path": str(muzzle.get_path()),
		"muzzle_position": str(visual.get_muzzle_position()),
		"muzzle_direction": str(visual.get_muzzle_direction()),
		"kite_model_path": str(kite.visual.get_path()),
		"kite_native_muzzle_nodes": kite.visual.find_children("*", "Marker3D", true, false).size(),
		"character_bones": visual.character_skeleton.get_bone_count(),
		"animation_source_bones": visual.animation_source_skeleton.get_bone_count(),
		"animation_tree_active": visual.animation_tree.active,
		"retarget_present": visual.retarget_modifier != null,
		"real_hand_ik_present": visual.combat_rig.right_arm_ik != null and visual.combat_rig.left_arm_ik != null
	}
	var f := FileAccess.open(output.path_join("scene_audit.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(result, "  "))
	f.close()
	print("READ_ONLY_SCENE_AUDIT: recorded; migration NOT performed")
	world.queue_free()
	await process_frame
	await process_frame
	root.get_node("AudioDirector").shutdown_for_test()
	await create_timer(0.2).timeout
	quit(0)
