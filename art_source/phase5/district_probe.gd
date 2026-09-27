extends SceneTree
var out := OS.get_environment("BUNNY_EVIDENCE")
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	root.size = Vector2i(1280,720)
	var area = load("res://scenes/areas/prototype_arena.tscn").instantiate()
	root.add_child(area)
	current_scene = area
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 120
	area.add_child(camera)
	camera.position = Vector3(0,80,-15)
	camera.look_at(Vector3(0,0,-80))
	camera.current = true
	await create_timer(0.7).timeout
	var region = area.find_child("NavigationRegion3D",true,false)
	var checks := {}
	var paths := []
	for x in [-32.0,0.0,32.0]:
		var path := NavigationServer3D.map_get_path(region.get_navigation_map(),Vector3(x,0,-50),Vector3(x,0,-106),true)
		checks["north_connector_"+str(x)] = path.size()>=2 and path[path.size()-1].distance_to(Vector3(x,0,-106)) < 0.5
		paths.append(str(path))
	checks["three_districts_render"] = area.find_child("NorthDistricts",true,false) != null
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("north_districts.png"))
	var f:= FileAccess.open(out.path_join("result.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"paths":paths},"  "))
	print(JSON.stringify(checks))
	area.queue_free()
	await process_frame
	root.get_node("AudioDirector").shutdown_for_test()
	quit(1 if checks.values().has(false) else 0)
