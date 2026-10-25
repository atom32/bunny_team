extends RefCounted
## Visual-only campus use. No quest nodes, collision, pickups or fake cover.
var b: RefCounted
var geo: CampusGeodata
var occupied: Dictionary={}
var lamps: Array[Transform3D]=[]
var benches: Array[Transform3D]=[]
var bins: Array[Transform3D]=[]
var bikes: Array[Transform3D]=[]
var drains: Array[Transform3D]=[]
var wayfinding_count:=0
var placement_log: Array[Dictionary]=[]

func build(builder: RefCounted) -> void:
	b=builder
	geo=b.geo
	_road_edges()
	_lake_seats()
	_bicycle_parking()
	_wayfinding()
	_gate()
	_build_instances()
	b.stats.street_lamps=lamps.size()
	b.stats.lakeside_benches=benches.size()
	b.stats.waste_bins=bins.size()
	b.stats.parked_bicycles=bikes.size()
	b.stats.road_drains=drains.size()
	b.stats.lake_wayfinding_signs=wayfinding_count
	b.world.set_meta("art_placements",placement_log)
	b=null

func _road_clear(point: Vector2, margin: float) -> bool:
	return not geo.road_blocks(point,margin)

func _safe(point: Vector2, radius := 1.0) -> bool:
	if not geo.safe_walk_point(point) or geo.is_building(point,radius) or geo.is_water(point,radius):return false
	if not _road_clear(point,radius):return false
	if geo.sports_blocks(point,radius):return false
	for tree: Vector3 in b.tree_positions:
		if Vector2(tree.x,tree.z).distance_squared_to(point)<2.2*2.2:return false
	return true

func _reserve(point: Vector2, spacing := 8.0) -> bool:
	var cell:=Vector2i(floori(point.x/spacing),floori(point.y/spacing))
	if occupied.has(cell):return false
	occupied[cell]=true
	return true

func _place(target: Array[Transform3D], kind: String, point: Vector2, yaw: float) -> void:
	target.append(Transform3D(Basis(Vector3.UP,yaw),geo.at3(point,.06)))
	placement_log.append({"kind":kind,"point":point,"illustrative":true})

func _road_edges() -> void:
	for entry: Dictionary in geo.data.roads:
		if not entry.inside_campus:continue
		var path:=CampusGeodata.polygon(entry.points)
		var width:=float(entry.width)
		var footway: bool=entry.tags.highway in ["footway","path","pedestrian","cycleway"]
		for i in range(path.size()-1):
			var a:=path[i]
			var c:=path[i+1]
			var length:=a.distance_to(c)
			if length<2:continue
			var tangent: Vector2=(c-a).normalized()
			var normal:=Vector2(-tangent.y,tangent.x)
			# Narrow service lanes do not receive invented highway sidewalks.
			if not footway and width>=6:
				for d in range(0,int(length)-4,5):
					for side: int in [-1,1]:
						var first: Vector2=a+tangent*d+normal*(width*.5+.95)*side
						var last: Vector2=a+tangent*(d+5)+normal*(width*.5+.95)*side
						var midpoint: Vector2=(first+last)*.5
						if not geo.is_building(midpoint,1.4) and not geo.is_water(midpoint,1.4) and _road_clear(midpoint,.8) and _road_clear(first,.8) and _road_clear(last,.8) and Geometry2D.is_point_in_polygon(midpoint,geo.boundary):
							b._ribbon(PackedVector2Array([first,last]),1.55,"paving",.068)
			for d in range(10,int(length),29):
				var point: Vector2=a+tangent*d+normal*(width*.5-.28)
				if geo.is_water(point) or geo.is_building(point):continue
				_place(drains,"drain",point,atan2(tangent.x,tangent.y))
			for d in range(17,int(length),49):
				var side: int=1 if d%2==0 else -1
				var point: Vector2=a+tangent*d+normal*(width*.5+2.15)*side
				if _safe(point,.45) and _reserve(point,9):
					_place(lamps,"lamp",point,atan2(-normal.x*side,-normal.y*side))

func _lake_seats() -> void:
	for lake: PackedVector2Array in geo.water:
		var distance_left:=12.0
		for i in lake.size():
			var a:=lake[i]
			var c:=lake[(i+1)%lake.size()]
			var length:=a.distance_to(c)
			var tangent: Vector2=(c-a).normalized()
			var normal:=Vector2(-tangent.y,tangent.x)
			if Geometry2D.is_point_in_polygon((a+c)*.5+normal,lake):normal=-normal
			while distance_left<length:
				var point: Vector2=a+tangent*distance_left+normal*4.2
				if _safe(point,1.2) and _reserve(point,7):
					var yaw:=atan2(-normal.x,-normal.y)
					_place(benches,"bench",point,yaw)
					var bin_point: Vector2=point+tangent*2.0
					if _safe(bin_point,.6):_place(bins,"bin",bin_point,yaw)
				distance_left+=27
			distance_left-=length

