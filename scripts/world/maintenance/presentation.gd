class_name MaintenancePresentation
extends Node3D
## Render-only dressing. Authored collision, navigation and checkpoint facts stay put.
const SURFACES:={
 "floor":[preload("res://assets/environment/compact_hideout/concrete/Floor_ConcreteFloor_Color_2k.jpg"),preload("res://assets/environment/compact_hideout/concrete/Floor_ConcreteFloor_Normal_2k.jpg"),preload("res://assets/environment/compact_hideout/concrete/Floor_ConcreteFloor_Roughness_2k.png")],
 "wall":[preload("res://assets/environment/compact_hideout/concrete/Wall_ConcreteWall_Color_2k.png"),preload("res://assets/environment/compact_hideout/concrete/Wall_ConcreteWall_Normal_2k.png"),preload("res://assets/environment/compact_hideout/concrete/Wall_ConcreteWall_Roughness_2k.png")]
}
const RADIO=preload("res://assets/environment/compact_hideout/furniture/radio.glb")
const SCREEN=preload("res://assets/environment/kenney_space_station_kit/computer-system.glb")
const TOOLBOX=preload("res://assets/environment/compact_hideout/polyhaven/metal_toolbox/metal_toolbox.gltf")
const FLOOR_SHADER=preload("res://scripts/world/maintenance/painted_concrete.gdshader")
var area: Node3D
var materials:={}
var vapor: CPUParticles3D
var wheel: Node3D
var needle: Node3D
var lamps: Array[MeshInstance3D]=[]
var gate_meshes:={}
var last_phase:=-1

func material(color: Color,metal:=0.0,rough:=.8,glow:=0.0) -> StandardMaterial3D:
	var result:=StandardMaterial3D.new()
	result.albedo_color=color;result.metallic=metal;result.roughness=rough
	if glow>0:result.emission_enabled=true;result.emission=color;result.emission_energy_multiplier=glow
	return result

func concrete(color: Color,wall:=false) -> StandardMaterial3D:
	var result:=material(color)
	var maps: Array=SURFACES["wall" if wall else "floor"]
	result.albedo_texture=maps[0]
	result.normal_enabled=true;result.normal_scale=.65
	result.normal_texture=maps[1]
	result.roughness_texture=maps[2]
	result.uv1_triplanar=true;result.uv1_world_triplanar=true;result.uv1_scale=Vector3.ONE*.35
	return result

func floor_surface(color: Color,panel_size:=4.0) -> ShaderMaterial:
	var result:=ShaderMaterial.new();result.shader=FLOOR_SHADER
	result.set_shader_parameter("albedo_map",SURFACES.floor[0]);result.set_shader_parameter("normal_map",SURFACES.floor[1]);result.set_shader_parameter("roughness_map",SURFACES.floor[2])
	result.set_shader_parameter("tint",color);result.set_shader_parameter("panel_size",panel_size)
	return result

func mesh(name: String,shape: Mesh,at: Vector3,surface: Material,parent: Node3D=null,occluder:=false) -> MeshInstance3D:
	var node:=MeshInstance3D.new();node.name=name;node.mesh=shape;node.position=at;node.material_override=surface
	if not parent:parent=self
	parent.add_child(node)
	if occluder:node.add_to_group("camera_occluder")
	return node

func box(name: String,at: Vector3,size: Vector3,surface: Material,parent: Node3D=null,occluder:=false) -> MeshInstance3D:
	var shape:=BoxMesh.new();shape.size=size
	return mesh(name,shape,at,surface,parent,occluder)

func tube(name: String,at: Vector3,radius: float,length: float,surface: Material,parent: Node3D=null,along_z:=false) -> MeshInstance3D:
	var shape:=CylinderMesh.new();shape.top_radius=radius;shape.bottom_radius=radius;shape.height=length;shape.radial_segments=12
	var node:=mesh(name,shape,at,surface,parent)
	if along_z:node.rotation.x=PI/2
	return node

func stencil(name: String,at: Vector3,text: String,color: Color,size:=50) -> Label3D:
	var label:=Label3D.new();label.name=name;label.position=at;label.rotation.x=-PI/2
	label.font=UIFactory.FONT;label.font_size=size;label.pixel_size=.018;label.outline_size=0
	label.modulate=color;label.text=tr(text);label.no_depth_test=false;add_child(label)
	label.set_meta("translation_key",text)
	return label

func _translate() -> void:
	for node in get_children():
		if node is Label3D:node.text=tr(node.get_meta("translation_key"))

