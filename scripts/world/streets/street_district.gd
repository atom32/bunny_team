extends Node3D
## Original urban district: dense frontages, traversable shops, courtyards and service alleys.
const HALF := 58
const ROOMS := [Vector3(-20,0,-20),Vector3(21,0,-19),Vector3(-21,0,22),Vector3(22,0,23)]
const SPAWNS := [Vector3(-47,.1,49),Vector3(46,.1,48),Vector3(-46,.1,-49),Vector3(47,.1,-48),Vector3(-52,.1,4),Vector3(52,.1,-3)]
const EXITS := [Vector3(-48,0,52),Vector3(48,0,52),Vector3(-48,0,-52),Vector3(48,0,-52)]
var obstacles: Array[Rect2] = []
var terminals: Array[Vector3] = []
var selected_spawn := -1
var task_index := 0
var route_map: Control
var active_exit_names: Array[String] = []
const REGIONAL_LOOT := [&"street_office_loot", &"street_pharmacy_loot", &"street_apartment_loot", &"street_repair_loot"]
var district_names := ["MUNICIPAL OFFICE","PHARMACY","APARTMENT LOBBY","REPAIR SHOP"]
var brick: ShaderMaterial
var plaster: Material
var concrete: ShaderMaterial
var loot_points: Array[LootSpawnPoint] = []
var enemy_points: Array[EnemySpawnPoint] = []

func _ready() -> void:
	brick = _material(Color("665447"),true)
	plaster = _pbr_material("painted_plaster_wall",2.0,Color("b5b1a1"))
	concrete = _material(Color("555653"),false)
	_build_world()
	_dress_city()
	_street_wear()
	_build_points()
	_build_navigation()
	GameLanguage.language_changed.connect(_refresh_language)

func _material(color: Color, masonry: bool) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://resources/materials/streets/weathered.gdshader")
	mat.set_shader_parameter("base_color",color)
	mat.set_shader_parameter("brick",masonry)
	return mat

