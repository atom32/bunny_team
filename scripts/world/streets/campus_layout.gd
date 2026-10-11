extends RefCounted
## One authored campus, inspired by Weijin Road's east gate, lakes and parallel avenues.
## Coordinates are composed deliberately. Randomness belongs to sortie assignments, not town form.
const ROAD_LINES := [
 [[Vector2(-55,5),Vector2(-34,5),Vector2(-12,4),Vector2(12,4),Vector2(36,4),Vector2(55,4)],6.4],
 [[Vector2(-54,48),Vector2(-27,47),Vector2(2,47),Vector2(27,47),Vector2(54,48)],5.4],
 [[Vector2(-49,-54),Vector2(-50,-32),Vector2(-50,-8),Vector2(-50,15),Vector2(-49,36),Vector2(-48,54)],4.4],
 [[Vector2(47,-53),Vector2(40,-35),Vector2(35,-12),Vector2(36,4),Vector2(35,30),Vector2(37,45),Vector2(48,54)],4.6],
 [[Vector2(-53,-43),Vector2(-29,-43),Vector2(-6,-42),Vector2(20,-41),Vector2(52,-42)],4.2],
 [[Vector2(-8,-52),Vector2(-8,-34),Vector2(-9,-15),Vector2(-10,4),Vector2(-10,23),Vector2(-8,47)],3.2],
 [[Vector2(-46,32),Vector2(-25,32),Vector2(-8,32),Vector2(12,31),Vector2(34,31)],3.0],
 [[Vector2(-48,-9),Vector2(-32,-9),Vector2(-18,-8),Vector2(-9,-7)],2.8],
]
var lakes := [
 PackedVector2Array([Vector2(-4,-37),Vector2(18,-37),Vector2(25,-29),Vector2(24,-16),Vector2(15,-8),Vector2(0,-9),Vector2(-5,-17)]),
 PackedVector2Array([Vector2(-4,35),Vector2(10,35),Vector2(10,42),Vector2(-4,42)]),
 PackedVector2Array([Vector2(12,35),Vector2(27,35),Vector2(27,42),Vector2(12,42)]),
]
var g: Node3D
var art: Node3D
var mats := {}

func build(district: Node3D) -> void:
	g=district
	art=Node3D.new();art.name="CampusPresentation";g.add_child(art)
	VisualFactory.add_world_environment(g,Color("b8cedb"),2.1)
	var environment := g.find_children("*","WorldEnvironment",true,false)[0] as WorldEnvironment
	environment.environment.ambient_light_color=Color("dce8ef")
	environment.environment.ambient_light_energy=.46
	environment.environment.adjustment_enabled=true
	environment.environment.adjustment_saturation=1.12
	environment.environment.glow_enabled=false
	environment.environment.ssao_enabled=true
	environment.environment.ssao_radius=1.0
	environment.environment.ssao_intensity=.9
	var sky:=Sky.new();var sky_material:=ProceduralSkyMaterial.new()
	sky_material.sky_top_color=Color("83b5d5");sky_material.sky_horizon_color=Color("d8e5e8")
	sky_material.ground_horizon_color=Color("c0cbb4");sky_material.ground_bottom_color=Color("8c9e78")
	sky.sky_material=sky_material;environment.environment.sky=sky
	environment.environment.reflected_light_source=Environment.REFLECTION_SOURCE_SKY
	var sun := g.find_children("*","DirectionalLight3D",true,false)[0] as DirectionalLight3D
	if sun:
		sun.rotation_degrees=Vector3(-39,-48,0)
		sun.light_color=Color("fff3df")
		sun.light_energy=1.95
		sun.directional_shadow_max_distance=140.0
	if g.lighting_variant == "night":
		environment.environment.ambient_light_color=Color("8daacc")
		environment.environment.ambient_light_energy=.22
		environment.environment.glow_enabled=true
		environment.environment.glow_intensity=.45
		sky_material.sky_top_color=Color("091426")
		sky_material.sky_horizon_color=Color("344963")
		sky_material.ground_horizon_color=Color("233041")
		sky_material.ground_bottom_color=Color("101a29")
		sun.rotation_degrees=Vector3(-32,35,0)
		sun.light_color=Color("a7c8ed")
		sun.light_energy=.45
	var ground: Material=_lawn(Color("72955d"))
	g._box(Vector3(116,.2,116),Vector3(0,-.12,0),ground,"CampusGround",true,false)
	_detail(Vector3(240,.10,240),Vector3(0,-.22,0),ground)
	_landscape()
	for entry in ROAD_LINES:
		var line := _smooth(entry[0])
		g.campus_roads.append([line,entry[1]])
	for road in g.campus_roads: _path(road[0],float(road[1]))
	for road in g.campus_roads: _curbs(road[0],float(road[1]))
	_forecourts()
	for polygon in lakes:
		g.campus_lakes.append(polygon)
		_lake(polygon)
	# The four existing narrative anchors remain reachable inside these distinct buildings.
	for index in 4: g._room(g.ROOMS[index],index)
	_library()
	_clinic()
	_dormitory()
	_workshop()
	_teaching_hall(Vector3(29,0,-25),Vector2(5,18),5.8)
	_teaching_hall(Vector3(-29,0,-52),Vector2(22,5),6.9)
	_teaching_hall(Vector3(22,0,-50),Vector2(17,5),4.9)
	_pavilion(Vector3(11,0,-5))
	for index in g.EXITS.size():
		_gate(g.EXITS[index],["卫津路 · 东门","北洋道 · 南门","校园北门","后勤服务门"][index],PI/2 if index in [0,3] else 0)
	_furniture()
	_shelter_route_clutter()
	_sports_court()
	# Actual cover, in plausible loading/parking locations rather than an arbitrary grid.
	for at in [Vector3(-47,0,-15),Vector3(40,0,-30),Vector3(43,0,31)]: g._vehicle(at)
	for at in [Vector3(-35,0,-9),Vector3(31,0,-8),Vector3(42,0,8)]:
		g._box(Vector3(2.2,.9,.7),at+Vector3.UP*.45,g.concrete,"CampusPlanterCover")
	_shore_planting()
	_boundary()
	_ground_zones()
	var dressing:=preload("res://scripts/presentation/streets/campus_dressing.gd").new()
	dressing.name="CampusDressing";g.add_child(dressing);dressing.build(self)
	_batch(art)

