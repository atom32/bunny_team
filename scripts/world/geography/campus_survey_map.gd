extends Control
## Full-scale map using the SAME geometry as the 3D world. Not a replacement
## illustration. Selecting a landmark only moves the aerial camera.
var survey: Node3D
var contours := false
var map_rect := Rect2(32,118,894,468)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _point(p: Vector2) -> Vector2:
	var bounds: Array = survey.geo.data.bounds
	var extent := Vector2(bounds[2]-bounds[0],bounds[3]-bounds[1])
	var scale_m := minf(map_rect.size.x/extent.x,map_rect.size.y/extent.y)
	return map_rect.get_center() + (p-Vector2((bounds[0]+bounds[2])*.5,(bounds[1]+bounds[3])*.5))*scale_m

func _fill(poly: PackedVector2Array, color: Color) -> void:
	var clip := PackedVector2Array([map_rect.position,Vector2(map_rect.end.x,map_rect.position.y),map_rect.end,Vector2(map_rect.position.x,map_rect.end.y)])
	for piece: PackedVector2Array in Geometry2D.intersect_polygons(poly,clip):
		var indices := Geometry2D.triangulate_polygon(piece)
		for j in range(0,indices.size(),3):
			var a := piece[indices[j]]
			var b := piece[indices[j+1]]
			var c := piece[indices[j+2]]
			if absf((b-a).cross(c-a))<.005:continue
			draw_primitive(PackedVector2Array([a,b,c]),PackedColorArray([color]),PackedVector2Array())

func _path(path: PackedVector2Array, color: Color, width: float) -> void:
	var clip := PackedVector2Array([map_rect.position,Vector2(map_rect.end.x,map_rect.position.y),map_rect.end,Vector2(map_rect.position.x,map_rect.end.y)])
	for piece: PackedVector2Array in Geometry2D.intersect_polyline_with_polygon(path,clip):
		if piece.size()>=2: draw_polyline(piece,color,width,true)

