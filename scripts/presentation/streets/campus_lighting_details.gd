extends Node3D
## Fixed campus presentation. No collision, navigation, loot, or narrative state.
var layout: RefCounted
var surfaces := {}

func build(campus: RefCounted) -> void:
	layout = campus
	for index in layout.g.ROOMS.size():
		var room := Node3D.new()
		room.name = ["ReadingRoom", "Clinic", "Dormitory", "Workshop"][index]
		room.position = layout.g.ROOMS[index]
		add_child(room)
		_room_lamps(room, index)
		_wall_services(room, index)
		match index:
			0: _reading_details(room)
			1: _clinic_details(room)
			2: _dormitory_details(room)
			3: _workshop_details(room)
		layout._batch(room)
	_roof_details()
	_entry_lamps()
	_path_fittings()
	_lakeside_details()
	_environment_decals()
	if layout.g.lighting_variant == "night": _night_lamps()
	layout._batch(self)

func _material(color: String, metal := 0.0, emission := 0.0) -> StandardMaterial3D:
	var key := color + str(metal) + str(emission)
	if not surfaces.has(key):
		surfaces[key] = VisualFactory.material(Color(color), metal, .72, Color(color) if emission > 0 else Color.BLACK, emission)
	return surfaces[key]

func _box(parent: Node3D, size: Vector3, at: Vector3, color: String, metal := 0.0, emission := 0.0) -> MeshInstance3D:
	return layout._detail(size, at, _material(color, metal, emission), parent)

func _line(parent: Node3D, a: Vector3, b: Vector3, width: float, color: String) -> void:
	var delta := b-a
	var mesh := _box(parent, Vector3(width, width, delta.length()), (a+b)*.5, color, .4)
	mesh.basis = Basis.looking_at(delta, Vector3.RIGHT if absf(delta.normalized().y) > .98 else Vector3.UP)

func _light(parent: Node3D, at: Vector3, color: String, energy: float, radius: float, shadows := false) -> OmniLight3D:
	var lamp := OmniLight3D.new()
	lamp.name = "PracticalLight"
	lamp.position = at
	lamp.light_color = Color(color)
	lamp.light_energy = energy
	lamp.omni_range = radius
	lamp.omni_attenuation = 1.25
	lamp.shadow_enabled = shadows
	lamp.shadow_blur = 1.4
	lamp.light_bake_mode = Light3D.BAKE_DISABLED
	parent.add_child(lamp)
	return lamp

func _wall_lamp(parent: Node3D, at: Vector3, color: String, energy: float, radius: float) -> void:
	# Reuse a sourced, textured enclosure rather than an untextured luminous cube.
	var fixture := SliceUI.prop(parent, "res://assets/environment/compact_hideout/polyhaven/industrial_wall_lamp/industrial_wall_lamp.gltf", at, .85)
	fixture.name = "WallLightFixture"
	_box(parent, Vector3(.26, .085, .03), at+Vector3(0, -.035, .09), color, 0.0, 1.3)
	_light(parent, at+Vector3(0, -.15, .36), color, energy, radius)

func _pendant(parent: Node3D, at: Vector3, color: String, energy: float, radius: float) -> void:
	# Small task fixture near a work surface, not a ceiling panel across the view.
	var fixture := Node3D.new()
	fixture.position = at
	parent.add_child(fixture)
	_box(fixture, Vector3(.07, .58, .07), Vector3(0, .29, 0), "5b695f", .5)
	_box(fixture, Vector3(1.25, .12, .28), Vector3.ZERO, "66716a", .6)
	_box(fixture, Vector3(1.08, .035, .20), Vector3(0, -.075, 0), color, 0.0, 2.0)
	layout._batch(fixture)
	for mesh in fixture.get_children():
		if mesh is MeshInstance3D: mesh.add_to_group("camera_occluder")
	_light(parent, at+Vector3(0, -.25, 0), color, energy, radius, true)

