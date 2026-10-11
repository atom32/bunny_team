extends Node3D
## Authored old-campus district: lakeside avenues, teaching courts and a western service quarter.
@export_enum("day", "night") var lighting_variant := "day"
const HALF := 58
const ROOMS := [Vector3(24,0,17),Vector3(-18,0,-20),Vector3(-31,0,22),Vector3(-37,0,-31)]
const SPAWNS := [Vector3(-47,.1,49),Vector3(-8,.1,53),Vector3(-48,.1,-48),Vector3(47,.1,-48),Vector3(-53,.1,-14),Vector3(53,.1,4)]
const EXITS := [Vector3(52,0,4),Vector3(-8,0,54),Vector3(-8,0,-52),Vector3(-52,0,-14)]
var obstacles: Array[Rect2] = []
var terminals: Array[Vector3] = []
var selected_spawn := -1
var task_index := 0
var route_map: Control
var active_exit_names: Array[String] = []
const REGIONAL_LOOT := [&"street_office_loot", &"street_pharmacy_loot", &"street_apartment_loot", &"street_repair_loot"]
var district_names := ["ARCHIVE READING ROOM","CAMPUS CLINIC","STUDENT DORMITORY","MAINTENANCE YARD"]
var brick: Material
var plaster: Material
var concrete: ShaderMaterial
var loot_points: Array[LootSpawnPoint] = []
var enemy_points: Array[EnemySpawnPoint] = []
var campus_layout: RefCounted
var campus_roads: Array = []
var campus_lakes: Array = []
var campus_buildings: Array = []

func _ready() -> void:
	brick = _pbr_material("wall_bricks_plaster",1.2,Color("c3a58b"))
	plaster = _pbr_material("painted_plaster_wall",2.0,Color("b5b1a1"))
	concrete = _material(Color("555653"),false)
	set_meta("map_revision",3)
	set_meta("lighting", lighting_variant)
	campus_layout = preload("res://scripts/world/streets/campus_layout.gd").new()
	campus_layout.build(self)
	var pharmacy_art := preload("res://scripts/presentation/streets/pharmacy_frontage.gd").new()
	pharmacy_art.name = "PharmacyFrontage"
	add_child(pharmacy_art)
	pharmacy_art.build(self,ROOMS[1])
	var lighting := preload("res://scripts/presentation/streets/campus_lighting_details.gd").new()
	lighting.name = "CampusLightingDetails"
	add_child(lighting)
	lighting.build(campus_layout)
	_build_points()
	_build_navigation()
	GameLanguage.language_changed.connect(_refresh_language)

func _material(color: Color, masonry: bool) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://resources/materials/streets/weathered.gdshader")
	mat.set_shader_parameter("base_color",color)
	mat.set_shader_parameter("brick",masonry)
	return mat

func _pbr_material(asset: String, metres: float, tint: Color, directory := "res://assets/environment/polyhaven_streets/") -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load(directory+asset+"_diff_1k.jpg")
	mat.albedo_color = tint
	mat.normal_enabled = true
	mat.normal_texture = load(directory+asset+"_nor_gl_1k.jpg")
	mat.normal_scale = .55
	mat.roughness_texture = load(directory+asset+"_rough_1k.jpg")
	mat.roughness = .95
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3.ONE/metres
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return mat

func _box(size: Vector3, at: Vector3, mat: Material, title: String, collide := true, navigation_block := true) -> Node3D:
	var node: Node3D
	if collide:
		node = VisualFactory.static_box(self,size,at,Color.WHITE,title)
		(node.get_node("Mesh") as MeshInstance3D).material_override = mat
	else:
		node = VisualFactory.box(self,size,at,Color.WHITE,title)
		(node as MeshInstance3D).material_override = mat
	if collide and navigation_block:
		obstacles.append(Rect2(Vector2(at.x-size.x*.5,at.z-size.z*.5),Vector2(size.x,size.z)).grow(.36))
	return node