func fit_model(scene: PackedScene,name: String,at: Vector3,size: Vector3,parent: Node3D=null) -> Node3D:
	if not parent:parent=self
	var node:=scene.instantiate() as Node3D;node.name=name;parent.add_child(node)
	var bounds:=AABB()
	for child: MeshInstance3D in node.find_children("*","MeshInstance3D",true,false):
		child.add_to_group("camera_occluder")
		var bound:=node.global_transform.affine_inverse()*child.global_transform*child.get_aabb()
		bounds=bound if bounds.size==Vector3.ZERO else bounds.merge(bound)
	assert(bounds.size.x>0 and bounds.size.y>0 and bounds.size.z>0)
	node.scale=size/bounds.size
	node.position=at-(bounds.position+Vector3(bounds.size.x/2,0,bounds.size.z/2))*node.scale
	return node

func build(world: Node3D) -> void:
	area=world
	materials={"floor":floor_surface(Color("778783")),"ward_floor":floor_surface(Color("b4bdae"),2.0),"wall":concrete(Color("b7c3bc"),true),"ward":material(Color("d4d8c5")),"teal":material(Color("467c79"),.15),"dark":material(Color("263c40"),.4),"steel":material(Color("758a8c"),.75,.4),"orange":material(Color("d8a33f"),.1),"white":material(Color("e2e0c9")),"linen":material(Color("c4cbbb")),"blanket":material(Color("496f7b")),"red":material(Color("a44336"),.3),"lamp":material(Color("a6d7bb"),0,.5,.4)}
	area.get_node("Ground").material_override=materials.floor
	for node in area.get_children():
		if not node is MeshInstance3D:continue
		if String(node.name).begins_with("Wall") or String(node.name).begins_with("ChamberWall"):
			node.material_override=materials.wall
			var size: Vector3=node.mesh.size
			box(String(node.name)+"Cap",node.position+Vector3.UP*(size.y/2+.025),Vector3(size.x+.03,.05,size.z+.03),materials.teal if node.position.x>5 else materials.dark,self,true)
			# Lower band is inside the original wall footprint, not a new obstacle.
			box(String(node.name)+"Base",Vector3(node.position.x,.42,node.position.z),Vector3(size.x+.012,.84,size.z+.012),materials.dark,self,true)
	_floor_zones();_covers();_ward();_controls();_pipes();_steam()
	var environment: WorldEnvironment=area.get_node("Environment")
	environment.environment=environment.environment.duplicate()
	environment.environment.ambient_light_color=Color("b9d4d0");environment.environment.ambient_light_energy=.62
	var light: DirectionalLight3D=area.get_node("Light")
	light.light_color=Color("d6e1d7");light.light_energy=.85
	for entry in [[Vector3(-10,2.7,12),Color("e3ba7a"),9.0],[Vector3(15,2.8,-10),Color("b5d4bf"),10.0],[Vector3(0,2.7,-34),Color("9fd3c1"),8.0]]:
		var lamp:=OmniLight3D.new();lamp.position=entry[0];lamp.light_color=entry[1];lamp.omni_range=entry[2];lamp.light_energy=.65;lamp.shadow_enabled=false;add_child(lamp)
	GameLanguage.language_changed.connect(_translate)
	var steam: MaintenanceSteam=area.get_node("Steam")
	update_steam(steam.phase(),steam.cycle_time,steam.isolated())

func _floor_zones() -> void:
	box("WardFloor",Vector3(13.5,.012,-11),Vector3(14.25,.024,13.25),materials.ward_floor)
	box("ChamberFloor",Vector3(0,.018,-13.5),Vector3(7.3,.036,12.25),materials.dark)
	# Thin slats read as drainage, not cover. Share one draw surface per set.
	var slat:=BoxMesh.new();slat.size=Vector3(.55,.018,.045)
	var multi:=MultiMesh.new();multi.transform_format=MultiMesh.TRANSFORM_3D;multi.mesh=slat;multi.instance_count=80
	for i in 80:multi.set_instance_transform(i,Transform3D(Basis.IDENTITY,Vector3(-3.15 if i<40 else 3.15,.048,-19.2+(i%40)*.29)))
	var drains:=MultiMeshInstance3D.new();drains.name="DrainageSlats";drains.multimesh=multi;drains.material_override=materials.steel;add_child(drains)
	for z in [-9.6,-16.4]:
		for i in 14:
			var stripe:=box("HazardStripe",Vector3(-3.25+i*.5,.063,z),Vector3(.22,.016,.32),materials.dark)
			stripe.rotation.y=-.45
	for z in range(-36,24,4):
		if z< -7 and z> -20:continue
		box("WayfindingLine",Vector3(-1.2,.035,z),Vector3(.08,.025,3.2),materials.teal)
	for entry in [[Vector3(-10,.04,15),"01 / SERVICE"],[Vector3(14,.04,-1),"02 / WARD"],[Vector3(0,.04,-33),"03 / WAY OUT"]]:stencil("ZoneStencil",entry[0],entry[1],Color("c5d1ba"),48)
	stencil("WardStencil",Vector3(13.5,.04,-15.8),"L-02 / QUIET PLEASE",Color("517776"),36)
	stencil("SteamStencil",Vector3(0,.065,-8),"STEAM / WAIT BEHIND THE LINE",Color("d8b66c"),30)
	# Exit arrows are floor paint; do not add a collision or false objective.
	for z in [-35.0,-31.7,20.0]:
		for side in [-1,1]:
			var arrow:=box("ExitArrow",Vector3(side*.22,.045,z),Vector3(.08,.02,.68),materials.white);arrow.rotation.y=side*.65