func _draw() -> void:
	if not survey: return
	var geo = survey.geo
	var extent := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO,extent),Color(.035,.055,.055,.84))
	draw_style_box(FieldManualStyle.panel(),Rect2(18,98,926,530))
	draw_rect(map_rect,Color("dfe4d7"))
	if survey.fieldwork and not survey.fieldwork.inside.is_empty():
		_draw_indoor()
		return
	if contours:
		# A regional DEM heat overlay, never fictional metre-scale contours.
		var dem: Dictionary = geo.data.dem
		var step := float(dem.step_m)
		for z in int(dem.rows)-1:
			for x in int(dem.columns)-1:
				var p := Vector2(dem.origin[0]+x*step,dem.origin[1]+z*step)
				var a := _point(p)
				var b := _point(p+Vector2.ONE*step)
				var rect := Rect2(a,b-a).intersection(map_rect)
				if rect.has_area():
					var elevation_m: float=geo.height_at(p)+float(dem.datum_m)
					draw_rect(rect,Color("55764a").lerp(Color("d1bf7f"),clampf((elevation_m-1.0)/12,0,1)))
	for entry: Dictionary in geo.data.landcover:
		var poly := PackedVector2Array()
		for p: Vector2 in geo.polygon(entry.points): poly.append(_point(p))
		_fill(poly,Color("bbcba5"))
	for lake: PackedVector2Array in geo.water:
		var poly := PackedVector2Array()
		for p: Vector2 in lake: poly.append(_point(p))
		_fill(poly,Color("6da7a3"))
	for entry: Dictionary in geo.data.roads:
		var path := PackedVector2Array()
		for p: Vector2 in geo.polygon(entry.points): path.append(_point(p))
		_path(path,Color("959e92"),maxf(1,float(entry.width)*.47))
	for i in geo.buildings.size():
		var poly := PackedVector2Array()
		for p: Vector2 in geo.buildings[i]: poly.append(_point(p))
		_fill(poly,Color("737d76"))
	var edge := PackedVector2Array()
	for p: Vector2 in geo.boundary: edge.append(_point(p))
	edge.append(edge[0])
	draw_polyline(edge,Color("374c48"),2,true)
	for site: Dictionary in survey.landmarks:
		var at := _point(site.point)
		draw_circle(at,4,Color("e8f34a"))
		var short_name: String={"天津大学图书馆":"图书馆","天津大学 第9教学楼":"九教 / 主楼","天津大学东门":"东门","天津大学西门":"西门"}.get(site.name,site.name)
		draw_string(UIFactory.FONT,at+Vector2(8,-6),short_name,HORIZONTAL_ALIGNMENT_LEFT,-1,14,FieldManualStyle.INK)
	if survey.fieldwork:
		var field: Node3D=survey.fieldwork
		if field.route_points.size()>1:
			var path:=PackedVector2Array()
			for point: Vector2 in field.route_points:path.append(_point(point))
			_path(path,Color("e7ef43"),3.5)
		for id: String in field.sites:
			var site: Dictionary=field.sites[id]
			var objective_site: String=field.journal.objective().site
			if survey.night_operation and survey.night_operation.state.active:objective_site=survey.night_operation.objective().site
			var active: bool=(field.tracked_site==id) if not field.tracked_site.is_empty() else objective_site==id
			var at:=_point(site.point)
			draw_rect(Rect2(at-Vector2(5,5),Vector2(10,10)),Color("e8f34a") if active else Color("408575"))
			if field.SITES.has(id):draw_string(UIFactory.FONT,at+Vector2(-5,-8),field.SITES[id].number,HORIZONTAL_ALIGNMENT_LEFT,-1,11,FieldManualStyle.INK)
			if active:draw_string(UIFactory.FONT,at+Vector2(9,17),"目标 / "+site.name,HORIZONTAL_ALIGNMENT_LEFT,-1,14,FieldManualStyle.INK)
	var actor_point: Vector3 = survey.actor.position if survey.walking else survey.focus
	if survey.night_operation and survey.night_operation.state.active:
		var target: Dictionary=survey.night_operation.objective()
		for id: String in ["canteen_north","network","swim"]:
			var point:=_point(survey.fieldwork.sites[id].point)
			draw_arc(point,13,0,TAU,28,Color("ad5d45"),2,true)
			draw_string(UIFactory.FONT,point+Vector2(14,0),"警戒区" if id!="swim" else "可选物资",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("8b4837"))
		var at:=_point(survey.fieldwork.sites[target.site].point)
		draw_arc(at,17,0,TAU,32,Color("b9a02d"),3,true)
		draw_string(UIFactory.FONT,Vector2(34,166),target.text+" / N任务与战利品",HORIZONTAL_ALIGNMENT_LEFT,-1,16,FieldManualStyle.INK)
	var marker := _point(Vector2(actor_point.x,actor_point.z))
	draw_circle(marker,6,Color("e8f34a"))
	draw_arc(marker,8,0,TAU,24,Color("1b2021"),2,true)
	var a := _point(Vector2(-400,390))
	var b := _point(Vector2(-200,390))
	draw_line(a,b,FieldManualStyle.INK,3)
	draw_string(UIFactory.FONT,a+Vector2(0,20),"200 m   /   N ↑",HORIZONTAL_ALIGNMENT_LEFT,-1,14,FieldManualStyle.INK)
	draw_string(UIFactory.FONT,Vector2(34,615),"WGS84 · 1 unit = 1 m · © OpenStreetMap contributors / ODbL · Regional DEM: Mapzen / USGS",HORIZONTAL_ALIGNMENT_LEFT,-1,12,FieldManualStyle.MUTED)
	if survey.fieldwork and survey.walking and (survey.fieldwork.journal.flags.accepted or not survey.fieldwork.tracked_site.is_empty() or (survey.night_operation and survey.night_operation.state.active)):
		draw_string(UIFactory.FONT,Vector2(34,143),"黄色路网与入口接驳 / 门口 E 进入，地图不传送角色",HORIZONTAL_ALIGNMENT_LEFT,-1,15,FieldManualStyle.INK)
		if survey.fieldwork.route_points.is_empty() and not survey.fieldwork.journal.flags.reported:draw_string(UIFactory.FONT,Vector2(34,166),"暂无连通导引，请沿地图选路；碰撞与真实距离保持。",HORIZONTAL_ALIGNMENT_LEFT,-1,14,FieldManualStyle.INK)