func _material(color: String, metal: float=0.0) -> Material:
	var key:=color+str(metal)
	if not mats.has(key): mats[key]=VisualFactory.material(Color(color),metal,.87)
	return mats[key]

func _lawn(tint: Color) -> Material:
	var material:=ShaderMaterial.new();material.shader=preload("res://resources/materials/streets/campus_ground.gdshader")
	material.set_shader_parameter("grass_albedo",load("res://assets/environment/campus/leafy_grass_diff_1k.jpg"))
	material.set_shader_parameter("soil_albedo",load("res://assets/environment/campus/forest_ground_04_diff_1k.jpg"))
	material.set_shader_parameter("ground_color",tint)
	mats["lawn_"+str(tint)]=material
	return material

func _surface(asset: String, metres: float, tint: Color) -> Material:
	var key:=asset+str(metres)+str(tint)
	if not mats.has(key): mats[key]=g._pbr_material(asset,metres,tint,"res://assets/environment/campus/")
	return mats[key]

func _detail(size: Vector3, at: Vector3, material: Material, parent: Node3D=null) -> MeshInstance3D:
	if parent==null: parent=art
	var mesh:=VisualFactory.box(parent,size,at,Color.WHITE,"CampusDetail")
	mesh.material_override=material
	return mesh

func _polygon(points: PackedVector2Array, y: float, material: Material, parent: Node3D=null) -> MeshInstance3D:
	if parent==null: parent=art
	var contour:=points.duplicate()
	if Geometry2D.is_polygon_clockwise(contour): contour.reverse()
	var triangles:=Geometry2D.triangulate_polygon(contour)
	var builder:=SurfaceTool.new();builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in range(0,triangles.size(),3):
		for corner in [0,1,2]:
			var p: Vector2=contour[triangles[index+corner]]
			builder.set_uv(p*.15);builder.set_normal(Vector3.UP)
			builder.add_vertex(Vector3(p.x,y,p.y))
	var mesh:=MeshInstance3D.new();mesh.mesh=builder.commit();mesh.material_override=material
	parent.add_child(mesh)
	return mesh

func _smooth(points: Array) -> PackedVector2Array:
	var curve:=Curve2D.new()
	for index in points.size():
		var before: Vector2=points[maxi(0,index-1)]
		var after: Vector2=points[mini(points.size()-1,index+1)]
		var tangent: Vector2=(after-before)*.14
		curve.add_point(points[index],-tangent,tangent)
	curve.bake_interval=1.8
	return curve.get_baked_points()

func _stroke(line: PackedVector2Array, width: float) -> PackedVector2Array:
	var left:=PackedVector2Array();var right:=PackedVector2Array()
	for index in line.size():
		var direction: Vector2=(line[mini(index+1,line.size()-1)]-line[maxi(0,index-1)]).normalized()
		var normal:=Vector2(-direction.y,direction.x)*width*.5
		left.append(line[index]+normal);right.append(line[index]-normal)
	right.reverse();left.append_array(right)
	return left

func _path(line: PackedVector2Array, width: float) -> void:
	var stone: Material=_surface("pavement_05",3.4,Color("c5c6b6"))
	_polygon(_stroke(line,width+1.8),.04,stone)
	var lane: Material=g._pbr_material("asphalt_02",3.2,Color("828785"))
	_polygon(_stroke(line,width),.065,lane)

func _curbs(line: PackedVector2Array, width: float) -> void:
	# Junctions have continuous asphalt; curbs terminate before crossing lanes.
	for side in [-1,1]:
		for index in range(line.size()-1):
			var a:=line[index];var b:=line[index+1];var gap:=b-a
			var normal: Vector2=Vector2(-gap.y,gap.x).normalized()*(width*.5+.75)*side
			var center: Vector2=(a+b)*.5+normal
			var junction:=false
			for other in g.campus_roads:
				if other[0]==line: continue
				if Geometry2D.is_point_in_polygon(center,_stroke(other[0],float(other[1])+2.0)):
					junction=true;break
			if junction: continue
			var curb:=_detail(Vector3(.11,.10,gap.length()+.03),Vector3(center.x,.085,center.y),_material("aaa99a"))
			curb.rotation.y=atan2(gap.x,gap.y)

func _forecourts() -> void:
	var paving:=_surface("pavement_05",3.4,Color("c6c1aa"))
	for polygon in [
		PackedVector2Array([Vector2(15,24),Vector2(33,24),Vector2(33,31),Vector2(15,31)]),
		PackedVector2Array([Vector2(-27,-13),Vector2(-10,-13),Vector2(-10,-7),Vector2(-27,-7)]),
		PackedVector2Array([Vector2(-39,29),Vector2(-22,29),Vector2(-22,32),Vector2(-39,32)]),
		PackedVector2Array([Vector2(-45,-24),Vector2(-29,-24),Vector2(-29,-10),Vector2(-45,-10)]),
		PackedVector2Array([Vector2(-22,13),Vector2(-14,13),Vector2(-14,29),Vector2(-22,29)]),
	]: _polygon(polygon,.043,paving)
	# Narrow pedestrian approaches meet the avenues instead of ending in bare grass.
	for line in [PackedVector2Array([Vector2(24,10),Vector2(24,7)]),PackedVector2Array([Vector2(-18,-36),Vector2(-18,-40)]),PackedVector2Array([Vector2(-31,32),Vector2(-31,45)])]:
		_polygon(_stroke(line,2.4),.045,paving)
	for at in [Vector3(15,0,27),Vector3(33,0,27),Vector3(-27,0,-12),Vector3(-23,0,29)]:
		_detail(Vector3(.85,.45,.85),at+Vector3.UP*.22,_material("8a846c"))
		_bush(at+Vector3.UP*.40,1.1)

func _bush(at: Vector3, radius: float) -> void:
	# Low leaf geometry keeps silhouettes irregular; no sphere primitives or gameplay collision.
	var source:=preload("res://scripts/world/streets/courtyard_tree.gd").new()
	var leaves:=MultiMesh.new();leaves.transform_format=MultiMesh.TRANSFORM_3D;leaves.use_colors=true
	leaves.mesh=source._leaf_mesh();leaves.instance_count=600
	var instance:=MultiMeshInstance3D.new();instance.multimesh=leaves;instance.material_override=source._leaf_material();instance.position=at
	art.add_child(instance);source.free()
	for n in leaves.instance_count:
		var angle:=n*2.399963
		var distance:=sqrt(float(n%113)/113.0)*radius
		var height:=.15+pow(1.0-distance/radius,.5)*radius*.55+sin(n*1.7)*.10
		var basis:=Basis.from_euler(Vector3(sin(n*1.1)*.8,angle,cos(n*.8)*.7)).scaled(Vector3.ONE*.85)
		leaves.set_instance_transform(n,Transform3D(basis,Vector3(cos(angle)*distance,height,sin(angle)*distance)))
		leaves.set_instance_color(n,[Color("586b47"),Color("6f8054"),Color("839266")][n%3].srgb_to_linear())

