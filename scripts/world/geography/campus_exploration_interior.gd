extends "res://scripts/world/geography/campus_interior.gd"
## Different traversable campus functions, not a reskin of the three quest rooms.
const Spaces := preload("res://scripts/world/geography/campus_spaces.gd")
var tour_points:=PackedVector2Array()

func refresh(_journal: CampusFieldworkJournal) -> void:
	pass # Exploration fixtures are not connected to the quest's A/B circuit.

func build(site: String) -> void:
	kind=site;name="Interior_"+site
	var spec: Dictionary=Spaces.ROOMS[site];extent=spec.size
	var tint: Color=Color("a4a797")
	if spec.layout in ["servers","control","plant","laboratory"]:tint=Color("7e918b")
	elif spec.layout in ["dorm_rooms","dorm_lounge","laundry"]:tint=Color("aaa08a")
	elif spec.layout in ["dining","kitchen"]:tint=Color("b6b396")
	_prepare_materials(tint);_shell(spec.title,Spaces.ground(site)==site)
	match spec.layout:
		"reading":_reading()
		"classrooms":_classrooms()
		"stage","auditorium":_auditorium(spec.layout=="stage")
		"laboratory":_laboratory()
		"dorm_lounge","laundry":_laundry(spec.layout=="dorm_lounge")
		"dorm_rooms":_dorm_rooms()
		"dining":_dining()
		"kitchen":_kitchen()
		"pool":_pool()
		"plant":_plant()
		"gym":_gym()
		"servers":_servers()
		"control":_control()
	# Every area has an actual near-field record, not a remote completion button.
	_box("SpaceLog",Vector3(.8,.09,.6),Vector3(0,.78,6.2),"signal")
	_box("LogPlinth",Vector3(1.0,.72,.8),Vector3(0,.36,6.2),"wood",true)
	_station("inspect_space","查看空间记录",Vector3(0,.04,7.5),0)
	if tour_points.is_empty():tour_points=PackedVector2Array([Vector2(0,7.5),Vector2(0,-5)])

func _reading() -> void:
	_wall(Vector2(-19,-3),Vector2(-1.7,-3));_wall(Vector2(1.7,-3),Vector2(19,-3))
	_wall(Vector2(7,-14),Vector2(7,-9.5));_wall(Vector2(7,-6.5),Vector2(7,-3))
	for x: int in [-13,-8]:_shelf(Vector3(x,0,-8))
	for x: int in [-12,-5,4]:
		_desk(Vector3(x,0,2));_chair(Vector3(x,0,4))
	_desk(Vector3(12,0,-11));_chair(Vector3(12,0,-9))
	_label("书库",Vector3(-10,2.8,-4),.009);_label("小组讨论室",Vector3(12,2.8,-4),.007)
	tour_points=PackedVector2Array([Vector2(0,7.5),Vector2(0,-8),Vector2(10,-8),Vector2(10,-5),Vector2(0,-8)])

func _classrooms() -> void:
	for x: int in [-5,6]:_wall(Vector2(x,-14),Vector2(x,3))
	for span: Vector2 in [Vector2(-19,-13),Vector2(-10,-2),Vector2(1,9),Vector2(12,19)]:_wall(Vector2(span.x,3),Vector2(span.y,3))
	for x: int in [-15,-9,-2,3,9,15]:
		for z: int in [-8,-3]:
			_box("StudentDesk",Vector3(2.4,.12,1.1),Vector3(x,.8,z),"wood",true)
			_box("DeskPedestal",Vector3(2.1,.7,.6),Vector3(x,.35,z),"metal")
			_chair(Vector3(x,0,z+1.4))
	for x: float in [-11.5,.5,12.5]:
		_box("Blackboard",Vector3(6,1.5,.08),Vector3(x,1.9,-13.7),"dark")
		_label("课堂 / 讨论 / 备课",Vector3(x,2.7,2.9),.006)
	tour_points=PackedVector2Array([Vector2(0,7.5),Vector2(-11.5,5),Vector2(-11.5,-10),Vector2(-11.5,5),Vector2(-.5,5),Vector2(-.5,-10),Vector2(-.5,5),Vector2(10.5,5),Vector2(10.5,-10),Vector2(10.5,5)])