func _indoor_point(point: Vector2) -> Vector2:
	return map_rect.get_center()+Vector2(0,18)+point*_indoor_scale()

func _indoor_scale() -> float:
	var size: Vector2=survey.fieldwork.rooms[survey.fieldwork.inside].extent
	return minf(17,minf((map_rect.size.x-80)/size.x,(map_rect.size.y-64)/size.y))

func _draw_indoor() -> void:
	var field: Node3D=survey.fieldwork
	var room: Node3D=field.rooms[field.inside]
	draw_string(UIFactory.FONT,Vector2(42,145),room.title+" / 楼层图",HORIZONTAL_ALIGNMENT_LEFT,-1,23,FieldManualStyle.INK)
	draw_rect(Rect2(_indoor_point(-room.extent*.5),room.extent*_indoor_scale()),Color("c3cabc"))
	for item: Dictionary in room.plan:
		if item.kind=="gate" and field.journal.flags.catalogue:continue
		var rect: Rect2=item.rect
		draw_rect(Rect2(_indoor_point(rect.position),rect.size*_indoor_scale()),Color("586b62") if item.kind=="wall" else (Color("b4a864") if item.kind=="stairs" else Color("8d9988")))
	var objective: String=field.journal.objective().action
	if survey.night_operation and survey.night_operation.state.active:objective=""
	for station: Dictionary in room.stations:
		var at:=_indoor_point(Vector2(station.point.x,station.point.z))
		var active: bool=station.id==objective or (station.id=="blackout" and objective=="restore")
		draw_circle(at,5,Color("e7ef43") if active else Color("38685d"))
		var short_name: String={"exit":"出口 / E","catalogue":"前台目录","archive_power":"柜电源","archive":"档案 / 熔芯","diagram":"支路图","relay":"检修台","isolate":"B 支路","blackout":"总闸 A+B","deliver":"签收台"}.get(station.id,station.label)
		if String(station.id).begins_with("stairs_"):short_name="楼梯 / E"
		draw_string(UIFactory.FONT,at+Vector2(8,-6),short_name,HORIZONTAL_ALIGNMENT_LEFT,-1,12,FieldManualStyle.INK)
	var local: Vector3=survey.actor.position-room.position
	if survey.night_operation and survey.night_operation.state.active:
		var target: Vector3=survey.night_operation.guide_point()-room.position
		var point:=_indoor_point(Vector2(target.x,target.z))
		draw_arc(point,10,0,TAU,24,Color("b09930"),3,true)
		draw_string(UIFactory.FONT,point+Vector2(12,16),"夜线目标 / 或前往出口、楼梯",HORIZONTAL_ALIGNMENT_LEFT,-1,12,FieldManualStyle.INK)
	var actor_at:=_indoor_point(Vector2(local.x,local.z))
	draw_circle(actor_at,6,Color("e7ef43"));draw_arc(actor_at,8,0,TAU,24,FieldManualStyle.INK,2,true)
	draw_string(UIFactory.FONT,Vector2(42,603),"游戏设计平面 · 非真实测绘 / E 交互与楼梯 · M 关闭 · 上层经楼梯返回入口层",HORIZONTAL_ALIGNMENT_LEFT,-1,14,FieldManualStyle.MUTED)

func _gui_input(event: InputEvent) -> void:
	if survey.walking:return # Read the plan without switching the active player to aerial mode.
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for site: Dictionary in survey.landmarks:
			if _point(site.point).distance_to(event.position) < 22:
				survey.select_landmark(site)
				survey.toggle_map()
				accept_event()
				return
