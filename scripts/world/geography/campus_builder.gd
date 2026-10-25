extends RefCounted
## Offline scene authoring only. Runtime loads the baked, editable world.tscn.
const Geo := preload("res://scripts/world/geography/campus_geodata.gd")
var geo: Geo
var world: Node3D
var batches := {}
var materials := {}
var tree_positions: Array[Vector3] = []
var stats := {}
var unit_box: BoxMesh
var carriageways: Array[Dictionary]=[]
var water_shores: Dictionary={}

func build() -> Node3D:
	geo = Geo.new()
	world = Node3D.new()
	world.name = "WeijinGeographicWorld"
	world.set_meta("horizontal_scale", 1.0)
	world.set_meta("source", "OSM way/48165383 + Mapzen N39E117; see assets/geography/weijin/SOURCE.json")
	world.set_meta("terrain_fidelity", "Regional DEM; illustrative architecture, bank profiles and planting; not a survey")
	world.set_meta("art_revision",2)
	unit_box=BoxMesh.new()
	unit_box.size=Vector3.ONE
	_materials()
	_index_carriageways()
	_environment()
	_ground()
	_lakes()
	_cover()
	_roads()
	_buildings()
	preload("res://scripts/world/geography/campus_architecture.gd").new().build(self)
	_trees()
	preload("res://scripts/world/geography/campus_dressing.gd").new().build(self)
	_flush()
	world.set_meta("build_stats", stats)
	return world

func _plain(color: String, texture := "") -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color)
	m.roughness = .88
	if not texture.is_empty(): m.albedo_texture = load(texture)
	return m

func _materials() -> void:
	for key: String in ["ground","park"]:
		var ground := ShaderMaterial.new()
		ground.shader=preload("res://resources/materials/streets/geographic_ground.gdshader")
		ground.set_shader_parameter("base_color",Color("637f4e") if key=="ground" else Color("668250"))
		ground.set_shader_parameter("detail_texture",load("res://assets/environment/campus/leafy_grass_diff_1k.jpg"))
		materials[key]=ground
	materials.paving = _plain("c9c9bb", "res://assets/environment/campus/pavement_05_diff_1k.jpg")
	materials.road = _plain("a4aaa2")
	materials.road.albedo_texture=load("res://assets/environment/polyhaven_streets/asphalt_02_diff_1k.jpg")
	materials.road.normal_enabled=true
	materials.road.normal_texture=load("res://assets/environment/polyhaven_streets/asphalt_02_nor_gl_1k.jpg")
	materials.road.normal_scale=.35
	materials.curb = _plain("aca998")
	var roof:=ShaderMaterial.new()
	roof.shader=preload("res://resources/materials/streets/campus_roof.gdshader")
	roof.set_shader_parameter("tile_albedo",load("res://assets/environment/campus/roof_tiles_14_diff_1k.jpg"))
	roof.set_shader_parameter("tile_normal",load("res://assets/environment/campus/roof_tiles_14_nor_gl_1k.jpg"))
	roof.set_shader_parameter("roof_color",Color("818b83"))
	materials.roof=roof
	materials.flat_roof=_plain("7b8176","res://assets/environment/campus/pavement_05_diff_1k.jpg")
	materials.sport = _plain("699c8c")
	materials.marking = _plain("ddd9bb")
	for entry: Array in [["stone","b5b29f"],["foundation","737869"],["trim","ccc9b6"],["metal","46534e"],["glass","334b46"],["reveal","283830"],["timber","8e7857"],["signal","d7df78"],["rubber","292f2c"],["bark","655d48"],["slate","657168"],["red_brick","92745c"],["paint","718d82"]]:
		materials[entry[0]]=_plain(entry[1])
	materials.glass.roughness=.25
	materials.glass.metallic=.18
	materials.metal.roughness=.53
	var soil:=ShaderMaterial.new()
	soil.shader=preload("res://resources/materials/streets/geographic_soil.gdshader")
	soil.set_shader_parameter("soil_detail",load("res://assets/environment/campus/forest_ground_04_diff_1k.jpg"))
	materials.soil=soil
	var water := ShaderMaterial.new()
	water.shader = preload("res://resources/materials/streets/geographic_water.gdshader")
	materials.water = water
	for i in 4:
		var facade := ShaderMaterial.new()
		facade.shader = preload("res://resources/materials/streets/geographic_facade.gdshader")
		facade.set_shader_parameter("wall_color", [Color("986d52"),Color("bebba6"),Color("a6ada0"),Color("a58e70")][i])
		facade.set_shader_parameter("wall_detail",load("res://assets/environment/polyhaven_streets/wall_bricks_plaster_diff_1k.jpg"))
		facade.set_shader_parameter("brick_amount",1.0 if i in [0,3] else .1)
		materials["facade%d"%i] = facade

