extends Node3D
## Authored cutaway play spaces, NOT surveyed floorplans of the real buildings.
var kind := ""
var stations: Array[Dictionary]=[]
var plan: Array[Dictionary]=[]
var materials: Dictionary={}
var gate: MeshInstance3D
var power_lamps: Array[MeshInstance3D]=[]
var room_lights: Array[OmniLight3D]=[]
var state_label: Label3D
const NAMES := {"library":"图书馆 · 档案区","main_hall":"九教 · 检修间","activity":"活动中心 · 补给站"}
const SPAWN := Vector3(0,.12,9)
var extent:=Vector2(32,24)
var entry_point:=SPAWN
var title := ""

func build(site: String) -> void:
	kind=site;name="Interior_"+site
	_prepare_materials(Color({"library":"929486","main_hall":"777f78","activity":"8c9d90"}[site]))
	_shell(NAMES[site])
	match site:
		"library":_library()
		"main_hall":_workshop()
		"activity":_relief()

func _prepare_materials(tint: Color) -> void:
	for entry: Array in [["wall","b8b7a2"],["trim","dad7c2"],["metal","465651"],["wood","82745a"],["paper","d9d5bb"],["cloth","7f9382"],["red","a95d4f"],["glass","578780"],["dark","263936"],["signal","d3de83"]]:
		var material:=StandardMaterial3D.new();material.albedo_color=Color(entry[1]);material.roughness=.78
		materials[entry[0]]=material
	materials.wall.albedo_texture=load("res://assets/environment/compact_hideout/concrete/Wall_ConcreteWall_Color_2k.png")
	materials.wall.normal_enabled=true;materials.wall.normal_texture=load("res://assets/environment/compact_hideout/concrete/Wall_ConcreteWall_Normal_2k.png");materials.wall.normal_scale=.35
	materials.wall.uv1_triplanar=true;materials.wall.uv1_world_triplanar=true;materials.wall.uv1_scale=Vector3.ONE*.35
	var floor_mat:=ShaderMaterial.new();floor_mat.shader=preload("res://resources/materials/streets/campus_interior_floor.gdshader")
	floor_mat.set_shader_parameter("tile_color",tint)
	floor_mat.set_shader_parameter("floor_size",extent)
	materials.floor=floor_mat

func _shell(caption: String, exterior_exit := true) -> void:
	title=caption
	var w:=extent.x*.5;var d:=extent.y*.5
	entry_point=Vector3(0,.12,d-3)
	_box("TileFloor",Vector3(extent.x,.3,extent.y),Vector3(0,-.15,0),"floor",true)
	_wall(Vector2(-w,-d),Vector2(w,-d))
	_wall(Vector2(-w,-d),Vector2(-w,d))
	_wall(Vector2(w,-d),Vector2(w,d))
	_wall(Vector2(-w,d),Vector2(-1.6,d),true)
	_wall(Vector2(1.6,d),Vector2(w,d),true)
	_box("ExitDoor",Vector3(3.1,2.8,.18),Vector3(0,1.4,d),"metal",true)
	_box("ExitGlazing",Vector3(2.4,1.4,.05),Vector3(0,1.9,d-.12),"glass")
	_label("返回校园 / E" if exterior_exit else "封闭后勤门 / 从楼梯返回",Vector3(0,3.1,d-.2),.007)
	if exterior_exit:_station("exit","返回校园",Vector3(0,.05,d-2),0)
	# An intentional roofless cutaway: south walls stay low visually, but
	# their collision remains full height. It does not delete exterior batches.
	_label(caption,Vector3(-w*.56,.04,d-2.1),.011,true)
	_label("游戏设计室内 / 非真实测绘",Vector3(w*.50,.04,d-1.6),.006,true)
	for x: int in [-10,0,10]:
		for z: int in [-7,5]:
			var light:=OmniLight3D.new();light.position=Vector3(x,4.8,z)
			light.light_color=Color("fff1d0");light.light_energy=.68;light.omni_range=13
			add_child(light)
			room_lights.append(light)
	var key:=DirectionalLight3D.new();key.rotation_degrees=Vector3(-65,-30,0);key.light_energy=.45;key.light_color=Color("d9e5dd");key.shadow_enabled=true;add_child(key)
	for x: int in [-12,-6,0,6,12]:
		_box("HighWindow",Vector3(3.7,1.3,.06),Vector3(x,2.2,-d+.2),"glass")
		_box("WindowSill",Vector3(4,.1,.28),Vector3(x,1.5,-d+.33),"trim")

