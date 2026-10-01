extends SceneTree
func _initialize():
	run.call_deferred()
func run():
	root.size = Vector2i(800,800)
	var stage = Node3D.new()
	root.add_child(stage)
	var model = load("res://bunny_player.glb").instantiate()
	stage.add_child(model)
	var world = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("343e4c")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("e9edf5")
	env.ambient_light_energy = .65
	world.environment = env
	stage.add_child(world)
	for setup in [Vector3(-25,-145,1.1),Vector3(-30,40,.55)]:
		var light = DirectionalLight3D.new()
		light.rotation_degrees = Vector3(setup.x,setup.y,0)
		light.light_energy = setup.z
		stage.add_child(light)
	var cam = Camera3D.new()
	cam.projection=Camera3D.PROJECTION_ORTHOGONAL
	cam.size=.68
	cam.position=Vector3(0,1.63,-4)
	stage.add_child(cam)
	cam.look_at(Vector3(0,1.63,0))
	var meshes=model.find_children("*","MeshInstance3D",true,false)
	for variant in ["baseline","no_normal","clay","skin_wrap"]:
		for mesh in meshes:
			for i in mesh.mesh.get_surface_count():
				var m = mesh.mesh.surface_get_material(i).duplicate() as StandardMaterial3D
				mesh.set_surface_override_material(i,m)
				if variant=="no_normal":m.normal_enabled=false
				if variant=="clay":
					if m.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED:continue
					m.albedo_texture=null
					m.albedo_color=Color(.65,.65,.65)
					m.normal_enabled=false
					m.metallic=0
					m.metallic_texture=null
					m.roughness_texture=null
					m.roughness=.8
				if variant=="skin_wrap":
					if m.resource_name.begins_with("ArtoriaLancer_Head") or m.resource_name.begins_with("ArtoriaLancer_Body"):
						m.diffuse_mode=BaseMaterial3D.DIFFUSE_LAMBERT_WRAP
						m.roughness_texture=null
						m.roughness=.65
					if m.resource_name.begins_with("ArtoriaLancer_Hair"):
						m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
						m.alpha_scissor_threshold=.3
						m.alpha_antialiasing_mode=BaseMaterial3D.ALPHA_ANTIALIASING_ALPHA_TO_COVERAGE
						m.alpha_antialiasing_edge=.2
						m.roughness=.65
						m.metallic_specular=.25
					if m.resource_name.begins_with("ArtoriaLancer_Eyes"):
						m.emission_enabled=true
						m.emission_texture=m.albedo_texture
						m.emission=Color.WHITE
						m.emission_energy_multiplier=.12
		if variant=="skin_wrap":root.msaa_3d=Viewport.MSAA_4X
		for f in 8:await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/bunny-face-audit/godot_"+variant+".png")
	quit()
