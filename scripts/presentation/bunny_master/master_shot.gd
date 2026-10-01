extends Control
## Isolated visual benchmark. Never changes shared imported materials or gameplay.
const CHARACTER := preload("res://scenes/player/player.tscn")
@export var capture_size := Vector2i(3840, 2160)
@export var camera_position := Vector3(0, 1.64, -2.9)
@export var camera_target := Vector3(0, 1.48, 0)
@export var camera_fov := 22.0
@export var key_energy := 1.35
@export var fill_energy := 0.45
@export var rim_energy := 1.5
var viewport: SubViewport
var stage: Node3D
var player: PlayerController
var camera: Camera3D
var baseline := false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	baseline = "--baseline" in OS.get_cmdline_user_args()
	if "--contact-detail" in OS.get_cmdline_user_args():
		camera_position = Vector3(-.7,1.3,-.65)
		camera_target = Vector3(0,1.18,-.32)
		camera_fov = 38.0
	viewport = SubViewport.new()
	viewport.name = "MasterRender"
	viewport.size = capture_size
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_8X
	viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var display := TextureRect.new()
	display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	display.texture = viewport.get_texture()
	display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(display)
	stage = Node3D.new()
	stage.name = "HangerMasterStage"
	viewport.add_child(stage)
	_build_hanger()
	_build_lighting()
	player = CHARACTER.instantiate() as PlayerController
	player.name = "Bunny"
	player.preview_mode = true
	stage.add_child(player)

	camera = Camera3D.new()
	camera.name = "FrontHalfBodyCamera"
	camera.position = camera_position
	camera.fov = camera_fov
	camera.near = 0.05
	stage.add_child(camera)
	camera.look_at(camera_target)
	camera.current = true
	var optics := CameraAttributesPractical.new()
	optics.dof_blur_far_enabled = true
	optics.dof_blur_far_distance = 3.65
	optics.dof_blur_far_transition = 1.0
	optics.dof_blur_amount = 0.12
	camera.attributes = optics
	for _frame in 40: await get_tree().physics_frame
	player.set_process(false)
	_freeze_portrait_pose()
	if not baseline: _apply_materials()
	for _frame in 12: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var args := OS.get_cmdline_user_args()
	var capture := args.find("--master-capture")
	if capture >= 0 and capture + 1 < args.size():
		var path := args[capture+1]
		var error := viewport.get_texture().get_image().save_png(path)
		print("BUNNY_MASTER_CAPTURE ",path," ",capture_size," renderer=",RenderingServer.get_current_rendering_method()," save=",error_string(error))
		player.queue_free()
		await get_tree().process_frame
		AudioDirector.shutdown_for_test()
		await get_tree().create_timer(0.2).timeout
		get_tree().quit(0 if error == OK else 1)

func _build_hanger() -> void:
	VisualFactory.static_box(stage, Vector3(12,0.2,8), Vector3(0,-0.1,0), Color("182632"), "HangerFloor")
	VisualFactory.box(stage, Vector3(12,4.6,0.2), Vector3(0,2.2,1.8), Color("08111c"), "BackWall")
	for x in [-2.3,-1.1,1.1,2.3]:
		VisualFactory.box(stage, Vector3(0.12,4.4,0.24), Vector3(x,2.1,1.64), Color("344857"), "StructuralBeam")
		var lamp := VisualFactory.box(stage, Vector3(0.055,1.4,0.035), Vector3(x,2.1,1.48), Color("618e93"), "BayLight")
		lamp.material_override = VisualFactory.material(Color("618e93"),0.1,0.4,Color("83b5b7"),1.6)
	for x in [-1.5,1.5]:
		SliceUI.prop(stage,"res://assets/environment/kenney_space_station_kit/container-tall.glb",Vector3(x,0,1.15),1.15)
	var sign := SliceUI.sign(stage,"07",Vector3(-1.1,1.55,1.46),Color("64838a"))
	sign.rotation.y = PI
	sign.font_size = 80
	sign.outline_size = 0
	sign.pixel_size = 0.0015

func _build_lighting() -> void:
	var world := WorldEnvironment.new()
	world.name = "MasterEnvironment"
	world.environment = RenderProfile.create_environment(Color("0d1823"))
	world.environment.ambient_light_energy = 0.18
	world.environment.sky.sky_material.sky_top_color = Color("4e5967")
	world.environment.sky.sky_material.sky_horizon_color = Color("727b84")
	world.environment.ssao_intensity = 0.45
	world.environment.ssao_radius = 0.22
	world.environment.glow_intensity = 0.12
	stage.add_child(world)
	_light("WarmKey",Vector3(-1.15,2.6,-2.1),Vector3(0,1.48,0),Color("ffe5d5"),key_energy,0.6,true)
	_light("NeutralFill",Vector3(1.5,1.9,-2.3),Vector3(0,1.5,0),Color("dce7f5"),fill_energy,0.8,false)
	_light("CoolHairRim",Vector3(0.8,2.65,0.7),Vector3(0,1.55,0),Color("a8d5e3"),rim_energy,0.45,true)

