extends Node3D
## Authored, visual-only campus use and wear. Existing physics, navigation and loot own gameplay.
var layout: RefCounted
var paint: ShaderMaterial
var finishes := {}

func build(campus: RefCounted) -> void:
	layout=campus
	paint=ShaderMaterial.new();paint.shader=preload("res://resources/materials/streets/campus_marking.gdshader")
	_street_surfaces()
	_entrances()
	_garden_edges()
	_green_fringe()
	_service_yard()
	_wall_utilities()
	_narrative_spaces()
	_beyond_boundary()
	layout._batch(self)

func _box(size: Vector3, at: Vector3, color: String, parent: Node3D=null) -> MeshInstance3D:
	if not finishes.has(color): finishes[color]=layout.g._material(Color(color),false)
	return layout._detail(size,at,finishes[color],self if parent==null else parent)

func _line(a: Vector3, b: Vector3, width: float, color: String, parent: Node3D=null) -> void:
	var delta:=b-a
	var mesh:=_box(Vector3(width,width,delta.length()),(a+b)*.5,color,parent)
	mesh.basis=Basis.looking_at(delta,Vector3.RIGHT if absf(delta.normalized().y)>.98 else Vector3.UP)

func _patch(points: PackedVector2Array, y: float, color: String) -> void:
	layout._polygon(points,y,layout._material(color),self)

func _street_surfaces() -> void:
	# Road infrastructure follows the existing curves. Nothing is an interaction or route marker.
	for road in layout.g.campus_roads:
		var path: PackedVector2Array=road[0]
		for i in range(3,path.size()-2,5):
			var tangent: Vector2=(path[i+1]-path[i-1]).normalized()
			var edge:=path[i]+Vector2(-tangent.y,tangent.x)*(float(road[1])*.5-.18)
			var grate:=_box(Vector3(.30,.025,.65),Vector3(edge.x,.080,edge.y),"454b46")
			grate.rotation.y=atan2(tangent.x,tangent.y)
			for n in 6:
				var at:=edge+tangent*(n*.095-.24)
				var slot:=_box(Vector3(.23,.012,.026),Vector3(at.x,.098,at.y),"232c29")
				slot.rotation.y=grate.rotation.y
			# Kerb joins and settled dust give the shoulder a scale visible at the game camera.
			var seam:=edge+Vector2(-tangent.y,tangent.x)*1.0
			var joint:=_box(Vector3(.65,.014,.035),Vector3(seam.x,.103,seam.y),"6e7164")
			joint.rotation.y=grate.rotation.y
	for at in [Vector2(41,4),Vector2(-29,4),Vector2(-10,18),Vector2(3,47),Vector2(-50,-28),Vector2(35,-34)]:
		var cover:=MeshInstance3D.new();var mesh:=CylinderMesh.new()
		mesh.top_radius=.38;mesh.bottom_radius=.38;mesh.height=.025;mesh.radial_segments=24
		cover.mesh=mesh;cover.material_override=layout._material("62685f",.3);cover.position=Vector3(at.x,.085,at.y);add_child(cover)
		for offset in [-.18,0,.18]: _box(Vector3(.48,.012,.025),Vector3(at.x,.103,at.y+offset),"404a43")
	for entry in [[Vector2(44,4),5.8],[Vector2(24,4),5.8],[Vector2(-24,4),5.8],[Vector2(-31,47),4.8],[Vector2(15,47),4.8]]:
		var at: Vector2=entry[0]
		for n in 7:
			# Individual worn stripes, rather than a perfectly solid painted rectangle.
			var stripe:=_box(Vector3(.31,.014,float(entry[1])-.12*(n%3)),Vector3(at.x-1.2+n*.4,.086,at.y),"b5b6a5")
			stripe.rotation.y=.012*sin(n*2.1)
			stripe.material_override=paint
			stripe.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for entry in [[Vector2(-40,4),Vector2(-28,4)],[Vector2(6,4),Vector2(18,4)],[Vector2(-23,47),Vector2(-9,47)]]:
		var a: Vector2=entry[0];var b: Vector2=entry[1]
		for n in 4:
			var start:=a.lerp(b,float(n)/4.0)
			_line(Vector3(start.x,.083,start.y),Vector3(start.x+1.4,.083,start.y),.065,"b2ab84")
	# Local repairs and branching cracks; they follow load and drainage, not a noise grid.
	var repair: Material=layout.g._pbr_material("asphalt_02",1.7,Color("717b73"))
	for at in [Vector2(46,5),Vector2(29,4),Vector2(-36,46),Vector2(-50,-22),Vector2(-12,-8),Vector2(-34,-43)]:
		layout._polygon(PackedVector2Array([at+Vector2(-.9,-.7),at+Vector2(.85,-.6),at+Vector2(1.1,.35),at+Vector2(.25,.85),at+Vector2(-1,.55)]),.080,repair,self)
		for n in 4:
			var a: Vector2=at+Vector2(-1+n*.55,sin(n*1.9)*.45)
			var b: Vector2=at+Vector2(-.5+n*.55,sin((n+1)*1.9)*.45)
			_line(Vector3(a.x,.095,a.y),Vector3(b.x,.095,b.y),.025,"353f38")
			if n==2: _line(Vector3(b.x,.095,b.y),Vector3(b.x+.2,.095,b.y+.6),.023,"353f38")