func _auditorium(stage: bool) -> void:
	_box("PresentationPlatform",Vector3(26,.36,5),Vector3(-2,.18,-11.7),"wood",true)
	_box("ProjectionScreen",Vector3(17,4,.12),Vector3(-2,3.1,-14.7),"paper")
	_box("Lectern",Vector3(1.4,1.1,.8),Vector3(-2,.55,-9.6),"metal",true)
	for row in 5:
		var z: float=-5.8+row*2.3
		for x: int in [-12,-8,-4,2,6,10]:
			var y: float=0.0 if stage else row*.12
			_box("SeatRiser",Vector3(1.4,y+.1,1.4),Vector3(x,y*.5,z),"metal")
			_chair(Vector3(x,y,z))
	if stage:
		for x: int in [-16,12]:
			_box("StageWing",Vector3(.3,4.4,5.3),Vector3(x,2.2,-11.5),"red")
		_label("侧台与排练通道",Vector3(15,2.7,-5),.007)
	else:_label("报告厅 / 侧廊通行",Vector3(0,.04,8.7),.009,true)
	tour_points=PackedVector2Array([Vector2(0,7.5),Vector2(14,6),Vector2(14,-7),Vector2(-16,-7),Vector2(-16,7),Vector2(0,7.5)])

func _laboratory() -> void:
	for x: int in [-10,0,10]:
		for z: int in [-8,-1]:
			_box("LabBench",Vector3(4.2,.96,1.65),Vector3(x,.48,z),"trim",true)
			for side: float in [-1.1,1.1]:
				_box("InstrumentBase",Vector3(.65,.16,.48),Vector3(x+side,1.06,z),"metal")
				_box("InstrumentStand",Vector3(.12,.65,.15),Vector3(x+side,1.42,z-.1),"metal")
				_box("InstrumentHead",Vector3(.42,.18,.26),Vector3(x+side,1.77,z-.1),"dark")
	for x: int in [-12,-5,3,11]:_cabinet(Vector3(x,0,-13.4),"InstrumentStore")
	_label("教学仪器 / 封存陈列",Vector3(0,2.8,-10.5),.01)
	tour_points=PackedVector2Array([Vector2(0,7.5),Vector2(-5,4),Vector2(-5,-10.5),Vector2(5,-10.5),Vector2(5,4)])

func _washer(at: Vector3) -> void:
	_box("Washer",Vector3(1.6,1.2,1.2),at+Vector3.UP*.6,"trim",true)
	var drum:=MeshInstance3D.new();var mesh:=CylinderMesh.new();mesh.top_radius=.45;mesh.bottom_radius=.45;mesh.height=.08;mesh.material=materials.dark
	drum.mesh=mesh;drum.position=at+Vector3(0,.64,.65);drum.rotation_degrees.x=90;add_child(drum)
	_box("WasherControl",Vector3(1.35,.18,.05),at+Vector3(0,1.02,.64),"metal")

func _laundry(lounge: bool) -> void:
	var w:=extent.x*.5;var d:=extent.y*.5
	_wall(Vector2(-w,0),Vector2(-1.6,0));_wall(Vector2(1.6,0),Vector2(w,0))
	_wall(Vector2(3,-d),Vector2(3,-7));_wall(Vector2(3,-3),Vector2(3,0))
	for x: int in [6,9,12]:_washer(Vector3(x,0,-d+2))
	for x: int in [-10,-5]:_desk(Vector3(x,0,-7));_chair(Vector3(x,0,-5))
	_desk(Vector3(-8,0,5));_chair(Vector3(-8,0,3))
	if lounge:
		_box("LoungeBench",Vector3(5,.55,1.1),Vector3(7,.275,3.5),"cloth",true)
		_box("MailSlots",Vector3(5,2,.6),Vector3(-10,1,-d+.6),"wood",true)
	else:
		for x: int in [5,9]:_box("ClothesRail",Vector3(.08,2.3,4),Vector3(x,1.15,-6),"metal")
	_label("公共自习 / 洗衣间",Vector3(0,2.8,0),.009)
	tour_points=PackedVector2Array([Vector2(0,7.5),Vector2(0,-5),Vector2(7,-5),Vector2(7,-8),Vector2(7,-5),Vector2(0,-5),Vector2(-2,-5)])