func _room(center: Vector3, index: int) -> void:
	var floor_mat := _material([Color("75604b"),Color("aaa99b"),Color("8c897c"),Color("b0ad9e")][index],false)
	floor_mat.set_shader_parameter("floor_finish",2 if index==2 else index+1)
	floor_mat.set_shader_parameter("floor_origin",Vector2(center.x,center.z))
	_box(Vector3(16,.12,14),center+Vector3(0,.02,0),floor_mat,"ShopFloor",true,false)
	for x in [-8,8]: _box(Vector3(.4,3.5,14),center+Vector3(x,1.75,0),brick,"ShopSideWall")
	# Two open entrances allow a street-to-courtyard shortcut.
	for z in [-7,7]:
		for x in [-4.8,4.8]: _box(Vector3(6.4,3.5,.4),center+Vector3(x,1.75,z),plaster,"ShopFrontWall")
		_box(Vector3(3.2,.5,.4),center+Vector3(0,3.25,z),plaster,"DoorLintel",true,false)
	var roof := _box(Vector3(16,.18,14),center+Vector3(0,3.6,0),concrete,"ShopRoof",true,false)
	roof.add_to_group("aim_cutaway_roof")
	campus_layout.interior(center,index)
	var door := load("res://scenes/world/door.tscn").instantiate() as Door
	door.name = "ShopDoor%d" % index
	door.position = center+Vector3(-1.1,0,7)
	door.initial_state = Door.State.OPEN
	add_child(door)
	var leaf := door.get_node("DoorLeaf/DoorBody/DoorMesh") as MeshInstance3D
	leaf.material_override=VisualFactory.material(Color("87917b"),.1,.85)
	door.get_node("DoorLabel").hide()
	var sign := SliceUI.sign(self,district_names[index],center+Vector3(0,3.15,7.3),Color("c5c0a6"))
	sign.font_size = 40
	sign.hide() # The campus facades carry physical signage.
	terminals.append(center+Vector3(-4,0,2.5))

func _tree(at: Vector3) -> void:
	var tree := preload("res://scripts/world/streets/courtyard_tree.gd").new()
	tree.name="CourtyardTree"
	tree.position=at
	add_child(tree)
	tree.build(int(abs(at.x)*103+abs(at.z)*59))
	tree.scale=Vector3.ONE*1.4
	obstacles.append(Rect2(Vector2(at.x-.252,at.z-.252),Vector2(.504,.504)).grow(.36))

func _vehicle(at: Vector3) -> void:
	var car := preload("res://scripts/world/streets/abandoned_sedan.gd").new()
	car.name="AbandonedSedan"
	car.position=at
	add_child(car)
	var variant:=int(abs(at.z))%3
	car.build([Color("616b61"),Color("596570"),Color("897b65")][variant],variant!=0)
	obstacles.append(Rect2(Vector2(at.x-.99,at.z-2.12),Vector2(1.98,4.24)).grow(.36))

