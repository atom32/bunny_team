extends Node
## A normal-input tour of all 12 outdoor entrances and 21 designed areas.
## Only production E doorway/floor transitions move between room instances.
const Spaces := preload("res://scripts/world/geography/campus_spaces.gd")
var survey: Node3D
var field: Node3D
var navigation: RefCounted
var failures: Array[String]=[]
var visited: Array[String]=[]
var checks:=0
var ticks:=0
var walked:=0.0
var climbs:=0
var floor_graph:=AStar2D.new()
var floor_ids:=0
var floor_room: Node3D
var evidence:=OS.get_environment("BUNNY_EVIDENCE")

func check(value: bool,text: String) -> void:
	checks+=1
	if not value:failures.append(text);push_error(text)

func frames(count := 12) -> void:
	for i in count:await get_tree().physics_frame

func key(code: Key) -> void:
	for pressed: bool in [true,false]:
		var event:=InputEventKey.new();event.physical_keycode=code;event.pressed=pressed;get_viewport().push_input(event);await get_tree().process_frame

func release() -> void:
	for action: String in ["move_left","move_right","move_forward","move_back"]:Input.action_release(action)

func follow(path: PackedVector2Array,origin := Vector3.ZERO) -> bool:
	var progress:=0.0;var steps:=0
	for point: Vector2 in path:
		var target:=point+Vector2(origin.x,origin.z)
		while Vector2(survey.actor.position.x,survey.actor.position.z).distance_to(target)>.22:
			var before:=Vector2(survey.actor.position.x,survey.actor.position.z)
			var direction:=before.direction_to(target);release()
			# Slow only through normal precision-walk input near a waypoint;
			# movement stats and collision remain untouched.
			var strength:=clampf(before.distance_to(target)*2,.25,1)
			Input.action_press("move_left" if direction.x<0 else "move_right",absf(direction.x)*strength)
			Input.action_press("move_forward" if direction.y<0 else "move_back",absf(direction.y)*strength)
			await get_tree().physics_frame
			var now:=Vector2(survey.actor.position.x,survey.actor.position.z)
			var distance:=now.distance_to(before);walked+=distance;progress+=distance;steps+=1;ticks+=1
			if steps%180==0:
				if progress<.35:check(false,"Blocked actual movement in %s at %s toward %s"%[field.inside,now,target]);release();return false
				progress=0
			if ticks>140000:check(false,"Bounded traversal tick budget exceeded");release();return false
	release();await frames(18);return true

func clear_floor(point: Vector2) -> bool:
	var half: Vector2=floor_room.extent*.5
	if absf(point.x)>half.x-.65 or absf(point.y)>half.y-.65:return false
	for item: Dictionary in floor_room.plan:
		if item.kind=="gate" and field.journal.flags.catalogue:continue
		if item.rect.grow(.45).has_point(point):return false
	return true

func clear_segment(a: Vector2,b: Vector2) -> bool:
	var steps:=maxi(1,ceili(a.distance_to(b)/.25))
	for i in range(steps+1):
		if not clear_floor(a.lerp(b,float(i)/steps)):return false
	return true

func build_floor_graph() -> void:
	floor_room=field.rooms[field.inside];floor_graph.clear()
	var grid: Dictionary={};var half: Vector2=floor_room.extent*.5
	for z in range(ceili((-half.y+.6)/.75),floori((half.y-.6)/.75)+1):
		for x in range(ceili((-half.x+.6)/.75),floori((half.x-.6)/.75)+1):
			var point:=Vector2(x,z)*.75
			if clear_floor(point):grid[Vector2i(x,z)]=grid.size();floor_graph.add_point(grid[Vector2i(x,z)],point)
	for cell: Vector2i in grid:
		for offset: Vector2i in [Vector2i(1,0),Vector2i(0,1),Vector2i(1,1),Vector2i(1,-1)]:
			if grid.has(cell+offset) and clear_segment(Vector2(cell)*.75,Vector2(cell+offset)*.75):floor_graph.connect_points(grid[cell],grid[cell+offset])
	floor_ids=grid.size()

func _attach(id: int,point: Vector2) -> void:
	floor_graph.add_point(id,point)
	var candidates: Array=[]
	for node in floor_ids:
		if floor_graph.get_point_position(node).distance_to(point)<1.9:candidates.append(node)
	for node: int in candidates:
		if clear_segment(point,floor_graph.get_point_position(node)):floor_graph.connect_points(id,node)

func go(point: Vector2) -> bool:
	var local: Vector3=survey.actor.position-floor_room.position
	var from:=Vector2(local.x,local.z)
	if clear_segment(from,point):return await follow(PackedVector2Array([point]),floor_room.position)
	_attach(floor_ids,from);_attach(floor_ids+1,point)
	var path:=floor_graph.get_point_path(floor_ids,floor_ids+1)
	floor_graph.remove_point(floor_ids);floor_graph.remove_point(floor_ids+1)
	if path.is_empty():check(false,"No furniture-clear path in "+field.inside+" to "+str(point));return false
	return await follow(path,floor_room.position)

func capture(label: String) -> void:
	if evidence.is_empty() or DisplayServer.get_name()=="headless":return
	for i in 18:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(evidence.path_join(label+".png"))

