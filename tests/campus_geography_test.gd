extends Node
## Synthetic geometry, collision and input acceptance, not a human playtest.
var checks := 0
var failures: Array[String] = []
var survey: Node3D
var capture_root := OS.get_environment("BUNNY_EVIDENCE")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message); push_error(message)

func frames(count := 8) -> void:
	for i in count: await get_tree().process_frame

func capture(label: String) -> void:
	if capture_root.is_empty() or DisplayServer.get_name()=="headless": return
	await frames(15)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(capture_root.path_join(label+".png"))

func map_key() -> void:
	for pressed: bool in [true,false]:
		var event:=InputEventKey.new()
		event.physical_keycode=KEY_M
		event.pressed=pressed
		get_viewport().push_input(event)
		await get_tree().process_frame

func _ready() -> void:
	await get_tree().process_frame
	var before := JSON.stringify(ProfileRuntime.get_profile().to_dict()) if ProfileRuntime.get_profile().has_method("to_dict") else ""
	survey=preload("res://scenes/presentation/campus_survey.tscn").instantiate()
	add_child(survey)
	await frames()
	var geo = survey.geo
	check(geo.data.horizontal_scale==1.0 and geo.data.vertical_exaggeration==1.0,"Horizontal and vertical scales are 1:1")
	check(geo.data.water.size()==4,"All four mapped lakes exist, not the compressed three-shape layout")
	check(geo.data.buildings.size()==467,"All retained source building outlines are baked")
	check(geo.data.boundary.size()==30,"All campus boundary corners preserved")
	check(geo.project(117.1724566,39.1070776).distance_to(Vector2(675.217,230.073))<.01,"East gate WGS84 projects to the source metre coordinates")
	check(geo.data.bounds[2]-geo.data.bounds[0]>1390,"Campus is ~1.4km wide, not enlarged 116m geometry")
	check(survey.landmarks.size()==8,"Four lakes, main hall, library and two mapped gates selectable")
	for lake in geo.water:
		check(Geometry2D.triangulate_polygon(lake).size()>=3,"Source lake outline triangulates")
	for index in [0,26,200,427]:
		check(geo.buildings[index].size()==geo.data.buildings[index].points.size(),"Building corner count not simplified")
	var world: Node=survey.get_node("WeijinGeographicWorld")
	var stats: Dictionary=world.get_meta("build_stats")
	check(stats.building_footprints==467 and stats.lakes==4,"Baked world matches shared geographic dataset")
	check(world.find_children("Building_*","StaticBody3D",false,false).size()==467,"Building outline wall collision exists")
	check(world.find_children("ground*Physics","StaticBody3D",false,false).size()>50,"Terrain collision covers the full campus")
	await capture("01_full_campus")
	for site in survey.landmarks:
		if site.name in ["青年湖","敬业湖","天津大学 第9教学楼"]:
			survey.select_landmark(site)
			survey.focus=survey.target_focus
			survey.distance=survey.target_distance
			survey._update_camera(0)
			await capture("02_"+site.name)
	await map_key()
	check(survey.route_map.visible,"Map toggle displays real geometry")
	await capture("03_source_map")
	await map_key()
	survey.toggle_walking()
	check(survey.walking,"Safe real east gate supports walking entry")
	await frames(45)
	check(survey.actor.is_on_floor(),"Actor stands on the DEM collision, not a fake y=0 plane")
	check(not survey.actor._try_fire(),"Survey visual weapon cannot fire without a sortie")
	for i in geo.water.size():
		var lake: PackedVector2Array=geo.water[i]
		var found:=false
		for j in lake.size():
			var midpoint: Vector2=(lake[j]+lake[(j+1)%lake.size()])*.5
			var tangent: Vector2=(lake[(j+1)%lake.size()]-lake[j]).normalized()
			for side: int in [-1,1]:
				var outward:=Vector2(-tangent.y,tangent.x)*side
				var at:=midpoint+outward*2
				if not geo.safe_walk_point(at):continue
				var hit:=KinematicCollision3D.new()
				var blocked: bool=survey.actor.test_move(Transform3D(Basis.IDENTITY,geo.at3(at,.05)),Vector3(-outward.x,0,-outward.y)*4,hit)
				if blocked and String(hit.get_collider().name).begins_with("LakeEdge"):found=true;break
			if found:break
		check(found,"Actual character capsule is blocked at lake shore %d"%i)
	var start: Vector3=survey.actor.position
	Input.action_press("move_left")
	for i in 150: await get_tree().physics_frame
	Input.action_release("move_left")
	var walked: float=survey.actor.position.distance_to(start)
	check(walked>10,"Normal movement input travels more than 10 actual metres")
	check(absf(survey.actor.position.y-geo.height_at(Vector2(survey.actor.position.x,survey.actor.position.z)))<1,"Walking follows local terrain elevation")
	await capture("04_east_gate_walk")
	survey.toggle_map()
	var paused: Vector3=survey.actor.position
	Input.action_press("move_left")
	for i in 30: await get_tree().physics_frame
	Input.action_release("move_left")
	check(survey.actor.position.distance_to(paused)<.2,"Map captures movement rather than moving unseen")
	survey.toggle_map()
	survey.reset_overview()
	check(not survey.walking and not survey.actor.is_physics_processing(),"Aerial mode disables actor movement")
	if not before.is_empty():check(JSON.stringify(ProfileRuntime.get_profile().to_dict())==before,"Survey does not mutate profile")
	print("CAMPUS GEOGRAPHY: ",checks," checks / ",failures.size()," failures; walked ",walked," m")
	if not capture_root.is_empty():
		var file:=FileAccess.open(capture_root.path_join("validation.json"),FileAccess.WRITE)
		file.store_string(JSON.stringify({"checks":checks,"failures":failures,"walked_m":walked,"stats":stats},"  "))
	get_tree().quit(0 if failures.is_empty() else 1)
