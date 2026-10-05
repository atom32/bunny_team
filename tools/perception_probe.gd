extends SceneTree
## Rendered controlled encounter: real Player/Enemy controllers, Input actions,
## collision, navigation and engine time. Test floor/occluder, not a new game map.
var evidence = OS.get_environment("BUNNY_EVIDENCE")
var player
var enemy
var world: Node3D
var camera: Camera3D
var label: Label
var failures: Array[String] = []
var records: Array = []

func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	if evidence.is_empty() or DisplayServer.get_name() == "headless": quit(2); return
	DirAccess.make_dir_recursive_absolute(evidence)
	world = Node3D.new()
	root.add_child(world)
	current_scene = world
	var env = WorldEnvironment.new()
	env.environment = RenderProfile.create_environment(Color("252e38"))
	world.add_child(env)
	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, -25, 0)
	light.shadow_enabled = true
	world.add_child(light)
	_box(Vector3(0, -.2, 0), Vector3(120, .4, 120), Color("35444c"))
	_box(Vector3(0, 1.5, 0), Vector3(10, 3, .4), Color("808d8c"))
	var nav = NavigationRegion3D.new()
	var mesh = NavigationMesh.new()
	var vertices = PackedVector3Array()
	for z in [-58.0, -.8, .8, 58.0]:
		for x in [-58.0, -5.6, 5.6, 58.0]: vertices.append(Vector3(x, 0, z))
	mesh.vertices = vertices
	for z in 3:
		for x in 3:
			if x == 1 and z == 1: continue
			var i = z * 4 + x
			mesh.add_polygon(PackedInt32Array([i, i + 4, i + 5, i + 1]))
	nav.navigation_mesh = mesh
	world.add_child(nav)
	var profile = root.get_node("ProfileRuntime").new_profile()
	var plan = load("res://scripts/systems/deployment_plan.gd").build(profile)
	var session = root.get_node("SortieRuntime").start_sortie(profile.create_sortie_request(&"street_district", &"streets_recon", plan.carried_ids()), profile)
	player = load("res://scenes/player/player.tscn").instantiate()
	player.configure_sortie(session)
	world.add_child(player)
	player.position = Vector3(0, 0, 6)
	var definition = root.get_node("ContentDB").get_enemy_definition(&"prototype_basic_enemy" if "--human" in OS.get_cmdline_user_args() else &"prototype_heavy_enemy")
	enemy = load("res://scripts/systems/enemy_spawn_service.gd").spawn(definition, Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, -9)), world)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 39
	world.add_child(camera)
	camera.position = Vector3(0, 30, 25)
	camera.look_at(Vector3(0, 0, 3))
	camera.current = true
	var ui = CanvasLayer.new()
	world.add_child(ui)
	label = Label.new()
	label.position = Vector2(24, 20)
	label.add_theme_font_size_override("font_size", 22)
	ui.add_child(label)
	await create_timer(.8).timeout
	check(enemy.awareness.state == EnemyAwareness.State.PATROL and not enemy.can_see_target(), "idle behind wall is not detected")
	await _capture("01_unaware", "PATROL / wall blocks vision")
	check(await _walk(Vector3(2, 0, 6), true), "quiet movement uses actual input")
	check(enemy.awareness.state == EnemyAwareness.State.PATROL, "quiet movement behind wall does not alert drone")
	Input.action_press("aim_down")
	Input.action_press("fire")
	await create_timer(.14).timeout
	Input.action_release("fire")
	Input.action_release("aim_down")
	check(enemy.awareness.state == EnemyAwareness.State.INVESTIGATE and not enemy._is_telegraphing, "gunfire triggers investigation without shooting through wall")
	await _capture("02_heard", "? / gunfire heard, no visual target")
	check(await _walk(Vector3(9, 0, 6), false), "move around cover")
	check(await _walk(Vector3(9, 0, -3), false), "enter real sightline")
	var engaged = false
	for tick in 180:
		await _tick()
		if enemy._engaged: engaged = true; break
	check(engaged, "actual AI acquires visible player")
	await _capture("03_detected", "! / visual contact confirmed")
	var before_attack = player.health
	await create_timer(4.0).timeout
	check(player.health < before_attack, "autonomous sight-confirmed attack damages real player")
	check(await _walk(Vector3(9, 0, 8), false), "retreat along cover edge")
	check(await _walk(Vector3(-40, 0, 34), false), "escape beyond sound and sight range")
	await create_timer(.6).timeout
	check(not enemy.can_see_target() and not enemy._engaged, "breaking contact clears combat lock")
	var last_known = enemy.awareness.last_known
	await _capture("04_search", "SEARCH / last observation, not current player position")
	check(await _walk(Vector3(-43, 0, 34), true), "quiet relocation while hidden")
	check(enemy.awareness.last_known.distance_to(last_known) < .001, "hidden relocation does not update AI knowledge")
	var returned = false
	for tick in 2400:
		await _tick()
		if enemy.awareness.state == EnemyAwareness.State.PATROL: returned = true; break
	check(returned, "finite search returns to patrol through real navigation")
	await _capture("05_disengaged", "PATROL / contact lost, home patrol resumed")
	check(not player.is_dead, "encounter remains survivable without invulnerability")
	for failure in failures: push_error("PERCEPTION_ROUTE: " + failure)
	FileAccess.open(evidence.path_join("result.json"), FileAccess.WRITE).store_string(JSON.stringify({"pass": failures.is_empty(), "failures": failures, "records": records, "player_health": player.health, "scope": "Controlled rendered encounter; real controllers/physics/input, test floor and occluder. Not manual play or a full mission."}, "\t"))
	root.get_node("FlowMenu").close()
	root.get_node("SortieRuntime").clear_session()
	world.free()
	root.get_node("AudioDirector").shutdown_for_test()
	await create_timer(.5).timeout
	print("PERCEPTION_GRAPHICAL_ROUTE: ", "PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)

func _walk(destination: Vector3, quiet: bool) -> bool:
	if quiet: Input.action_press("precision_walk")
	for tick in 900:
		await _tick()
		var gap = destination - player.global_position
		gap.y = 0
		for action in ["move_left", "move_right", "move_forward", "move_back"]: Input.action_release(action)
		if gap.length() < .5:
			Input.action_release("precision_walk")
			return true
		if player.is_dead: break
		gap = gap.normalized()
		Input.action_press("move_right" if gap.x >= 0 else "move_left", absf(gap.x))
		Input.action_press("move_back" if gap.z >= 0 else "move_forward", absf(gap.z))
	for action in ["move_left", "move_right", "move_forward", "move_back", "precision_walk"]: Input.action_release(action)
	return false

func _box(position: Vector3, size: Vector3, color: Color) -> void:
	var body = StaticBody3D.new()
	body.collision_layer = 4
	body.position = position
	var shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	var visual = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = .85
	visual.material_override = material
	body.add_child(visual)
	world.add_child(body)

func _capture(name: String, caption: String) -> void:
	label.text = "ALPHA / PERCEPTION VALIDATION\n" + caption
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(evidence.path_join(name + ".png"))
	records.append({"frame": name, "state": enemy.awareness.state, "known": str(enemy.awareness.last_known), "enemy": str(enemy.global_position), "player": str(player.global_position), "health": player.health, "muzzle": str(enemy.presentation.get_muzzle_position())})

func check(condition: bool, message: String) -> void:
	print("PERCEPTION_ROUTE ", "PASS: " if condition else "FAIL: ", message)
	if not condition: failures.append(message)

func _tick() -> void:
	await physics_frame
	if paused and root.get_node("FlowMenu").mode == "pause":
		print("PERCEPTION_ROUTE: resume isolated test after window focus loss")
		root.get_node("FlowMenu").close()