func _environment() -> void:
	var env := WorldEnvironment.new()
	env.name = "CampusDaylight"
	var settings := Environment.new()
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("6097c5")
	sky_material.sky_horizon_color = Color("cddfdc")
	sky_material.ground_horizon_color = Color("cddfdc")
	sky_material.ground_bottom_color = Color("aab9af")
	sky.sky_material = sky_material
	settings.background_mode = Environment.BG_SKY
	settings.sky = sky
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	settings.ambient_light_energy = .45
	settings.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	settings.ssao_enabled = true
	settings.ssao_radius = 1.4
	env.environment = settings
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-46,-36,0)
	sun.light_color = Color("fff4df")
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 280
	world.add_child(sun)

func _batch(key: String, point: Vector3) -> SurfaceTool:
	var id := "%s_%d_%d" % [key,floori(point.x/128),floori(point.z/128)]
	if not batches.has(id):
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		tool.set_material(materials[key])
		batches[id] = {"tool":tool,"key":key}
	return batches[id].tool

func _tri(key: String, a: Vector3, b: Vector3, c: Vector3, uva: Vector2, uvb: Vector2, uvc: Vector2) -> void:
	var tool := _batch(key,(a+b+c)/3.0)
	var normal := (b-a).cross(c-a).normalized()
	# Godot's front faces are clockwise; retain the outward geometric normal.
	for i: int in [0,2,1]:
		tool.set_normal(normal)
		tool.set_uv([uva,uvb,uvc][i])
		if water_shores.has(key):
			var point: Vector3=[a,b,c][i]
			var p:=Vector2(point.x,point.z)
			var shore: PackedVector2Array=water_shores[key]
			var distance:=INF
			for j in shore.size():distance=minf(distance,p.distance_to(Geometry2D.get_closest_point_to_segment(p,shore[j],shore[(j+1)%shore.size()])))
			tool.set_color(Color(clampf(distance/8.0,0,1),0,0,1))
		tool.add_vertex([a,b,c][i])

func _index_carriageways() -> void:
	for entry: Dictionary in geo.data.roads:
		if entry.tags.highway in ["footway","path","cycleway","steps","pedestrian"]:continue
		for poly: PackedVector2Array in Geometry2D.offset_polyline(Geo.polygon(entry.points),float(entry.width)*.5,Geometry2D.JOIN_ROUND,Geometry2D.END_ROUND):
			carriageways.append({"poly":poly,"rect":Geo.rect(poly)})

func _clip_carriageway(poly: PackedVector2Array) -> Array[PackedVector2Array]:
	var pieces: Array[PackedVector2Array]=[poly]
	var bounds:=Geo.rect(poly)
	for road: Dictionary in carriageways:
		if not bounds.intersects(road.rect):continue
		var clipped: Array[PackedVector2Array]=[]
		for piece: PackedVector2Array in pieces:clipped.append_array(Geometry2D.clip_polygons(piece,road.poly))
		pieces=clipped
		if pieces.is_empty():break
	return pieces

func _surface(poly: PackedVector2Array, key: String, offset: float, fixed_height := NAN) -> void:
	if key=="paving":
		for piece: PackedVector2Array in _clip_carriageway(poly):_surface_raw(piece,key,offset,fixed_height)
	else:_surface_raw(poly,key,offset,fixed_height)

