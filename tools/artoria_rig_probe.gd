extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.size = Vector2i(1000,1000)
	var stage := Node3D.new()
	root.add_child(stage)
	current_scene = stage
	var player = load("res://scenes/player/player.tscn").instantiate()
	player.preview_mode = true
	stage.add_child(player)
	player.equip_weapon(root.get_node("ContentDB").get_weapon(&"weapon.assault_rifle_01"))
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("343e4c")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_energy = .7
	stage.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-30,-150,0)
	stage.add_child(light)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.3
	cam.position = Vector3(.5,1.25,-4)
	stage.add_child(cam)
	cam.look_at(Vector3(0,1,0))
	for frame in 60:
		await physics_frame
	for side in ["front","side","back"]:
		cam.position = {"front":Vector3(.5,1.25,-4),"side":Vector3(4,1.2,0),"back":Vector3(1,3,2.8)}[side]
		cam.look_at(Vector3(0,1,0))
		for frame in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/artoria_rig_"+side+".png")
	var sk = player.character_skeleton
	for name in ["Character1_Hips","Character1_Head","Character1_LeftFoot","Character1_LeftHand","Character1_RightHand"]:
		print(name, " ",sk.global_transform * sk.get_bone_global_pose(sk.find_bone(name)))
	print("GUN ",player.equipped_weapon_visual.global_transform)
	print("ERROR ",player.combat_rig.get_hand_error(&"right")," ",player.combat_rig.get_hand_error(&"left"))
	player.set_process(false)
	player.body_visual.rotation.y = 0
	for id in [&"prototype_basic_enemy", &"prototype_heavy_enemy"]:
		var enemy = load("res://scenes/enemies/enemy.tscn").instantiate()
		enemy.configure_from_definition(root.get_node("ContentDB").get_enemy_definition(id))
		stage.add_child(enemy)
		enemy.set_physics_process(false)
		enemy.position.x = -1.5 if id == &"prototype_basic_enemy" else 1.5
		for frame in 20:
			enemy.presentation.update_visual(enemy.position + Vector3(0,1,-10), Vector3.ZERO, 0, 1.0/60.0)
			await process_frame
	cam.size = 5.3
	cam.position = Vector3(1,3,-7)
	cam.look_at(Vector3(0,.8,0))
	for frame in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/artoria_enemy_lineup.png")
	player.queue_free()
	await process_frame
	root.get_node("AudioDirector").shutdown_for_test()
	quit()
