extends Node3D
## Authored pharmacy art. All geometry is visual; existing walls/cover/points own gameplay.
var _sage: Material
var _iron: Material
var _stone: Material
var _paper: Material
var _glass: Material
var _timber: Material
var _roof_metal: Material
var _detail_parent: Node3D

func build(district: Node3D, center: Vector3) -> void:
	position = center
	var paint := ShaderMaterial.new()
	paint.shader = preload("res://resources/materials/streets/pharmacy_paint.gdshader")
	paint.set_shader_parameter("paint_color",Color("71866b"))
	_sage = paint
	_iron = VisualFactory.material(Color("48534d"),.65,.63)
	_stone = district._pbr_material("painted_plaster_wall",.8,Color("c8be9e"))
	_paper = VisualFactory.material(Color("ccc5ad"),0,.95)
	_glass = VisualFactory.material(Color("263b38"),.28,.28)
	_timber = district._material(Color("655442"),false)
	var roof_material := ShaderMaterial.new()
	roof_material.shader = preload("res://resources/materials/streets/pharmacy_roof.gdshader")
	_roof_metal = roof_material
	for entry in [["Storefront",_storefront],["ServiceWall",_service_wall],["ReceivingCounter",_receiving_counter]]:
		_detail_parent = Node3D.new()
		_detail_parent.name = entry[0]
		add_child(_detail_parent)
		entry[1].call()
		_merge(_detail_parent)
	_retint_existing(district,center)
	_roof(district,center)
	# Batch facade/interior primitives by material. Roof art remains with the existing cutaway.

func _box(size: Vector3, at: Vector3, material: Material, parent: Node3D = null) -> MeshInstance3D:
	if parent == null: parent = _detail_parent
	var item := VisualFactory.box(parent,size,at,Color.WHITE,"PharmacyDetail")
	item.material_override = material
	return item

func _text(parent: Node3D, value: String, at: Vector3, pixels: float, size: int = 40) -> Label3D:
	var label := SliceUI.sign(parent,value,at,Color("d4d0b7"))
	label.font_size = size
	label.pixel_size = pixels
	label.outline_size = 0
	return label