func _entrances() -> void:
	# Keep the open door axes and the 3.2m entry gaps empty.
	for at in [Vector3(-25,0,-11),Vector3(30,0,26),Vector3(-36,0,30),Vector3(20,0,44)]: _bins(at)
	_notice(Vector3(-22.8,0,-12.3),"校医室 / 值班公告",0)
	_notice(Vector3(-25,0,29.7),"七斋 / 公共告示",0)
	_notice(Vector3(31,0,25),"阅览室 / 开放时间",0)
	for n in 4: _bicycle(Vector3(-26+n*.82,0,-10.8),-.12+n*.09,["5c7468","877150","536574","69735c"][n])
	for n in 5: _bicycle(Vector3(-39.2,0,14.5+n*.83),PI/2+.05*sin(n),["536574","877150","5c7468"][n%3])
	for n in 3: _bicycle(Vector3(17+n*.9,0,25.5),.05*n,"656e58")
	# Bike parking markings and rack arches make these read as designed parking areas.
	for entry in [[Vector3(-24.8,0,-10.8),0.0,4],[Vector3(-39.2,0,16.2),PI/2,5],[Vector3(17.9,0,25.5),0.0,3]]:
		var rack:=Node3D.new();rack.position=entry[0];rack.rotation.y=entry[1];add_child(rack)
		for n in int(entry[2])+1:
			var x: float=(n-float(entry[2])*.5)*.83
			for z in [-.42,.42]: _box(Vector3(.045,.68,.045),Vector3(x,.39,z),"788378",rack)
			_line(Vector3(x,.74,-.42),Vector3(x,.74,.42),.05,"788378",rack)
		layout._batch(rack)
	for at in [Vector3(-22,0,-12.2),Vector3(-14,0,-12.2),Vector3(20.7,0,25.4),Vector3(27.3,0,25.4)]:
		_box(Vector3(.14,.65,.14),at+Vector3.UP*.34,"778175")
		_box(Vector3(.16,.075,.16),at+Vector3.UP*.62,"c0b391")
	for entry in [[Vector2(-18,-12),Vector2(-18,-9.5)],[Vector2(24,24.5),Vector2(24,28)],[Vector2(-31,29),Vector2(-31,30)]]:
		var a: Vector2=entry[0];var b: Vector2=entry[1]
		# Scuffed approach paving only; no new walkable path or movement rule.
		for n in 9:
			var p:=a.lerp(b,float(n)/9.0)+Vector2(sin(n*2.2)*.38,0)
			_box(Vector3(.18,.008,.34),Vector3(p.x,.067,p.y),"9d9d87").rotation.y=.12*sin(n)

func _bins(at: Vector3) -> void:
	for n in 2:
		var center:=at+Vector3(n*.55,0,0)
		_box(Vector3(.44,.68,.45),center+Vector3.UP*.36,"546c61" if n==0 else "647688")
		_box(Vector3(.49,.07,.50),center+Vector3.UP*.74,"818779")
		_box(Vector3(.28,.16,.025),center+Vector3(0,.51,.235),"c4c2ad")
		_box(Vector3(.23,.07,.028),center+Vector3(0,.64,.25),"293b33")
	for n in 6:
		var p:=at+Vector3(sin(n*2.4)*.7,.058,cos(n*2.4)*.55)
		_box(Vector3(.11,.006,.19),p,"afa68a").rotation.y=n*1.4

func _notice(at: Vector3, text: String, angle: float) -> void:
	var board:=Node3D.new();board.position=at;board.rotation.y=angle;add_child(board)
	for x in [-.72,.72]: _box(Vector3(.075,1.65,.075),Vector3(x,.83,0),"667566",board)
	_box(Vector3(1.65,.82,.08),Vector3(0,1.27,0),"536959",board)
	_box(Vector3(1.77,.07,.32),Vector3(0,1.77,0),"8c927d",board)
	for n in 6:
		var x: float=-.59+(n%3)*.43;var y: float=1.48-(n/3)*.37
		_box(Vector3(.32,.27,.014),Vector3(x,y,.049),["bab896","adbaac","bab09b"][n%3],board)
		for row in 3: _box(Vector3(.22,.010,.017),Vector3(x,y+.07-row*.044,.061),"728176",board)
	layout._sign(board,text,Vector3(0,1.70,.11),.0026)
	layout._batch(board)