func _room_lamps(room: Node3D, index: int) -> void:
	# Each room has an identifiable working zone and a softer circulation zone.
	var colors := ["e8d3a5", "dbe9df", "efd0a0", "d9e7ec"]
	var tasks := [Vector3(4.6, 2.65, -.8), Vector3(4.7, 2.65, -3.6), Vector3(-3.3, 2.65, -2.0), Vector3(-5, 2.65, -1.4)]
	_pendant(room, tasks[index], colors[index], 2.2, 6.2)
	_wall_lamp(room, Vector3(-3.3, 2.7, -6.68), colors[index], 1.1, 5.2)
	_wall_lamp(room, Vector3(4.7, 2.7, -6.68), "f1dab4" if index == 2 else "dbe5df", .65, 4.5)
	if index == 0:
		_light(room, Vector3(-4.7, 1.18, 1), "f1ca88", .85, 2.7)
	if index == 3:
		# Small service inspection light facing the parked vehicle.
		_box(room, Vector3(.55, .12, .34), Vector3(4, 2.7, -.7), "626b64", .6)
		_box(room, Vector3(.46, .03, .25), Vector3(4, 2.62, -.7), "e1e8d9", 0.0, 1.4)
		_light(room, Vector3(4, 2.4, -.7), "e1e8d9", .85, 4.5)

func _wall_services(room: Node3D, index: int) -> void:
	# Baseboards, sockets and cable routes attach to existing walls.
	for side in [-1, 1]:
		_box(room, Vector3(.075, .16, 13.0), Vector3(side*7.72, .17, 0), "626e61")
	for x in [-5.4, 5.6]:
		_box(room, Vector3(.15, .19, .045), Vector3(x, .48, -6.72), "a5ad99")
		for dx in [-.035, .035]: _box(room, Vector3(.018, .035, .012), Vector3(x+dx, .50, -6.69), "445348")
	_line(room, Vector3(-7.70, 2.98, -6.45), Vector3(7.70, 2.98, -6.45), .045, "9da693")
	_line(room, Vector3(-7.70, .5, -6.45), Vector3(-7.70, 2.98, -6.45), .045, "9da693")
	_box(room, Vector3(.44, .65, .09), Vector3(-7.6, 1.4, -6.5), "687a6c", .4)
	_box(room, Vector3(.09, .12, .025), Vector3(-7.61, 1.35, -6.44), "bac1ae")
	# A radiator and intake grille give the north wall a built interior scale.
	_box(room, Vector3(1.75, .72, .13), Vector3(1.05, .52, -6.62), "9ca592", .2)
	for n in 10: _box(room, Vector3(.045, .60, .07), Vector3(.35+n*.155, .55, -6.52), "bdc3ae", .1)
	_box(room, Vector3(.70, .42, .06), Vector3(6.6, 2.55, -6.7), "56665b")
	for n in 5: _box(room, Vector3(.62, .018, .035), Vector3(6.6, 2.4+n*.065, -6.66), "9aa693")
	# A fixed location plate is scenery, not a hint or an interactable.
	var plate := _box(room, Vector3(1.4, .28, .04), Vector3(-1.75, 2.0, -6.72), "64786a")
	plate.name = "RoomPlate"
	layout._sign(room, ["图书阅览 · 阅后归架", "医务室 · 请保持清洁", "宿舍值班 · 寝具领用登记", "后勤维修 · 工具用后归位"][index], Vector3(-1.75, 2.0, -6.68), .0027)

func _paper_stack(room: Node3D, at: Vector3, count: int) -> void:
	for n in count:
		var paper := _box(room, Vector3(.34, .012, .24), at+Vector3(n*.008, n*.013, sin(n)*.012), "ccc4a9")
		paper.rotation.y = .05*sin(n*2.3)
	_box(room, Vector3(.12, .013, .075), at+Vector3(.07, count*.013+.008, 0), "858c75")

func _reading_details(room: Node3D) -> void:
	for z in [-3.6, 1.1]:
		_paper_stack(room, Vector3(4.28, 1.105, z+.05), 5)
		for n in 3:
			_box(room, Vector3(.26, .06+n*.008, .35), Vector3(5.02, 1.13+n*.065, z-.08), ["7f6953", "728777", "a49975"][n])
		_box(room, Vector3(.07, .09, .07), Vector3(4.9, 1.13, z+.32), "b0b49b")
	# Archive trolley beside the existing cabinets, keeping the aisle clear.
	for level in [.28, .80]:
		_box(room, Vector3(.72, .055, 1.0), Vector3(-6.25, level, 3.05), "6d7a6d", .4)
		for n in 3: _box(room, Vector3(.55, .07, .26), Vector3(-6.25, level+.07, 2.75+n*.29), "a99878")
	for x in [-6.55, -5.95]:
		for z in [2.62, 3.48]: _box(room, Vector3(.045, .97, .045), Vector3(x, .56, z), "52665c", .5)
	_paper_stack(room, Vector3(-4.1, .82, 1.2), 4)