func _ground_zones() -> void:
	var shores:=PackedVector2Array();var counts:=PackedInt32Array()
	for lake in lakes:
		counts.append(lake.size())
		for n in 8: shores.append(lake[n%lake.size()])
	var trees:=PackedVector2Array()
	for tree in g.get_children():
		if tree.get_script()==preload("res://scripts/world/streets/courtyard_tree.gd"): trees.append(Vector2(tree.position.x,tree.position.z))
	var tree_count:=trees.size();assert(tree_count<=32)
	while trees.size()<32: trees.append(Vector2.ZERO)
	for material in mats.values():
		if material is ShaderMaterial and material.shader==preload("res://resources/materials/streets/campus_ground.gdshader"):
			material.set_shader_parameter("lake_points",shores)
			material.set_shader_parameter("lake_counts",counts)
			material.set_shader_parameter("tree_points",trees)
			material.set_shader_parameter("tree_count",tree_count)

func _shore_planting() -> void:
	# Deliberate small groups beside banks, leaving the promenade and landmark sightlines clear.
	for at in [Vector3(-6.5,0,-32),Vector3(-7,0,-19),Vector3(26,0,-14),Vector3(26,0,-32),Vector3(4,0,-40),Vector3(26,0,-39),Vector3(-5,0,43.5),Vector3(28.5,0,43.5)]:
		_bush(at,1.25)
	for at in [Vector3(-7,0,-27),Vector3(27,0,-19),Vector3(25,0,-37),Vector3(5,0,-40),Vector3(29,0,35),Vector3(-6,0,38)]: g._tree(at)
	for at in [Vector3(-3.5,0,-16),Vector3(20,0,-34),Vector3(23,0,-20),Vector3(-2.5,0,40),Vector3(24,0,40)]:
		for n in 18:
			var offset:=Vector3(sin(n*2.4)*.7,.27+n%4*.055,cos(n*2.4)*.7)
			var blade:=_detail(Vector3(.035,.45+n%4*.08,.055),at+offset,_material("7e8a5b"))
			blade.rotation.z=sin(n)*.18
	# Several floating leaf patches, not a uniform pattern over every square metre.
	for at in [Vector3(1,.067,-12),Vector3(20,.067,-29),Vector3(5,.067,39),Vector3(22,.067,38)]:
		for n in 9:
			var circle:=PackedVector2Array()
			var offset:=Vector2(sin(n*2.4),cos(n*2.4))*sqrt(n)*.32
			for corner in 7: circle.append(Vector2(at.x,at.z)+offset+Vector2.from_angle(corner*TAU/7)*.13)
			_polygon(circle,at.y,_material("637852"))

func _landscape() -> void:
	var lawn: Material=_lawn(Color("72955d"))
	for polygon in [
  PackedVector2Array([Vector2(-47,-6),Vector2(-13,-6),Vector2(-13,1),Vector2(-47,1)]),
  PackedVector2Array([Vector2(-6,7),Vector2(32,7),Vector2(32,9),Vector2(14,9),Vector2(13,27),Vector2(-6,28)]),
  PackedVector2Array([Vector2(-7,33),Vector2(30,33),Vector2(30,44),Vector2(-7,44)]),
  PackedVector2Array([Vector2(-46,34),Vector2(-13,34),Vector2(-13,44),Vector2(-46,44)]),
  PackedVector2Array([Vector2(-46,8),Vector2(-14,8),Vector2(-14,13),Vector2(-46,13)]),
  PackedVector2Array([Vector2(-4,-6),Vector2(29,-6),Vector2(29,0),Vector2(-4,0)]),
  PackedVector2Array([Vector2(-5,-40),Vector2(30,-40),Vector2(30,-6),Vector2(-5,-6)]),
 ]: _polygon(polygon,.025,lawn)
	for at in [Vector3(-42,0,0),Vector3(-33,0,0),Vector3(-22,0,0),Vector3(-14,0,0),Vector3(1,0,0),Vector3(22,0,0),Vector3(31,0,0),Vector3(-43,0,8),Vector3(-19,0,8),Vector3(1,0,10),Vector3(9,0,23),Vector3(-4,0,27),Vector3(-21,0,38),Vector3(-35,0,38),Vector3(31,0,39),Vector3(-2,0,-39),Vector3(20,0,-39)]: g._tree(at)

func _lake(polygon: PackedVector2Array) -> void:
	var shore:=Geometry2D.offset_polygon(polygon,1.9)
	assert(not shore.is_empty())
	_polygon(shore[0],.042,_surface("pavement_05",3.4,Color("b8bca7")))
	var material:=ShaderMaterial.new();material.shader=preload("res://resources/materials/streets/campus_water.gdshader")
	var shores:=polygon.duplicate()
	while shores.size()<8: shores.append(polygon[0])
	material.set_shader_parameter("shore_points",shores)
	material.set_shader_parameter("shore_count",polygon.size())
	var water:=_polygon(polygon,.052,material)
	water.name="CampusLake"
	# A low retaining bank/filled basin prevents walking into water, not an invisible tall wall.
	var body:=StaticBody3D.new();body.name="LakeBasin";body.collision_layer=4;body.collision_mask=0;g.add_child(body)
	var shape:=ConvexPolygonShape3D.new();var vertices:=PackedVector3Array()
	for p in polygon:
		vertices.append(Vector3(p.x,-.15,p.y));vertices.append(Vector3(p.x,.25,p.y))
	shape.points=vertices
	var collision:=CollisionShape3D.new();collision.shape=shape;body.add_child(collision)
	for index in polygon.size():
		var a:=polygon[index];var b:=polygon[(index+1)%polygon.size()];var gap:=b-a;var center: Vector2=(a+b)*.5
		var bank:=_detail(Vector3(.38,.29,gap.length()+.1),Vector3(center.x,.12,center.y),_material("a4a294"))
		bank.rotation.y=atan2(gap.x,gap.y)
		# Evenly sized coping stones belong to a retaining wall, not scattered noise.
		for n in maxi(1,int(gap.length())):
			var at: Vector2=a.lerp(b,float(n)/maxi(1,int(gap.length())))
			var joint:=_detail(Vector3(.40,.015,.035),Vector3(at.x,.272,at.y),_material("555f57"))
			joint.rotation.y=atan2(gap.x,gap.y)

