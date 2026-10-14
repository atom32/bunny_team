extends Node
const OUT := "/Users/xudawei/bunny_team/art_source/bunny_operator_20261010/fixture_evidence/"
var checks := []
func _ready() -> void:
	_run.call_deferred()
func check(ok: bool, title: String) -> void:
	checks.append({"pass":ok,"check":title})
	print("BUNNY_FIXTURE ", "PASS " if ok else "FAIL ",title)
func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var scene=load("res://scenes/art_showcase/bunny_operator.tscn").instantiate()
	add_child(scene)
	await get_tree().process_frame
	check(scene.review_fixture and scene.model != null,"explicit existing-character fixture, no new model claimed")
	if scene.model == null:
		get_tree().quit(1)
		return
	var meshes=scene.model.find_children("*","MeshInstance3D",true,false)
	check(meshes.size()==11,"normalized fixture preserves eleven render meshes")
	var bound := AABB()
	var first := true
	var textures := 0
	for mesh: MeshInstance3D in meshes:
		var current: AABB=evaluated_bounds(mesh)
		bound=current if first else bound.merge(current)
		first=false
		for index in mesh.mesh.get_surface_count():
			var material=mesh.mesh.surface_get_material(index)
			check(material != null,"material exists: "+mesh.name+" / "+str(index))
			if material is BaseMaterial3D and material.albedo_texture:
				textures+=1
				check(material.albedo_texture.get_width()>0,"embedded texture readable: "+mesh.name)
	check(absf(bound.size.y-2.05)<.001 and absf(bound.position.y)<.001,"root normalization gives 2.05m full height and feet at zero")
	check(textures>0,"fixture texture references are intact")
	var skeleton=scene.model.find_child("Skeleton3D",true,false)
	check(skeleton != null and skeleton.get_bone_count()>=52,"existing fixture skeleton survives export/import")
	for title in ["FRONT","RIGHT","BACK","GAME"]:
		scene.view(title)
		check(scene.camera.global_transform.is_finite(),"camera transform finite: "+title)
		await get_tree().create_timer(.25).timeout
		await RenderingServer.frame_post_draw
		check(get_tree().root.get_texture().get_image().save_png(OUT+title.to_lower()+".png")==OK,"fixture screenshot: "+title)
	var file=FileAccess.open(OUT+"validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"test_only_existing_character":true,"checks":checks,"bounds":{"min":str(bound.position),"size":str(bound.size)}},"  "));file.close()
	scene.queue_free()
	await get_tree().process_frame
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(.15).timeout
	get_tree().quit(0 if checks.all(func(row):return row.pass) else 1)

func evaluated_bounds(mesh: MeshInstance3D) -> AABB:
	var sk := mesh.get_node_or_null(mesh.skeleton) as Skeleton3D
	var bounds := AABB()
	var first := true
	var bone_ids: Array[int] = []
	if mesh.skin and sk:
		for bind in mesh.skin.get_bind_count():
			bone_ids.append(sk.find_bone(mesh.skin.get_bind_name(bind)) if mesh.skin.get_bind_name(bind) != &"" else mesh.skin.get_bind_bone(bind))
	for surface in mesh.mesh.get_surface_count():
		var arrays := mesh.mesh.surface_get_arrays(surface)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var joints: PackedInt32Array = arrays[Mesh.ARRAY_BONES] if arrays[Mesh.ARRAY_BONES] != null else PackedInt32Array()
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS] if arrays[Mesh.ARRAY_WEIGHTS] != null else PackedFloat32Array()
		var stride := int(joints.size()/verts.size())
		for index in verts.size():
			var point: Vector3
			if mesh.skin and sk and stride > 0:
				point = Vector3.ZERO
				for slot in stride:
					var bind := joints[index*stride+slot]
					var weight := weights[index*stride+slot]
					if weight > 0:
						point += (sk.get_bone_global_pose(bone_ids[bind])*mesh.skin.get_bind_pose(bind)*verts[index])*weight
				point = sk.to_global(point)
			else: point = mesh.to_global(verts[index])
			bounds = AABB(point, Vector3.ZERO) if first else bounds.expand(point)
			first = false
	return bounds