func _bicycle(at: Vector3, angle: float, color: String) -> void:
	var bike:=Node3D.new();bike.position=at;bike.rotation.y=angle;add_child(bike)
	for z in [-.58,.58]:
		var tire:=MeshInstance3D.new();var mesh:=TorusMesh.new()
		mesh.inner_radius=.28;mesh.outer_radius=.32;mesh.rings=24;mesh.ring_segments=6
		tire.mesh=mesh;tire.material_override=layout._material("303b35");tire.position=Vector3(0,.37,z);tire.rotation.z=PI/2;bike.add_child(tire)
		for n in 6:
			var direction:=Vector2.from_angle(n*PI/6)*.28
			_line(Vector3(0,.37+direction.x,z+direction.y),Vector3(0,.37-direction.x,z-direction.y),.011,"9a9c8b",bike)
	var rear:=Vector3(0,.37,-.58);var front:=Vector3(0,.37,.58);var crank:=Vector3(0,.33,-.05)
	var seat:=Vector3(0,.85,-.27);var neck:=Vector3(0,.87,.40)
	for pair in [[rear,seat],[rear,crank],[seat,crank],[seat,neck],[neck,crank],[neck,front]]: _line(pair[0],pair[1],.055,color,bike)
	_box(Vector3(.19,.065,.26),seat+Vector3.UP*.1,"35443a",bike)
	_line(neck,neck+Vector3(0,.20,-.10),.035,"9a9c8b",bike)
	_line(neck+Vector3(-.28,.20,-.1),neck+Vector3(.28,.20,-.1),.035,"9a9c8b",bike)
	_box(Vector3(.22,.035,.38),Vector3(0,.72,-.65),"788378",bike)
	_line(Vector3(0,.36,-.08),Vector3(.25,.08,-.25),.026,"677267",bike)
	layout._batch(bike)

func _garden_edges() -> void:
	# Larger planted islands interrupt lawn sheets. Their low forms leave actors and targets readable.
	for entry in [[Vector2(-41,-2.7),Vector2(6,1.5)],[Vector2(-24,-3),Vector2(5,1.7)],[Vector2(26,-3),Vector2(7,1.5)],
		[Vector2(48,-7),Vector2(9,3.2)],[Vector2(45,-24),Vector2(6,4)],[Vector2(49,34),Vector2(6,2.5)],[Vector2(-2,18),Vector2(3,8)],[Vector2(-37,40.5),Vector2(4.2,2.8)],[Vector2(-25.4,40.5),Vector2(5,2.2)],[Vector2(-19,38),Vector2(5,2.6)],[Vector2(29,38),Vector2(1.4,6)]]:
		var center: Vector2=entry[0];var size: Vector2=entry[1]
		var polygon:=PackedVector2Array()
		for n in 14:
			var angle: float=n*TAU/14
			polygon.append(center+Vector2(cos(angle),sin(angle))*size*.5*(1.0+.05*sin(n*2.3)))
		var soil:=ShaderMaterial.new();soil.shader=preload("res://resources/materials/streets/campus_soil.gdshader")
		soil.set_shader_parameter("ground_detail",load("res://assets/environment/campus/forest_ground_04_diff_1k.jpg"))
		soil.set_shader_parameter("center",center);soil.set_shader_parameter("radius",size*.5)
		layout._polygon(polygon,.043,soil,self).cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for i in 7:
			var p:=center+Vector2(sin(i*2.4)*size.x*.34,cos(i*2.4)*size.y*.32)
			layout._bush(Vector3(p.x,.08,p.y),.40+.17*(i%3))
			for n in 4:
				var offset:=Vector2(sin(n*2.4)*.3,cos(n*2.4)*.3)
				var stem:=Vector3(p.x+offset.x,.34,p.y+offset.y)
				_line(stem-Vector3.UP*.18,stem+Vector3.UP*.12,.02,"76825b")
				_box(Vector3(.10,.05,.10),stem+Vector3.UP*.14,"bdb98b" if i%3 else "aca685")
	for at in [Vector3(45.5,0,-5.2),Vector3(51.3,0,-5.2),Vector3(-3.5,0,18)]:
		# Low timber seats beside planting, never across a door or road.
		for x in [-.75,.75]: _box(Vector3(.08,.44,.40),at+Vector3(x,.26,0),"5b695b")
		for z in [-.16,.05,.25]: _box(Vector3(1.95,.065,.15),at+Vector3(0,.50,z),"a08b64")
	# Fallen leaves collect under the current trees and along sheltered pavement edges.
	for tree in layout.g.get_children():
		if tree.get_script()!=preload("res://scripts/world/streets/courtyard_tree.gd"): continue
		for n in 16:
			var angle: float=n*2.399963
			var radius: float=.6+sqrt(float(n)/16.0)*2.4
			var p:=Vector2(tree.position.x,tree.position.z)+Vector2.from_angle(angle)*radius
			if layout.water_blocks(p): continue
			var shape:=PackedVector2Array([p+Vector2(-.08,0),p+Vector2(-.03,-.045),p+Vector2(.09,.015),p+Vector2(-.025,.05)])
			_patch(shape,.113,["949367","8a895c","a99c70"][n%3])