func water_blocks(at: Vector2) -> bool:
	for polygon in lakes:
		if Geometry2D.is_point_in_polygon(at,polygon): return true
		for index in polygon.size():
			if Geometry2D.get_closest_point_to_segment(at,polygon[index],polygon[(index+1)%polygon.size()]).distance_to(at)<.85: return true
	return false

func _solid(center: Vector3, size: Vector3, material: Material, title: String) -> StaticBody3D:
	var body: StaticBody3D=g._box(size,center+Vector3.UP*size.y*.5,material,title)
	g.campus_buildings.append([Vector2(center.x,center.z),Vector2(size.x,size.z)])
	return body

func _roof_body(center: Vector3) -> StaticBody3D:
	for body in g.find_children("*","StaticBody3D",true,false):
		if body.is_in_group("aim_cutaway_roof") and body.position.distance_to(center+Vector3(0,3.6,0))<.1: return body
	return null

func _pitched_roof(parent: Node3D, width: float, depth: float, rise: float, color: String) -> void:
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points: Array[Vector3]=[Vector3(-width*.5,.1,-depth*.5),Vector3(width*.5,.1,-depth*.5),Vector3(-width*.5,.1,depth*.5),Vector3(width*.5,.1,depth*.5),Vector3(-width*.5,rise,0),Vector3(width*.5,rise,0)]
	for face in [[0,4,5],[0,5,1],[4,2,3],[4,3,5],[0,2,4],[1,5,3]]:
		for index in [face[2],face[1],face[0]]:
			surface.set_uv(Vector2(points[index].x,points[index].z)*.4);surface.add_vertex(points[index])
	surface.generate_normals();surface.generate_tangents()
	var mesh:=MeshInstance3D.new();mesh.name="PitchedCampusRoof";mesh.mesh=surface.commit()
	var material:=ShaderMaterial.new();material.shader=preload("res://resources/materials/streets/campus_roof.gdshader")
	material.set_shader_parameter("tile_albedo",load("res://assets/environment/campus/roof_tiles_14_diff_1k.jpg"))
	material.set_shader_parameter("tile_normal",load("res://assets/environment/campus/roof_tiles_14_nor_gl_1k.jpg"))
	material.set_shader_parameter("roof_color",Color(color).lightened(.28))
	material.set_shader_parameter("desaturate",.18 if color=="78624c" else .88)
	mesh.material_override=material;parent.add_child(mesh)
	for z in [-depth*.5,depth*.5]:
		_detail(Vector3(width+.4,.22,.30),Vector3(0,.04,z),_material("4d5d57"),parent)
	_detail(Vector3(width+.2,.18,.24),Vector3(0,rise+.04,0),_material("777a72"),parent)

func _window_row(parent: Node3D, width: float, height: float, depth: float, floors: int) -> void:
	for floor_index in floors:
		for x in range(-int(width*.5)+2,int(width*.5)-1,3):
			for side in [-1,1]:
				var at:=Vector3(x,-height*.5+1.6+floor_index*2.25,side*(depth*.5+.03))
				_detail(Vector3(1.3,1.35,.08),at,_material("304945"),parent)
				_detail(Vector3(1.45,.12,.23),at+Vector3(0,-.74,side*.07),_material("c1ba9f"),parent)
				_detail(Vector3(.055,1.38,.12),at,_material("a7a895"),parent)
				_detail(Vector3(1.3,.055,.12),at,_material("a7a895"),parent)

func _model(asset: String, at: Vector3, scale_factor: float, angle: float=0.0, collide: bool=true) -> Node3D:
	# Reuse already imported, textured furniture. Its measured extent owns the simple collision.
	var model:=SliceUI.prop(g,"res://assets/environment/compact_hideout/polyhaven/"+asset+"/"+asset+".gltf",at,scale_factor)
	model.rotation.y=angle
	if collide:
		var bounds:=AABB();var first:=true
		for mesh in model.find_children("*","MeshInstance3D",true,false):
			var relative: Transform3D=g.global_transform.affine_inverse()*mesh.global_transform
			var extent: AABB=relative*mesh.get_aabb()
			bounds=extent if first else bounds.merge(extent);first=false
		assert(not first)
		var body: StaticBody3D=g._box(bounds.size,bounds.get_center(),g.concrete,"CampusFurniture")
		body.get_node("Mesh").hide();model.reparent(body,true)
	return model

func _cabinet(at: Vector3, kind: int, angle: float=0.0) -> void:
	var shelf:=_model("steel_frame_shelves_01",at,.10,angle)
	var contents:=Node3D.new();contents.name="ShelfContents";contents.scale=Vector3.ONE/shelf.scale;shelf.add_child(contents)
	for level in [.25,.9,1.55]:
		for slot in 4:
			var position:=Vector3(-.38+slot*.25,level,.0)
			var color:=_material(["9c9179","c4c1ab","8a7d62","7a8b6b"][kind])
			_detail(Vector3(.19,.23,.32),position,color,contents)
			_detail(Vector3(.15,.04,.012),position+Vector3(0,.0,.167),_material("d2c6a9"),contents)
	_batch(contents)

func _bunk(at: Vector3) -> void:
	_model("vintage_day_bed",at,1.0,PI/2)
	_model("vintage_day_bed",at+Vector3.UP*1.4,1.0,PI/2,false)
	for x in [-.44,.44]:
		for z in [-.98,.98]: _detail(Vector3(.055,2.55,.055),at+Vector3(x,1.3,z),_material("657361",.45))
	for y in [.3,.6,.9,1.2]: _detail(Vector3(.7,.055,.06),at+Vector3(0,y,1.03),_material("89917d",.45))