func _dorm_rooms() -> void:
	var w:=extent.x*.5;var d:=extent.y*.5
	for x: float in [-2.5,2.5]:
		for span: Vector2 in [Vector2(-15,-10.5),Vector2(-7.5,-1.5),Vector2(1.5,7.5),Vector2(10.5,15)]:_wall(Vector2(x,span.x),Vector2(x,span.y))
	for z: float in [-4.5,4.5]:
		_wall(Vector2(-w,z),Vector2(-2.5,z));_wall(Vector2(2.5,z),Vector2(w,z))
	for side: int in [-1,1]:
		for z: int in [-9,0,9]:
			if side==1 and z==9:
				_cabinet(Vector3(11,0,5.2),"LandingStorage")
				_label("公共楼梯前室",Vector3(7,2.4,9),.006)
				continue
			for x: int in [8,13]:
				var at:=Vector3(x*side,0,z-1)
				var collider:=_box("DormBed",Vector3(2.1,.65,3.2),at+Vector3.UP*.325,"cloth",true);collider.hide()
				_prop("polyhaven/vintage_day_bed/vintage_day_bed.gltf","BedArt",at,Vector3(2.1,.95,3.2))
			_desk(Vector3(side*8,0,z+2.8));_chair(Vector3(side*8,0,z+4.1))
			_label("起居房间 / 设计",Vector3(side*4.4,2.4,z),.005)
	tour_points=PackedVector2Array([Vector2(0,7.5),Vector2(0,9),Vector2(-5,9),Vector2(0,9),Vector2(0,0),Vector2(5,0),Vector2(0,0),Vector2(0,-9),Vector2(-5,-9),Vector2(0,-9)])

func _dining() -> void:
	var w:=extent.x*.5;var d:=extent.y*.5
	_box("ServingCounter",Vector3(extent.x-8,1.0,1.6),Vector3(-1,.5,-d+4),"trim",true)
	for x: int in [-11,-4,3,10]:
		_box("MenuBoard",Vector3(4,1.3,.1),Vector3(x,2.4,-d+.4),"dark")
		_box("ServingTray",Vector3(1.8,.08,.7),Vector3(x,1.06,-d+4),"metal")
	for x: int in [-11,-4,4]:
		for z: int in [-3,3]:
			_box("DiningTable",Vector3(3.5,.14,1.2),Vector3(x,.82,z),"wood",true)
			for offset: float in [-1.2,1.2]:_box("DiningBench",Vector3(3.2,.45,.42),Vector3(x,.225,z+offset),"metal",true)
	_label("取餐窗口 / 餐厅",Vector3(0,3,-d+5),.01)
	tour_points=PackedVector2Array([Vector2(0,7.5),Vector2(9,7),Vector2(9,-6),Vector2(-15,-6),Vector2(-15,7)])

func _kitchen() -> void:
	for x: int in [-11,-4,4,11]:_cabinet(Vector3(x,0,-13.2),"ColdAndDryStore")
	for x: int in [-10,0,10]:
		_box("PreparationIsland",Vector3(4.8,.95,1.6),Vector3(x,.475,-4),"metal",true)
		_box("Worktop",Vector3(4.9,.08,1.7),Vector3(x,.99,-4),"trim")
		for offset: float in [-1.5,1.5]:_box("PreparationTray",Vector3(.9,.12,.6),Vector3(x+offset,1.08,-4),"paper")
	_shelf(Vector3(-14,0,2),false);_shelf(Vector3(8,0,1),false)
	_label("备餐 / 清洗 / 储藏",Vector3(0,2.8,-8),.01)
	tour_points=PackedVector2Array([Vector2(0,7.5),Vector2(-5,5),Vector2(-5,-8),Vector2(5,-8),Vector2(5,6)])

func _pool() -> void:
	var blocker:=_box("PoolNoSwimmingVolume",Vector3(22,2,16),Vector3(-4,.5,-2),"glass",true);blocker.hide()
	_box("PoolWater",Vector3(22,.02,16),Vector3(-4,.02,-2),"glass")
	for z: float in [-10.15,6.15]:_box("PoolCoping",Vector3(22.5,.25,.3),Vector3(-4,.125,z),"trim")
	for x: float in [-15.15,7.15]:_box("PoolCoping",Vector3(.3,.25,16.5),Vector3(x,.125,-2),"trim")
	for x: int in [-12,-8,-4,0,4]:
		_box("LaneRope",Vector3(.05,.035,15.6),Vector3(x,.055,-2),"paper")
		for z in 12:_box("LaneFloat",Vector3(.15,.07,.15),Vector3(x,.08,-9.3+z*1.25),"red" if z%3==0 else "paper")
	_wall(Vector2(12,-15),Vector2(12,-6.5));_wall(Vector2(12,-3.5),Vector2(12,4))
	for z: int in [-10,-6,0]:_cabinet(Vector3(16.5,0,z),"ChangingLocker")
	_label("更衣区",Vector3(15,2.8,4),.008);_label("池畔环道 / 不可游泳",Vector3(-3,.05,8.7),.008,true)
	tour_points=PackedVector2Array([Vector2(0,9),Vector2(-17,9),Vector2(-17,-12),Vector2(10,-12),Vector2(10,-5),Vector2(14,-5),Vector2(10,-5),Vector2(10,9)])