func _surface_raw(poly: PackedVector2Array, key: String, offset: float, fixed_height: float) -> void:
	var indices := Geometry2D.triangulate_polygon(poly)
	for i in range(0,indices.size(),3):
		var p: Vector2 = poly[indices[i]]
		var q: Vector2 = poly[indices[i+1]]
		var r: Vector2 = poly[indices[i+2]]
		var a := geo.at3(p,offset)
		var b := geo.at3(q,offset)
		var c := geo.at3(r,offset)
		if key!="ground" and is_nan(fixed_height):
			a=geo.mesh_at3(p,offset);b=geo.mesh_at3(q,offset);c=geo.mesh_at3(r,offset)
		if not is_nan(fixed_height):
			a.y = fixed_height; b.y = fixed_height; c.y = fixed_height
		# Godot front faces are clockwise in screen space (upward normal).
		if (b-a).cross(c-a).y < 0:
			_tri(key,a,c,b,p/3.0,r/3.0,q/3.0)
		else: _tri(key,a,b,c,p/3.0,q/3.0,r/3.0)

func _ground() -> void:
	var dem: Dictionary = geo.data.dem
	var origin := Vector2(dem.origin[0],dem.origin[1])
	var end := origin + Vector2(int(dem.columns)-1,int(dem.rows)-1)*float(dem.step_m)
	var step := 12.0
	var count := 0
	for z in range(int(origin.y),int(end.y),int(step)):
		for x in range(int(origin.x),int(end.x),int(step)):
			var cell := PackedVector2Array([Vector2(x,z),Vector2(x+step,z),Vector2(x+step,z+step),Vector2(x,z+step)])
			var pieces: Array[PackedVector2Array] = [cell]
			for i in geo.water.size():
				if not Rect2(x,z,step,step).intersects(geo.water_bounds[i]): continue
				var clipped: Array[PackedVector2Array] = []
				for piece: PackedVector2Array in pieces: clipped.append_array(Geometry2D.clip_polygons(piece,geo.water[i]))
				pieces = clipped
			for piece: PackedVector2Array in pieces: _surface(piece,"ground",0.0)
			count += 1
	stats.terrain_cells = count

func _quad(key: String, a: Vector3, b: Vector3, c: Vector3, d: Vector3, width: float, height: float) -> void:
	_tri(key,a,b,c,Vector2(0,0),Vector2(width,0),Vector2(width,height))
	_tri(key,a,c,d,Vector2(0,0),Vector2(width,height),Vector2(0,height))

func _lakes() -> void:
	for i in geo.water.size():
		var poly := geo.water[i]
		var heights: Array[float] = []
		for p: Vector2 in poly: heights.append(geo.height_at(p))
		heights.sort()
		# Generic low embankment, explicitly not bathymetry or an as-built survey.
		var level := heights[heights.size()/2] - .65
		var water_material: ShaderMaterial=materials.water.duplicate()
		var water_key: String="water%d"%i
		materials[water_key]=water_material
		water_shores[water_key]=poly
		# Interpolate the baked shore-distance gradient on a small interior
		# grid, keeping the exact source shoreline and original collision.
		var bounds:=Geo.rect(poly)
		for z in range(floori(bounds.position.y/6)*6,ceili(bounds.end.y/6)*6,6):
			for x in range(floori(bounds.position.x/6)*6,ceili(bounds.end.x/6)*6,6):
				var cell:=PackedVector2Array([Vector2(x,z),Vector2(x+6,z),Vector2(x+6,z+6),Vector2(x,z+6)])
				for piece: PackedVector2Array in Geometry2D.intersect_polygons(poly,cell):_surface(piece,water_key,0,level)
		var collision := PackedVector3Array()
		for j in poly.size():
			var p := poly[j]
			var q := poly[(j+1)%poly.size()]
			var a := geo.at3(p,.08)
			var b := geo.at3(q,.08)
			var c := Vector3(q.x,level-.5,q.y)
			var d := Vector3(p.x,level-.5,p.y)
			_quad("curb",a,b,c,d,p.distance_to(q),1.0)
			var center: Vector3=(a+b)*.5
			_box(Vector3(.38,.16,p.distance_to(q)+.08),center+Vector3.UP*.06,"stone",atan2(q.x-p.x,q.y-p.y))
			# A restrained garden rail on the smaller formal lakes; the large
			# Youth Lake keeps its open-bank silhouette. This is art, not survey.
			if String(geo.data.water[i].name)!="青年湖" and p.distance_to(q)>2:
				var steps:=ceili(p.distance_to(q)/3.0)
				for post in range(steps+1):
					var point: Vector3=geo.mesh_at3(p.lerp(q,float(post)/steps),.1)
					_beam(point,point+Vector3.UP*.82,.045,"metal")
				_beam(a+Vector3.UP*.80,b+Vector3.UP*.80,.05,"metal")
				_beam(a+Vector3.UP*.33,b+Vector3.UP*.33,.03,"metal")
			# Full-height edge below ground; raised 0.45m stops walking into water.
			var a_top := a + Vector3.UP*.45
			var b_top := b + Vector3.UP*.45
			collision.append_array([a_top,b_top,c,a_top,c,d])
		_collider("LakeEdge%d"%i,collision)
	stats.lakes = geo.water.size()
	stats.water_interior_tessellation_m=6