func _storefront() -> void:
	# Flat panels and glass lie on the existing solid facade, never across the open door.
	for x in [-4.8,4.8]:
		_box(Vector3(6.35,.85,.10),Vector3(x,.45,7.26),_sage)
		_box(Vector3(6.35,.72,.16),Vector3(x,2.97,7.28),_sage)
		for edge in [-3.12,3.12]:
			_box(Vector3(.19,3.2,.18),Vector3(x+edge,1.62,7.31),_sage)
	# A glazed display bay on the left, a mostly shuttered bay on the right.
	_box(Vector3(5.65,1.65,.12),Vector3(-4.8,1.72,7.32),_glass)
	for x in [-7.65,-4.8,-1.95]: _box(Vector3(.11,1.82,.24),Vector3(x,1.72,7.45),_iron)
	for y in [.83,2.58]: _box(Vector3(5.9,.10,.26),Vector3(-4.8,y,7.45),_iron)
	_box(Vector3(5.85,.16,.55),Vector3(-4.8,.8,7.43),_stone)
	for x in [-6.8,-6.15,-3.75,-3.25]:
		_box(Vector3(.35,.35,.10),Vector3(x,1.16,7.42),_paper)
		_box(Vector3(.36,.08,.11),Vector3(x,1.12,7.44),_sage)
	# Worn shutter, asymmetric with the display window.
	_box(Vector3(5.6,1.85,.12),Vector3(4.8,1.70,7.35),_iron)
	for row in 18:
		_box(Vector3(5.55,.035,.04),Vector3(4.8,.82+row*.102,7.43),_sage)
	_box(Vector3(.9,.08,.08),Vector3(4.8,.83,7.48),_iron)
	for x in [-1.7,1.7]: _box(Vector3(.22,3.1,.25),Vector3(x,1.55,7.28),_sage)
	# Store identity is painted on an actual wall-mounted sign, not a floating waypoint.
	_box(Vector3(9.4,.85,.18),Vector3(-.6,3.12,7.53),_sage)
	_storefront_texture()
	# Red identifies medical supplies in the story bible. This is a wall sign,
	# not an objective marker; the generated facade remains the surface beneath it.
	var medical_red := _medical_sign_material()
	_box(Vector3(8.8,.82,.075),Vector3(-1.55,3.04,7.78),medical_red)
	_box(Vector3(.95,.82,.08),Vector3(-6.5,3.04,7.78),medical_red)
	_box(Vector3(.16,.58,.03),Vector3(-6.5,3.04,7.84),_paper)
	_box(Vector3(.58,.16,.03),Vector3(-6.5,3.04,7.85),_paper)
	_text(_detail_parent,"药房 · 校医室",Vector3(-1.55,3.05,7.84),.018,44)
	# Corrugated canopy and edge strip: supported above the entrance, no ground pillars.
	var canopy := _box(Vector3(13.8,.10,.40),Vector3(-.7,2.65,7.48),_iron)
	canopy.rotation.x = -.1
	canopy.add_to_group("camera_occluder")
	for x in [-6.7,-3.7,.1,3.3,5.7]:
		_box(Vector3(.10,.07,.42),Vector3(x,2.71,7.48),_sage).rotation.x = -.1
	_box(Vector3(13.9,.10,.07),Vector3(-.7,2.59,7.71),_sage)
	for x in [-6.2,4.7]:
		_box(Vector3(.05,.46,.06),Vector3(x,2.35,7.45),_iron).rotation.x = -.55
	# Entry lamp gives the open doorway a modest warm focal point.
	_box(Vector3(.55,.08,.36),Vector3(.7,2.75,7.47),_iron)
	_box(Vector3(.34,.055,.22),Vector3(.7,2.70,7.47),VisualFactory.material(Color("d4b778"),0,.6,Color("ceaf6d"),.8))
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(.7,2.6,7.7)
	lamp.light_color = Color("efc28b")
	lamp.light_energy = .55
	lamp.omni_range = 4.5
	_detail_parent.add_child(lamp)
	_text(_detail_parent,"处方 · 居民补给",Vector3(-4.8,.47,7.38),.005,30)
	# Thin deposits against the facade, not arbitrary debris scattered across a route.
	for x in [-7.6,-6.2,3.5,6.2]:
		_box(Vector3(.42,.006,.25),Vector3(x,.092,7.5),_paper).rotation.y = x*.1

func _service_wall() -> void:
	# The western wall is visible when approaching along the central street.
	for z in [-5.3,-1.0,4.3]:
		_box(Vector3(.09,3.0,.15),Vector3(-8.27,1.55,z),_iron)
		for y in [.5,1.9,2.8]: _box(Vector3(.14,.05,.28),Vector3(-8.28,y,z),_sage)
	_box(Vector3(.25,.85,1.45),Vector3(-8.32,2.05,-3.5),_stone)
	for n in 9: _box(Vector3(.04,.55,.07),Vector3(-8.47,2.05,-4.05+n*.14),_iron)
	for z in [-5.4,4.4]:
		_box(Vector3(.16,3.5,.16),Vector3(-8.30,1.75,z),_iron)
	_box(Vector3(.14,.15,9.8),Vector3(-8.30,.34,-.5),_iron)
	_box(Vector3(.08,1.1,1.25),Vector3(-8.26,1.35,1.9),_paper)
	var notice := _text(_detail_parent,"药房\n收货登记在店内",Vector3(-8.32,1.4,1.9),.005,30)
	notice.rotation.y = -PI/2