func _build_points() -> void:
	for index in SPAWNS.size():
		var point := Marker3D.new();point.name="StreetSpawn%d"%index;point.position=SPAWNS[index]
		point.add_to_group("player_spawn_point");add_child(point)
	for index in EXITS.size():
		var exit := load("res://scenes/world/extraction_point.tscn").instantiate() as ExtractionPoint
		exit.name="Exit%d"%index;exit.extraction_id=StringName("streets_exit_%d"%index);exit.position=EXITS[index];add_child(exit)
		campus_layout.extraction_marking(exit)
	for index in 4:
		for offset in [Vector3(-5,0,-4.5),Vector3(5,0,4),Vector3(-3,0,4.5)]:
			var loot := LootSpawnPoint.new();loot.name="IndoorLoot%d_%d"%[index,loot_points.size()]
			loot.set_meta("campus_storage",index)
			loot.position=ROOMS[index]+offset;loot.setup(&"prototype_high_value_loot" if offset.z<0 and index==0 else REGIONAL_LOOT[index])
			add_child(loot);loot_points.append(loot)
	# Ordinary loot tables keep their existing rolls. The campus places them where supplies belong.
	for entry in [[Vector3(-32,0,-20),3],[Vector3(30,0,-40),0],[Vector3(-35,0,7),2],[Vector3(45.5,0,31),3],[Vector3(-16,0,27),2],[Vector3(28,0,28),0]]:
		var loot := LootSpawnPoint.new();loot.name="StreetLoot%d"%loot_points.size();loot.position=entry[0]
		loot.setup(REGIONAL_LOOT[entry[1]]);loot.set_meta("campus_storage",entry[1]);add_child(loot);loot_points.append(loot)
		campus_layout.storage_site(loot.position,entry[1])
	for at in [Vector3(37,.1,27),Vector3(-37,.1,-16),Vector3(31,.1,-39),Vector3(-10,.1,25),Vector3(-34,.1,4),Vector3(34,.1,4),Vector3(22,.1,29),Vector3(-18,.1,-9),Vector3(-31,.1,32),Vector3(-48,.1,-26)]:
		var point := EnemySpawnPoint.new();point.name="StreetPMC%d"%enemy_points.size();point.position=at
		point.enemy_definition_id=&"prototype_basic_enemy";point.activation_group_id=&"streets_reserve"
		# Outer posts hold territory; street teams flank or close distance. Reuse
		# the same actors/stats, positions and spawn eligibility, not extra spawns.
		point.tactical_role = [1, 0, 2, 2, 1, 1, 2, 2, 3, 3][enemy_points.size()]
		add_child(point);enemy_points.append(point)
	for at in [Vector3(-18,.1,-9), Vector3(-31,.1,32)]:
		var point := EnemySpawnPoint.new()
		point.name = "CampusInfected%d" % enemy_points.size()
		point.position = at
		point.enemy_definition_id = &"campus_infected"
		point.tactical_role = EnemyTactics.Role.PRESSURE
		point.activation_group_id = &"streets_reserve"
		add_child(point); enemy_points.append(point)
	var terminal := RecordsTerminal.new()
	terminal.name="StreetTerminal";terminal.objective_id=&"streets_terminal";terminal.position=terminals[0];add_child(terminal)
	var alarm := RecordsAlarm.new();alarm.name="RecordsAlarm";terminal.add_child(alarm)
	terminal.objective_interacted.connect(func(_id: StringName): alarm.arm(SortieRuntime.get_current_session()))
	var survey := load("res://scenes/world/objective_reach_zone.tscn").instantiate() as ObjectiveReachZone
	survey.name="StreetSurvey";survey.objective_id=&"streets_survey";survey.position=ROOMS[1]+Vector3(0,0,11);add_child(survey)
	campus_layout.survey_marking(survey)
	var session := SortieRuntime.get_current_session()
	if session and session.mission_id == &"streets_relay":
		survey.hide()
		for index in [0,3]:
			var relay := RelayStation.new()
			relay.name = "RelayOffice" if index == 0 else "RelayRepair"
			relay.objective_id = &"relay_office" if index == 0 else &"relay_repair"
			relay.position = ROOMS[index] + Vector3(3,0,2.5)
			add_child(relay)