func _cover() -> void:
	for entry: Dictionary in geo.data.landcover:
		_drape(Geo.polygon(entry.points),"park",.025)
	for entry: Dictionary in geo.data.pitches:
		var poly := Geo.polygon(entry.points)
		_drape(poly,"sport",.045)
		for j in poly.size(): _ribbon(PackedVector2Array([poly[j],poly[(j+1)%poly.size()]]),.12,"marking",.065)
		if poly.size() == 4:
			_ribbon(PackedVector2Array([(poly[0]+poly[1])*.5,(poly[2]+poly[3])*.5]),.12,"marking",.065)

func _drape(poly: PackedVector2Array, key: String, offset: float) -> void:
	var bounds:=Geo.rect(poly)
	var dem: Dictionary=geo.data.dem
	var collar:=Rect2(Vector2(dem.origin[0],dem.origin[1]),Vector2(int(dem.columns)-1,int(dem.rows)-1)*float(dem.step_m))
	bounds=bounds.intersection(collar)
	for z in range(floori(bounds.position.y/12)*12,ceili(bounds.end.y/12)*12,12):
		for x in range(floori(bounds.position.x/12)*12,ceili(bounds.end.x/12)*12,12):
			for triangle: PackedVector2Array in [PackedVector2Array([Vector2(x,z+12),Vector2(x,z),Vector2(x+12,z)]),PackedVector2Array([Vector2(x+12,z),Vector2(x+12,z+12),Vector2(x,z+12)])]:
				for piece: PackedVector2Array in Geometry2D.intersect_polygons(poly,triangle):_surface(piece,key,offset)

func _ribbon(points: PackedVector2Array, width: float, key: String, offset: float) -> void:
	var dem: Dictionary=geo.data.dem
	var a:=Vector2(dem.origin[0],dem.origin[1])+Vector2.ONE*width
	var b:=Vector2(dem.origin[0]+(int(dem.columns)-1)*float(dem.step_m),dem.origin[1]+(int(dem.rows)-1)*float(dem.step_m))-Vector2.ONE*width
	var collar:=PackedVector2Array([a,Vector2(b.x,a.y),b,Vector2(a.x,b.y)])
	for path: PackedVector2Array in Geometry2D.intersect_polyline_with_polygon(points,collar):
		_ribbon_piece(path,width,key,offset)

func _ribbon_piece(points: PackedVector2Array, width: float, key: String, offset: float) -> void:
	for i in range(points.size()-1):
		var p := points[i]
		var q := points[i+1]
		var length := p.distance_to(q)
		if length < .05: continue
		var segments := ceili(length/3.0)
		var across := Vector2(-(q-p).y,(q-p).x).normalized()*width*.5
		for j in segments:
			var start := p.lerp(q,float(j)/segments)
			var finish := p.lerp(q,float(j+1)/segments)
			if key=="paving":
				_surface(PackedVector2Array([start-across,finish-across,finish+across,start+across]),key,offset)
				continue
			var a := geo.mesh_at3(start-across,offset)
			var b := geo.mesh_at3(finish-across,offset)
			var c := geo.mesh_at3(finish+across,offset)
			var d := geo.mesh_at3(start+across,offset)
			_tri(key,a,c,b,(start-across)/3.0,(finish+across)/3.0,(finish-across)/3.0)
			_tri(key,a,d,c,(start-across)/3.0,(start+across)/3.0,(finish+across)/3.0)
		# Round join fill prevents cracks at unsimplified OSM bends/intersections.
		var circle := PackedVector2Array()
		for j in 12: circle.append(p + Vector2.from_angle(j*TAU/12)*width*.5)
		_surface(circle,key,offset)