func _box(label: String, size: Vector3, at: Vector3, material: String, solid := false) -> MeshInstance3D:
	var node:=MeshInstance3D.new();node.name=label;node.position=at
	var mesh:=BoxMesh.new();mesh.size=size;mesh.material=materials[material];node.mesh=mesh
	add_child(node)
	if solid:
		var body:=StaticBody3D.new();body.name="Body";body.collision_layer=4;body.collision_mask=0;node.add_child(body)
		var collision:=CollisionShape3D.new();collision.name="Collision";var shape:=BoxShape3D.new();shape.size=size
		collision.shape=shape;body.add_child(collision)
		if label!="TileFloor":plan.append({"rect":Rect2(Vector2(at.x-size.x*.5,at.z-size.z*.5),Vector2(size.x,size.z)),"kind":"gate" if label=="ArchiveGate" else ("wall" if label=="Wall" else "furniture")})
	return node

func _wall(a: Vector2, b: Vector2, cutaway := false) -> void:
	var size:=Vector3(absf(b.x-a.x)+.20,3.1,absf(b.y-a.y)+.20)
	var mid: Vector2=(a+b)*.5
	var wall:=_box("Wall",size,Vector3(mid.x,1.55,mid.y),"wall",true)
	if cutaway:
		# Keep the body at its original world height when lowering the mesh.
		var body: StaticBody3D=wall.get_node("Body");body.position.y=1.05
		wall.position.y=.50
		var mesh:=wall.mesh as BoxMesh;mesh.size.y=1.0
	_box("Skirting",Vector3(size.x+.02,.14,size.z+.02),Vector3(mid.x,.08,mid.y),"metal")
	_box("PaintedDado",Vector3(size.x+.018,.85,size.z+.018),Vector3(mid.x,.50,mid.y),"cloth")
	if not cutaway:_box("Cornice",Vector3(size.x+.05,.12,size.z+.05),Vector3(mid.x,3.1,mid.y),"trim")

func _label(text: String, at: Vector3, scale_m := .008, floor_text := false) -> Label3D:
	var label:=Label3D.new();label.text=text;label.font=UIFactory.FONT;label.font_size=48
	label.pixel_size=scale_m;label.position=at;label.modulate=Color("e6e4ce");label.outline_size=3;label.outline_modulate=Color("293b35")
	if floor_text:label.rotation_degrees.x=-90
	else:label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test=false;add_child(label);return label

func _prop(asset: String, label: String, at: Vector3, size: Vector3) -> Node3D:
	var scene: PackedScene=load("res://assets/environment/compact_hideout/"+asset)
	var model:=scene.instantiate() as Node3D;model.name=label;add_child(model)
	var bounds:=ItemPresentation.bounds(model)
	assert(bounds.size.x>0 and bounds.size.y>0 and bounds.size.z>0)
	model.scale=size/bounds.size
	model.position=at-(bounds.position+Vector3(bounds.size.x*.5,0,bounds.size.z*.5))*model.scale
	return model

func _station(id: String, label: String, at: Vector3, seconds: float) -> void:
	stations.append({"id":id,"label":label,"point":at,"seconds":seconds})
	var node:=Node3D.new();node.name="Station_"+id;node.position=at;add_child(node)
	var ring:=MeshInstance3D.new();var mesh:=TorusMesh.new();mesh.inner_radius=.18;mesh.outer_radius=.23;mesh.material=materials.signal
	ring.mesh=mesh;ring.position.y=.06;node.add_child(ring)
	if id!="exit":_label(label,at+Vector3.UP*1.7,.006)