func _receiving_counter() -> void:
	# Ledger and empty trays sit on existing counter/crate surfaces; no new solid cover.
	var countertop := PlaneMesh.new()
	countertop.size = Vector2(3,.8)
	var counter_art := MeshInstance3D.new()
	counter_art.name = "ReceivingLedgerSurface"
	counter_art.mesh = countertop
	var counter_material := StandardMaterial3D.new()
	counter_material.albedo_texture = load("res://assets/environment/pharmacy/countertop_v1.png") as Texture2D
	assert(counter_material.albedo_texture != null)
	counter_material.roughness = .9
	counter_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	counter_art.material_override = counter_material
	counter_art.position = Vector3(-3,.916,-3)
	_detail_parent.add_child(counter_art)
	# The designated batch has its own empty receiving trays, on the existing
	# counter. The ordinary pharmacy shelves and loot remain separate.
	for x in [-3.8,-2.8]:
		_box(Vector3(.82,.025,.57),Vector3(x,.96,-3.02),_iron)
		for edge in [-.41,.41]: _box(Vector3(.024,.13,.57),Vector3(x+edge,1.02,-3.02),_sage)
		for edge in [-.285,.285]: _box(Vector3(.82,.13,.025),Vector3(x,1.02,-3.02+edge),_sage)
		_box(Vector3(.55,.14,.015),Vector3(x,1.02,-2.72),_paper)
		_text(_detail_parent,"敷料" if x < -3 else "织物",Vector3(x,1.03,-2.70),.0045,32)
	var record := Node3D.new()
	record.name = "FixedBatchReceivingRecord"
	record.position = Vector3(-3.3,1.35,-3.48)
	record.rotation.x = -.55
	_detail_parent.add_child(record)
	_box(Vector3(2.45,.92,.04),Vector3.ZERO,_sage,record)
	_box(Vector3(2.28,.72,.025),Vector3(0,-.02,.035),_paper,record)
	_box(Vector3(.35,.055,.025),Vector3(0,.43,.045),_iron,record)
	_text(record,NarrativeSlice.PHARMACY_BATCH,Vector3(0,.22,.055),.007,36).modulate = Color("434e43")
	_text(record,"批次收货格 / 普通库存另计",Vector3(0,-.12,.055),.0045,30).modulate = Color("434e43")
	for x in [-4.45,-2.15]: _box(Vector3(.05,.35,.05),Vector3(x,1.11,-3.51),_iron)
	# A second fixed sheet displays the exact existing fact, without an allegation.
	var ledger := _text(_detail_parent,NarrativeSlice.BATCH_INFORMATION,Vector3(-3,.938,-3),.0022,28)
	ledger.rotation.x = -PI/2
	ledger.modulate = Color("424c40")
	for x in [3.6,4.3]:
		_box(Vector3(.58,.045,.44),Vector3(x,.747,-4.5),_iron)
		for edge in [-.29,.29]: _box(Vector3(.025,.11,.44),Vector3(x+edge,.78,-4.5),_sage)
		for edge in [-.22,.22]: _box(Vector3(.58,.11,.025),Vector3(x,.78,-4.5+edge),_sage)
	var task_light := OmniLight3D.new()
	task_light.position = Vector3(-4,2.7,-4.4)
	task_light.light_color = Color("dce1c4")
	task_light.light_energy = 1.1
	task_light.omni_range = 7
	_detail_parent.add_child(task_light)
	_box(Vector3(1.4,.08,.14),Vector3(-4,2.8,-6.65),_iron)
	_box(Vector3(1.2,.06,.14),Vector3(-4,2.75,-6.63),VisualFactory.material(Color("dedcc1"),0,.5,Color("dddcc5"),.45))
	# This ordinary return crate is not the designated receiving batch.
	_box(Vector3(.42,.19,.02),Vector3(4,.42,-4.18),_paper)
	_text(_detail_parent,"普通周转箱",Vector3(4,.43,-4.15),.0022,26)
	# Receiving task is physically at (-4,-4), within reach of this ledger.

func _medical_sign_material() -> Material:
	var material := ShaderMaterial.new()
	material.shader = preload("res://resources/materials/streets/pharmacy_paint.gdshader")
	material.set_shader_parameter("paint_color",Color("8e493d"))
	material.set_shader_parameter("wear_amount",.18)
	return material

