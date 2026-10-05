extends SceneTree
## Controlled rendered visibility/cover fixture. Uses production actors/HUD/
## physics, not a new map, manual playthrough, or balance acceptance.
var evidence := OS.get_environment("BUNNY_EVIDENCE")
var world: Node3D
var player
var enemy
var sensor
var hud
var camera: Camera3D
var caption: Label
var failures: Array[String] = []
var records: Array = []

func _initialize() -> void:
	process_frame.connect(_resume_test_focus)
	_run.call_deferred()

func _run() -> void:
	if evidence.is_empty() or DisplayServer.get_name() == "headless": quit(2); return
	DirAccess.make_dir_recursive_absolute(evidence)
	root.size = Vector2i(1280, 720)
	world = Node3D.new()
	root.add_child(world)
	current_scene = world
	var env := WorldEnvironment.new()
	env.environment = RenderProfile.create_environment(Color("252e38"))
	world.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, -25, 0)
	light.shadow_enabled = true
	world.add_child(light)
	_box(Vector3(0, -.2, 0), Vector3(60, .4, 60), Color("35444c"))
	var profile = root.get_node("ProfileRuntime").new_profile()
	var plan = load("res://scripts/systems/deployment_plan.gd").build(profile)
	var session = root.get_node("SortieRuntime").start_sortie(profile.create_sortie_request(&"street_district", &"streets_recon", plan.carried_ids()), profile)
	player = load("res://scenes/player/player.tscn").instantiate()
	player.configure_sortie(session)
	world.add_child(player)
	player.set_physics_process(false)
	player.aim_direction = Vector3.FORWARD
	player.aim_world_point = Vector3(0, 1.1, -10)
	var definition = root.get_node("ContentDB").get_enemy_definition(&"prototype_basic_enemy")
	enemy = load("res://scripts/systems/enemy_spawn_service.gd").spawn(definition, Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, -8)), world)
	enemy.set_physics_process(false)
	sensor = load("res://scripts/battle/player_visibility.gd").new()
	sensor.actor = player
	world.add_child(sensor)
	sensor.track_enemy(enemy)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 24
	world.add_child(camera)
	camera.position = Vector3(9, 20, 16)
	camera.look_at(Vector3(0, 0, -2))
	camera.current = true
	var mouse := InputEventMouseMotion.new()
	mouse.position = camera.unproject_position(player.aim_world_point)
	mouse.global_position = mouse.position
	Input.parse_input_event(mouse)
	hud = load("res://scripts/ui/battle_hud.gd").new()
	world.add_child(hud)
	hud.set_health(player.health, player.max_health)
	var layer := CanvasLayer.new()
	world.add_child(layer)
	caption = Label.new()
	caption.position = Vector2(350, 134)
	caption.add_theme_font_size_override("font_size", 19)
	layer.add_child(caption)
	process_frame.connect(func():
		if is_instance_valid(player):
			hud.set_perception(sensor, camera)
			hud.set_ammo(player.get_magazine_ammo(), player.weapon_data.magazine_capacity, player.get_reserve_ammo()))
	for i in 30:
		player.combat_rig.update_pose(player.aim_world_point, player.aim_direction, 0, 1.0 / 60.0, true)
		player.animation_source_skeleton.advance(1.0 / 60.0)
		player.combat_rig.apply_skeleton_ik(1.0 / 60.0)
		await physics_frame
	check(sensor.can_see_enemy(enemy) and enemy.presentation.visible, "front contact visible")
	await _capture("01_observed", "FRONT CONTACT / actual sightline")
	var wall := _box(Vector3(0, 1.5, -4), Vector3(6, 3, .4), Color("758786"))
	for mesh in wall.find_children("*", "MeshInstance3D", true, false): mesh.transparency = .82
	await physics_frame
	await physics_frame
	sensor.refresh()
	sensor.hear(enemy.global_position, 40, &"gunfire")
	check(not enemy.presentation.visible and enemy.visible, "camera-faded wall still hides enemy but not its gameplay")
	await _capture("02_occluded", "WALL / camera fade does NOT reveal the actor\nHeard bearing only; no precise enemy marker")
	wall.free()
	await physics_frame
	await physics_frame
	sensor.refresh()
	check(enemy.presentation.visible, "opening sightline reacquires contact")
	await _capture("03_reacquired", "SIGHTLINE OPEN / contact reacquired")
	enemy.global_position = Vector3(0, 0, 8)
	enemy.rotation.y = 0
	await physics_frame
	await physics_frame
	sensor.refresh()
	enemy.target = player
	enemy._shot_aim_point = player.global_position + Vector3.UP * 1.05
	for i in 30: enemy._update_presentation(1.0 / 60.0, enemy._shot_aim_point, 0)
	var hp: float = player.health
	enemy._finish_telegraphed_shot(.01)
	await create_timer(.15).timeout
	hud.set_health(player.health, player.max_health)
	check(player.health < hp and not enemy.presentation.visible and sensor.heard_kind == &"gunfire", "unobserved rear attacker deals real damage and emits sound bearing")
	await _capture("04_rear_fire", "REAR SHOT / damage is real; shooter remains unseen\nSound cue is approximate and expires")
	enemy.position = Vector3(0, 0, -8)
	wall = _box(Vector3(0, 1.5, -1), Vector3(3, 3, .2), Color("758786"))
	await physics_frame
	await physics_frame
	var rounds: int = player.get_magazine_ammo()
	check(player.debug_fire_once() and player.get_magazine_ammo() == rounds - 1, "firing into cover still consumes actual ammunition")
	check(sensor.aim_trace().blocked, "actual weapon centerline reports cover")
	await _capture("05_cover", "COVER / amber warning and interception point\nNo reticle hit-confirm from hidden colliders")
	FileAccess.open(evidence.path_join("result.json"), FileAccess.WRITE).store_string(JSON.stringify({"pass": failures.is_empty(), "checks": 6, "failures": failures, "records": records, "scope": "Controlled rendered fixture: production actors, damage, ammo, physics, HUD. Fixed placements / faded test wall; not manual play or full mission."}, "\t"))
	for failure in failures: push_error("VISIBILITY_ROUTE: " + failure)
	root.get_node("SortieRuntime").clear_session()
	world.free()
	root.get_node("AudioDirector").shutdown_for_test()
	await create_timer(.5).timeout
	print("PLAYER_VISIBILITY_GRAPHICAL: ", "PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)

func _capture(name: String, text: String) -> void:
	caption.text = "ALPHA / PLAYER INFORMATION\n" + text
	hud.set_perception(sensor, camera)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(evidence.path_join(name + ".png"))
	records.append({"frame": name, "enemy_visible": enemy.presentation.visible, "root_visible": enemy.visible, "heard": str(sensor.heard_direction), "health": player.health, "blocked": sensor.aim_trace().blocked})

func _box(at: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = at
	body.collision_layer = 4
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = .85
	visual.material_override = material
	body.add_child(visual)
	world.add_child(body)
	return body

func check(condition: bool, message: String) -> void:
	print("VISIBILITY_ROUTE ", "PASS: " if condition else "FAIL: ", message)
	if not condition: failures.append(message)

func _resume_test_focus() -> void:
	if paused and root.get_node("FlowMenu").mode == "pause": root.get_node("FlowMenu").close()