func interior(center: Vector3, index: int) -> void:
	var paper:=_material("d2c5aa");var timber:=_material("716046")
	# Keep the clinic's recorded batch and the dorm receipt at their existing counter.
	if index in [1,2]:
		g._box(Vector3(3,.9,.8),center+Vector3(-3,.45,-3),timber,"Counter")
		for x in [-3.8,-2.7]: _detail(Vector3(.4,.018,.28),center+Vector3(x,.92,-3),paper)
	match index:
		0:
			# Reading hall: open central aisle, archive cabinets west, reading desks east.
			for z in [-2.0,0.0]: _cabinet(center+Vector3(-6.4,0,z),0,PI/2)
			_cabinet(center+Vector3(-5.1,0,-5.8),0)
			for z in [-3.6,1.1]:
				_model("metal_office_desk",center+Vector3(4.6,0,z),1.35)
				for x in [3.8,5.4]: _model("metal_stool_01",center+Vector3(x,0,z+1.1),.9)
				_detail(Vector3(.7,.025,.45),center+Vector3(4.6,1.08,z),paper)
			_model("metal_office_desk",center+Vector3(-4.0,0,1.0),1.0)
			_model("desk_lamp_arm_01",center+Vector3(-4.7,.80,1),.7,0,false)
			var rug := ShaderMaterial.new()
			rug.shader = preload("res://resources/materials/streets/campus_rug.gdshader")
			rug.set_shader_parameter("rug_origin",Vector2(center.x,center.z))
			_detail(Vector3(2.3,.035,7.6),center+Vector3(0,.087,0),rug)
		1:
			# Prescription counter west, examination room east, waiting area at the south entrance.
			g._box(Vector3(.22,2.4,7.8),center+Vector3(1.6,1.2,-1),g.plaster,"ClinicPartition")
			for z in [-.5,1.2]: _cabinet(center+Vector3(-6.6,0,z),1,PI/2)
			_cabinet(center+Vector3(6.4,0,2.3),1,PI/2)
			_model("vintage_day_bed",center+Vector3(4.7,0,-3.6),1.2,PI/2)
			_detail(Vector3(.86,.06,1.9),center+Vector3(4.7,.64,-3.6),_material("c4c6b0"))
			_detail(Vector3(.6,.12,.28),center+Vector3(4.7,.72,-4.3),paper)
			_model("metal_stool_01",center+Vector3(3.3,0,-3.1),.85)
			for x in [-6,-4.5]: _model("metal_stool_01",center+Vector3(x,0,5.7),.85)
			for x in [-7.7,7.7]: _detail(Vector3(.045,1.12,13),center+Vector3(x,.62,0),_material("84967c"))
			_detail(Vector3(.22,.7,.045),center+Vector3(4.8,2,-6.76),_material("75906c"))
			_detail(Vector3(.7,.22,.045),center+Vector3(4.8,2,-6.74),_material("75906c"))
		2:
			# Dormitory ground floor: mail/warden side west and two bed bays east of the corridor.
			g._box(Vector3(.22,2.7,7.4),center+Vector3(2.3,1.35,-1.1),g.plaster,"DormitoryPartition")
			for z in [-3.8,1.0]: _bunk(center+Vector3(5.4,0,z))
			_cabinet(center+Vector3(6.1,0,5.7),2)
			_model("metal_office_desk",center+Vector3(-5.4,0,.2),1.1)
			for x in [-6.6,-5.9]:
				for z in [-1.8,-1.3,-.8,-.3]:
					_detail(Vector3(.52,.38,.25),center+Vector3(x,1.4,z),_material("78806c"))
					_detail(Vector3(.34,.025,.27),center+Vector3(x,1.45,z+.1),_material("414e42"))
			for z in [3.0,5.0]: _model("metal_stool_01",center+Vector3(-6.2,0,z),.85)
			_detail(Vector3(3.5,.025,10),center+Vector3(0,.087,0),_material("89867a"))
		3:
			# An actual repair bay replaces the identical shop partition.
			g._vehicle(center+Vector3(4.0,0,-1.9))
			for z in [-3.5,.7]:
				_model("metal_office_desk",center+Vector3(-5.0,0,z),1.25)
				_model("metal_toolbox",center+Vector3(-5.4,.99,z),1.3,0,false)
			_model("metal_tool_chest",center+Vector3(-6.6,0,4.9),2.0,PI/2)
			_cabinet(center+Vector3(6.1,0,-5.7),3)
			for x in [2.5,5.5]: _detail(Vector3(.10,.013,7.6),center+Vector3(x,.09,-1.4),_material("bdab70"))
			for n in 3:
				_model("old_military_crate",center+Vector3(-5.5+n*.4,0,-5.5),.50,n*.6,false)
	# A physical notice board for each room, no floating location label.
	_detail(Vector3(2.0,.9,.065),center+Vector3(-4.0,2.0,-6.75),_material("5f644e"))
	for n in 4: _detail(Vector3(.28,.35,.018),center+Vector3(-4.6+n*.4,2,-6.70),paper)

func _library() -> void:
	var center: Vector3=g.ROOMS[0]
	var roof:=_roof_body(center);assert(roof!=null)
	_pitched_roof(roof,16.8,14.6,3.6,"667773")
	for x in [-5.5,5.5]:
		_detail(Vector3(1.9,.16,2.4),Vector3(x,1.84,3.8),_material("596d68",.1),roof)
		for z in [2.7,4.9]: _detail(Vector3(2.1,.12,.11),Vector3(x,2.0,z),_material("a1a696"),roof)
	for z in [-7.25,7.25]: _detail(Vector3(17,.12,.18),Vector3(0,.16,z),_material("68776f",.45),roof)
	var wing:=_solid(center+Vector3(-12,0,0),Vector3(7,5.2,12),g._pbr_material("painted_plaster_wall",1.5,Color("baaa91")),"LibraryWestWing")
	_window_row(wing,7,5.2,12,2)
	var upper:=Node3D.new();upper.position.y=2.6;wing.add_child(upper);_pitched_roof(upper,7.6,12.6,1.2,"535950");_batch(wing)
	var facade:=Node3D.new();facade.name="ArchiveFacade";facade.position=center;g.add_child(facade)
	for x in [-7,-4.5,4.5,7]:
		_detail(Vector3(.32,3.4,.40),Vector3(x,1.7,7.3),_material("bcb297"),facade)
		_detail(Vector3(.52,.18,.56),Vector3(x,.15,7.3),_material("c6baa0"),facade)
	_detail(Vector3(16.6,.22,.58),Vector3(0,3.42,7.25),_material("bcb297"),facade)
	for x in [-5,5]:
		_detail(Vector3(2.6,1.6,.08),Vector3(x,1.8,7.28),_material("304945"),facade)
		for offset in [-.85,0,.85]: _detail(Vector3(.10,1.8,.15),Vector3(x+offset,1.8,7.36),_material("bcb297"),facade)
	_sign(facade,"档案阅览楼",Vector3(0,3.1,7.4),.006)
	_batch(facade)
	g.campus_buildings.append([Vector2(center.x,center.z),Vector2(16,14)])