func inspect_area() -> bool:
	build_floor_graph()
	var room: Node3D=field.rooms[field.inside]
	var note:=Vector2.ZERO
	for station: Dictionary in room.stations:
		if station.id=="inspect_space":note=Vector2(station.point.x,station.point.z)
	if not await go(note):return false
	var station: Dictionary=field.nearest()
	check(not station.is_empty() and station.id=="inspect_space","Space record is reached by actual movement: "+field.inside)
	await key(KEY_E);await frames()
	check(field.inside in field.journal.space_notes,"Near-field record is persisted: "+field.inside)
	visited.append(field.inside)
	if Spaces.ROOMS[field.inside].layout!="legacy":
		for point: Vector2 in room.tour_points:
			if not await go(point):return false
	field.notice_left=0
	await capture("space_"+field.inside)
	await key(KEY_M);await capture("plan_"+field.inside);await key(KEY_M)
	print("SPACE WALK ",field.inside," / ",snappedf(walked,.1)," m")
	return true

func climb_to(target: String) -> bool:
	var room: Node3D=field.rooms[field.inside]
	var x:=Spaces.stair_x(field.inside);var start: float=room.extent.y*.5-6
	if not await go(Vector2(x,start-.75)):return false
	if not await follow(PackedVector2Array([Vector2(x,start+3.6)]),room.position):return false
	check(survey.actor.position.y-room.position.y>1.1 and survey.actor.is_on_floor(),"Controller physically climbs the stair ramp: "+field.inside)
	climbs+=1
	await key(KEY_E);await frames(22)
	check(field.inside==target,"E landing transfers to linked floor: "+target)
	if field.inside!=target:return false
	var next: Node3D=field.rooms[target]
	# Walk down from its landing before pathing across the flat floor.
	return await follow(PackedVector2Array([Vector2(Spaces.stair_x(target),next.extent.y*.5-6.75)]),next.position)

func click(button: Button) -> void:
	check(button!=null and get_viewport().get_visible_rect().encloses(button.get_global_rect()),"Open-space directory button fits viewport")
	if DisplayServer.get_name()=="headless":button.pressed.emit();return
	for pressed: bool in [true,false]:
		var event:=InputEventMouseButton.new();event.position=button.get_global_rect().get_center();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;get_viewport().push_input(event);await get_tree().process_frame

func finish(before: String) -> void:
	release()
	check(visited.size()==21 and climbs==18,"All 21 areas and nine two-way stair pairs were traversed")
	check(JSON.stringify(ProfileRuntime.get_profile().to_dict())==before,"Expanded campus leaves the entire legacy profile unchanged")
	var loaded:=CampusFieldworkJournal.new(survey.fieldwork_path)
	check(loaded.load_progress() and loaded.space_notes==field.journal.space_notes and loaded.space_notes.size()==21,"All exploration notes survive an actual file reload")
	check(not loaded.flags.accepted,"Exploration does not silently accept or complete the quest")
	print("CAMPUS SPACES RUN: ",checks," checks / ",failures.size()," failures / ",visited.size()," areas / ",climbs," climbs / ",snappedf(walked,.1)," m")
	if not evidence.is_empty():
		var file:=FileAccess.open(evidence.path_join("spaces_run.json"),FileAccess.WRITE)
		file.store_string(JSON.stringify({"checks":checks,"failures":failures,"visited":visited,"climbs":climbs,"walked_m":walked,"ticks":ticks,"native":DisplayServer.get_name()!="headless","method":"Normal movement, E door/landing transfers, actual O directory clicks and M maps; no actor fixture relocations"},"  "))
	get_tree().quit(0 if failures.is_empty() else 1)

func _ready() -> void:
	await get_tree().process_frame
	var before:=JSON.stringify(ProfileRuntime.get_profile().to_dict())
	survey=preload("res://scenes/presentation/campus_survey.tscn").instantiate();survey.fieldwork_path="user://spaces_run_%s.json"%Time.get_ticks_usec();add_child(survey)
	field=survey.fieldwork;navigation=preload("res://scripts/world/geography/campus_fieldwork_route.gd").new(survey.geo)
	survey.toggle_walking();await frames(40)
	var position_before: Vector3=survey.actor.position
	await key(KEY_O);await capture("space_directory")
	await click(field.panel.find_child("TrackSpace_gym",true,false));await frames()
	check(field.tracked_site=="gym" and survey.actor.position.distance_to(position_before)<.01,"Directory marking never teleports the player")
	await key(KEY_M);await frames(12);check(field.route_points.size()>1,"Free exploration has road guidance without accepting a quest");await capture("space_route");await key(KEY_M)
	for id: String in Spaces.SITES:
		var here:=Vector2(survey.actor.position.x,survey.actor.position.z)
		var path: PackedVector2Array=navigation.find_path(here,field.sites[id].point)
		check(path.size()>1,"Source-building entrance has a connected route: "+id)
		if path.is_empty() or not await follow(path):finish(before);return
		await key(KEY_E);await frames(30)
		check(field.inside==id,"Normal source-campus entrance opens the correct building: "+id)
		if field.inside!=id or not await inspect_area():finish(before);return
		var upper:=Spaces.partner(id)
		if not upper.is_empty():
			if not await climb_to(upper) or not await inspect_area() or not await climb_to(id):finish(before);return
			build_floor_graph()
		var room: Node3D=field.rooms[id]
		if not await go(Vector2(0,room.extent.y*.5-3)):finish(before);return
		var outside: Vector3=field.outside_return
		await key(KEY_E);await frames(25)
		check(field.inside.is_empty() and survey.actor.position.distance_to(outside)<.3,"Building return preserves its actual outdoor doorway: "+id)
	await key(KEY_O);await capture("space_directory_complete");await key(KEY_O)
	finish(before)