func _clinic_details(room: Node3D) -> void:
	# These are ordinary examination accessories, never the MED batch evidence.
	_box(room, Vector3(.63, .07, .44), Vector3(3.7, .81, -4.7), "acb8ae", .6)
	for n in 3: _box(room, Vector3(.04, .04, .29), Vector3(3.55+n*.11, .87, -4.7), "d3d6bd")
	_box(room, Vector3(.5, .50, .45), Vector3(6.2, .30, -5.5), "bac4b6")
	_box(room, Vector3(.51, .045, .46), Vector3(6.2, .57, -5.5), "84998b")
	_box(room, Vector3(.62, .07, .42), Vector3(-6.3, .25, 4.0), "809d8c")
	_box(room, Vector3(.50, .4, .32), Vector3(-6.3, .49, 4.0), "bcc5b1")
	_line(room, Vector3(-6.3, .5, 4.1), Vector3(-5.9, 1.55, 4.1), .045, "948c71")
	_box(room, Vector3(.26, .03, .13), Vector3(-5.9, 1.55, 4.1), "c8c8ac")
	for x in [-6, -4.5]: _box(room, Vector3(.27, .018, .18), Vector3(x, .52, 5.7), "b5b49b")
	_paper_stack(room, Vector3(5.6, .15, -5.5), 2)

func _dormitory_details(room: Node3D) -> void:
	for z in [-3.8, 1.0]:
		# Bags and shoes sit under/along the already solid bunk footprint.
		_box(room, Vector3(.6, .32, .4), Vector3(5.4, .24, z+.57), "746a56")
		_box(room, Vector3(.055, .34, .42), Vector3(5.4, .24, z+.57), "b4a58a")
		for x in [5.75, 5.95]: _box(room, Vector3(.14, .075, .30), Vector3(x, .14, z-.9), "424e42")
		_box(room, Vector3(.40, .09, .53), Vector3(5.35, .74, z-.5), "98aa8c")
		for dx in [-.12, .12]: _box(room, Vector3(.02, .012, .53), Vector3(5.35+dx, .80, z-.5), "c3b993")
	_paper_stack(room, Vector3(-5.5, .9, .2), 6)
	_box(room, Vector3(.26, .03, .36), Vector3(-5.07, .92, .38), "627e6e")
	_box(room, Vector3(.14, .12, .16), Vector3(-5.8, .96, .15), "a9ac8b")
	# Individual hooks and hung folded towels, against the partition, not in the corridor.
	for z in [-3.2, -2.2, -1.2]:
		_box(room, Vector3(.04, .08, .04), Vector3(2.47, 1.55, z), "6e776c", .4)
		_box(room, Vector3(.07, .64, .38), Vector3(2.48, 1.19, z), "b0b59b")

func _workshop_details(room: Node3D) -> void:
	for z in [-3.5, .7]:
		_box(room, Vector3(.53, .013, .37), Vector3(-4.65, 1.03, z+.16), "a1a393")
		for n in 4: _box(room, Vector3(.025, .028, .24+n*.025), Vector3(-4.83+n*.10, 1.055, z+.16), "8faaa0", .65)
		_box(room, Vector3(.17, .14, .15), Vector3(-4.95, 1.09, z-.26), "827257")
	# A hose curled beside the lift parking line, not a random pile in the central path.
	var coil := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius=.36; mesh.outer_radius=.43; mesh.rings=32; mesh.ring_segments=8
	coil.mesh=mesh;coil.material_override=_material("394e43")
	coil.position=Vector3(6.9, .16, -1.2);room.add_child(coil)
	_line(room, Vector3(6.9, .17, -1.0), Vector3(7.1, .17, .25), .055, "394e43")
	for n in 3:
		_box(room, Vector3(.27, .40, .27), Vector3(-6.95+n*.34, .29, -4.8), "8c7d53" if n != 1 else "6c8576", .2)
		_box(room, Vector3(.09, .055, .09), Vector3(-6.95+n*.34, .52, -4.8), "b8b49c")
	for x in [3.0, 4.7]: _box(room, Vector3(.5, .028, .34), Vector3(x, .105, -5.1), "a99a78").rotation.y = x*.13

