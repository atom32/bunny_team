extends RefCounted
## Offline scene authoring only. Runtime loads the baked, editable world.tscn.
const Geo := preload("res://scripts/world/geography/campus_geodata.gd")
var geo: Geo
var world: Node3D
var batches := {}
var materials := {}
var tree_positions: Array[Vector3] = []
var stats := {}

func build() -> Node3D:
	geo = Geo.new()
	world = Node3D.new()
	world.name = "WeijinGeographicWorld"
	world.set_meta("horizontal_scale", 1.0)
	world.set_meta("source", "OSM way/48165383 + Mapzen N39E117; see assets/geography/weijin/SOURCE.json")
	world.set_meta("terrain_fidelity", "Regional DEM; illustrative architecture, bank profiles and planting; not a survey")
	_materials()
	_environment()
	_ground()
	_lakes()
	_cover()
	_roads()
	_buildings()
	_trees()
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
		ground.set_shader_parameter("base_color",Color("a6ae8f") if key=="ground" else Color("77965b"))
		ground.set_shader_parameter("detail_texture",load("res://assets/environment/campus/leafy_grass_diff_1k.jpg"))
		materials[key]=ground
	materials.paving = _plain("c9c9bb", "res://assets/environment/campus/pavement_05_diff_1k.jpg")
	materials.road = _plain("515853")
	materials.road.albedo_texture=load("res://assets/environment/polyhaven_streets/asphalt_02_diff_1k.jpg")
	materials.curb = _plain("aca998")
	materials.roof = _plain("bab9aa", "res://assets/environment/campus/roof_tiles_14_diff_1k.jpg")
	materials.sport = _plain("699c8c")
	materials.marking = _plain("ddd9bb")
	var water := ShaderMaterial.new()
	water.shader = preload("res://resources/materials/streets/geographic_water.gdshader")
	materials.water = water
	for i in 4:
		var facade := ShaderMaterial.new()
		facade.shader = preload("res://resources/materials/streets/geographic_facade.gdshader")
		facade.set_shader_parameter("wall_color", [Color("d1c5a9"),Color("a69079"),Color("b9b9a9"),Color("c7b8a0")][i])
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
		tool.add_vertex([a,b,c][i])

func _surface(poly: PackedVector2Array, key: String, offset: float, fixed_height := NAN) -> void:
	var indices := Geometry2D.triangulate_polygon(poly)
	for i in range(0,indices.size(),3):
		var p: Vector2 = poly[indices[i]]
		var q: Vector2 = poly[indices[i+1]]
		var r: Vector2 = poly[indices[i+2]]
		var a := geo.at3(p,offset)
		var b := geo.at3(q,offset)
		var c := geo.at3(r,offset)
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
		_surface(poly,"water",0,level)
		var collision := PackedVector3Array()
		for j in poly.size():
			var p := poly[j]
			var q := poly[(j+1)%poly.size()]
			var a := geo.at3(p,.08)
			var b := geo.at3(q,.08)
			var c := Vector3(q.x,level-.5,q.y)
			var d := Vector3(p.x,level-.5,p.y)
			_quad("curb",a,b,c,d,p.distance_to(q),1.0)
			# Full-height edge below ground; raised 0.45m stops walking into water.
			var a_top := a + Vector3.UP*.45
			var b_top := b + Vector3.UP*.45
			collision.append_array([a_top,b_top,c,a_top,c,d])
		_collider("LakeEdge%d"%i,collision)
	stats.lakes = geo.water.size()

func _cover() -> void:
	for entry: Dictionary in geo.data.landcover:
		_surface(Geo.polygon(entry.points),"park",.015)
	for entry: Dictionary in geo.data.pitches:
		var poly := Geo.polygon(entry.points)
		_surface(poly,"sport",.045)
		for j in poly.size(): _ribbon(PackedVector2Array([poly[j],poly[(j+1)%poly.size()]]),.12,"marking",.065)
		if poly.size() == 4:
			_ribbon(PackedVector2Array([(poly[0]+poly[1])*.5,(poly[2]+poly[3])*.5]),.12,"marking",.065)

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
			var a := geo.at3(start-across,offset)
			var b := geo.at3(finish-across,offset)
			var c := geo.at3(finish+across,offset)
			var d := geo.at3(start+across,offset)
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
			_quad("facade%d"%(int(String(entry.osm_id).get_slice("/",1))%4),a,b,c,d,p.distance_to(q),float(entry.height)+.3)
			faces.append_array([a,b,c,a,c,d])
		_surface(poly,"roof",0,top)
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
					if occupied.has(cell) or not geo.safe_walk_point(point) or geo.is_building(point,3) or geo.is_water(point,3): continue
					occupied[cell]=true
					tree_positions.append(geo.at3(point))
	var trunk := CylinderMesh.new()
	trunk.top_radius=.14; trunk.bottom_radius=.26; trunk.height=5.0; trunk.radial_segments=8
	trunk.material=_plain("6e6651")
	var crown := SphereMesh.new()
	crown.radius=2.2; crown.height=4.8; crown.radial_segments=12; crown.rings=6
	crown.material=_plain("668744")
	var groups := {}
	for i in tree_positions.size():
		var p := tree_positions[i]
		var key := Vector2i(floori(p.x/128),floori(p.z/128))
		if not groups.has(key): groups[key]=[]
		groups[key].append([p,i])
	for key: Vector2i in groups:
		var entries: Array = groups[key]
		for part in ["Trunks","Crowns"]:
			var multi := MultiMesh.new()
			multi.transform_format=MultiMesh.TRANSFORM_3D
			multi.mesh=trunk if part=="Trunks" else crown
			multi.instance_count=entries.size()*(1 if part=="Trunks" else 3)
			for j in entries.size():
				var p: Vector3 = entries[j][0]
				var n := int(entries[j][1])
				if part=="Trunks": multi.set_instance_transform(j,Transform3D(Basis.IDENTITY,p+Vector3.UP*2.5))
				else:
					for cluster in 3:
						var angle := n*1.73 + cluster*TAU/3
						var offset := Vector3(cos(angle)*1.4,5.3+cluster*.7,sin(angle)*1.4)
						var scale := Vector3(1,.95+sin(n)*.25,1)
						multi.set_instance_transform(j*3+cluster,Transform3D(Basis.IDENTITY.scaled(scale),p+offset))
			var mesh := MultiMeshInstance3D.new()
			mesh.name="Illustrative%s_%d_%d"%[part,key.x,key.y]
			mesh.multimesh=multi
			mesh.visibility_range_end=2600
			mesh.visibility_range_end_margin=100
			world.add_child(mesh)
	stats.illustrative_and_mapped_trees = tree_positions.size()

func _flush() -> void:
	for id: String in batches:
		var entry: Dictionary = batches[id]
		var mesh: ArrayMesh = entry.tool.commit()
		var instance := MeshInstance3D.new()
		instance.name = id
		instance.mesh = mesh
		world.add_child(instance)
		if entry.key == "ground": _collider(id+"_Physics",mesh.get_faces())
	stats.mesh_chunks = batches.size()
