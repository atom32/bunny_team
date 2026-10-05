extends SceneTree
## Controlled comparison, not a production map/manual playtest. Real actors,
## perception, navigation, timers and damage; stationary player, no invulnerability.
var evidence := OS.get_environment("BUNNY_EVIDENCE")
var world: Node3D
var player
var enemy
var label: Label
var records: Array = []
var failures: Array[String] = []
var checks := 0

func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	if evidence.is_empty() or DisplayServer.get_name() == "headless": quit(2); return
	DirAccess.make_dir_recursive_absolute(evidence)
	world = Node3D.new()
	root.add_child(world)
	current_scene = world
	var environment := WorldEnvironment.new()
	environment.environment = RenderProfile.create_environment(Color("252e38"))
	world.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -25, 0)
	light.shadow_enabled = true
	world.add_child(light)
	_floor()
	var nav := NavigationRegion3D.new()
	var mesh := NavigationMesh.new()
	mesh.vertices = PackedVector3Array([Vector3(-30,0,-30),Vector3(30,0,-30),Vector3(30,0,30),Vector3(-30,0,30)])
	mesh.add_polygon(PackedInt32Array([0,3,2,1]))
	nav.navigation_mesh = mesh
	world.add_child(nav)
	var profile = root.get_node("ProfileRuntime").new_profile()
	var plan = load("res://scripts/systems/deployment_plan.gd").build(profile)
	var session = root.get_node("SortieRuntime").start_sortie(profile.create_sortie_request(&"street_district", &"streets_recon", plan.carried_ids()), profile)
	player = load("res://scenes/player/player.tscn").instantiate()
	player.configure_sortie(session)
	world.add_child(player)
	player.position = Vector3(0, 0, -12)
	Input.action_press("aim_down")
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 24
	world.add_child(camera)
	camera.position = Vector3(14, 24, 15)
	camera.look_at(Vector3(1, 0, -6))
	camera.current = true
	var ui := CanvasLayer.new()
	world.add_child(ui)
	label = Label.new()
	label.position = Vector2(24, 20)
	label.add_theme_font_size_override("font_size", 22)
	ui.add_child(label)
	_marker(Vector3(0, .1, 0), "POST / START")
	_marker(Vector3(0, .1, -12), "OBSERVED CONTACT")
	for tick in 120: await _tick()
	var roles = load("res://scripts/enemies/enemy_tactics.gd").Role
	var cases = [[roles.GUARD, "guard", "HOLD POST"], [roles.FLANKER, "flanker", "MOVE TO REACHABLE FLANK"], [roles.PRESSURE, "pressure", "CLOSE TO 4.5 m STANDOFF"]]
	for item in cases:
		enemy = load("res://scripts/systems/enemy_spawn_service.gd").spawn(root.get_node("ContentDB").get_enemy_definition(&"prototype_basic_enemy"), Transform3D.IDENTITY, world)
		enemy.tactics.role = item[0]
		enemy._strafe_direction = 1
		var before = player.health
		var path := PackedVector3Array()
		await _capture(item[1] + "_start", item[2] + " / same start, stats and target")
		for tick in 240:
			await _tick()
			if tick % 20 == 0: path.append(enemy.global_position + Vector3.UP * .07)
		path.append(enemy.global_position + Vector3.UP * .07)
		var trace := _trace(path)
		check(enemy.awareness.state == 2, item[1] + " acquires contact through actual sight")
		check(player.health < before, item[1] + " autonomous attack damages player")
		match item[0]:
			roles.GUARD: check(enemy.position.length() < .8, "guard remains at post")
			roles.FLANKER: check(enemy.position.x > 1.5, "flanker actually traverses laterally")
			roles.PRESSURE: check(enemy.position.z < -4 and enemy.position.distance_to(player.position) > 3, "pressure advances but retains standoff")
		await _capture(item[1] + "_end", item[2] + " / 4 s real simulation; line = travelled path")
		records.append({"role": item[1], "position": str(enemy.position), "goal": str(enemy.tactics.current_destination(enemy)), "player_damage": before - player.health, "trajectory": Array(path).map(func(v): return [v.x, v.y, v.z])})
		enemy.free()
		trace.free()
		for tick in 5: await _tick()
	check(not player.is_dead, "comparison completed without invulnerability or health reset")
	Input.action_release("aim_down")
	FileAccess.open(evidence.path_join("result.json"), FileAccess.WRITE).store_string(JSON.stringify({"pass": failures.is_empty(), "checks": checks, "failures": failures, "records": records, "scope": "Controlled rendered role comparison, identical camera/floor/stats, normal AI and damage. Not manual play or difficulty acceptance."}, "\t"))
	for failure in failures: push_error("TACTICS_ROUTE: " + failure)
	root.get_node("FlowMenu").close()
	root.get_node("SortieRuntime").clear_session()
	world.free()
	root.get_node("AudioDirector").shutdown_for_test()
	await create_timer(.5).timeout
	print("TACTICS_GRAPHICAL_ROUTE: ", "PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)

func _floor() -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 4
	body.position.y = -.2
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(60, .4, 60)
	shape.shape = box
	body.add_child(shape)
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = box.size
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("35444c")
	material.roughness = .85
	visual.material_override = material
	body.add_child(visual)
	world.add_child(body)

func _marker(at: Vector3, text: String) -> void:
	var marker := Label3D.new()
	marker.text = text
	marker.position = at + Vector3(0, 0, 1.2)
	marker.font_size = 32
	marker.pixel_size = .009
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	world.add_child(marker)

func _trace(path: PackedVector3Array) -> MeshInstance3D:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for at in path: mesh.surface_add_vertex(at)
	mesh.surface_end()
	var node := MeshInstance3D.new()
	node.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("77e3d6")
	node.material_override = material
	world.add_child(node)
	return node

func _capture(name: String, caption: String) -> void:
	label.text = "ALPHA / TACTICAL ROLES / CONTROLLED COMPARISON\n" + caption
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(evidence.path_join(name + ".png"))

func _tick() -> void:
	await physics_frame
	if paused and root.get_node("FlowMenu").mode == "pause": root.get_node("FlowMenu").close()

func check(condition: bool, message: String) -> void:
	checks += 1
	print("TACTICS_ROUTE ", "PASS: " if condition else "FAIL: ", message)
	if not condition: failures.append(message)
