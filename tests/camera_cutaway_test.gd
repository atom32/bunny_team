extends Node3D
## Rendered pixel checks, not just GeometryInstance3D.transparency getters.
var checks := 0
var failures: Array[String] = []
var actor: Node3D
var camera: Camera3D
var solver: Node
var roof: StaticBody3D
var mesh: MeshInstance3D

func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures.append(message);push_error(message)

func frame() -> void:
	await get_tree().process_frame
	if DisplayServer.get_name()!="headless": await RenderingServer.frame_post_draw

func sample(name: String, green: bool, black := false) -> void:
	if DisplayServer.get_name()=="headless": return
	await frame()
	var image:=get_viewport().get_texture().get_image()
	var at: Vector2i=Vector2i(camera.unproject_position(Vector3(0,1,0)))
	var count:=0
	for x in range(at.x-6,at.x+7):
		for y in range(at.y-6,at.y+7):
			var color:=image.get_pixel(x,y)
			# Forward+ deliberately retains 12% of non-roof canopies. Green
			# dominance detects the actor through that tint, not pure RGB only.
			if color.g>.6 and color.g-color.r>.4 and color.g-color.b>.4: count+=1
	print("CUTAWAY_PIXELS ",name," green=",count,"/169 renderer=",RenderingServer.get_current_rendering_method())
	check(count>140 if green else count<10,"rendered green actor "+("visible: " if green else "occluded: ")+name)
	var center:=image.get_pixelv(at)
	if black: check(center.r+center.g+center.b<.1,"externally hidden geometry remains absent in actual render: "+name)
	elif not green: check(center.r>.6 and center.r-center.g>.4,"opaque roof actually drawn again, not just missing green: "+name)
	if "--capture" in OS.get_cmdline_user_args():
		check(image.save_png(OS.get_environment("BUNNY_EVIDENCE").path_join(name+".png"))==OK,"capture "+name)

func make_mesh(parent: Node3D,size: Vector3,at: Vector3,material: Material) -> MeshInstance3D:
	var part:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=size
	part.mesh=box;part.position=at;part.material_override=material;parent.add_child(part)
	return part

func _ready() -> void: _run.call_deferred()

func _run() -> void:
	var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color.BLACK;add_child(env)
	actor=Node3D.new();add_child(actor)
	var green:=StandardMaterial3D.new();green.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;green.albedo_color=Color.GREEN
	make_mesh(actor,Vector3(.8,1.8,.8),Vector3(0,.9,0),green)
	camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=10;add_child(camera)
	camera.position=Vector3(0,9,6);camera.look_at(Vector3(0,1,0));camera.current=true
	for kind in ["standard","shader","canopy"]:
		await fixture(kind)
	AudioDirector.shutdown_for_test()
	print("CAMERA_CUTAWAY_TEST: ","PASS" if failures.is_empty() else "FAIL"," / ",checks," checks")
	get_tree().quit(0 if failures.is_empty() else 1)

func fixture(kind: String) -> void:
	actor.position=Vector3.ZERO
	roof=StaticBody3D.new();roof.collision_layer=4;roof.collision_mask=0;roof.position=Vector3(0,3.6,0);add_child(roof)
	roof.add_to_group("aim_cutaway_roof")
	var shape:=CollisionShape3D.new();shape.shape=BoxShape3D.new();shape.shape.size=Vector3(8,.3,8);roof.add_child(shape)
	var material: Material
	if kind=="shader":
		var shader:=Shader.new();shader.code="shader_type spatial; render_mode unshaded; void fragment(){ALBEDO=vec3(1.0,0.0,0.0);}"
		var custom:=ShaderMaterial.new();custom.shader=shader;material=custom
	else:
		var standard:=StandardMaterial3D.new();standard.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;standard.albedo_color=Color.RED;material=standard
	mesh=make_mesh(roof,Vector3(8,.3,8),Vector3.ZERO,material)
	if kind=="canopy":
		shape.disabled=true;mesh.add_to_group("camera_occluder")
	var keep:=make_mesh(roof,Vector3(.15,.2,.15),Vector3(3,.3,0),material);keep.add_to_group("camera_keep_visible")
	var camera_transform:=camera.global_transform
	solver=load("res://scripts/battle/camera_occlusion.gd").new();add_child(solver)
	for _tick in 3: await get_tree().physics_frame
	await sample(kind+"_before",false)
	solver.update_occlusion(camera,actor,1.0)
	await sample(kind+"_cut",true)
	check(mesh.visible and mesh.material_override==material,"cutaway retains scene visibility and exact original material: "+kind)
	check(keep.visible and keep.transparency==0,"keep-visible trim is untouched: "+kind)
	check(camera.global_transform==camera_transform,"cutaway never moves or rotates camera: "+kind)
	check(roof.collision_layer==4 and not shape.disabled if kind!="canopy" else shape.disabled,"cutaway does not alter authored collision: "+kind)
	if kind!="canopy":
		var hit:=get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0,1,0),Vector3(0,6,0),4))
		check(not hit.is_empty() and hit.collider==roof,"real physics ray still hits cut roof: "+kind)
		check(roof.is_in_group("active_aim_cutaway"),"only authored physical roof gets mouse-picking cutaway: "+kind)
	else:
		for tick in 8:
			solver.update_occlusion(camera,actor,.1)
			await sample(kind+"_stable_"+str(tick),true)
	actor.position.x=20;solver.update_occlusion(camera,actor,1.0)
	await sample(kind+"_restored",false)
	check(mesh.visible and mesh.transparency==0 and not roof.is_in_group("active_aim_cutaway"),"leaving restores state: "+kind)
	actor.position.x=0;solver.update_occlusion(camera,actor,1.0);mesh.hide()
	actor.position.x=20;solver.update_occlusion(camera,actor,1.0)
	check(not mesh.visible,"external hide during cutaway is never resurrected: "+kind)
	await sample(kind+"_external_hidden",false,true)
	mesh.show();actor.position.x=0;solver.update_occlusion(camera,actor,1.0)
	solver.free()
	await sample(kind+"_teardown",false)
	check(mesh.visible and mesh.transparency==0 and not roof.is_in_group("active_aim_cutaway"),"freeing only solver restores geometry and mouse flags: "+kind)
	roof.free();await get_tree().physics_frame