func add_stair(target: String, x: float) -> void:
	var start:=extent.y*.5-6;var end:=start+4
	# Visible treads share a continuous wedge collider. A normal CharacterBody
	# can climb it; there is no invisible lift or disabled collision shortcut.
	var body:=StaticBody3D.new();body.name="StairRamp";body.collision_layer=4;body.collision_mask=0;add_child(body)
	var collider:=CollisionShape3D.new();var shape:=ConvexPolygonShape3D.new()
	var points:=PackedVector3Array()
	for side: float in [-.95,.95]:
		points.append_array([Vector3(x+side,-.2,start),Vector3(x+side,-.2,end),Vector3(x+side,0,start),Vector3(x+side,1.4,end)])
	shape.points=points;collider.shape=shape;body.add_child(collider)
	for step in 14:
		var h: float=(step+1)*.1;var z: float=start+(step+.5)*4.0/14
		_box("StairTread",Vector3(1.9,h,4.0/14+.01),Vector3(x,h*.5,z),"stone" if materials.has("stone") else "trim")
		_box("StairNosing",Vector3(1.9,.025,.035),Vector3(x,h+.014,start+step*4.0/14),"metal")
	for side: int in [-1,1]:
		var rail:=_box("StairHandrail",Vector3(.055,.055,sqrt(4*4+1.4*1.4)),Vector3(x+side*1.0,1.6,start+2),"metal")
		rail.rotation.x=-atan(1.4/4.0)
		for step in 5:
			var z: float=start+step;var y: float=step*.35
			_box("StairRailPost",Vector3(.05,.9,.05),Vector3(x+side*1.0,y+.45,z),"metal")
	plan.append({"rect":Rect2(x-.95,start,1.9,4),"kind":"stairs"})
	_station("stairs_"+target,"楼梯 / E 切换楼层",Vector3(x,1.26,end-.4),0)
	_label("楼梯平台",Vector3(x,2.9,end-.4),.006)

func _desk(at: Vector3, width := 3.0) -> void:
	var collision:=_box("Desk",Vector3(width,.93,1.35),at+Vector3.UP*.465,"wood",true)
	collision.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;collision.hide()
	_prop("polyhaven/metal_office_desk/metal_office_desk.gltf","OfficeDesk",at,Vector3(width,.94,1.35))
	_box("PaperStack",Vector3(.65,.06,.44),at+Vector3(-.65,.98,0),"paper")
	_prop("polyhaven/desk_lamp_arm_01/desk_lamp_arm_01.gltf","DeskLamp",at+Vector3(.75,.96,0),Vector3(.65,.7,.5))

func _chair(at: Vector3) -> void:
	var collision:=_box("Chair",Vector3(.65,.65,.65),at+Vector3.UP*.325,"metal",true);collision.hide();collision.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_prop("polyhaven/metal_stool_01/metal_stool_01.gltf","MetalStool",at,Vector3(.65,.67,.65))

func _shelf(at: Vector3, books := true) -> void:
	var collision:=_box("Shelf",Vector3(1.0,2.4,4.6),at+Vector3.UP*1.2,"wood",true);collision.hide();collision.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_box("ShelfCore",Vector3(.08,2.4,4.6),at+Vector3.UP*1.2,"wood")
	for z: float in [-2.25,2.25]:_box("ShelfUpright",Vector3(1.0,2.4,.10),at+Vector3(0,1.2,z),"wood")
	# Shelf recesses retain a dark back, with irregular spine widths and colors.
	for side: int in [-1,1]:
		_box("ShelfBack",Vector3(.04,2.12,4.3),at+Vector3(side*.05,1.23,0),"dark")
		for tier in 4:
			_box("ShelfBoard",Vector3(.54,.07,4.45),at+Vector3(side*.27,.23+tier*.55,0),"wood")
			for book in (14 if books else 4):
				var z: float=-1.95+book*(.29 if books else 1.0)
				var material: String=["red","cloth","paper","metal"][(book+tier)%4]
				_box("BookSpine" if books else "ArchiveBox",Vector3(.41,.32+(book%3)*.026 if books else .4,.13 if books else .72),at+Vector3(side*.28,.44+tier*.55,z),material)