func _roof(district: Node3D, center: Vector3) -> void:
	var roof: StaticBody3D
	for candidate in district.find_children("*","StaticBody3D",true,false):
		if candidate.is_in_group("aim_cutaway_roof") and candidate.position.distance_to(center+Vector3(0,3.6,0)) < .1: roof = candidate
	assert(roof != null)
	var details := Node3D.new()
	details.name = "PharmacyRoofDetails"
	roof.add_child(details)
	# Local roof art inherits its original body's camera fade and mouse-picking cutaway.
	for x in [-7.7,7.7]: _box(Vector3(.21,.45,13.8),Vector3(x,.30,0),_stone,details)
	for z in [-6.8,6.8]: _box(Vector3(15.6,.45,.21),Vector3(0,.30,z),_stone,details)
	for x in [-6.5,-3.25,0.0,3.25,6.5]:
		var cap := _box(Vector3(3.1,.14,6.6),Vector3(x,.35,-3.25),_roof_metal,details)
		cap.rotation.x = -.075
		var other := _box(Vector3(3.1,.14,6.6),Vector3(x,.35,3.25),_roof_metal,details)
		other.rotation.x = .075
		_box(Vector3(.08,.16,13.2),Vector3(x-1.55,.38,0),_sage,details)
	_box(Vector3(2.4,.38,1.6),Vector3(4.5,.4,-4),_iron,details)
	for n in 10: _box(Vector3(2.05,.03,.045),Vector3(4.5,.61,-4.63+n*.14),_sage,details)
	_merge(details)

func _merge(parent: Node3D) -> void:
	var grouped := {}
	for child in parent.get_children():
		if not child is MeshInstance3D: continue
		var material: Material = child.material_override
		if not grouped.has(material): grouped[material] = []
		grouped[material].append(child)
	for material in grouped:
		var builder := SurfaceTool.new()
		builder.begin(Mesh.PRIMITIVE_TRIANGLES)
		for item in grouped[material]: builder.append_from(item.mesh,0,item.transform)
		builder.set_material(material)
		var mesh := MeshInstance3D.new()
		mesh.name = "PharmacySurface"
		mesh.mesh = builder.commit()
		# Front art uses the existing visual-only occlusion mechanism; physics is never added.
		if parent.name in ["Storefront","ServiceWall"]: mesh.add_to_group("camera_occluder")
		parent.add_child(mesh)
		for item in grouped[material]: item.free()

func _retint_existing(district: Node3D, center: Vector3) -> void:
	for body in district.find_children("*","StaticBody3D",true,false):
		var offset: Vector3 = body.position-center
		if offset.length() > 12 or not body.has_node("Mesh"): continue
		var visual := body.get_node("Mesh") as MeshInstance3D
		if offset.distance_to(Vector3(0,.02,0)) < .1:
			var tile := ShaderMaterial.new()
			tile.shader = preload("res://resources/materials/streets/pharmacy_floor.gdshader")
			tile.set_shader_parameter("exterior",false)
			visual.material_override = tile
		elif absf(offset.y-1.75) < .1 and (absf(absf(offset.x)-8)<.1 or absf(absf(offset.z)-7)<.1):
			visual.material_override = _stone

func _storefront_texture() -> void:
	var texture := load("res://assets/environment/pharmacy/storefront_v1.png") as Texture2D
	assert(texture != null)
	var image := texture.get_image()
	var used := image.get_used_rect()
	# Keep the source PNG untouched. Three UV regions align the generated alpha entrance
	# to the existing 3.2 m doorway, independent of the model's exact opening proportions.
	var scan_y := used.position.y+roundi(used.size.y*.65)
	var middle := used.get_center().x
	assert(image.get_pixel(middle,scan_y).a < .05)
	var opening_left := middle
	var opening_right := middle
	while opening_left > used.position.x and image.get_pixel(opening_left-1,scan_y).a < .5: opening_left-=1
	while opening_right < used.end.x-1 and image.get_pixel(opening_right+1,scan_y).a < .5: opening_right+=1
	for region in [[used.position.x,opening_left,-4.8,6.4],[opening_left,opening_right,0.0,3.2],[opening_right,used.end.x,4.8,6.4]]:
		var material := StandardMaterial3D.new()
		material.albedo_texture = texture
		material.roughness = .87
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		material.alpha_scissor_threshold = .5
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		material.uv1_scale = Vector3(float(region[1]-region[0])/image.get_width(),float(used.size.y)/image.get_height(),1)
		material.uv1_offset = Vector3(float(region[0])/image.get_width(),float(used.position.y)/image.get_height(),0)
		var plane := QuadMesh.new()
		plane.size = Vector2(region[3],3.3)
		var surface := MeshInstance3D.new()
		surface.name = "StorefrontArtwork"
		surface.mesh = plane
		surface.material_override = material
		surface.position = Vector3(region[2],1.65,7.67)
		_detail_parent.add_child(surface)
