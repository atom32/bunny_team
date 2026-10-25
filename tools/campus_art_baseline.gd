extends SceneTree
## One-time independent comparison with the retained pre-art builder.
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var path:=OS.get_environment("BUNNY_BEFORE_BUILDER")
	if path.is_empty():quit(1);return
	var script: GDScript=load(path)
	var source: RefCounted=script.new()
	var world: Node3D=source.build()
	root.add_child(world)
	# Independent copy of the layout-only fingerprint, without loading gameplay
	# autoload dependencies in a SceneTree --script bootstrap.
	var parts: Array[String]=[]
	for node: CollisionShape3D in world.find_children("*","CollisionShape3D",true,false):
		var shape:=node.shape
		var dimensions: String=""
		if shape is ConcavePolygonShape3D:dimensions=str(shape.get_faces())
		elif shape is BoxShape3D:dimensions=str(shape.size)
		elif shape is ConvexPolygonShape3D:dimensions=str(shape.points)
		elif shape is SphereShape3D:dimensions=str(shape.radius)
		elif shape is CylinderShape3D or shape is CapsuleShape3D:dimensions=str([shape.radius,shape.height])
		parts.append(str([shape.get_class(),dimensions,node.global_transform]))
	parts.sort()
	var signature: String="\n".join(parts).sha256_text()
	print("PRE_ART_PHYSICS ",signature)
	var file:=FileAccess.open(OS.get_environment("BUNNY_EVIDENCE").path_join("physics_baseline.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"layout_sha256":signature,"data_sha256":FileAccess.get_sha256("res://assets/geography/weijin/campus.json"),"builder_sha256":FileAccess.get_sha256(path),"collision_shapes":world.find_children("*","CollisionShape3D",true,false).size()},"  "))
	world.free()
	quit()