func _service_yard() -> void:
	# Loose pallets, packing scraps and maintenance supplies belong beside the existing crates.
	for entry in [[Vector3(-32,0,-22),.08],[Vector3(-35,0,-21.5),-.18],[Vector3(43,0,31.6),.04]]:
		var pallet:=Node3D.new();pallet.position=entry[0];pallet.rotation.y=entry[1];add_child(pallet)
		for z in [-.46,.46]: _box(Vector3(1.6,.10,.14),Vector3(0,.14,z),"847652",pallet)
		for n in 6: _box(Vector3(.18,.055,1.1),Vector3(-.65+n*.26,.22,0),"99825d" if n%2 else "806e52",pallet)
		layout._batch(pallet)
	for at in [Vector3(-34.5,0,-21.3),Vector3(-31,0,-22.3)]:
		_box(Vector3(.74,.45,.65),at+Vector3.UP*.30,"8c7c5a")
		_box(Vector3(.09,.45,.66),at+Vector3.UP*.30,"b2a078")
		_box(Vector3(.22,.16,.018),at+Vector3(-.13,.34,.334),"beb797")
		for y in [.31,.36]: _box(Vector3(.17,.013,.02),at+Vector3(-.13,y,.346),"5f6959")
		for side in [-1,1]:
			var flap:=_box(Vector3(.40,.025,.64),at+Vector3(side*.48,.57,0),"a79570")
			flap.rotation.z=side*.35
	for at in [Vector3(-33.4,0,-21.5),Vector3(-31.6,0,-23.0)]:
		SliceUI.prop(self,"res://assets/environment/compact_hideout/polyhaven/old_military_crate/old_military_crate.gltf",at,.55).rotation.y=.25
	_bins(Vector3(-45.3,0,-22))
	for n in 5:
		var p:=Vector3(-34+sin(n*2.4)*3,.063,-22+cos(n*2.4)*.7)
		_box(Vector3(.25,.008,.34),p,"b2aa8a").rotation.y=n*.7
	for x in [-35.6,-34.1]:
		for n in 8: _box(Vector3(.07,.009,.32),Vector3(x+sin(n)*.025,.062,-19-n*.38),"797b68")

func _beyond_boundary() -> void:
	# The camera sees past exit gates. Public streets and rooflines replace the endless lawn backdrop.
	var pavement: Material=layout._surface("pavement_05",3.4,Color("b9bda9"))
	var asphalt: Material=layout.g._pbr_material("asphalt_02",3.2,Color("858a83"))
	for entry in [[Vector3(14,.015,176),Vector3(67,.033,0)],[Vector3(160,.015,12),Vector3(0,.033,66)],[Vector3(160,.015,9),Vector3(0,.033,-65)],
		[Vector3(8,.015,144),Vector3(-64,.033,0)]]:
		layout._detail(entry[0]+Vector3(3,0,3),entry[1]-Vector3.UP*.005,pavement,self)
		layout._detail(entry[0],entry[1]+Vector3.UP*.01,asphalt,self)
	for n in 30:
		_box(Vector3(.10,.008,2.1),Vector3(67,.055,-72+n*5),"b5ac7b")
	for n in 25:
		_box(Vector3(2.1,.008,.10),Vector3(-62+n*5,.055,66),"b5ac7b")
	for at in [Vector3(-75,0,-33),Vector3(-76,0,6),Vector3(-76,0,38),Vector3(-40,0,-80),Vector3(2,0,-81),Vector3(43,0,-81),Vector3(-34,0,83),Vector3(15,0,83),Vector3(48,0,83),Vector3(86,0,-28),Vector3(87,0,16)]:
		var width: float=15+int(abs(at.x))%9
		var height: float=4.6+int(abs(at.z))%3
		var block:=Node3D.new();block.position=at;block.rotation.y=.07*sin(at.x);add_child(block)
		_box(Vector3(width,height,10),Vector3(0,height*.5,0),"aa977e",block).material_override=layout.g.brick
		layout._window_row(block,width,height,10,2)
		var roof:=Node3D.new();roof.position.y=height;block.add_child(roof)
		layout._pitched_roof(roof,width+.6,10.7,1.2,"5b685f")
		layout._batch(block);layout._batch(roof)