func _cabinet(at: Vector3, label: String) -> void:
	_box(label,Vector3(2.3,2.15,.72),at+Vector3.UP*1.075,"metal",true)
	for x: float in [-.56,.56]:
		_box("CabinetDoor",Vector3(1.04,1.97,.06),at+Vector3(x,1.08,.4),"cloth")
		_box("CabinetHandle",Vector3(.06,.24,.07),at+Vector3(x-.31,1.2,.46),"trim")
	var lamp:=_box("PowerLamp",Vector3(.12,.12,.04),at+Vector3(.79,1.87,.45),"signal")
	lamp.set_meta("role",label)
	power_lamps.append(lamp)

func _library() -> void:
	_wall(Vector2(-16,0),Vector2(-1.6,0));_wall(Vector2(1.6,0),Vector2(16,0))
	_wall(Vector2(3,-12),Vector2(3,-7.6));_wall(Vector2(3,-4.4),Vector2(3,0))
	gate=_box("ArchiveGate",Vector3(.16,2.9,3.2),Vector3(3,1.45,-6),"metal",true)
	_box("GateWindow",Vector3(.18,1.4,2.4),Vector3(3,1.8,-6),"glass")
	_label("档案室 / 值班目录领钥匙",Vector3(3,3.4,-5.9),.006)
	_desk(Vector3(-8,0,5.4),4.8);_chair(Vector3(-8,0,3.7))
	_box("Catalogue",Vector3(.85,.13,.65),Vector3(-8,.99,5.5),"signal")
	_station("catalogue","01 / 值班目录",Vector3(-8,.03,7),0)
	for x: int in [-12,-7]:_shelf(Vector3(x,0,-6))
	_box("ArchiveRunner",Vector3(2.5,.018,8),Vector3(-9.5,.012,-6),"cloth")
	_shelf(Vector3(7,0,-3),false)
	_cabinet(Vector3(7,0,-10.9),"ArchivePower")
	_station("archive_power","02 / 档案柜电源 · 3s",Vector3(7,.03,-9),3)
	_cabinet(Vector3(12.5,0,-10.9),"ArchiveCabinet")
	_box("SealedCase",Vector3(.9,.33,.65),Vector3(12.5,.48,-9.8),"signal")
	_station("archive","03 / 封装档案 · 4s",Vector3(12.5,.03,-8.7),4)
	for x: int in [6,11]:
		_desk(Vector3(x,0,4));_chair(Vector3(x,0,6))
	_label("借阅 / READING",Vector3(9,.035,1.5),.009,true)
	_label("资料借阅与防汛档案",Vector3(-8,3.5,1),.01)

func _workshop() -> void:
	for x: int in [-3,3]:_wall(Vector2(x,-12),Vector2(x,0))
	for segment: Vector2 in [Vector2(-16,-10),Vector2(-7,-3),Vector2(3,7),Vector2(10,16)]:_wall(Vector2(segment.x,0),Vector2(segment.y,0))
	_desk(Vector3(-7,0,4.7),4)
	_box("CircuitDiagram",Vector3(1.5,.08,.9),Vector3(-7,1,4.7),"signal")
	_station("diagram","支路图 / A 应急 · B 试验",Vector3(-7,.03,6.1),0)
	_desk(Vector3(-10,0,-8.7),6)
	_prop("polyhaven/metal_toolbox/metal_toolbox.gltf","Toolbox",Vector3(-12,.95,-8.7),Vector3(.9,.40,.48))
	_box("FuseTray",Vector3(1.8,.18,.8),Vector3(-10,1,-8.7),"metal")
	for x: float in [-10.5,-10,-9.5]:_box("Fuse",Vector3(.13,.12,.5),Vector3(x,1.16,-8.7),"paper")
	_station("relay","04 / 更换熔芯 · 6s",Vector3(-10,.03,-6.7),6)
	_shelf(Vector3(-14,0,-5),false)
	_cabinet(Vector3(8,0,-10.8),"BranchIsolator")
	_station("isolate","05 / 隔离 B · 保留 A",Vector3(8,.03,-8.7),3)
	_cabinet(Vector3(13,0,-10.8),"MasterBreaker")
	_box("MasterWarning",Vector3(2.0,.20,.08),Vector3(13,1.8,-10.32),"red")
	_station("blackout","总闸 / 同时控制 A 与 B",Vector3(13,.03,-8.7),3)
	_label("A 应急 / 常供    B 试验 / 隔离",Vector3(10.3,3.4,-9.5),.007)
	state_label=_label("",Vector3(10.5,2.8,-10.7),.007)
	_box("InsulatingMat",Vector3(8.7,.018,2.1),Vector3(10.3,.015,-8.5),"dark")
	for x in 18:_box("CautionMark",Vector3(.20,.02,.17),Vector3(6.1+x*.49,.03,-7.4),"signal")
	for x: float in [-1.5,1.5]:_box("CableRun",Vector3(.12,.05,10),Vector3(x,.04,-5),"metal")
	_label("检修 / WORKSHOP",Vector3(-9,.035,-2.2),.009,true)
	_label("配电 / SWITCHGEAR",Vector3(9,.035,-2.2),.009,true)
	for x: int in [7,12]:_chair(Vector3(x,0,6))