func _clinic() -> void:
	var wing:=_solid(g.ROOMS[1]+Vector3(2,0,-13),Vector3(15,4.3,6),g.plaster,"ClinicRearWing")
	_window_row(wing,15,4.3,6,1)
	_detail(Vector3(15.3,.22,6.3),Vector3(0,2.3,0),_material("5b6f63"),wing)
	for x in [-4,4]: _detail(Vector3(1.4,.4,.9),Vector3(x,2.7,0),_material("899289"),wing)
	_batch(wing)
	g.campus_buildings.append([Vector2(g.ROOMS[1].x,g.ROOMS[1].z),Vector2(16,14)])

func _dormitory() -> void:
	var side:=_solid(g.ROOMS[2]+Vector3(-12,0,0),Vector3(7,8.5,17),g.brick,"DormitoryWestWing")
	_window_row(side,7,8.5,17,3)
	_detail(Vector3(7.4,.3,17.4),Vector3(0,4.4,0),_material("76766b"),side)
	var back:=_solid(g.ROOMS[2]+Vector3(-1,0,-12),Vector3(20,6.8,5),g.brick,"DormitoryNorthWing")
	_window_row(back,20,6.8,5,2)
	_detail(Vector3(20.5,.25,5.5),Vector3(0,3.52,0),_material("5f6660"),back)
	_batch(side);_batch(back)
	var roof:=_roof_body(g.ROOMS[2]);_pitched_roof(roof,16.5,14.4,1.9,"78624c")
	for x in [-6,6]:
		_detail(Vector3(.65,1.25,.8),Vector3(x,2.35,0),g.brick,roof)
		_detail(Vector3(.9,.14,1.0),Vector3(x,3.03,0),_material("84877a"),roof)
	var porch:=Node3D.new();porch.name="DormitoryEntrance";porch.position=g.ROOMS[2];g.add_child(porch)
	_detail(Vector3(5.4,.18,1.2),Vector3(0,2.95,7.4),_material("888573"),porch)
	for x in [-2.5,2.5]: _detail(Vector3(.18,2.9,.18),Vector3(x,1.45,7.6),_material("b6ad93"),porch)
	_sign(porch,"学生宿舍 · 七斋",Vector3(0,2.67,7.9),.0045)
	_batch(porch)
	g.campus_buildings.append([Vector2(g.ROOMS[2].x,g.ROOMS[2].z),Vector2(16,14)])

func _workshop() -> void:
	var roof:=_roof_body(g.ROOMS[3]);_pitched_roof(roof,16.6,14.5,1.35,"65736a")
	var shed:=_solid(Vector3(-41,0,-16),Vector3(5,3.2,5.8),g.concrete,"MaintenanceShed")
	_detail(Vector3(5.4,.2,6.2),Vector3(0,1.8,0),_material("586e66"),shed)
	for z in [-1.8,1.8]:
		_detail(Vector3(.08,2.5,2.5),Vector3(-2.54,0,z),_material("58605b"),shed)
	_batch(shed)
	var facade:=Node3D.new();facade.name="WorkshopEntrance";facade.position=g.ROOMS[3];g.add_child(facade)
	_detail(Vector3(15.7,.15,1.0),Vector3(0,2.9,7.5),_material("65736a"),facade)
	for x in [-6,5]:
		_detail(Vector3(2.5,2.1,.09),Vector3(x,1.25,7.3),_material("48584f"),facade)
		for n in 11: _detail(Vector3(2.5,.04,.04),Vector3(x,.3+n*.19,7.36),_material("8e9482"),facade)
	_sign(facade,"后勤维修",Vector3(-1,2.75,7.9),.006)
	_batch(facade)
	g.campus_buildings.append([Vector2(g.ROOMS[3].x,g.ROOMS[3].z),Vector2(16,14)])

func _teaching_hall(center: Vector3, size: Vector2, height: float) -> void:
	var body:=_solid(center,Vector3(size.x,height,size.y),g.brick,"TeachingHall")
	_window_row(body,size.x,height,size.y,maxi(1,int(height/2.3)))
	for x in [-size.x*.5+.3,0,size.x*.5-.3]:
		_detail(Vector3(.48,height,.20),Vector3(x,0,size.y*.5+.08),_material("b3a990"),body)
	_detail(Vector3(size.x+.3,.24,size.y+.3),Vector3(0,height*.5-.04,0),_material("b3a990"),body)
	var roof:=Node3D.new();roof.position.y=height*.5;body.add_child(roof)
	_pitched_roof(roof,size.x+.6,size.y+.6,1.5,"4c5754")
	_batch(body);_batch(roof)

func _sports_court() -> void:
	# An eastern sports court gives the open teaching-side ground a real campus use.
	var surface:=_surface("pavement_05",3.4,Color("9c9d87"))
	_polygon(PackedVector2Array([Vector2(40,10),Vector2(54,10),Vector2(54,29),Vector2(40,29)]),.038,surface)
	_detail(Vector3(12,.015,17),Vector3(47,.05,19.5),_material("667860"))
	var paint:=_material("c2c0a1")
	for x in [41.25,52.75]: _detail(Vector3(.085,.02,16.5),Vector3(x,.069,19.5),paint)
	for z in [11.25,19.5,27.75]: _detail(Vector3(11.5,.02,.085),Vector3(47,.069,z),paint)
	for z in [13,26]:
		_detail(Vector3(4,.02,.085),Vector3(47,.069,z),paint)
		for x in [45,49]: _detail(Vector3(.085,.02,3.5),Vector3(x,.069,11.25+1.75 if z<20 else 27.75-1.75),paint)
		var stand: StaticBody3D=g._box(Vector3(.14,3.4,.14),Vector3(47,1.7,10.8 if z<20 else 28.2),_material("69715f"),"BasketballStand")
		_detail(Vector3(1.2,.72,.10),Vector3(0,1.1,.3 if z<20 else -.3),_material("b9bbaa"),stand)
		var hoop:=MeshInstance3D.new();var mesh:=TorusMesh.new();mesh.inner_radius=.22;mesh.outer_radius=.245;mesh.rings=20;mesh.ring_segments=6
		hoop.mesh=mesh;hoop.material_override=_material("917652");hoop.position=Vector3(0,.97,.65 if z<20 else -.65);stand.add_child(hoop);_batch(stand)
	var circle:=MeshInstance3D.new();var mesh:=TorusMesh.new();mesh.inner_radius=1.47;mesh.outer_radius=1.52;mesh.rings=48;mesh.ring_segments=6
	circle.mesh=mesh;circle.material_override=paint;circle.position=Vector3(47,.073,19.5);art.add_child(circle)
	_bench(Vector3(54.5,0,16),PI/2)