func _roads() -> void:
	for entry: Dictionary in geo.data.roads:
		var path := Geo.polygon(entry.points)
		if path.size()<2: continue
		var footway: bool = entry.tags.highway in ["footway","path","cycleway","steps","pedestrian"]
		_ribbon(path,float(entry.width)+.45,"curb",.025)
		_ribbon(path,float(entry.width),"paving" if footway else "road",.055)
		if not footway and float(entry.width)>=7.0:
			for j in range(path.size()-1):
				var a := path[j]
				var b := path[j+1]
				var length := a.distance_to(b)
				for d in range(0,int(length)-3,8):
					_ribbon(PackedVector2Array([a.lerp(b,float(d)/length),a.lerp(b,float(d+3)/length)]),.11,"marking",.074)
	stats.road_ways = geo.data.roads.size()

func _buildings() -> void:
	for i in geo.data.buildings.size():
		var entry: Dictionary = geo.data.buildings[i]
		var poly := geo.buildings[i]
		var base := -INF
		for p: Vector2 in poly: base = maxf(base,geo.height_at(p))
		var top := base + float(entry.height)
		var family: int=preload("res://scripts/world/geography/campus_architecture.gd").family(entry)
		var faces := PackedVector3Array()
		# Outward wall winding depends on the exact source ring orientation.
		var reverse := Geometry2D.is_polygon_clockwise(poly)
		for j in poly.size():
			var p := poly[j]
			var q := poly[(j+1)%poly.size()]
			if reverse:
				var temp := p; p = q; q = temp
			var a := geo.at3(p,-.3)
			var b := geo.at3(q,-.3)
			var c := Vector3(q.x,top,q.y)
			var d := Vector3(p.x,top,p.y)
			# Retain the existing two-sided physical triangle order for compatibility.
			faces.append_array([a,b,c,a,c,d])
			# Source winding is not a reliable screen-space/front-face convention.
			# Test the actual polygon and orient render normals to its exterior.
			var tangent: Vector2=(q-p).normalized()
			var normal:=Vector2(-tangent.y,tangent.x)
			if Geometry2D.is_point_in_polygon((p+q)*.5+normal*.1,poly):
				var first:=a;a=b;b=first
				var last:=c;c=d;d=last
			var length:=p.distance_to(q)
			_tri("facade%d"%family,a,b,c,Vector2(0,a.y-base),Vector2(length,b.y-base),Vector2(length,top-base))
			_tri("facade%d"%family,a,c,d,Vector2(0,a.y-base),Vector2(length,top-base),Vector2(0,top-base))
		_collider("Building_"+String(entry.osm_id).replace("/","_"),faces)
	stats.building_footprints = geo.data.buildings.size()

func _collider(label: String, faces: PackedVector3Array) -> void:
	if faces.is_empty(): return
	var body := StaticBody3D.new()
	body.name = label
	body.collision_layer = 4
	body.collision_mask = 0
	var collision := CollisionShape3D.new()
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(faces)
	collision.shape = shape
	body.add_child(collision)
	world.add_child(body)