func _green_fringe() -> void:
	# Sheltered planting against walls breaks up empty lawn while the middle stays open.
	for at in [Vector3(55,0,-30),Vector3(54,0,-23),Vector3(54.5,0,-16),Vector3(54.5,0,-7),Vector3(55,0,15),Vector3(55,0,23),
		Vector3(54,0,35),Vector3(51,0,43),Vector3(39,0,-38),Vector3(46,0,-40),Vector3(-55,0,-36),Vector3(-55,0,-23),
		Vector3(-55,0,10),Vector3(-55,0,33),Vector3(-55,0,42),Vector3(-20,0,51),Vector3(25,0,51),
		Vector3(60,0,-35),Vector3(60,0,-19),Vector3(60,0,-3),Vector3(60,0,18),Vector3(60,0,38)]:
		for n in 3:
			var p: Vector3=at+Vector3(sin(n*2.4)*1.1,0,cos(n*2.4)*1.3)
			layout._bush(p,.62+n*.26)
			var leaves: MultiMeshInstance3D=layout.art.get_children()[-1]
			leaves.material_override.albedo_color=Color("a1af8d" if n%2 else "819976")

func _wall_utilities() -> void:
	# Mounted on existing solid walls: they inherit the owner's cutaway and do not imply an open door.
	var body: Node3D=layout.g.find_child("MaintenanceShed",true,false)
	var panels:=Node3D.new();panels.name="ShedWallDetails";body.add_child(panels)
	_box(Vector3(1.45,2.0,.065),Vector3(.45,-.4,2.94),"5c7164",panels)
	for x in [-.29,1.19]: _box(Vector3(.065,2.05,.09),Vector3(x,-.4,2.99),"899487",panels)
	for y in [-1.38,.58]: _box(Vector3(1.50,.06,.09),Vector3(.45,y,2.99),"899487",panels)
	_box(Vector3(.08,.16,.06),Vector3(.89,-.4,3.03),"4c584d",panels)
	_box(Vector3(.88,.62,.10),Vector3(-1.52,.25,2.97),"535f55",panels)
	for n in 7: _box(Vector3(.78,.035,.10),Vector3(-1.52,.01+n*.08,3.04),"889381",panels)
	_line(Vector3(2.6,-1.4,2.7),Vector3(2.6,1.65,2.7),.075,"708175",panels)
	for y in [-.7,.5,1.5]: _box(Vector3(.12,.04,.16),Vector3(2.6,y,2.7),"939b89",panels)
	layout._batch(panels)

func _narrative_spaces() -> void:
	# Scene use comes from the existing rooms and evidence, never from new quests.
	_mail_room()
	_shelter_pilot()
	_repair_workplace()
	_gate_notices()

func _wall_sign(parent: Node3D, text: String, at: Vector3, size: Vector2, color: String, pixels: float=.007) -> Node3D:
	var sign:=Node3D.new();sign.position=at;parent.add_child(sign)
	_box(Vector3(size.x+.12,size.y+.12,.045),Vector3.ZERO,"697263",sign)
	_box(Vector3(size.x,size.y,.022),Vector3(0,0,.034),color,sign)
	var label:=SliceUI.sign(sign,text,Vector3(0,0,.053),Color("e3ddc5"))
	label.font_size=38;label.pixel_size=pixels;label.outline_size=0
	label.billboard=BaseMaterial3D.BILLBOARD_DISABLED
	layout._batch(sign)
	return sign