func _pavilion(at: Vector3) -> void:
	var pavilion:=Node3D.new();pavilion.name="LakesidePavilion";pavilion.position=at;g.add_child(pavilion)
	var stone:=_material("b8b49e")
	var footprint:=PackedVector2Array()
	for n in 6:
		var direction:=Vector2.from_angle(n*TAU/6)
		footprint.append(direction*1.8)
		g._box(Vector3(.14,2.6,.14),at+Vector3(direction.x*1.45,1.4,direction.y*1.45),stone,"PavilionColumn")
	_polygon(footprint,.12,stone,pavilion)
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for n in 6:
		var a:=Vector2.from_angle(n*TAU/6)*2.25
		var b:=Vector2.from_angle((n+1)*TAU/6)*2.25
		for vertex in [Vector3(0,4.1,0),Vector3(a.x,2.75,a.y),Vector3(b.x,2.75,b.y)]:
			surface.add_vertex(vertex)
		var beam:=_detail(Vector3(.18,.18,a.distance_to(b)),Vector3((a.x+b.x)*.5,2.74,(a.y+b.y)*.5),_material("6a7669"),pavilion)
		beam.rotation.y=atan2(b.x-a.x,b.y-a.y)
	surface.generate_normals()
	var mesh:=MeshInstance3D.new();mesh.mesh=surface.commit();mesh.material_override=_material("486254")
	pavilion.add_child(mesh)
	_detail(Vector3(.24,.35,.24),Vector3(0,4.2,0),_material("b3b18d"),pavilion)
	_batch(pavilion)

func _gate(at: Vector3, title: String, angle: float) -> void:
	var gate:=Node3D.new();gate.name="CampusGate";gate.position=at;gate.rotation.y=angle;g.add_child(gate)
	for side in [-1,1]:
		_detail(Vector3(.65,2.4,.65),Vector3(side*3,1.2,0),_material("997d62"),gate)
		_detail(Vector3(.85,.18,.85),Vector3(side*3,2.48,0),_material("bfb798"),gate)
	_detail(Vector3(6.6,.20,.48),Vector3(0,2.78,0),_material("777d71"),gate)
	_sign(gate,title,Vector3(0,2.75,.3),.005)
	_batch(gate)

func _sign(parent: Node3D, text: String, at: Vector3, pixels: float) -> void:
	var label:=SliceUI.sign(parent,text,at,Color("d9d1b5"))
	label.font_size=34;label.pixel_size=pixels;label.outline_size=1
	label.billboard=BaseMaterial3D.BILLBOARD_DISABLED

func _bench(at: Vector3, angle: float) -> void:
	var bench: StaticBody3D=g._box(Vector3(2.0,.52,.6),at+Vector3.UP*.26,_material("625d47"),"LakeBench")
	bench.rotation.y=angle;bench.get_node("Mesh").hide()
	for x in [-.75,.75]:
		for z in [-.22,.22]: _detail(Vector3(.09,.43,.09),Vector3(x,-.04,z),_material("515c50",.5),bench)
	for z in [-.20,0,.20]: _detail(Vector3(2.05,.09,.15),Vector3(0,.29,z),_material("897b59"),bench)
	_detail(Vector3(2.05,.55,.1),Vector3(0,.50,-.30),_material("897b59"),bench)
	_batch(bench)

func _furniture() -> void:
	for entry in [[Vector3(3,0,-6),PI],[Vector3(19,0,-6),PI],[Vector3(1,0,33),0.0],[Vector3(21,0,33),0.0],[Vector3(20,0,44),PI]]: _bench(entry[0],entry[1])
	# Sparse lamps deliberately track the avenue and entrances.
	for at in [Vector3(-34,0,8),Vector3(-17,0,7),Vector3(16,0,7),Vector3(34,0,7),Vector3(-32,0,45),Vector3(9,0,45),Vector3(33,0,45)]:
		var pole:=VisualFactory.cylinder(art,.06,3.8,at+Vector3.UP*1.9,Color("657166"),"CampusLamp")
		pole.material_override=_material("657166",.35)
		_detail(Vector3(.45,.16,.4),at+Vector3.UP*3.8,_material("c1bea3"))
	# Bike racks and parked bicycles give the dorm court an everyday human scale.
	for x in [-36,-34.7,-33.4]:
		for z in [-.5,.5]:
			var wheel:=MeshInstance3D.new();var mesh:=TorusMesh.new();mesh.inner_radius=.26;mesh.outer_radius=.31;mesh.rings=12;mesh.ring_segments=8
			wheel.mesh=mesh;wheel.material_override=_material("353e38",.25);wheel.position=Vector3(x,.33,13+z);wheel.rotation.z=PI/2;art.add_child(wheel)
		_detail(Vector3(.055,.60,1.0),Vector3(x,.6,13),_material("8a8b72",.35))
		_detail(Vector3(.3,.08,.22),Vector3(x,.93,13),_material("353e38"))
	for at in [Vector3(-33,0,-20),Vector3(-32,0,-19),Vector3(-31,0,-20)]:
		_detail(Vector3(.9,.6,.8),at+Vector3.UP*.3,_material("7e7056"))
		for edge in [-.35,.35]: _detail(Vector3(.07,.62,.83),at+Vector3(edge,.3,0),_material("a39a7f"))

func extraction_marking(exit: Node3D) -> void:
	exit.get_node("ExtractionPad").hide()
	for child in exit.get_children():
		if child is MeshInstance3D: child.material_override=_material("b0a983")
		if child is Label3D:
			child.pixel_size=.012;child.font_size=34;child.outline_size=2;child.modulate=Color("e2dac0")
			child.position=Vector3(0,.7,2.35)
			child.no_depth_test=true
	var ring:=MeshInstance3D.new();var mesh:=TorusMesh.new()
	mesh.inner_radius=1.94;mesh.outer_radius=2.04;mesh.rings=48;mesh.ring_segments=6
	ring.mesh=mesh;ring.position.y=.12;ring.material_override=_material("bdb285");exit.add_child(ring)