func _covers() -> void:
	for i in 8:
		var old:=area.get_node("Cover"+str(i)) as MeshInstance3D
		old.material_override=materials.teal if i%2==0 else materials.dark
		var size: Vector3=old.mesh.size
		for side in [-1,1]:
			box("CabinetCorner",old.position+Vector3(side*(size.x/2-.06),0,0),Vector3(.09,size.y+.02,size.z+.02),materials.steel,self,true)
		box("CabinetTop",old.position+Vector3.UP*(size.y/2-.04),Vector3(size.x-.06,.07,size.z-.06),materials.steel)
		for y in [.4,.65,.9]:box("CabinetVent",Vector3(old.position.x,y,old.position.z+size.z/2+.008),Vector3(size.x*.62,.035,.012),materials.dark)
		box("CabinetTag",Vector3(old.position.x,1.13,old.position.z+size.z/2+.012),Vector3(.4,.16,.015),materials.orange)
	fit_model(TOOLBOX,"Toolbox",Vector3(-6,1.41,18),Vector3(.9,.35,.45))

func _ward() -> void:
	for i in 2:
		var bed:=area.get_node("Bed"+str(i)) as MeshInstance3D
		bed.material_override=materials.linen
		area.get_node("Pillow"+str(i)).material_override=materials.white
		var x:=10.0 if i==0 else 18.0
		box("BedBlanket",Vector3(x,.915,-12.45),Vector3(1.72,.055,2.15),materials.blanket)
		for z in [-14.6,-11.4]:
			box("BedEndRail",Vector3(x,.78,z),Vector3(1.8,.11,.08),materials.steel)
			for side in [-1,1]:tube("BedPost",Vector3(x+side*.84,.6,z),.055,1.15,materials.steel)
		for side in [-1,1]:box("BedSideRail",Vector3(x+side*.86,.83,-13),Vector3(.06,.08,3.35),materials.steel)
		box("BlanketFold",Vector3(x,.954,-13.45),Vector3(1.7,.04,.17),materials.teal)
	# A low bedside shelf stays within the existing bed collision volume.
	box("BedsideTray",Vector3(10,1.04,-11.65),Vector3(1.25,.05,.55),materials.ward)
	for x in [7.0,20.0]:
		box("WardWallBand",Vector3(x,1.15,-17.6),Vector3(1.1,.48,.035),materials.teal)
		box("WardLight",Vector3(x,2.55,-17.6),Vector3(.7,.1,.1),materials.lamp)
	area.get_node("WardSign").visible=false

func _controls() -> void:
	for entry in [["Bypass","01"],["WardControl","02"],["NorthControl","03"]]:
		var control:=area.get_node(entry[0]) as Node3D
		control.get_node("TerminalPedestal").material_override=materials.dark
		fit_model(SCREEN,String(entry[0])+"Terminal",control.position+Vector3(0,1.12,0),Vector3(.75,.45,.42))
		var lamp:=box("ControlStatus",control.position+Vector3(0,1.66,0),Vector3(.5,.065,.08),materials.lamp)
		lamps.append(lamp)
		control.get_node("WorldLabel").visible=false
	area.get_node("Radio/WorldLabel").visible=false
	fit_model(RADIO,"ArrivalRadio",area.get_node("Radio").position+Vector3(0,1.13,0),Vector3(.52,.36,.2))
	var valve: Node3D=area.get_node("SteamValve")
	valve.get_node("Pedestal").material_override=materials.dark;valve.get_node("Handle").visible=false
	wheel=Node3D.new();wheel.name="ValveWheel";wheel.position=valve.position+Vector3(0,1.3,.36);add_child(wheel)
	var ring:=TorusMesh.new();ring.inner_radius=.36;ring.outer_radius=.45;ring.rings=16;ring.ring_segments=8
	mesh("Rim",ring,Vector3.ZERO,materials.orange,wheel).rotation.x=PI/2
	for angle in [0.0,PI/2]:box("Spoke",Vector3.ZERO,Vector3(.85,.075,.075),materials.orange,wheel).rotation.z=angle
	valve.get_node("WorldLabel").visible=false
	stencil("ValveStencil",valve.position+Vector3(0,.05,1.15),"V / STEAM VALVE",Color("dec485"),32)
	var gauge:=tube("PressureGauge",valve.position+Vector3(0,1.98,.12),.24,.06,materials.white);gauge.rotation.x=PI/2
	needle=Node3D.new();needle.name="GaugeNeedle";needle.position=valve.position+Vector3(0,1.98,.17);add_child(needle)
	box("Needle",Vector3(.075,0,0),Vector3(.19,.025,.018),materials.red,needle)