func configure_sortie_layout(spawn: Node3D, rng: RandomNumberGenerator) -> void:
	selected_spawn=SPAWNS.find(spawn.position)
	active_exit_names.clear()
	var ranked: Array[int] = [0,1,2,3]
	ranked.sort_custom(func(a: int,b: int) -> bool: return EXITS[a].distance_to(spawn.position)>EXITS[b].distance_to(spawn.position))
	for index in EXITS.size():
		var exit := get_node("Exit%d"%index) as ExtractionPoint
		exit.available = index in ranked.slice(0,2)
		# A guaranteed retreat remains possible without mission completion.
		# The second, no-farther assigned route rewards recovering the records.
		exit.required_objective_id = &"streets_terminal" if index == ranked[1] else &""
		exit.visible=exit.available
		var exit_name: String = ["EAST CAMPUS GATE","SOUTH CAMPUS GATE","NORTH CAMPUS GATE","WEST SERVICE GATE"][index]
		for label in exit.find_children("*","Label3D",true,false): label.text = exit_name
		if exit.available: active_exit_names.append(exit_name)
	task_index = rng.randi_range(0,3)
	get_node("StreetTerminal").position=terminals[task_index]
	_refresh_language()
	get_node("StreetSurvey").position=ROOMS[(task_index+2)%4]+Vector3(0,0,11)
	for loot in loot_points:
		loot.enabled = loot.loot_table_id==&"prototype_high_value_loot" or String(loot.name).begins_with("Indoor") or rng.randf()>=.35
	var initial_count := 0
	for point in enemy_points:
		point.initial_spawn=point.position.distance_to(spawn.position)>24 and (point.enemy_definition_id == &"campus_infected" or initial_count<3)
		if point.initial_spawn and point.enemy_definition_id != &"campus_infected": initial_count+=1
	set_meta("sortie_brief", "RECORDS: %s / EXITS: %s"%[district_names[task_index]," + ".join(active_exit_names)])

func create_route_map(actor: Node3D) -> void:
	var layer := CanvasLayer.new()
	layer.name = "DistrictRouteMap"
	layer.layer = 5
	add_child(layer)
	route_map = preload("res://scripts/world/streets/route_map.gd").new()
	route_map.district = self
	route_map.actor = actor
	layer.add_child(route_map)

func _refresh_language() -> void:
	get_node("StreetTerminal").interaction_prompt = tr("SEARCH %s RECORDS") % tr(district_names[task_index])

func _build_navigation() -> void:
	var free_cells := {}
	for x in range(-56,56):
		for z in range(-56,56):
			var cell := Rect2(Vector2(x,z),Vector2.ONE)
			var blocked := false
			for obstacle in obstacles:
				if obstacle.intersects(cell): blocked=true;break
			if not blocked and campus_layout: blocked = campus_layout.water_blocks(cell.get_center())
			if not blocked: free_cells[Vector2i(x,z)] = true
	var vertices: Array[Vector3] = []
	var lookup := {}
	var polygons: Array[PackedInt32Array] = []
	for x in range(-56,56,2):
		for z in range(-56,56,2):
			var fine := false
			for room in ROOMS:
				if Rect2(Vector2(room.x-9,room.z-8),Vector2(18,16)).intersects(Rect2(Vector2(x,z),Vector2(2,2))): fine=true
			var all_free := true
			for dx in 2:
				for dz in 2:
					if not free_cells.has(Vector2i(x+dx,z+dz)): all_free=false
			if all_free and not fine:
				# Unit-length boundary edges match the adjacent fine cells exactly.
				_nav_add([Vector2i(x,z),Vector2i(x+1,z),Vector2i(x+2,z),Vector2i(x+2,z+1),Vector2i(x+2,z+2),Vector2i(x+1,z+2),Vector2i(x,z+2),Vector2i(x,z+1)],vertices,lookup,polygons)
			else:
				for dx in 2:
					for dz in 2:
						var u := x+dx
						var v := z+dz
						if free_cells.has(Vector2i(u,v)):
							_nav_add([Vector2i(u,v),Vector2i(u+1,v),Vector2i(u+1,v+1),Vector2i(u,v+1)],vertices,lookup,polygons)
	var mesh := NavigationMesh.new()
	mesh.vertices=PackedVector3Array(vertices)
	for polygon in polygons: mesh.add_polygon(polygon)
	var region := NavigationRegion3D.new()
	region.name="StreetNavigation"
	region.navigation_mesh=mesh
	add_child(region)

func _nav_add(points: Array, vertices: Array[Vector3], lookup: Dictionary, polygons: Array[PackedInt32Array]) -> void:
	var polygon := PackedInt32Array()
	for point: Vector2i in points:
		if not lookup.has(point):
			lookup[point]=vertices.size()
			vertices.append(Vector3(point.x,.03,point.y))
		polygon.append(lookup[point])
	polygons.append(polygon)