func survey_marking(survey: Node3D) -> void:
	survey.get_node("ReachZoneMarker").hide()
	var ring:=MeshInstance3D.new();var mesh:=TorusMesh.new()
	mesh.inner_radius=2.33;mesh.outer_radius=2.4;mesh.rings=48;mesh.ring_segments=6
	ring.mesh=mesh;ring.position.y=.10;ring.material_override=_material("b4ac8b");survey.add_child(ring)
	for child in survey.get_children():
		if child is Label3D:
			child.pixel_size=.006;child.font_size=30;child.modulate=Color("d1cbb2")

func storage_site(at: Vector3, kind: int) -> void:
	# Small mundane storage landmarks explain why loot exists at this precise location.
	var props:=Node3D.new();props.name="CampusStorage";props.position=at;g.add_child(props)
	if kind==2:
		for x in [-.7,.7]:
			_detail(Vector3(.48,.62,.55),Vector3(x,.31,-.5),_material("8c8170"),props)
			_detail(Vector3(.38,.05,.45),Vector3(x,.64,-.5),_material("b0a58d"),props)
	elif kind==3:
		_detail(Vector3(1.8,.10,1.0),Vector3(0,.10,0),_material("817354"),props)
		for x in [-.8,.8]: _detail(Vector3(.10,.13,1.0),Vector3(x,.12,0),_material("aa9c77"),props)
		_detail(Vector3(.55,.6,.6),Vector3(.7,.4,-.7),_material("63705c"),props)
	else:
		_detail(Vector3(1.6,.20,.9),Vector3(0,.13,0),_material("797c6a"),props)
		for x in [-.65,.65]: _detail(Vector3(.10,.7,.1),Vector3(x,.45,-.5),_material("a1a18d"),props)
		_detail(Vector3(1.5,.10,.14),Vector3(0,.8,-.5),_material("a1a18d"),props)
	_batch(props)

func _boundary() -> void:
	for x in [-58,58]: g._box(Vector3(.4,1.5,116),Vector3(x,.75,0),g.brick,"CampusBoundary")
	for z in [-58,58]: g._box(Vector3(116,1.5,.4),Vector3(0,.75,z),g.brick,"CampusBoundary")
	for z in [-56,56]:
		_detail(Vector3(116,.16,.75),Vector3(0,1.45,z),_material("a39b80"))

func _batch(parent: Node3D) -> void:
	# One mesh per shared material within each fade/collision owner, not hundreds of draw calls.
	var grouped: Dictionary={}
	for child in parent.get_children():
		if not child is MeshInstance3D or child.name=="Mesh" or not child.visible: continue
		var material: Material=child.material_override
		if not grouped.has(material): grouped[material]=[]
		grouped[material].append(child)
	for material in grouped:
		var builder:=SurfaceTool.new();builder.begin(Mesh.PRIMITIVE_TRIANGLES)
		for child in grouped[material]: builder.append_from(child.mesh,0,child.transform)
		builder.set_material(material)
		var mesh:=MeshInstance3D.new();mesh.name="CampusSurface";mesh.mesh=builder.commit();parent.add_child(mesh)
		for child in grouped[material]: child.free()

func _shelter_route_clutter() -> void:
	# Two authored route obstructions requested for the shelter pilot. g._box
	# supplies both real collision and the existing navigation obstacle footprint.
	# Keep the entrance, receipt counter and all exits clear; there is no random clutter.
	var bedding: Node3D=g._box(Vector3(2.6,1.1,9.0),Vector3(-21,.55,33),_material("879480"),"ShelterStoredBedding")
	# Filled, tied bundles and rolled mattresses occupy the conservative box.
	# Hide the plain proxy mesh: repeated flat cuboids would read as a new wall.
	bedding.get_node("Mesh").hide()
	for n in 6:
		var z: float=-3.75+n*1.5
		var cloth:=_material(["9eaa94","b1a48a","8a9d8b","c0b395","9aa68c","a8987e"][n])
		_detail(Vector3(2.57,.78,1.43),Vector3(0,-.16,z),cloth,bedding)
		for roll_z in [-.48,0,.48]:
			var roll:=MeshInstance3D.new();var cylinder:=CylinderMesh.new()
			cylinder.top_radius=.18;cylinder.bottom_radius=.18;cylinder.height=2.4;cylinder.radial_segments=16
			roll.mesh=cylinder;roll.material_override=cloth;roll.position=Vector3(0,.37,z+roll_z);roll.rotation.z=PI/2;bedding.add_child(roll)
		for x in [-.65,.65]:
			_detail(Vector3(.055,.79,1.46),Vector3(x,-.16,z),_material("626f61"),bedding)
		for y in [-.28,.06]:
			_detail(Vector3(2.63,.025,1.46),Vector3(0,y,z),_material("a6ac96"),bedding)
	_batch(bedding)
	var tables: Node3D=g._box(Vector3(4.8,1.1,1.6),Vector3(-49.8,.55,31.5),_material("7c7058"),"ShelterFallenTables")
	# Two overturned distribution tables sit together, not a military roadblock.
	for x in [-1.2,1.2]:
		_detail(Vector3(2.25,.06,1.45),Vector3(x,.58,0),_material("9c8b69"),tables)
		for edge in [-.95,.95]:
			_detail(Vector3(.11,1.12,1.5),Vector3(x+edge,0,0),_material("596f63"),tables)
		_detail(Vector3(2.2,.08,.10),Vector3(x,.12,.82),_material("596f63"),tables)
		# Folded legs remain recognisable on the side of the stacked tables.
		for side in [-1,1]:
			var leg:=_detail(Vector3(1.35,.08,.10),Vector3(x,side*.21,.86),_material("596f63"),tables)
			leg.rotation.z=side*.32
	_batch(tables)
	# The abandoned queue material connects the displaced table stack to its window.
	for n in 3:
		var strip:=_detail(Vector3(.10,.025,.70),Vector3(-47.3+n*.6,.09,31.7-n*.17),_material("798776"))
		strip.rotation.y=.7+n*.2