func _roof_details() -> void:
	# The original dorm wing boxes left large blank tops at the game camera.
	# Roofs remain under those same cutaway owners and add no physical height.
	for entry in [["DormitoryWestWing", 7.6, 17.7, 4.45, 1.15], ["DormitoryNorthWing", 20.6, 5.7, 3.52, .85]]:
		var owner: Node3D = layout.g.find_child(entry[0], true, false)
		var roof := Node3D.new()
		roof.name = "DormitoryTiledRoof"
		roof.position.y = entry[3]
		owner.add_child(roof)
		layout._pitched_roof(roof, entry[1], entry[2], entry[4], "665e50")
		layout._batch(roof)
	var rear: Node3D = layout.g.find_child("ClinicRearWing", true, false)
	var service := Node3D.new()
	service.name = "ClinicRoofServices"
	rear.add_child(service)
	_box(service, Vector3(2.3,.12,1.3), Vector3(3.7,2.63,0), "697a70", .5)
	_box(service, Vector3(1.5,.65,.9), Vector3(3.7,3.0,0), "a3ad9a", .4)
	for n in 7: _box(service, Vector3(.025,.46,.06), Vector3(3.14+n*.18,3.0,.48), "596c60", .5)
	_line(service, Vector3(3.6,2.78,-.25), Vector3(3.6,2.78,-2.6), .10, "939c88")
	_line(service, Vector3(3.6,2.78,-2.6), Vector3(-1.4,2.78,-2.6), .10, "939c88")
	for x in [-5.4,-1.4]:
		_box(service, Vector3(.22,.76,.22), Vector3(x,2.95,-2.6), "788b7c", .5)
		_box(service, Vector3(.48,.09,.42), Vector3(x,3.38,-2.6), "a0aa92", .4)
	layout._batch(service)

func _entry_lamps() -> void:
	for index in [0, 2, 3]:
		var entry := Node3D.new()
		entry.name = "EntrancePractical%d" % index
		entry.position = layout.g.ROOMS[index]+Vector3(0, 0, 7.32)
		add_child(entry)
		_wall_lamp(entry, Vector3(1.9, 2.6, .18), "efdab2", .8, 4.2)
		_line(entry, Vector3(1.9, 2.76, .16), Vector3(4.0, 2.76, .16), .035, "7e8978")
		_box(entry, Vector3(.28, .32, .08), Vector3(4, 2.6, .15), "758571", .4)
		layout._batch(entry)

func _path_fittings() -> void:
	# Improve the existing daylight-off street lamps; no decorative glow on sunny lawns.
	for at in [Vector3(-34,0,8),Vector3(-17,0,7),Vector3(16,0,7),Vector3(34,0,7),Vector3(-32,0,45),Vector3(9,0,45),Vector3(33,0,45)]:
		_box(self, Vector3(.27,.15,.27), at+Vector3.UP*.09, "849283", .4)
		_box(self, Vector3(.08,.34,.04), at+Vector3(0,.85,.075), "8b978a", .6)
		for y in [.75, .93]: _box(self, Vector3(.035,.025,.018), at+Vector3(0,y,.10), "bac1a9", .5)
		_box(self, Vector3(.34,.018,.30), at+Vector3.UP*3.705, "9fae9c")
	# Leaves collect at curb/bench edges, while the usable promenade stays clean.
	for at in [Vector3(2,0,-6.45),Vector3(20,0,-6.45),Vector3(-22,0,30),Vector3(24,0,25.1),Vector3(-35,0,-23)]:
		for n in 14:
			var leaf := _box(self, Vector3(.12,.007,.18), at+Vector3(sin(n*2.4)*.66,.078,cos(n*2.1)*.24), ["988b5e","8e976c","b2a074"][n%3])
			leaf.rotation.y=n*1.7