func _bicycle_parking() -> void:
	var index:=0
	for entry: Dictionary in geo.data.buildings:
		if not entry.inside_campus:continue
		if entry.tags.building not in ["dormitory","university","school"] and entry.name.is_empty():continue
		index+=1
		if index%2==0:continue
		var poly:=CampusGeodata.polygon(entry.points)
		var found:=false
		for i in poly.size():
			var a:=poly[i]
			var c:=poly[(i+1)%poly.size()]
			if a.distance_to(c)<12:continue
			var tangent: Vector2=(c-a).normalized()
			var normal:=Vector2(-tangent.y,tangent.x)
			if Geometry2D.is_point_in_polygon((a+c)*.5+normal,poly):normal=-normal
			var point: Vector2=(a+c)*.5+normal*3.4
			if not _safe(point,1.6) or not _reserve(point,8):continue
			for j in 3:
				var at: Vector2=point+tangent*(j-1)*.68
				if _safe(at,1.05):_place(bikes,"bicycle",at,atan2(normal.x,normal.y)+.17*j)
			found=true
			break
		if found:continue

func _gate() -> void:
	var at:=geo.project(117.1724566,39.1070776)
	for side: int in [-1,1]:
		var p: Vector2=at+Vector2(0,side*8.5)
		var floor: Vector3=geo.at3(p)
		b._box(Vector3(1.05,2.6,1.05),floor+Vector3.UP*1.3,"red_brick")
		b._box(Vector3(1.24,.16,1.24),floor+Vector3.UP*2.67,"stone")
		b._box(Vector3(1.28,.17,1.28),floor+Vector3.UP*.09,"foundation")
		b._box(Vector3(.04,.68,.78),floor+Vector3(-.55,1.7,0),"metal")
		b._box(Vector3(.05,.065,.68),floor+Vector3(-.58,1.45,0),"signal")
	var sign:=Label3D.new()
	sign.name="EastGateCampusSign"
	sign.text="卫津路校区\nWEIJIN CAMPUS"
	sign.font=UIFactory.FONT;sign.font_size=42;sign.pixel_size=.0045
	sign.modulate=Color("dbdbc7");sign.outline_size=0
	sign.position=geo.at3(at+Vector2(-.58,-8.5),1.82)
	sign.rotation.y=-PI*.5;sign.visibility_range_end=120
	b.world.add_child(sign)

func _wayfinding() -> void:
	for lake_index in geo.water.size():
		var poly:=geo.water[lake_index]
		for i in poly.size():
			var a:=poly[i]
			var c:=poly[(i+1)%poly.size()]
			var tangent: Vector2=(c-a).normalized()
			var normal:=Vector2(-tangent.y,tangent.x)
			if Geometry2D.is_point_in_polygon((a+c)*.5+normal,poly):normal=-normal
			var p: Vector2=(a+c)*.5+normal*5.6
			if not _safe(p,1.0) or not _reserve(p,6):continue
			var floor:=geo.mesh_at3(p,.04)
			var yaw:=atan2(normal.x,normal.y)
			b._box(Vector3(.07,2.05,.07),floor+Vector3.UP*1.025,"metal",yaw)
			b._box(Vector3(1.35,.74,.10),floor+Vector3.UP*1.78,"trim",yaw)
			b._box(Vector3(1.35,.07,.12),floor+Vector3.UP*2.11,"signal",yaw)
			var right:=Vector2(cos(yaw),-sin(yaw))
			var to_gate: Vector2=geo.project(117.1724566,39.1070776)-p
			var text:=Label3D.new()
			text.name="LakeWayfinding%d"%lake_index
			text.text=String(geo.data.water[lake_index].name)+"\n东门方位 "+("→" if to_gate.dot(right)>0 else "←")
			text.font=UIFactory.FONT;text.font_size=40;text.pixel_size=.0045;text.outline_size=0
			text.modulate=Color("2a3831")
			text.position=floor+Vector3(normal.x*.08,1.79,normal.y*.08)
			text.rotation.y=yaw;text.visibility_range_end=95
			b.world.add_child(text)
			placement_log.append({"kind":"wayfinding","point":p,"illustrative":true,"source_name":geo.data.water[lake_index].name})
			wayfinding_count+=1
			break