func _plant() -> void:
	for x: int in [-11,-3,6]:
		_box("PumpSkid",Vector3(3.0,.25,3.4),Vector3(x,.125,-5),"metal",true)
		var pump:=MeshInstance3D.new();var cylinder:=CylinderMesh.new();cylinder.top_radius=.85;cylinder.bottom_radius=.85;cylinder.height=1.7;cylinder.material=materials.cloth;pump.mesh=cylinder;pump.position=Vector3(x,1.1,-5);add_child(pump)
		_box("PipeRiser",Vector3(.32,3,.32),Vector3(x+1,1.5,-6),"metal")
	_box("PipeHeader",Vector3(25,.35,.35),Vector3(-1,2.9,-7),"metal")
	_cabinet(Vector3(12,0,-12.5),"PlantBoard");_shelf(Vector3(-14,0,3),false)
	_label("后勤设备 / 无现实操作参数",Vector3(0,3.4,-8),.009)
	tour_points=PackedVector2Array([Vector2(0,7.5),Vector2(-7,3),Vector2(-7,-10),Vector2(11,-10),Vector2(11,5)])

func _gym() -> void:
	_box("CourtSurface",Vector3(24,.025,14),Vector3(-4,.016,-3),"wood")
	for z: int in [-10,4]:_box("CourtBoundary",Vector3(24,.025,.07),Vector3(-4,.04,z),"paper")
	for x: int in [-16,8]:_box("CourtBoundary",Vector3(.07,.025,14),Vector3(x,.04,-3),"paper")
	_box("CourtCentre",Vector3(.07,.025,14),Vector3(-4,.04,-3),"paper")
	for x: int in [-15,7]:
		_box("HoopPost",Vector3(.13,3,.13),Vector3(x,1.5,-3),"metal")
		_box("Backboard",Vector3(.15,1.3,2),Vector3(x,3,-3),"trim")
	_wall(Vector2(12,-15),Vector2(12,-4.5));_wall(Vector2(12,-1.5),Vector2(12,4))
	for z: int in [-10,-6,0]:_box("EquipmentRack",Vector3(3,1.8,1),Vector3(16, .9,z),"metal",true)
	for x: int in [-12,-6]:_box("StretchMat",Vector3(3,.04,1.5),Vector3(x,.03,8),"cloth")
	_label("训练区 / 器材间",Vector3(3,2.6,5),.01)
	tour_points=PackedVector2Array([Vector2(0,7.5),Vector2(-17,7),Vector2(-17,-12),Vector2(10,-12),Vector2(10,-3),Vector2(14,-3),Vector2(10,-3),Vector2(10,7)])

func _servers() -> void:
	for x: int in [-12,-6,0,6]:
		for z: int in [-8,-2]:
			_box("ServerRack",Vector3(1.9,2.7,3.3),Vector3(x,1.35,z),"metal",true)
			for unit in 9:
				_box("RackFront",Vector3(1.6,.17,.04),Vector3(x,.3+unit*.25,z+1.68),"dark")
				_box("RackIndicator",Vector3(.08,.08,.05),Vector3(x+.6,.3+unit*.25,z+1.71),"signal")
	_desk(Vector3(-9,0,5));_chair(Vector3(-9,0,7))
	_label("机房 / 离线虚构设备",Vector3(1,3,-11),.009)
	tour_points=PackedVector2Array([Vector2(0,7.5),Vector2(10,6),Vector2(10,-11),Vector2(-3,-11),Vector2(-3,3),Vector2(10,3)])

func _control() -> void:
	_wall(Vector2(-18,0),Vector2(-10,0));_wall(Vector2(-7,0),Vector2(7,0));_wall(Vector2(10,0),Vector2(18,0))
	_wall(Vector2(0,-14),Vector2(0,0))
	for x: int in [-12,-7]:
		_desk(Vector3(x,0,-7));_chair(Vector3(x,0,-5))
		_box("Monitor",Vector3(2.1,1.1,.12),Vector3(x,1.6,-7.4),"glass")
	for x: int in [5,11]:_shelf(Vector3(x,0,-8),false)
	_desk(Vector3(-8,0,4));_chair(Vector3(-8,0,6))
	_label("值班 / 资料室",Vector3(0,2.8,0),.009)
	tour_points=PackedVector2Array([Vector2(0,7.5),Vector2(-8.5,2),Vector2(-8.5,-3),Vector2(-8.5,2),Vector2(8.5,2),Vector2(8.5,-9),Vector2(8.5,2)])