func _lakeside_details() -> void:
	# A maintained rest stop rather than random debris across the lawn.
	for at in [Vector3(3,0,-6),Vector3(19,0,-6),Vector3(21,0,33)]:
		_box(self, Vector3(.28,.034,.38), at+Vector3(.28,.58,0), "677d70")
		_box(self, Vector3(.24,.009,.34), at+Vector3(.28,.60,0), "c8c1a4")
		var flask := MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		cylinder.top_radius=.06;cylinder.bottom_radius=.065;cylinder.height=.25;cylinder.radial_segments=16
		flask.mesh=cylinder;flask.material_override=_material("8fa39a",.65)
		flask.position=at+Vector3(-.48,.7,0);add_child(flask)
		_box(self, Vector3(.12,.035,.12), at+Vector3(-.48,.84,0), "b9c0a7", .35)
		for n in 6:
			var mark := _box(self, Vector3(.14,.007,.23), at+Vector3(sin(n*2.7)*.5,.081,1.05+n*.18), "a4a58c")
			mark.rotation.y=.2*sin(n)
	var station := Node3D.new()
	station.name = "LakesideCareStation"
	station.position=Vector3(10.275,0,-2.75)
	add_child(station)
	_line(station,Vector3(0,1.5,-1.0),Vector3(0,1.5,.07),.055,"758878")
	_box(station,Vector3(1.7,.66,.065),Vector3(0,1.7,.07),"607b6b")
	_box(station,Vector3(1.5,.47,.018),Vector3(0,1.7,.114),"b8bca2")
	layout._sign(station,"湖岸保洁 · 工具归位",Vector3(0,1.71,.135),.004)
	for x in [-.13,.13]:
		_line(station,Vector3(x,.25,.16),Vector3(x+.1,1.5,.16),.035,"8e8968")
	_box(station,Vector3(.27,.075,.14),Vector3(-.13,.21,.16),"a09166")
	_box(station,Vector3(.22,.065,.18),Vector3(.13,.21,.16),"789282")
	_box(station,Vector3(.14,.04,.075),Vector3(0,1.4,.16),"5f7164",.5)
	layout._batch(station)
	# Low perennial beds frame the rest stop while keeping both lake/avenue routes open.
	for center in [Vector2(6.7,-1.2),Vector2(20.9,-1.2)]:
		var bed := PackedVector2Array([center+Vector2(-1.7,-.5),center+Vector2(1.6,-.5),center+Vector2(1.9,.35),center+Vector2(-1.5,.45)])
		var soil := ShaderMaterial.new()
		soil.shader = preload("res://resources/materials/streets/campus_soil.gdshader")
		soil.set_shader_parameter("ground_detail",preload("res://assets/environment/campus/forest_ground_04_diff_1k.jpg"))
		soil.set_shader_parameter("center",center)
		soil.set_shader_parameter("radius",Vector2(1.9,.65))
		layout._polygon(bed,.043,soil,self).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for n in 5:
			layout._bush(Vector3(center.x-1.25+n*.62,.03,center.y),.35)
		for n in 8:
			_box(self,Vector3(.10,.035,.18),Vector3(center.x-1.5+n*.42,.07,center.y+.48),"9da58c")

func _night_lamps() -> void:
	var lenses := Node3D.new()
	lenses.name="NightLampLenses"
	add_child(lenses)
	# Sources coincide with authored avenue fixtures; no gameplay collision changes.
	for at in [Vector3(-34,3.65,8),Vector3(-17,3.65,7),Vector3(16,3.65,7),Vector3(34,3.65,7),Vector3(-32,3.65,45),Vector3(9,3.65,45),Vector3(33,3.65,45)]:
		_light(self, at+Vector3(.14,-.18,.10), "ffd39a", 5.5, 12.0, true)
		var lens := _box(lenses, Vector3(.32,.018,.28), at+Vector3.UP*.042, "ffd39a", 0.0, 3.0)
		lens.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for at in layout.g.EXITS:
		_light(self, at+Vector3(0,2.8,-1.0), "b9d8de", 3.5, 9.0, true)
	for at in [Vector3(6,2.6,-3),Vector3(19,2.6,-3),Vector3(-13,2.6,-9)]:
		_wall_lamp(self, at, "f3d7a7", 1.8, 7.5)

func _environment_decals() -> void:
	var decals := Node3D.new()
	decals.name="AftermathDecals"
	add_child(decals)
	# Fixed aftermath, separate from deterministic quest evidence and random loot.
	var blood := preload("res://assets/environment/campus/decals/blood_dried_v1.png")
	var scorch := preload("res://assets/environment/campus/decals/scorch_v1.png")
	for entry in [[blood,Vector3(-19,.086,-17),Vector2(1.8,1.2),.4], [blood,Vector3(-15,.075,-10),Vector2(1.0,.7),2.1], [blood,Vector3(-24,.075,32),Vector2(1.4,.9),1.2], [scorch,Vector3(-39,.086,-29),Vector2(3.4,2.3),.6], [scorch,Vector3(-33,.075,8),Vector2(2.2,1.5),2.4]]:
		var material := StandardMaterial3D.new()
		material.albedo_texture=entry[0]
		material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		material.roughness=1.0
		material.cull_mode=BaseMaterial3D.CULL_DISABLED
		var plane := MeshInstance3D.new()
		plane.name="AftermathDecal%d" % decals.get_child_count()
		var mesh := PlaneMesh.new()
		mesh.size=entry[2]
		plane.mesh=mesh
		plane.material_override=material
		plane.position=entry[1]
		plane.rotation.y=entry[3]
		plane.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		decals.add_child(plane)