func _shape_beam(shapes: Array, a: Vector3, c: Vector3, width: float, key: String) -> void:
	var basis:=Basis(Quaternion(Vector3.UP,a.direction_to(c)))*Basis.from_scale(Vector3(width,a.distance_to(c),width))
	shapes.append([key,b.unit_box,Transform3D(basis,(a+c)*.5)])

func _build_instances() -> void:
	var shapes: Array=[]
	b._module_box(shapes,Vector3(.10,5.5,.10),Vector3(0,2.75,0),"metal")
	b._module_box(shapes,Vector3(.29,.20,.29),Vector3(0,.11,0),"foundation")
	b._module_box(shapes,Vector3(.11,.11,1.55),Vector3(0,5.45,.67),"metal")
	b._module_box(shapes,Vector3(.42,.15,.78),Vector3(0,5.40,1.36),"metal")
	b._module_box(shapes,Vector3(.31,.025,.64),Vector3(0,5.31,1.36),"trim")
	b._instances("IllustrativeStreetLamps",b._module(shapes),lamps,0,650)
	shapes=[]
	for side: int in [-1,1]:
		b._module_box(shapes,Vector3(.08,.45,.55),Vector3(side*.73,.225,0),"metal")
		b._module_box(shapes,Vector3(.09,.63,.08),Vector3(side*.73,.6,-.25),"metal")
	for z: float in [-.22,-.07,.08,.23]:
		b._module_box(shapes,Vector3(1.92,.07,.115),Vector3(0,.47,z),"timber")
	for y: float in [.64,.81,.98]:
		b._module_box(shapes,Vector3(1.92,.12,.075),Vector3(0,y,-.27),"timber")
	b._instances("IllustrativeLakesideBenches",b._module(shapes),benches,0,300)
	shapes=[]
	for side: int in [-1,1]:
		b._module_box(shapes,Vector3(.38,.76,.46),Vector3(side*.23,.4,0),"paint" if side<0 else "metal")
		b._module_box(shapes,Vector3(.39,.08,.48),Vector3(side*.23,.82,0),"stone")
		b._module_box(shapes,Vector3(.19,.025,.19),Vector3(side*.23,.865,0),"reveal")
		b._module_box(shapes,Vector3(.17,.12,.014),Vector3(side*.23,.54,.24),"trim")
	b._instances("IllustrativeCampusBins",b._module(shapes),bins,0,220)
	shapes=[]
	b._module_box(shapes,Vector3(.38,.025,.65),Vector3(0,.015,0),"metal")
	for i in 6:b._module_box(shapes,Vector3(.25,.012,.032),Vector3(0,.034,-.25+i*.1),"reveal")
	b._instances("IllustrativeRoadDrains",b._module(shapes),drains,0,110)
	_bicycle_mesh()

func _bicycle_mesh() -> void:
	var shapes: Array=[]
	var tyre:=TorusMesh.new()
	tyre.inner_radius=.28;tyre.outer_radius=.33;tyre.rings=24;tyre.ring_segments=8
	for x: float in [-.61,.61]:
		shapes.append(["rubber",tyre,Transform3D(Basis(Vector3.RIGHT,PI*.5),Vector3(x,.34,0))])
		for i in 8:
			var end:=Vector3(x+cos(i*TAU/8)*.29,.34+sin(i*TAU/8)*.29,0)
			_shape_beam(shapes,Vector3(x,.34,0),end,.011,"stone")
	var rear:=Vector3(-.61,.34,0)
	var pedal:=Vector3(-.08,.32,0)
	var saddle:=Vector3(-.20,.83,0)
	var handle:=Vector3(.40,.86,0)
	var front:=Vector3(.61,.34,0)
	for pair: Array in [[rear,pedal],[rear,saddle],[saddle,pedal],[saddle,handle],[pedal,handle],[handle,front]]:
		_shape_beam(shapes,pair[0],pair[1],.035,"paint")
	_shape_beam(shapes,saddle,saddle+Vector3.UP*.16,.035,"metal")
	_shape_beam(shapes,handle,handle+Vector3.UP*.17,.035,"metal")
	b._module_box(shapes,Vector3(.28,.055,.16),saddle+Vector3.UP*.18,"rubber")
	b._module_box(shapes,Vector3(.035,.035,.40),handle+Vector3.UP*.18,"metal")
	b._module_box(shapes,Vector3(.15,.03,.27),pedal,"metal")
	b._instances("IllustrativeParkedBicycles",b._module(shapes),bikes,0,180)