func _mail_room() -> void:
	var porch: Node3D=layout.g.find_child("DormitoryEntrance",true,false)
	for child in porch.get_children():
		if child is Label3D: child.hide()
	_wall_sign(porch,"七斋 · 宿舍",Vector3(0,2.61,8.68),Vector2(4.8,.98),"706f5c",.014)
	_wall_sign(porch,"值班收发",Vector3(-4.7,2.45,7.32),Vector2(3.5,.72),"4a6964",.014)
	# Receipt stays on the existing counter. The slots rise from its back edge;
	# the central walking aisle and the real paper's click/interaction area stay open.
	var desk:=Node3D.new();desk.name="MailCounterDetails";desk.position=layout.g.ROOMS[2];add_child(desk)
	_box(Vector3(2.45,.90,.10),Vector3(-2.8,1.42,-3.35),"526d66",desk)
	for x in [-4.04,-3.2,-2.37,-1.54]: _box(Vector3(.055,.94,.55),Vector3(x,1.43,-3.12),"526d66",desk)
	for y in [.96,1.41,1.88]: _box(Vector3(2.55,.055,.54),Vector3(-2.8,y,-3.12),"74857a",desk)
	for slot in 3:
		for level in 2:
			var p:=Vector3(-3.61+slot*.83,1.04+level*.45,-3.03)
			for n in 3:
				_box(Vector3(.48-n*.04,.025,.30),p+Vector3(.03*n,.025*n,.02*n),"c7bca0",desk)
			_box(Vector3(.32,.08,.014),p+Vector3(0,.21,.24),"d1c6ac",desk)
	# A clipboard frames the existing fixed paper instead of adding another receipt.
	var receipt_local: Vector3=NarrativeSlice.RECEIPT_POSITION-layout.g.ROOMS[2]
	_box(Vector3(.55,.014,.42),receipt_local-Vector3.UP*.018,"526d66",desk)
	_box(Vector3(.16,.016,.045),receipt_local+Vector3(0,.008,-.18),"9b9e8a",desk)
	_wall_sign(desk,"收发登记",Vector3(-3,2.25,-3.42),Vector2(2.45,.54),"4a6964",.008).rotation.x=-.40
	# Two sorted parcels on the existing desk, unlike random box piles at every door.
	for entry in [[Vector3(-5.5,.84,.30),Vector3(.52,.26,.43)],[Vector3(-5,.84,-.15),Vector3(.43,.21,.38)]]:
		var p: Vector3=entry[0];var size: Vector3=entry[1]
		_box(size,p+Vector3.UP*size.y*.5,"9d8760",desk)
		_box(Vector3(.06,size.y+.004,size.z+.008),p+Vector3.UP*size.y*.5,"c3b391",desk)
		_box(Vector3(.22,.011,.17),p+Vector3.UP*(size.y+.008),"d1c6ac",desk)
	# Folded ordinary household fabric remains decoration, with no item instances.
	for n in 3:
		var p:=Vector3(6.05,1.4+n*.07,5.7)
		_box(Vector3(.55,.065,.32),p,"b5ad91" if n%2 else "9eac9b",desk)
		_line(p+Vector3(-.26,-.018,.17),p+Vector3(.26,-.018,.17),.018,"d2c9af",desk)
	layout._batch(desk)
	# Window repair is attached to the existing wing, so its cutaway owns it.
	var wing: Node3D=layout.g.find_child("DormitoryWestWing",true,false)
	var repaired:=Node3D.new();repaired.name="MaintainedWindow";wing.add_child(repaired)
	for n in 3:
		var strip:=_box(Vector3(1.8,.16,.05),Vector3(0,-1.25+n*.43,8.58),"8b795b",repaired)
		strip.rotation.z=.04*(n-1)
	_box(Vector3(.06,1.23,.07),Vector3(.54,-.82,8.62),"b6a782",repaired)
	layout._batch(repaired)