func _relief() -> void:
	_wall(Vector2(-16,-2),Vector2(-1.7,-2));_wall(Vector2(1.7,-2),Vector2(16,-2))
	for x: int in [-12,-7]:
		for z: int in [3,8]:
			var frame:=_box("CotFrame",Vector3(2.1,.6,3.2),Vector3(x,.3,z),"metal",true);frame.hide();frame.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_prop("polyhaven/vintage_day_bed/vintage_day_bed.gltf","ReliefCot",Vector3(x,0,z),Vector3(2.1,.95,3.2))
	_desk(Vector3(9,0,-7),6)
	_box("ReceiptTerminal",Vector3(1.2,.1,.8),Vector3(9,.99,-7),"dark")
	_box("ReceiptScreen",Vector3(1.0,.65,.10),Vector3(9,1.35,-7.25),"glass")
	_station("deliver","06 / 补给站签收 · 3s",Vector3(9,.03,-5),3)
	for x: int in [-12,-7]:_shelf(Vector3(x,0,-7),false)
	for x: int in [6,10,14]:
		for z: int in [3,6]:
			var crate:=_box("ReliefCrate",Vector3(1.9,.85,1.3),Vector3(x,.425,z),"wood",true);crate.hide();crate.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_prop("polyhaven/old_military_crate/old_military_crate.gltf","ReliefCrateArt",Vector3(x,0,z),Vector3(1.9,.85,1.3))
	_cabinet(Vector3(13.7,0,-10.8),"EmergencyColdStore")
	_label("应急冷藏 / 支路 A",Vector3(13,2.9,-10),.006)
	_label("休息 / REST",Vector3(-9,.035,.5),.01,true)
	_label("物资 / SUPPLIES",Vector3(10,.035,.5),.01,true)
	_label("签收后请回东门报平安",Vector3(8,3.4,-8),.008)

func refresh(journal: CampusFieldworkJournal) -> void:
	if gate:
		gate.visible=not journal.flags.catalogue
		find_child("GateWindow",true,false).visible=gate.visible
		gate.get_node("Body/Collision").set_deferred("disabled",journal.flags.catalogue)
	for lamp: MeshInstance3D in power_lamps:
		var material: StandardMaterial3D=materials.signal.duplicate()
		var online: bool=journal.flags.archive_power if kind=="library" else (journal.flags.relay and not journal.blackout)
		if kind=="activity":online=journal.flags.shelter_power and not journal.blackout
		var isolated: bool=lamp.get_meta("role")=="BranchIsolator" and journal.flags.shelter_power
		if isolated:online=false
		material.albedo_color=Color("b9d77b") if online else (Color("34423d") if isolated else Color("a45e4d"))
		material.emission_enabled=online;material.emission=material.albedo_color;material.emission_energy_multiplier=.25
		lamp.material_override=material
	for light: OmniLight3D in room_lights:light.light_energy=.17 if journal.blackout else .68
	if state_label:state_label.text="A 失电 / B 失电 · 需恢复总闸" if journal.blackout else ("A 应急在线 / B 已隔离" if journal.flags.shelter_power else "A 总闸合闸 / B 尚未隔离")
	var case:=find_child("SealedCase",true,false)
	if case:case.visible=not journal.flags.archive
