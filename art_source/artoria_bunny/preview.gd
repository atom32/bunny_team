extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.size = Vector2i(800, 1000)
	var stage := Node3D.new()
	root.add_child(stage)
	var model := load("res://bunny_player.glb").instantiate() as Node3D
	stage.add_child(model)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("343e4c")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("e9edf5")
	environment.environment.ambient_light_energy = .65
	stage.add_child(environment)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-25, -145, 0)
	key.light_energy = 1.4
	stage.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-30, 40, 0)
	fill.light_energy = .75
	stage.add_child(fill)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.4
	camera.position = Vector3(.25, 1.25, -4)
	stage.add_child(camera)
	camera.look_at(Vector3(0, .97, 0))
	camera.current = true
	for frame in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/artoria_game_export_front.png")
	camera.position = Vector3(.7,3.0,2.3)
	camera.look_at(Vector3(0,.97,0))
	for frame in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/artoria_game_export_back.png")
	var skeleton := model.find_child("Skeleton3D",true,false) as Skeleton3D
	print("BONES ",skeleton.get_bone_count()," TRANSFORM ",skeleton.transform)
	for name in ["Character1_Hips","Character1_Head","Character1_LeftArm","Character1_LeftHand","Character1_LeftFoot"]:
		print(name," ",skeleton.get_bone_global_rest(skeleton.find_bone(name)))
	quit()
