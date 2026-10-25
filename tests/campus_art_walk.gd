extends Node
## Source-road graph supplies waypoints; ONLY normal movement input moves the
## actor. No teleports, collision changes, speed changes, quest grants or saves.
var survey: Node3D
var geo: CampusGeodata
var graph:=AStar2D.new()
var ids: Dictionary={}
var failures: Array[String]=[]
var walked:=0.0
var ticks:=0
var stops: Array[Dictionary]=[]
var evidence:=OS.get_environment("BUNNY_EVIDENCE")

func _point_id(p: Vector2) -> int:
	var key:=Vector2i(roundi(p.x*1000),roundi(p.y*1000))
	if not ids.has(key):
		var id:=ids.size()
		ids[key]=id
		graph.add_point(id,p)
	return ids[key]

func _clear_segment(a: Vector2, c: Vector2) -> bool:
	var samples:=maxi(1,ceili(a.distance_to(c)/3.0))
	for i in range(samples+1):
		var p:=a.lerp(c,float(i)/samples)
		if not Geometry2D.is_point_in_polygon(p,geo.boundary) or geo.is_water(p,.9) or geo.is_building(p,.9):return false
	return true

func _build_graph() -> void:
	for entry: Dictionary in geo.data.roads:
		var path:=CampusGeodata.polygon(entry.points)
		for i in range(path.size()-1):
			var a:=path[i]
			var c:=path[i+1]
			if a.distance_to(c)<.1 or not _clear_segment(a,c):continue
			graph.connect_points(_point_id(a),_point_id(c))

func _release() -> void:
	for action: String in ["move_left","move_right","move_forward","move_back"]:Input.action_release(action)

func _input_direction(v: Vector2) -> void:
	_release()
	if v.x<0:Input.action_press("move_left",-v.x)
	else:Input.action_press("move_right",v.x)
	if v.y<0:Input.action_press("move_forward",-v.y)
	else:Input.action_press("move_back",v.y)

func _follow(path: PackedVector2Array) -> bool:
	var previous: Vector2=Vector2(survey.actor.position.x,survey.actor.position.z)
	var progress:=0.0
	for point: Vector2 in path:
		while Vector2(survey.actor.position.x,survey.actor.position.z).distance_to(point)>.65:
			var here:=Vector2(survey.actor.position.x,survey.actor.position.z)
			_input_direction(here.direction_to(point))
			await get_tree().physics_frame
			var now:=Vector2(survey.actor.position.x,survey.actor.position.z)
			walked+=now.distance_to(previous)
			progress+=now.distance_to(previous)
			previous=now
			ticks+=1
			if ticks%120==0:
				if progress<.6:
					failures.append("Real controller blocked at %s aiming for %s"%[now,point]);_release();return false
				progress=0.0
			if ticks>42000:failures.append("Walk exceeded the bounded route tick budget");_release();return false
	_release()
	return true

func _capture(name: String) -> void:
	if evidence.is_empty() or DisplayServer.get_name()=="headless":return
	for i in 20:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(evidence.path_join("route_"+name+".png"))

func _ready() -> void:
	await get_tree().process_frame
	var before:=JSON.stringify(ProfileRuntime.get_profile().to_dict())
	survey=preload("res://scenes/presentation/campus_survey.tscn").instantiate()
	add_child(survey)
	geo=survey.geo
	_build_graph()
	survey.toggle_walking()
	for i in 45:await get_tree().process_frame
	var targets: Array[Dictionary]=[
		{"name":"main_hall","at":Vector2(332,124)},
		{"name":"youth_shore","at":Vector2(307,-200)},
		{"name":"north_dormitory","at":Vector2(-80,-305)},
		{"name":"northwest_courts","at":Vector2(-390,-210)},
		{"name":"west_services","at":Vector2(-590,200)},
		{"name":"west_gate","at":Vector2(-272,202)},
		{"name":"jingye_shore","at":Vector2(90,275)},
		{"name":"east_gate","at":Vector2(669,230)}]
	await _capture("east_start")
	for target: Dictionary in targets:
		var start:=graph.get_closest_point(Vector2(survey.actor.position.x,survey.actor.position.z))
		var candidates: Array=[]
		for id: int in graph.get_point_ids():candidates.append(id)
		candidates.sort_custom(func(a: int,c: int)->bool:return graph.get_point_position(a).distance_squared_to(target.at)<graph.get_point_position(c).distance_squared_to(target.at))
		var path:=PackedVector2Array()
		var destination: Vector2=target.at
		for candidate: int in candidates:
			if graph.get_point_position(candidate).distance_to(target.at)>120:break
			path=graph.get_point_path(start,candidate)
			if not path.is_empty():destination=graph.get_point_position(candidate);break
		if path.is_empty():failures.append("No connected source-road route to "+String(target.name));break
		if not await _follow(path):break
		for i in 12:await get_tree().physics_frame
		stops.append({"name":target.name,"position":survey.actor.position,"source_road_stop":destination,"walked_m":walked})
		print("CAMPUS WALK STOP ",target.name," / ",snappedf(walked,.1)," m / ",survey.actor.position)
		await _capture(target.name)
	_release()
	if JSON.stringify(ProfileRuntime.get_profile().to_dict())!=before:failures.append("Read-only geographic walk mutated Profile")
	if stops.size()!=targets.size():failures.append("Not all eight geographic art zones were reached")
	if walked<1800:failures.append("Insufficient full-campus input traversal")
	print("CAMPUS ART WALK: ",failures.size()," failures / ",snappedf(walked,.1)," m / ",stops.size()," stops")
	for failure: String in failures:push_error(failure)
	if not evidence.is_empty():
		var file:=FileAccess.open(evidence.path_join("walk_validation.json"),FileAccess.WRITE)
		file.store_string(JSON.stringify({"failures":failures,"walked_m":walked,"ticks":ticks,"stops":stops,"source_road_graph_nodes":graph.get_point_count(),"native":DisplayServer.get_name()!="headless","method":"Normal controller input on source-road graph; no teleports or speed/collision changes"},"  "))
	get_tree().quit(0 if failures.is_empty() else 1)
