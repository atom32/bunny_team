extends SceneTree
## Controlled asset review, NOT production route/AI acceptance.
var out := OS.get_environment("BUNNY_EVIDENCE")
var actor: Node3D
var world: Node3D
var camera: Camera3D

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	world=Node3D.new()
	root.add_child(world)
	current_scene=world
	var env:=WorldEnvironment.new()
	var settings:=Environment.new()
	settings.background_mode=Environment.BG_COLOR
	settings.background_color=Color("1d2830")
	settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color=Color("c0ced5")
	settings.ambient_light_energy=.65
	env.environment=settings
	world.add_child(env)
	var light:=DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-48,-28,0)
	light.light_energy=1.1
	light.shadow_enabled=true
	world.add_child(light)
	var plane:=MeshInstance3D.new()
	var mesh:=PlaneMesh.new()
	mesh.size=Vector2(50,50)
	plane.mesh=mesh
	var mat:=StandardMaterial3D.new()
	mat.albedo_color=Color("4d5860")
	mat.roughness=.9
	plane.material_override=mat
	world.add_child(plane)
	camera=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=3.0
	world.add_child(camera)
	actor=load("res://scenes/enemies/enemy.tscn").instantiate()
	world.add_child(actor)
	actor.set_physics_process(false)
	await create_timer(.3).timeout
	var adapter=actor.get_node("EnemyDronePresentation")
	_set_camera(Vector3(3,2.6,-4),3.0)
	await _capture("drone_front")
	adapter.visual.visible=false
	actor.humanoid_visual.animation_source_model.visible=true
	actor.humanoid_visual.character_model.visible=true
	actor.humanoid_visual.weapon_visual.visible=true
	await _capture("legacy_front")
	adapter.visual.visible=true
	actor.humanoid_visual.animation_source_model.visible=false
	actor.humanoid_visual.character_model.visible=false
	actor.humanoid_visual.weapon_visual.visible=false
	_set_camera(Vector3(4,1.6,0),3.0)
	await _capture("drone_side")
	_set_camera(Vector3(-3,2.7,4),3.0)
	await _capture("drone_rear")
	for framing in [["near",4.5],["medium",12.0],["far",24.0]]:
		_set_camera(Vector3(0,18.2,13.7),framing[1])
		await _capture("readability_"+framing[0])
	_set_camera(Vector3(3,2.6,-4),3.0)
	actor.velocity=Vector3(3.2,0,0)
	await create_timer(.25).timeout
	await _capture("move")
	actor.velocity=Vector3.ZERO
	actor._is_telegraphing=true
	await _capture("telegraph")
	actor._is_telegraphing=false
	actor.humanoid_visual.fire_recoil()
	CombatEffects.muzzle_flash(world,actor.humanoid_visual.get_muzzle_position(),actor.humanoid_visual.get_muzzle_direction(),Color("ff3658"),.68)
	await process_frame
	await _capture("fire",false)
	actor.receive_damage(DamagePacket.new(8,0,0,null,&"probe",&"",Vector3.ZERO,Vector3.ZERO,Vector3(.1,0,0)))
	await _capture("hit",false)
	await create_timer(.3).timeout
	actor.receive_damage(DamagePacket.new(999,0,0,null,&"probe",&"",Vector3.ZERO,Vector3.ZERO,Vector3(.1,0,0)))
	await _capture("death",false)
	await create_timer(.7).timeout
	await _capture("wreck",false)
	root.get_node("AudioDirector").shutdown_for_test()
	quit()

func _process(delta: float) -> bool:
	if is_instance_valid(actor) and not actor.is_dead:
		actor.humanoid_visual.update_visual(Vector3(0,1.05,-8),Vector3.RIGHT,actor.velocity.length(),delta)
	return false

func _set_camera(offset: Vector3,size: float) -> void:
	camera.size=size
	camera.position=offset
	camera.look_at(Vector3(0,.85,0))

func _capture(label: String,settle: bool=true) -> void:
	if settle: await create_timer(.16).timeout
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(label+".png"))