func _pipes() -> void:
	for x in [-3.65,3.65]:
		tube("SupplyPipe",Vector3(x,2.5,-13.5),.14,12.5,materials.steel,self,true).add_to_group("camera_occluder")
		for z in [-8.5,-11.5,-14.5,-18.5]:
			tube("PipeCollar",Vector3(x,2.5,z),.19,.14,materials.dark,self,true).add_to_group("camera_occluder")
			box("PipeBracket",Vector3(x,2.5,z),Vector3(.3,.55,.12),materials.orange,self,true)
	for z in [-15,-13,-11]:
		for x in [-2.9,-1.45,0,1.45,2.9]:tube("FloorNozzle",Vector3(x,.045,z),.12,.09,materials.steel)
	for name in ["ServiceGate","WardGate","NorthGate"]:
		var gate: Node3D=area.get_node(name)
		var panel:=gate.get_node(name+"Panel") as MeshInstance3D
		panel.material_override=materials.teal
		var width: float=panel.mesh.size.x
		for i in 8:box("ShutterRib",Vector3(0,.2+i*.44,.37),Vector3(width-.04,.045,.06),materials.steel,gate,true)
		box("ShutterStripe",Vector3(0,.22,.375),Vector3(width-.04,.2,.035),materials.orange,gate,true)
		box("ShutterHousing",gate.position+Vector3.UP*3.65,Vector3(width+.4,.35,1),materials.dark,self,true)
		gate_meshes[name]=gate.find_children("*","MeshInstance3D",true,false)

func _steam() -> void:
	var jets: Node3D=area.get_node("Steam/Jets")
	for child in jets.get_children():child.visible=false
	var gradient:=Gradient.new();gradient.colors=PackedColorArray([Color(.78,.88,.89,.3),Color(.78,.88,.89,0)])
	var texture:=GradientTexture2D.new();texture.gradient=gradient;texture.width=64;texture.height=64;texture.fill=GradientTexture2D.FILL_RADIAL;texture.fill_from=Vector2(.5,.5);texture.fill_to=Vector2(1,.5)
	var surface:=StandardMaterial3D.new();surface.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;surface.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;surface.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED
	surface.albedo_texture=texture;surface.depth_draw_mode=BaseMaterial3D.DEPTH_DRAW_DISABLED;surface.cull_mode=BaseMaterial3D.CULL_DISABLED
	var quad:=QuadMesh.new();quad.size=Vector2(1.2,1.2)
	vapor=CPUParticles3D.new();vapor.name="SteamVapor";vapor.position=Vector3(0,.12,-13);vapor.mesh=quad;vapor.material_override=surface
	vapor.amount=96;vapor.lifetime=.65;vapor.preprocess=.2;vapor.use_fixed_seed=true;vapor.seed=42;vapor.local_coords=true
	vapor.emission_shape=CPUParticles3D.EMISSION_SHAPE_BOX;vapor.emission_box_extents=Vector3(3.2,.02,2.8)
	vapor.direction=Vector3.UP;vapor.spread=12;vapor.initial_velocity_min=1.8;vapor.initial_velocity_max=3.2;vapor.gravity=Vector3(0,.3,0)
	vapor.scale_amount_min=.65;vapor.scale_amount_max=1.1;vapor.emitting=false;jets.add_child(vapor)

func update_steam(phase: int,clock: float,off: bool) -> void:
	if not is_instance_valid(vapor):return
	if phase!=last_phase:
		vapor.emitting=phase==2
		if phase==2:vapor.restart()
		last_phase=phase
	wheel.rotation.z=-PI/2 if off else 0
	needle.rotation.z=0 if off else -.7+clock/MaintenanceSteam.PERIOD*2.1
	for i in lamps.size():
		var done:=MaintenanceStory.done(SortieRuntime.get_current_session(),MaintenanceStory.ORDER[i])
		lamps[i].material_override=materials.lamp if done else materials.orange
	for name in gate_meshes:
		var open:=MaintenanceStory.done(SortieRuntime.get_current_session(),area.GATES[name])
		for panel: MeshInstance3D in gate_meshes[name]:panel.visible=not open
