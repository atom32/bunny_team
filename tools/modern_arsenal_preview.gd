extends SceneTree
## Render the production weapon scenes as a comparison sheet in an imported copy.
## MODERN_ARSENAL_PREVIEW must be an absolute output PNG path outside the project.

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var path := OS.get_environment("MODERN_ARSENAL_PREVIEW")
	if path.is_empty() or DisplayServer.get_name() == "headless":
		push_error("Provide MODERN_ARSENAL_PREVIEW and a graphics renderer")
		quit(2)
		return
	root.size = Vector2i(1280, 1120)
	root.content_scale_size = Vector2i(1280, 1120)
	var stage := Node3D.new()
	root.add_child(stage)
	current_scene = stage
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("20282c")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("d5e2ec")
	environment.environment.ambient_light_energy = .7
	stage.add_child(environment)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-28, -35, 0)
	key.light_energy = 2.1
	stage.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(20, 125, 0)
	fill.light_energy = 1.1
	stage.add_child(fill)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 4.25
	camera.position = Vector3(0, 0, 5)
	stage.add_child(camera)
	camera.current = true
	var index := 0
	var content := root.get_node("ContentDB")
	for key_name in ["pistol", "smg", "assault_rifle", "shotgun", "sniper", "lmg", "rocket_launcher"]:
		var weapon: Resource = content.get_weapon(StringName("weapon." + key_name + "_01"))
		var model := weapon.scene.instantiate() as Node3D
		model.scale = Vector3.ONE * .44
		model.rotation_degrees.y = -82
		stage.add_child(model)
		var bounds := AABB()
		var first := true
		for node in model.get_node("Art").find_children("*", "MeshInstance3D", true, false):
			var mesh := node as MeshInstance3D
			var box := mesh.global_transform * mesh.get_aabb()
			bounds = box if first else bounds.merge(box)
			first = false
		var center := Vector3(-1.0 + (index % 2) * 2.0, 1.22 - (index / 2) * .78, 0)
		model.position += center - bounds.get_center()
		_label(stage, weapon.display_name, center + Vector3(0, .29, .12), 35, Color("f2f1e9"))
		var ammo: Resource = content.get_ammo(weapon.get_runtime_ammo_definition_id())
		_label(stage, "%s  |  MAG %d" % [ammo.display_name, weapon.magazine_capacity], center + Vector3(0, -.27, .12), 25, Color("a9bdc5"))
		index += 1
	_label(stage, "MODERN ARSENAL\n6 FIREARM CLASSES + RPG", Vector3(1, -1.12, .1), 38, Color("d4b98b"))
	for frame in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(path)
	root.get_node("AudioDirector").shutdown_for_test()
	print("MODERN_ARSENAL_PREVIEW: ", "PASS" if error == OK else "FAIL")
	quit(0 if error == OK else 1)

func _label(parent: Node3D, text: String, position: Vector3, size: int, color: Color) -> void:
	var label := Label3D.new()
	label.text = text
	label.position = position
	label.font_size = size
	label.pixel_size = .0018
	label.modulate = color
	label.outline_size = 0
	label.no_depth_test = true
	parent.add_child(label)