func _repair_workplace() -> void:
	var entrance: Node3D=layout.g.find_child("WorkshopEntrance",true,false)
	for child in entrance.get_children():
		if child is Label3D: child.hide()
	_wall_sign(entrance,"后勤维修",Vector3(-4.8,2.40,8.06),Vector2(4.2,.72),"525d52",.017)
	# Upper-wall tool shapes occupy the established workbench bay, not free ground.
	var details:=Node3D.new();details.name="WorkshopToolBoard";details.position=layout.g.ROOMS[3];add_child(details)
	_box(Vector3(3.8,1.25,.075),Vector3(-4.6,2.02,-6.65),"65756b",details)
	for x in [-6.4,-2.8]: _box(Vector3(.08,1.32,.1),Vector3(x,2.02,-6.58),"9a9c86",details)
	for entry in [[-6.0,1.8],[-5.5,2.0],[-4.9,1.85],[-4.1,1.9],[-3.3,2.0]]:
		var x: float=entry[0];var y: float=entry[1]
		_line(Vector3(x,y,-6.54),Vector3(x+.06,y+.35,-6.54),.08,"b6b8a2",details)
		_box(Vector3(.23,.11,.08),Vector3(x+.06,y+.36,-6.54),"737c70",details)
		_box(Vector3(.11,.19,.09),Vector3(x,y-.1,-6.53),"908367",details)
	# A repaired supply conduit connects existing wall equipment. Yellow is local
	# equipment safety paint, not a faction colour or a new blocking barricade.
	for z in [-5.8,-4.3,-2.8,-1.3,.2]:
		_line(Vector3(-7.58,.42,z),Vector3(-7.58,.42,z+1.43),.065,"5c685a",details)
		_box(Vector3(.12,.13,.10),Vector3(-7.58,.42,z),"9b9d87",details)
	_box(Vector3(.08,.8,1.0),Vector3(-7.58,1.1,.3),"6c7d70",details)
	for n in 4: _box(Vector3(.09,.08,.12),Vector3(-7.62,.82+n*.18,.81),"b6a471" if n%2 else "3e4b43",details)
	_wall_sign(details,"工具归位",Vector3(-4.6,2.85,-6.62),Vector2(2.2,.45),"52634f",.006)
	layout._batch(details)
	var shed: Node3D=layout.g.find_child("MaintenanceShed",true,false)
	_wall_sign(shed,"公用设备 / 后勤维护",Vector3(.45,.86,3.02),Vector2(2.7,.40),"626d59",.0047)
	var apron:=Node3D.new();apron.name="ServiceApronWear";add_child(apron)
	# Scuff direction follows the current loading area, leaving the road untouched.
	for n in 7:
		var z: float=-20+n*.66
		_box(Vector3(.065,.008,.38),Vector3(-35.3,.065,z),"686c5b",apron)
		_box(Vector3(.065,.008,.38),Vector3(-34.1,.065,z+.08),"686c5b",apron)
	layout._batch(apron)

func _gate_notices() -> void:
	# These generic notices do not declare a locked/open state. Actual assigned
	# conditions are still read from each existing ExitPlaque at runtime.
	for at in layout.g.EXITS:
		var stand:=Node3D.new();stand.name="GateNotice";stand.position=at+Vector3(-3.2,0,-3.6);add_child(stand)
		for x in [-.62,.62]: _box(Vector3(.08,1.9,.08),Vector3(x,.95,0),"737b6a",stand)
		_wall_sign(stand,"通行告示",Vector3(0,1.52,.06),Vector2(2.55,.63),"6f725b",.012).rotation.x=-.40
		for n in 6: _box(Vector3(.37,.10,.025),Vector3(-1.08+n*.43,1.13,.10),"b4a366" if n%2 else "404c42",stand)
		_box(Vector3(1.6,.61,.06),Vector3(0,.82,.025),"485e52",stand)
		layout._batch(stand)

