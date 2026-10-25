extends SceneTree
## Rebuild only the dedicated geographic scene, never the authored legacy map.
func _initialize() -> void:
	if DisplayServer.get_name()=="headless":
		push_error("Bake with --rendering-method gl_compatibility (not --headless): DummyRenderer discards MultiMesh buffers.")
		quit(1)
		return
	var builder := preload("res://scripts/world/geography/campus_builder.gd").new()
	var world: Node3D = builder.build()
	if builder.stats.get("foliage_variants",0)!=4 or builder.stats.get("window_modules",0)<10000 or builder.stats.get("landmark_facades",0)!=4:
		push_error("Incomplete art bake: refusing to replace the geographic scene")
		world.free()
		quit(1)
		return
	root.add_child(world)
	for node: Node in world.find_children("*","",true,false):
		node.owner = world
	var scene := PackedScene.new()
	var error := scene.pack(world)
	if error == OK:
		DirAccess.make_dir_recursive_absolute("res://scenes/areas/campus_geography")
		error = ResourceSaver.save(scene,"res://scenes/areas/campus_geography/world.tscn")
	print("WEIJIN BUILD ",error," ",builder.stats)
	quit(0 if error == OK else 1)