func _pbr_material(asset: String, metres: float, tint: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	var directory := "res://assets/environment/polyhaven_streets/"
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

func _build_world() -> void:
	VisualFactory.add_world_environment(self,Color("7a858d"),.9)
	var environment := find_child("WorldEnvironment",true,false) as WorldEnvironment
	if environment:
		environment.environment.ambient_light_energy = .38
		environment.environment.glow_enabled = false
	_box(Vector3(116,.2,116),Vector3(0,-.12,0),concrete,"DistrictGround",true,false)
	var asphalt := _pbr_material("asphalt_02",3.0,Color("727578"))
	# Main avenue, two service lanes and two cross streets: connected loops, not a repeated grid.
	for x in [-43,0,43]:
		_box(Vector3(10,.035,114),Vector3(x,.005,0),asphalt,"Street",false)
		for edge in [-5.6,5.6]: _box(Vector3(1.2,.14,114),Vector3(x+edge,.04,0),concrete,"Sidewalk",false)
	for z in [-43,4,43]: _box(Vector3(112,.04,8),Vector3(0,.015,z),asphalt,"CrossStreet",false)
	for z in range(-54,55,6):
		_box(Vector3(.12,.025,2),Vector3(0,.05,z),VisualFactory.material(Color("a6a494")),"FadedLaneStripe",false)
	for index in ROOMS.size(): _room(ROOMS[index],index)
	# Dense residential frontages overlook the playable shop/courtyard layer.
	for x in [-31,-9,10,32]:
		for z in [-32,34]: _apartment(Vector3(x,0,z),Vector3(11,10+abs(x)%3,9))
	for z in [-18,20]:
		_apartment(Vector3(-54,0,z),Vector3(5,13,18))
		_apartment(Vector3(54,0,z),Vector3(5,15,18))
	for at in [Vector3(-20,0,-7),Vector3(23,0,-6),Vector3(-20,0,9),Vector3(20,0,10)]:
		_box(Vector3(12,.07,10),at+Vector3.UP*.025,_material(Color("5c6250"),false),"OvergrownCourt",false)
		for x in [-4,4]:
			_box(Vector3(2.2,.45,.55),at+Vector3(x,.25,0),VisualFactory.material(Color("4b4239")),"Bench")
			_tree(at+Vector3(x,0,3))
	for at in [Vector3(-42,0,24),Vector3(3,0,-35),Vector3(42,0,-14),Vector3(3,0,34)]: _vehicle(at)
	for at in [Vector3(-46,0,-36),Vector3(46,0,37),Vector3(-3,0,7),Vector3(4,0,-8)]:
		_box(Vector3(2.4,.9,.6),at+Vector3.UP*.45,concrete,"ConcreteCover")
	for x in [-58,58]: _box(Vector3(.5,3,116),Vector3(x,1.5,0),brick,"Boundary")
	for z in [-58,58]: _box(Vector3(116,3,.5),Vector3(0,1.5,z),brick,"Boundary")
	var rng := RandomNumberGenerator.new();rng.seed=907
	for index in 110:
		var at := Vector3(rng.randf_range(-52,52),.07,rng.randf_range(-52,52))
		var debris := _box(Vector3(rng.randf_range(.08,.4),.09,rng.randf_range(.1,.35)),at,concrete,"Debris",false)
		debris.rotation.y = rng.randf_range(0,TAU)
	for x in [-37,6,37]:
		for z in [-40,5,40]:
			VisualFactory.cylinder(self,.055,5,Vector3(x,2.5,z),Color("494b48"),"LampPost")
			_box(Vector3(.5,.12,.2),Vector3(x,5,z),VisualFactory.material(Color("aaa18a")),"Lamp",false)

func _room(center: Vector3, index: int) -> void:
	var floor_mat := _material([Color("75604b"),Color("aaa99b"),Color("939086"),Color("666761")][index],false)
	floor_mat.set_shader_parameter("floor_finish",index+1)
	_box(Vector3(16,.12,14),center+Vector3(0,.02,0),floor_mat,"ShopFloor",true,false)
	for x in [-8,8]: _box(Vector3(.4,3.5,14),center+Vector3(x,1.75,0),brick,"ShopSideWall")
	# Two open entrances allow a street-to-courtyard shortcut.
	for z in [-7,7]:
		for x in [-4.8,4.8]: _box(Vector3(6.4,3.5,.4),center+Vector3(x,1.75,z),plaster,"ShopFrontWall")
		_box(Vector3(3.2,.5,.4),center+Vector3(0,3.25,z),plaster,"DoorLintel",true,false)
	var roof := _box(Vector3(16,.18,14),center+Vector3(0,3.6,0),concrete,"ShopRoof",true,false)
	roof.add_to_group("aim_cutaway_roof")
	_box(Vector3(.35,2.7,8),center+Vector3(1.5,1.35,-1),plaster,"InteriorPartition")
	_box(Vector3(3,.9,.8),center+Vector3(-3,.45,-3),VisualFactory.material(Color("595244")),"Counter")
	for x in [-6,6]:
		_dress_shelf(center,index,x)
	var door := load("res://scenes/world/door.tscn").instantiate() as Door
	door.name = "ShopDoor%d" % index
	door.position = center+Vector3(-1.1,0,7)
	door.initial_state = Door.State.OPEN
	add_child(door)
	var sign := SliceUI.sign(self,district_names[index],center+Vector3(0,3.15,7.3),Color("c5c0a6"))
	sign.font_size = 40
	terminals.append(center+Vector3(-4,0,2.5))
	var light := OmniLight3D.new();light.position=center+Vector3(-2,2.7,1)
	light.light_color=Color("d1bd96");light.light_energy=.8;light.omni_range=7;add_child(light)
	_dress_interior(center,index)

func _dress_shelf(center: Vector3, index: int, x: float) -> void:
	var shelf := _box(Vector3(.65,1.8,4),center+Vector3(x,.9,0),concrete,"StorageShelf")
	shelf.get_node("Mesh").hide()
	var frame_color := Color("54594f")
	for edge in [-.3,.3]:
		for end in [-1.9,1.9]: VisualFactory.box(shelf,Vector3(.055,1.8,.055),Vector3(edge,0,end),frame_color,"ShelfUpright")
	for level in [-.4,.2,.8]:
		VisualFactory.box(shelf,Vector3(.68,.055,4),Vector3(0,level,0),Color("716959"),"ShelfBoard")
		for slot in range(7):
			var at := Vector3(0,level+.15,-1.65+slot*.52)
			if index==0:
				VisualFactory.box(shelf,Vector3(.38,.25,.32),at,Color("8c816c") if slot%2 else Color("5b6553"),"ArchiveFolder")
				VisualFactory.box(shelf,Vector3(.006,.045,.15),at+Vector3(-.195,0,0),Color("b6b09c"),"FolderLabel")
			elif index==1:
				VisualFactory.box(shelf,Vector3(.26,.23,.22),at,Color("d0cbb7") if slot%2 else Color("769184"),"MedicineCarton")
				VisualFactory.box(shelf,Vector3(.27,.025,.23),at+Vector3(0,-.04,0),Color("517768"),"MedicineStripe")
			elif index==3:
				VisualFactory.box(shelf,Vector3(.3,.25,.28),at,Color("8b7049") if slot%2 else Color("505950"),"WorkshopPartsBox")
			elif level<0:
				VisualFactory.box(shelf,Vector3(.4,.23,.35),at,Color("70604e"),"ResidentParcel")

func _dress_interior(at: Vector3,index: int) -> void:
	# Each interior has its own use, floor finish and readable local landmark.
	var board := _box(Vector3(2.6,1.25,.08),at+Vector3(-4,1.9,-6.7),VisualFactory.material(Color("565342")),"NoticeBoard",false)
	for n in 6:
		VisualFactory.box(board,Vector3(.28,.37,.01),Vector3(-.85+(n%3)*.72,-.24+(n/3)*.55,.055),Color("c1bbaa"),"NoticePaper")
	if index==0:
		var desk := _box(Vector3(2.1,.8,1.2),at+Vector3(4,.48,-2),VisualFactory.material(Color("514d40")),"OfficeDesk")
		VisualFactory.box(desk,Vector3(.5,.36,.05),Vector3(0,.55,-.2),Color("303b37"),"OfficeMonitor")
		VisualFactory.box(desk,Vector3(.25,.04,.27),Vector3(0,.42,-.2),Color("747369"),"MonitorStand")
		VisualFactory.box(desk,Vector3(.45,.03,.16),Vector3(0,.415,.22),Color("3c4039"),"Keyboard")
		_box(Vector3(.85,1.8,1.2),at+Vector3(-7,.98,-4.9),VisualFactory.material(Color("717469")),"FilingCabinet")
		for y in [.35,.85,1.35]: _box(Vector3(.07,.035,.4),at+Vector3(-6.54,y,-4.9),VisualFactory.material(Color("bbb5a5")),"DrawerHandle",false)
	elif index==1:
		var cross := _box(Vector3(.18,.75,.05),at+Vector3(0,2.1,-6.75),VisualFactory.material(Color("79927b")),"PharmacyCross",false)
		VisualFactory.box(cross,Vector3(.65,.18,.06),Vector3.ZERO,Color("79927b"),"CrossBar")
		for n in 5:
			VisualFactory.cylinder(self,.06,.18,at+Vector3(-4+n*.37,1.08,-3),Color("b0ac94"),"PrescriptionBottle")
		_box(Vector3(1.6,.65,.6),at+Vector3(4,.4,-4.5),VisualFactory.material(Color("6c776c")),"MedicineReturnCrate")
	elif index==2:
		for n in 8:
			var mailbox := _box(Vector3(.42,.35,.25),at+Vector3(-7.5,1+(n/4)*.4,-1+(n%4)*.5),VisualFactory.material(Color("626a5c")),"Mailbox",false)
			VisualFactory.box(mailbox,Vector3(.015,.02,.22),Vector3(.22,.05,0),Color("282f29"),"MailSlot")
		_box(Vector3(2.5,.48,.75),at+Vector3(4,.3,-3),VisualFactory.material(Color("554a3f")),"LobbyBench")
		_box(Vector3(2.5,.65,.12),at+Vector3(4,.67,-3.36),VisualFactory.material(Color("554a3f")),"BenchBack",false)
	else:
		for n in 3:
			var tire := MeshInstance3D.new()
			var mesh := TorusMesh.new();mesh.inner_radius=.17;mesh.outer_radius=.36;mesh.rings=16;mesh.ring_segments=12
			tire.mesh=mesh;tire.material_override=VisualFactory.material(Color("30332e"),0,.97)
			tire.position=at+Vector3(4,.29+n*.22,-4.4);add_child(tire)
		_box(Vector3(.85,.7,.85),at+Vector3(4,.4,-4.4),concrete,"TireStackCollision").get_node("Mesh").hide()
		for n in 5:
			_box(Vector3(.05,.45,.05),at+Vector3(-4.8+n*.4,1.7,-6.62),VisualFactory.material(Color("85867a"),.6,.6),"HangingTool",false)
			_box(Vector3(.16,.09,.07),at+Vector3(-4.8+n*.4,1.5,-6.59),VisualFactory.material(Color("85867a"),.6,.6),"ToolHead",false)

func _apartment(center: Vector3,size: Vector3) -> void:
	var masonry := int(abs(center.x))%3==1
	var variant := int(abs(center.x)+abs(center.z))%4
	var facade: Material
	if masonry:
		facade=_pbr_material("wall_bricks_plaster",1.0,[Color("b8aca0"),Color("adb09d"),Color("c3aa97"),Color("a8b3a8")][variant])
	else:
		facade=plaster.duplicate()
		(facade as StandardMaterial3D).albedo_color=[Color("b5b1a1"),Color("a3afa4"),Color("c0b69c"),Color("abaeac")][variant]
	var body := _box(size,center+Vector3.UP*size.y*.5,facade,"ResidentialBlock")
	var trim := _material(Color("918e7f"),false)
	for side in [-1,1]:
		var z: float = side*(size.z*.5+.09)
		var ground_y: float = -size.y*.5
		var plinth:=VisualFactory.box(body,Vector3(size.x,1,.15),Vector3(0,ground_y+.5,z),Color.WHITE,"StonePlinth")
		plinth.material_override=concrete
		var entrance_x: float = size.x*(-.22 if variant%2 else .22)
		var doorway:=Vector3(entrance_x,ground_y+1.15,z+side*.035)
		VisualFactory.box(body,Vector3(1.35,2.25,.10),doorway,Color("2b3632"),"ClosedResidentialDoor")
		for x in [-.77,.77]:
			var jamb:=VisualFactory.box(body,Vector3(.13,2.6,.25),doorway+Vector3(x,.04,0),Color.WHITE,"EntranceJamb")
			jamb.material_override=trim
		VisualFactory.box(body,Vector3(1.65,.15,.25),doorway+Vector3(0,1.32,0),Color("949182"),"EntranceLintel")
		VisualFactory.box(body,Vector3(1.12,.45,.13),doorway+Vector3(0,.75,side*.03),Color("48534d"),"DoorTransom")
		VisualFactory.box(body,Vector3(.025,.24,.03),doorway+Vector3(.43,-.16,side*.1),Color("aaa996"),"DoorHandle")
		VisualFactory.box(body,Vector3(2.1,.13,1.0),doorway+Vector3(0,1.40,side*.37),Color("4a554e"),"EntranceCanopy")
		for x in [-.8,.8]:
			VisualFactory.box(body,Vector3(.025,.42,.025),doorway+Vector3(x,1.13,side*.7),Color("60695c"),"CanopyBracket")
		var address:=SliceUI.sign(body,str(7+variant),doorway+Vector3(1.02,.65,side*.12),Color("b7b59f"))
		address.rotation.y=0 if side==1 else PI
		address.font_size=26;address.pixel_size=.003
		for x in [-.47,.47]:
			var pilaster:=VisualFactory.box(body,Vector3(.26,size.y-.1,.18),Vector3(size.x*x,0,z),Color.WHITE,"FacadePilaster")
			pilaster.material_override=trim
		for floor_y in range(1,int(size.y/2.4)+1):
			VisualFactory.box(body,Vector3(size.x,.11,.19),Vector3(0,ground_y+floor_y*2.3-.96,z),Color("807f73"),"FacadeBand")

	for floor_index in range(1,int(size.y/2.4)+1):
		for x in [-.32,0,.32]:
			for side in [-1,1]:
				var point := Vector3(size.x*x,-size.y*.5+floor_index*2.3,size.z*.5*side+.03*side)
				VisualFactory.box(body,Vector3(1.35,1.6,.12),point,Color("303735"),"WindowRecess")
				VisualFactory.box(body,Vector3(1.5,.1,.28),point+Vector3(0,-.85,0),Color("79766a"),"WindowSill")
				VisualFactory.box(body,Vector3(.055,1.6,.15),point,Color("77766e"),"WindowMullion")
				VisualFactory.box(body,Vector3(1.4,.07,.15),point,Color("77766e"),"WindowTransom")
				if x==0 and floor_index%2==1:
					VisualFactory.box(body,Vector3(2.2,.14,.9),point+Vector3(0,-.87,side*.42),Color("67685e"),"BalconySlab")
					VisualFactory.box(body,Vector3(2.2,.07,.07),point+Vector3(0,-.05,side*.85),Color("434a46"),"BalconyRail")
					for bar in [-.9,-.45,0,.45,.9]:
						VisualFactory.box(body,Vector3(.035,.8,.035),point+Vector3(bar,-.43,side*.85),Color("434a46"),"BalconyBar")
				if (int(abs(center.x))+floor_index+int(x*100))%7==2:
					for board_index in range(2):
						var board:=VisualFactory.box(body,Vector3(1.45,.19,.04),point+Vector3(0,board_index*.46-.2,side*.11),Color("71634e"),"BoardedWindow")
						board.rotation.z=.08 if board_index==0 else -.12
				if floor_index%2==0: VisualFactory.box(body,Vector3(.75,.5,.45),point+Vector3(.3,-1,0),Color("8a877c"),"ACUnit")
	VisualFactory.box(body,Vector3(size.x+.3,.2,size.z+.3),Vector3(0,size.y*.5,0),Color("41443f"),"RoofCornice")
	var roof_y := size.y*.5+.15
	var roof := VisualFactory.box(body,Vector3(size.x-.2,.06,size.z-.2),Vector3(0,roof_y,0),Color.WHITE,"WeatheredRoof")
	roof.material_override = _material(Color("414641"),false)
	for side in [-1,1]:
		VisualFactory.box(body,Vector3(size.x,.45,.18),Vector3(0,roof_y+.2,side*(size.z*.5-.1)),Color("777767"),"RoofParapet")
		VisualFactory.box(body,Vector3(.18,.45,size.z),Vector3(side*(size.x*.5-.1),roof_y+.2,0),Color("777767"),"RoofParapet")
	for x in [-.25,.25]:
		VisualFactory.box(body,Vector3(.7,1.1,.85),Vector3(size.x*x,roof_y+.55,-size.z*.2),Color("716758"),"Chimney")
		VisualFactory.box(body,Vector3(.9,.12,1),Vector3(size.x*x,roof_y+1.15,-size.z*.2),Color("484d46"),"ChimneyCap")
	VisualFactory.box(body,Vector3(1.6,.45,1),Vector3(-size.x*.25,roof_y+.25,size.z*.25),Color("777b71"),"RoofVent")
	for slot in range(6):
		VisualFactory.box(body,Vector3(1.4,.02,.025),Vector3(-size.x*.25,roof_y+.485,size.z*.25-.4+slot*.15),Color("333d38"),"VentSlat")

func _tree(at: Vector3) -> void:
	var tree := preload("res://scripts/world/streets/courtyard_tree.gd").new()
	tree.name="CourtyardTree"
	tree.position=at
	add_child(tree)
	tree.build(int(abs(at.x)*103+abs(at.z)*59))
	obstacles.append(Rect2(Vector2(at.x-.18,at.z-.18),Vector2(.36,.36)).grow(.36))

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
	for index in 4:
		for offset in [Vector3(-5,0,-4.5),Vector3(5,0,4),Vector3(-3,0,4.5)]:
			var loot := LootSpawnPoint.new();loot.name="IndoorLoot%d_%d"%[index,loot_points.size()]
			loot.position=ROOMS[index]+offset;loot.setup(&"prototype_high_value_loot" if offset.z<0 else REGIONAL_LOOT[index])
			add_child(loot);loot_points.append(loot)
	for at in [Vector3(-47,0,36),Vector3(47,0,-36),Vector3(-31,0,8),Vector3(32,0,9),Vector3(-32,0,-8),Vector3(32,0,-7)]:
		var loot := LootSpawnPoint.new();loot.name="StreetLoot%d"%loot_points.size();loot.position=at;loot.setup(&"street_supply_loot");add_child(loot);loot_points.append(loot)
	for at in [Vector3(-43,.1,-30),Vector3(43,.1,30),Vector3(0,.1,-20),Vector3(0,.1,23),Vector3(-32,.1,4),Vector3(32,.1,4),Vector3(-20,.1,-9),Vector3(21,.1,-7),Vector3(-21,.1,10),Vector3(22,.1,11)]:
		var point := EnemySpawnPoint.new();point.name="StreetPMC%d"%enemy_points.size();point.position=at
		point.enemy_definition_id=&"prototype_basic_enemy";point.activation_group_id=&"streets_reserve"
		# Outer posts hold territory; street teams flank or close distance. Reuse
		# the same actors/stats, positions and spawn eligibility, not extra spawns.
		point.tactical_role = [1, 1, 0, 2, 1, 1, 2, 2, 3, 3][enemy_points.size()]
		add_child(point);enemy_points.append(point)
	var terminal := RecordsTerminal.new()
	terminal.name="StreetTerminal";terminal.objective_id=&"streets_terminal";terminal.position=terminals[0];add_child(terminal)
	var alarm := RecordsAlarm.new();alarm.name="RecordsAlarm";terminal.add_child(alarm)
	terminal.objective_interacted.connect(func(_id: StringName): alarm.arm(SortieRuntime.get_current_session()))
	var survey := load("res://scenes/world/objective_reach_zone.tscn").instantiate() as ObjectiveReachZone
	survey.name="StreetSurvey";survey.objective_id=&"streets_survey";survey.position=Vector3(23,0,-6);add_child(survey)
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
		var exit_name: String = ["SOUTH SERVICE GATE","SOUTH TRAM CHECKPOINT","NORTH ARCHWAY","NORTH LOADING GATE"][index]
		for label in exit.find_children("*","Label3D",true,false): label.text = exit_name
		if exit.available: active_exit_names.append(exit_name)
	task_index = rng.randi_range(0,3)
	get_node("StreetTerminal").position=terminals[task_index]
	_refresh_language()
	get_node("StreetSurvey").position=ROOMS[(task_index+2)%4]+Vector3(0,0,11)
	for loot in loot_points:
		loot.enabled = loot.loot_table_id==&"prototype_high_value_loot" or rng.randf()>=.35
	for point in enemy_points:
		point.initial_spawn=point.position.distance_to(spawn.position)>24
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

func _dress_city() -> void:
	# Age, domestic details and discarded everyday objects distinguish the urban setting.
	for x in [-27,25]:
		for z in [-52,52]: _apartment(Vector3(x,0,z),Vector3(18,14 if x<0 else 11,6))
	for index in ROOMS.size():
		var at: Vector3 = ROOMS[index]
		var awning := _box(Vector3(12,.16,1.3),at+Vector3(0,3.1,7.8),_material(Color("4e625b") if index%2==0 else Color("73564b"),false),"FadedAwning",false)
		awning.rotation.x = -.1
		for x in [-5,5]:
			_box(Vector3(2.4,1.5,.06),at+Vector3(x,1.9,7.23),VisualFactory.material(Color("303d3a"),.25,.45),"ShopWindow",false)
			_box(Vector3(2.5,.09,.22),at+Vector3(x,1.1,7.25),concrete,"WindowSill",false)
		for x in [-5.5,5.5]:
			_box(Vector3(.45,.08,.7),at+Vector3(x,.14,3),VisualFactory.material(Color("7d7560")),"DiscardedBox",false)
		_box(Vector3(1.6,.72,.55),at+Vector3(-4,.45,1),VisualFactory.material(Color("605b50")),"RecordsDesk")
		for offset in [Vector3(-.35,0,0),Vector3(.25,.012,.05)]:
			_box(Vector3(.24,.015,.32),at+Vector3(-4,.82,1)+offset,VisualFactory.material(Color("b7b2a0")),"ScatteredRecords",false)
		var sign := SliceUI.sign(self,["АДМИНИСТРАЦИЯ","АПТЕКА","ДОМ 07","РЕМОНТ"][index],at+Vector3(0,2.75,7.9),Color("a7a08b"))
		sign.font_size=28
	for at in [Vector3(-33,0,-17),Vector3(33,0,18),Vector3(-33,0,20),Vector3(33,0,-22)]:
		_box(Vector3(1.4,1.1,.9),at+Vector3.UP*.55,_material(Color("41574d"),false),"RustingDumpster")
		_box(Vector3(1.5,.07,1),at+Vector3.UP*1.15,VisualFactory.material(Color("303c35"),.4,.85),"DumpsterLid",false)
		for n in 5:
			var bag := VisualFactory.sphere(self,.22,at+Vector3(1.1+(n%2)*.3,.2,(n/2)*.35),Color("292e29"),"TrashBag")
			bag.scale=Vector3(1,.8,1.15)
		for n in 6: _box(Vector3(.09,.07,1.2),at+Vector3(-1.4+n*.12,.1,.3),VisualFactory.material(Color("776247")),"PalletPlank",false)
	for z in [-43,4,43]:
		for x in range(-4,5): _box(Vector3(.5,.025,3.3),Vector3(x*.85,.065,z-2.1),VisualFactory.material(Color("b6b3a2")),"WeatheredCrosswalk",false)
	for x in [-37,37]:
		for z in [-31,25]:
			var sign := SliceUI.sign(self,"OLD TOWN / 07",Vector3(x,2.7,z),Color("a6aa96"))
			sign.font_size=32

func _street_wear() -> void:
	var rng := RandomNumberGenerator.new();rng.seed=741
	for x in [-43,0,43]:
		for z in [-35,-12,19,36]:
			for side in [-1,1]:
				var patch:=MeshInstance3D.new();patch.name="CurbGrime"
				var plane:=PlaneMesh.new();plane.size=Vector2(rng.randf_range(.6,1.1),rng.randf_range(2.3,5.2));patch.mesh=plane
				patch.position=Vector3(x+side*4.75,.072,z)
				patch.rotation.y=rng.randf_range(-.12,.12)
				var mat:=ShaderMaterial.new();mat.shader=preload("res://resources/materials/streets/street_grime.gdshader")
				mat.set_shader_parameter("tint",Color("57503e"));mat.set_shader_parameter("seed",rng.randf_range(0,100))
				patch.material_override=mat;add_child(patch)
	for at in [Vector3(-42,.074,25),Vector3(3,.074,-36),Vector3(42,.074,-15),Vector3(3,.074,35)]:
		var patch:=MeshInstance3D.new();patch.name="OilAndDamp"
		var plane:=PlaneMesh.new();plane.size=Vector2(2.1,3.4);patch.mesh=plane
		patch.position=at
		var mat:=ShaderMaterial.new();mat.shader=preload("res://resources/materials/streets/street_grime.gdshader")
		mat.set_shader_parameter("tint",Color("202b26"));mat.set_shader_parameter("wetness",.85);mat.set_shader_parameter("seed",rng.randf_range(0,100))
		patch.material_override=mat;add_child(patch)
	# Storefront identities are readable without relying on their text labels.
	var pharmacy: Vector3=ROOMS[1]+Vector3(5,2.2,7.35)
	for size in [Vector3(.3,1.15,.08),Vector3(1.15,.3,.08)]:
		_box(size,pharmacy,VisualFactory.material(Color("77957c")),"PharmacyCross",false)
	var office: Vector3=ROOMS[0]
	for x in [-2,2]:
		_box(Vector3(.28,2.8,.30),office+Vector3(x,1.4,7.28),_material(Color("9b9686"),false),"MunicipalEntrancePillar",false)
	_box(Vector3(4.6,.21,.50),office+Vector3(0,2.93,7.32),concrete,"MunicipalEntranceHeader",false)
	var workshop: Vector3=ROOMS[3]
	for z in [-7.24,7.24]:
		_box(Vector3(2.1,2.4,.08),workshop+Vector3(5,1.3,z),VisualFactory.material(Color("676e65")),"ClosedGarageShutter",false)
		for row in range(12):
			_box(Vector3(2.08,.028,.10),workshop+Vector3(5,.22+row*.195,z+signf(z)*.025),VisualFactory.material(Color("434c46")),"ShutterSlat",false)