func _light(title: String, at: Vector3, focus: Vector3, color: Color, energy: float, source_size: float, shadows: bool) -> void:
	var light := SpotLight3D.new()
	light.name = title
	light.position = at
	light.light_color = color
	light.light_energy = energy
	light.light_size = source_size
	light.spot_range = 8.0
	light.spot_angle = 55.0
	light.spot_attenuation = 0.5
	light.shadow_enabled = shadows
	light.shadow_bias = 0.015
	stage.add_child(light)
	light.look_at(focus)

func _apply_materials() -> void:
	var replacements := {}
	for mesh in player.character_skeleton.find_children("*","MeshInstance3D",true,false):
		for index in mesh.mesh.get_surface_count():
			var original: StandardMaterial3D = mesh.mesh.surface_get_material(index)
			var key := original.resource_name
			if not replacements.has(key):
				var material := original.duplicate() as StandardMaterial3D
				if "Head_Game" in key or "Body_Game" in key:
					material.subsurf_scatter_enabled = true
					material.subsurf_scatter_skin_mode = true
					material.subsurf_scatter_strength = 0.16
					material.subsurf_scatter_transmittance_enabled = true
					material.subsurf_scatter_transmittance_color = Color("c87469")
					material.subsurf_scatter_transmittance_depth = 0.012
					material.roughness = 0.82
					material.metallic_specular = 0.32
					material.normal_scale = 0.32
				elif "Hair_Game" in key:
					material.roughness = 0.65
					material.metallic_specular = 0.3
					material.normal_scale = 0.35
					material.anisotropy_enabled = true
					material.anisotropy = 0.35
				elif "Eyes_Game" in key:
					material.roughness_texture = null
					material.roughness = 0.65
					material.metallic_specular = 0.05
					material.normal_scale = 0.15
				elif "Cornea_Game" in key:
					material.roughness = 0.06
					material.albedo_color = Color(1,1,1,0.012)
					material.metallic_specular = 0.35
				elif "Headress_Game" in key:
					material.roughness_texture = null
					material.roughness = 0.38
					material.metallic = 0.65
					material.metallic_specular = 0.3
				elif "Suit_Game" in key:
					material.metallic = 0.38
					material.roughness = 0.85
					material.normal_scale = 0.45
				replacements[key] = material
			mesh.set_surface_override_material(index,replacements[key])


func _freeze_portrait_pose() -> void:
	player.body_visual.rotation.y = 0.0
	player.animation_tree.active = false
	player.retarget_modifier.active = false
	for modifier in player.character_skeleton.find_children("*", "SkeletonModifier3D", true, false):
		modifier.active = false
	for modifier in player.animation_source_skeleton.find_children("*", "SkeletonModifier3D", true, false):
		modifier.active = false
	var clip_name := "W2_Stand_Aim_Idle_v2" if "--aim-pose" in OS.get_cmdline_user_args() else "W2_Stand_Relaxed_Idle_v2"
	if "--source-rig" in OS.get_cmdline_user_args():
		player.body_visual.hide()
		var source := preload("res://scripts/presentation/bunny_master/rifle_pose.gd").sample_source(stage,clip_name,.5,false)
		source.rotation.y=PI
		var sk := source.find_child("Skeleton3D",true,false) as Skeleton3D
		_print_hand_frames(sk, "")
		return
	preload("res://scripts/presentation/bunny_master/rifle_pose.gd").apply(player.character_skeleton,clip_name)
	_attach_portrait_rifle()

func _attach_portrait_rifle() -> void:
	var skeleton := player.character_skeleton
	var weapon := load("res://assets/weapons/mocap_m4/M4_Rifle_01.fbx").instantiate() as Node3D
	stage.add_child(weapon)
	preload("res://scripts/presentation/bunny_master/rifle_contact.gd").fit(skeleton,weapon)
	for mesh in weapon.find_children("*", "MeshInstance3D", true, false):
		for index in mesh.mesh.get_surface_count():
			var mat := mesh.mesh.surface_get_material(index).duplicate() as StandardMaterial3D
			mat.metallic = 0.65
			mat.roughness = 0.68
			mesh.set_surface_override_material(index,mat)

func _print_hand_frames(sk: Skeleton3D, prefix: String) -> void:
	for side in ["Left", "Right"]:
		var name: String = prefix+side+"Hand"
		var wrist := sk.get_bone_global_pose(sk.find_bone(name)).origin
		var middle := sk.get_bone_global_pose(sk.find_bone(name+"Middle1")).origin
		var index := sk.get_bone_global_pose(sk.find_bone(name+"Index1")).origin
		var pinky := sk.get_bone_global_pose(sk.find_bone(name+"Pinky1")).origin
		var along := wrist.direction_to(middle)
		var normal := (index-pinky).normalized().cross(along).normalized()
		print("HAND_FRAME ",side," wrist=",sk.to_global(wrist)," palm=",sk.to_global(wrist.lerp(middle,.55))," normal=",sk.global_basis*normal," fingers=",sk.global_basis*along)