func _shelter_pilot() -> void:
	# ENV-CAMPUS-01, P01/P02 only. Fixed historical dressing, not quest facts.
	# Notices revise a location's use; no named culprit or explanation of MED-TK-071.
	var porch: Node3D=layout.g.find_child("DormitoryEntrance",true,false)
	_pilot_paper(porch,"临时安置\n登记 · D-14",Vector3(4.5,2.02,7.32),Vector2(2.8,1.45),.011)
	var lobby:=Node3D.new();lobby.name="ShelterRegistration";lobby.position=layout.g.ROOMS[2];add_child(lobby)
	# The existing desk and bed bays own the footprints; central corridor stays empty.
	_pilot_paper(lobby,"临时安置登记",Vector3(-5.4,1.28,.36),Vector2(2.4,.65),.009).rotation.x=-.75
	_box(Vector3(.62,.018,.42),Vector3(-5.4,.95,.12),"b7b298",lobby)
	for n in 5:
		_box(Vector3(.42,.012,.26),Vector3(-5.45+n*.01,.974+n*.013,.11),"ded5b8",lobby)
		_box(Vector3(.28,.004,.012),Vector3(-5.45+n*.01,.982+n*.013,.15),"8a957e",lobby)
	# Older allocation notice survives beside the later courtyard revision.
	_pilot_paper(lobby,"D-14  顺序领取",Vector3(-4.0,2.05,-6.64),Vector2(2.35,.63),.009)
	for z in [-3.8,1.0]:
		# Different folded blankets and pillows mark occupied, organised temporary beds.
		for y in [.68,2.08]:
			_box(Vector3(.70,.09,.76),Vector3(5.4,y,z+.49),"8f9d86" if z<0 else "b3a38b",lobby)
			_box(Vector3(.61,.11,.29),Vector3(5.4,y+.02,z-.66),"d2c8ac",lobby)
		# Personal bags rest on the existing bunk's foot, rather than creating new obstacles.
		var bag:=Node3D.new();bag.position=Vector3(5.4,.76,z+.48);lobby.add_child(bag)
		_box(Vector3(.42,.28,.29),Vector3(0,.14,0),"6f806e",bag)
		for x in [-.13,.13]: _box(Vector3(.035,.29,.30),Vector3(x,.14,0),"b5aa8c",bag)
		_line(Vector3(-.10,.29,0),Vector3(-.10,.36,0),.026,"515f50",bag)
		_line(Vector3(-.10,.36,0),Vector3(.10,.36,0),.026,"515f50",bag)
		_line(Vector3(.10,.36,0),Vector3(.10,.29,0),.026,"515f50",bag)
	layout._batch(lobby)
	# Distribution occupies an existing ground-floor window of the solid west wing.
	# Attach to its cutaway owner; an intact sill/glazing never implies a new door.
	var wing: Node3D=layout.g.find_child("DormitoryWestWing",true,false)
	var window:=Node3D.new();window.name="ShelterDistributionWindow";window.position=Vector3(-1,-2.65,8.5);wing.add_child(window)
	_wall_sign(window,"七斋补给点",Vector3(0,1.11,.13),Vector2(2.7,.51),"586f63",.010)
	_box(Vector3(1.24,1.24,.018),Vector3(0,0,.08),"334c44",window)
	# Bracing behind a translucent pane supports closure, not an accusation of violence.
	for side in [-1,1]:
		var brace:=_box(Vector3(1.35,.12,.024),Vector3(0,side*.20,.10),"9b8765",window)
		brace.rotation.z=side*.38
	var glass:=StandardMaterial3D.new();glass.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color=Color(.42,.58,.51,.25);glass.roughness=.32
	layout._detail(Vector3(1.24,1.24,.01),Vector3(0,0,.123),glass,window)
	for x in [-.70,.70]: _box(Vector3(.095,1.47,.13),Vector3(x,0,.13),"b8b29a",window)
	_box(Vector3(1.52,.10,.13),Vector3(0,.70,.13),"b8b29a",window)
	_pilot_paper(window,"D-14\n顺序领取",Vector3(1.85,.12,.13),Vector2(2.10,1.35),.009)
	# A later sheet visibly covers the earlier rule, rather than explaining the incident.
	_pilot_paper(window,"D-6\n分批领取",Vector3(2.18,-.40,.20),Vector2(1.80,1.25),.009).rotation.z=-.09
	# Side bay stays useful: sorted household fabric on the existing adjacent sill.
	for n in 3: _box(Vector3(.65,.065,.32),Vector3(3,.065*n-.63,.15),"b2a58a" if n%2 else "879a85",window)
	_wall_sign(window,"侧窗递送",Vector3(3,-.18,.15),Vector2(1.36,.36),"5c7165",.006)
	layout._batch(window)
	var court:=Node3D.new();court.name="InterruptedDistributionQueue";court.position=layout.g.ROOMS[2]+Vector3(-13,0,9.0);add_child(court)
	# Shallow floor traces and fallen pieces only; no upright invisible-collision barriers.
	# The old queue leads to this window, not across the current dorm doorway or road.
	for z in [.55,1.15,1.75,2.35]:
		for x in [-.75,.75]: _box(Vector3(.045,.008,.32),Vector3(x,.086,z),"b6ac83",court)
	for entry in [[Vector3(-.6,.10,.45),-.20],[Vector3(.50,.10,1.25),.48]]:
		var rail:=Node3D.new();rail.position=entry[0];rail.rotation.y=entry[1];court.add_child(rail)
		_box(Vector3(.08,.065,1.15),Vector3.ZERO,"798776",rail)
		for z in [-.46,.46]: _box(Vector3(.35,.025,.09),Vector3(0,-.02,z),"8f9985",rail)
	# A split queue strip curls toward the window; wear stays local to this old use.
	_line(Vector3(-.68,.096,2.65),Vector3(-.22,.098,1.73),.035,"7b8471",court)
	_line(Vector3(-.22,.098,1.73),Vector3(-.31,.10,.82),.035,"7b8471",court)
	for n in 5:
		var paper:=_box(Vector3(.14,.008,.18),Vector3(sin(n*2.4)*.6,.09,.45+n*.28),"c1b99e",court)
		paper.rotation.y=n*.64
	layout._batch(court)

func _pilot_paper(parent: Node3D, text: String, at: Vector3, size: Vector2, pixels: float) -> Node3D:
	var note:=_wall_sign(parent,text,at,size,"c9c3a5",pixels)
	for child in note.get_children():
		if child is Label3D: child.modulate=Color("3f5146")
	return note