func _trees() -> void:
	# Only 2 individual trees are mapped. Other avenue planting is illustrative
	# and stored separately, never silently labelled as surveyed locations.
	for point: Dictionary in geo.data.points:
		if point.tags.get("natural","") == "tree": tree_positions.append(geo.at3(Vector2(point.point[0],point.point[1])))
	var mapped_count:=tree_positions.size()
	var occupied := {}
	for entry: Dictionary in geo.data.roads:
		if not entry.inside_campus or entry.tags.highway in ["steps","path","footway","cycleway"]: continue
		var path := Geo.polygon(entry.points)
		for i in range(path.size()-1):
			var a := path[i]
			var b := path[i+1]
			var length := a.distance_to(b)
			var normal := Vector2(-(b-a).y,(b-a).x).normalized()
			for distance in range(6,int(length),14):
				for side: int in [-1,1]:
					var point := a.lerp(b,float(distance)/length)+normal*(float(entry.width)*.5+3.2)*side
					var cell := Vector2i(floori(point.x/8),floori(point.y/8))
					if occupied.has(cell) or not geo.safe_walk_point(point) or geo.is_building(point,4) or geo.is_water(point,3) or geo.road_blocks(point,1.3) or geo.sports_blocks(point,1.3): continue
					occupied[cell]=true
					tree_positions.append(geo.at3(point))
	preload("res://scripts/world/geography/campus_foliage.gd").new().build(self)
	stats.illustrative_and_mapped_trees = tree_positions.size()
	var locations: Array[Dictionary]=[]
	for i in tree_positions.size():locations.append({"point":Vector2(tree_positions[i].x,tree_positions[i].z),"mapped":i<mapped_count})
	world.set_meta("tree_art_placements",locations)

func _box(size: Vector3, at: Vector3, key: String, yaw := 0.0) -> void:
	_batch(key,at).append_from(unit_box,0,Transform3D(Basis(Vector3.UP,yaw)*Basis.from_scale(size),at))

func _beam(a: Vector3, b: Vector3, width: float, key: String) -> void:
	if a.distance_to(b)<.001:return
	var basis:=Basis(Quaternion(Vector3.UP,a.direction_to(b)))*Basis.from_scale(Vector3(width,a.distance_to(b),width))
	_batch(key,(a+b)*.5).append_from(unit_box,0,Transform3D(basis,(a+b)*.5))

func _module(shapes: Array) -> ArrayMesh:
	var tools: Dictionary={}
	for shape: Array in shapes:
		var key: String=shape[0]
		if not tools.has(key):
			var tool:=SurfaceTool.new()
			tool.begin(Mesh.PRIMITIVE_TRIANGLES)
			tool.set_material(materials[key])
			tools[key]=tool
		tools[key].append_from(shape[1],0,shape[2])
	var result:=ArrayMesh.new()
	for key: String in tools:tools[key].commit(result)
	return result

func _module_box(shapes: Array, size: Vector3, at: Vector3, key: String) -> void:
	shapes.append([key,unit_box,Transform3D(Basis.IDENTITY.scaled(size),at)])

func _instances(prefix: String, mesh: Mesh, transforms: Array[Transform3D], near_distance := 0.0, far_distance := 2600.0) -> void:
	var groups: Dictionary={}
	for transform: Transform3D in transforms:
		var p:=transform.origin
		var key:=Vector2i(floori(p.x/128),floori(p.z/128))
		if not groups.has(key):groups[key]=[]
		groups[key].append(transform)
	for key: Vector2i in groups:
		var list: Array=groups[key]
		var multi:=MultiMesh.new()
		multi.transform_format=MultiMesh.TRANSFORM_3D
		multi.mesh=mesh
		multi.instance_count=list.size()
		for i in list.size():multi.set_instance_transform(i,list[i])
		var node:=MultiMeshInstance3D.new()
		node.name="%s_%d_%d"%[prefix,key.x,key.y]
		node.multimesh=multi
		node.visibility_range_begin=near_distance
		node.visibility_range_end=far_distance
		node.set_meta("art_only",true)
		world.add_child(node)

func _flush() -> void:
	for id: String in batches:
		var entry: Dictionary = batches[id]
		entry.tool.generate_tangents()
		var mesh: ArrayMesh = entry.tool.commit()
		var instance := MeshInstance3D.new()
		instance.name = id
		instance.mesh = mesh
		world.add_child(instance)
		if entry.key == "ground": _collider(id+"_Physics",mesh.get_faces())
	stats.mesh_chunks = batches.size()
