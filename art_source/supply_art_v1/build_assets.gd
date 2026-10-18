extends SceneTree
## Offline project-authored supply meshes. No gameplay mesh generation.
const OUT := "res://assets/props/supply_art_v1/"
const SCENES := "res://scenes/props/supply_art_v1/"
var materials: Dictionary={}
var parts: Dictionary={}
func _initialize() -> void: run.call_deferred()
func mesh_arrays(vertices: Array,normals: Array,uvs: Array,indices: Array) -> ArrayMesh:
	var data:=[];data.resize(Mesh.ARRAY_MAX)
	data[Mesh.ARRAY_VERTEX]=PackedVector3Array(vertices);data[Mesh.ARRAY_NORMAL]=PackedVector3Array(normals)
	data[Mesh.ARRAY_TEX_UV]=PackedVector2Array(uvs);data[Mesh.ARRAY_INDEX]=PackedInt32Array(indices)
	var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,data)
	return mesh
func metal(name: String,color: String,metallic: float,roughness: float) -> StandardMaterial3D:
	var mat:=StandardMaterial3D.new();mat.resource_name=name;mat.albedo_color=Color(color);mat.metallic=metallic;mat.roughness=roughness
	mat.take_over_path(OUT+name+".tres");assert(ResourceSaver.save(mat,OUT+name+".tres")==OK);materials[name]=mat;return mat
func add_mesh(parent: Node3D,name: String,mesh: Mesh,mat: Material,at:=Vector3.ZERO) -> MeshInstance3D:
	var node:=MeshInstance3D.new();node.name=name;node.mesh=mesh;node.material_override=mat;node.position=at;parent.add_child(node)
	return node
func revolve(parent: Node3D,name: String,profile: Array,at: Vector3,mat: Material,segments:=96) -> MeshInstance3D:
	var vertices:=[];var normals:=[];var uvs:=[];var indices:=[]
	for j in profile.size():
		var a: Vector2=profile[(j-1+profile.size())%profile.size()];var b: Vector2=profile[(j+1)%profile.size()]
		var delta: Vector2=(b-a).normalized()
		for i in segments+1:
			var angle:=TAU*i/segments;var p: Vector2=profile[j]
			vertices.append(Vector3(p.x*cos(angle),p.x*sin(angle),p.y));normals.append(Vector3(delta.y*cos(angle),delta.y*sin(angle),-delta.x))
			uvs.append(Vector2(float(i)/segments,float(j)/profile.size()))
	for j in profile.size():
		for i in segments:
			var a:=j*(segments+1)+i;var b:=((j+1)%profile.size())*(segments+1)+i
			indices.append_array([a,b,b+1,a,b+1,a+1])
	return add_mesh(parent,name,mesh_arrays(vertices,normals,uvs,indices),mat,at)
func bevel_box(parent: Node3D,name: String,size: Vector3,at: Vector3,mat: Material,bevel:=.003) -> MeshInstance3D:
	var vertices:=[];var normals:=[];var uvs:=[];var indices:=[]
	var inner: Vector3=size*.5-Vector3.ONE*bevel
	var axes: Array[Vector3]=[Vector3.RIGHT,Vector3.UP,Vector3.BACK]
	for face in 6:
		var axis:=face/2;var sign:=1.0 if face%2==0 else -1.0
		var normal: Vector3=axes[axis]*sign;var u: Vector3=axes[(axis+1)%3];var v: Vector3=axes[(axis+2)%3]
		var us:=[];var vs:=[]
		for value in [-1.0,-.92,-.707,-.38,0.0,.38,.707,.92,1.0]:
			us.append(signf(value)*inner[(axis+1)%3]+value*bevel if value!=0 else 0.0)
			vs.append(signf(value)*inner[(axis+2)%3]+value*bevel if value!=0 else 0.0)
		var start:=vertices.size()
		for j in vs.size():
			for i in us.size():
				var p: Vector3=normal*size[axis]*.5+u*us[i]+v*vs[j]
				var q:=p.clamp(-inner,inner);var n: Vector3=(p-q).normalized()
				vertices.append(q+n*bevel);normals.append(n);uvs.append(Vector2(float(i)/(us.size()-1),float(j)/(vs.size()-1)))
		for j in vs.size()-1:
			for i in us.size()-1:
				var a:=start+j*us.size()+i;var b:=a+us.size()
				if sign>0:indices.append_array([a,b,b+1,a,b+1,a+1])
				else:indices.append_array([a,b+1,b,a,a+1,b+1])
	return add_mesh(parent,name,mesh_arrays(vertices,normals,uvs,indices),mat,at)

func box(root: Node3D,name: String,size: Vector3,at: Vector3,mat: String,bevel:=.003) -> MeshInstance3D:
	return bevel_box(root,name,size,at,materials[mat],minf(bevel,minf(size.x,minf(size.y,size.z))*.35))
func cylinder(root: Node3D,name: String,radius: float,height: float,at: Vector3,mat: String) -> MeshInstance3D:
	var node:=revolve(root,name,[Vector2(.0001,0),Vector2(radius*.94,0),Vector2(radius,.002),Vector2(radius,height-.002),Vector2(radius*.94,height),Vector2(.0001,height)],at,materials[mat],64)
	node.rotation.x=-PI/2;return node
func text(root: Node3D,words: String,at: Vector3,size:=.00025,color:=Color("dedbcd"),rotate:=Vector3.ZERO) -> void:
	var node:=Label3D.new();node.name="Print"+str(root.get_child_count());node.text=words;node.font=load("res://resources/fonts/game_ui.tres");node.font_size=48;node.pixel_size=size;node.modulate=color;node.outline_size=0;node.position=at;node.rotation_degrees=rotate
	root.add_child(node)
func line(root: Node3D,name: String,a: Vector3,b: Vector3,width: float,mat: String) -> void:
	var node:=box(root,name,Vector3(width,width,a.distance_to(b)),(a+b)*.5,mat,width*.3)
	if a.distance_to(b)>.0001:node.look_at_from_position((a+b)*.5,b)
func tube(root: Node3D,name: String,path: Array,radius: float,mat: String,closed:=false) -> void:
	var vertices:=[];var normals:=[];var uvs:=[];var indices:=[]
	for i in path.size():
		var next: Vector3=path[(i+1)%path.size()] if closed or i<path.size()-1 else path[i]
		var prev: Vector3=path[(i-1+path.size())%path.size()] if closed or i>0 else path[i]
		var tangent: Vector3=(next-prev).normalized();var side:=tangent.cross(Vector3.UP if absf(tangent.y)<.9 else Vector3.RIGHT).normalized();var up:=tangent.cross(side)
		for j in 13:
			var angle:=TAU*j/12;var n:=side*cos(angle)+up*sin(angle)
			vertices.append(path[i]+n*radius);normals.append(n);uvs.append(Vector2(float(i)/path.size(),float(j)/12))
	for i in path.size() if closed else path.size()-1:
		for j in 12:
			var a:=i*13+j;var b:=((i+1)%path.size())*13+j;indices.append_array([a,b,b+1,a,b+1,a+1])
	add_mesh(root,name,mesh_arrays(vertices,normals,uvs,indices),materials[mat])
func ellipse(root: Node3D,name: String,center: Vector3,radii: Vector2,thickness: float,mat: String,vertical:=false) -> void:
	var path:=[]
	for i in 96:
		var a:=TAU*i/96;path.append(center+(Vector3(cos(a)*radii.x,sin(a)*radii.y,0) if vertical else Vector3(cos(a)*radii.x,0,sin(a)*radii.y)))
	tube(root,name,path,thickness,mat,true)
func seam(root: Node3D,y: float,z: float,width: float) -> void:
	for i in 26:box(root,"Stitch"+str(i),Vector3(.002,.0007,.0012),Vector3(-width*.45+i*width*.9/25,y,z),"thread",.0002)
func screws(root: Node3D,width: float,height: float,z: float) -> void:
	for x in [-1,1]:
		for y in [-1,1]:
			var at:=Vector3(x*width*.5,height*.5+y*height*.38,z)
			revolve(root,"Fastener",[Vector2(.0001,0),Vector2(.003,0),Vector2(.003,.0015),Vector2(.0001,.0015)],at,materials.steel,32)
			box(root,"ScrewSlot",Vector3(.003,.0006,.0003),at+Vector3(0,0,.0016),"rubber",.0001)
func save_asset(root: Node3D,name: String,id: String) -> void:
	root.set_meta("presentation_definition_id",id)
	# Batch static geometry by material: one mesh, few surfaces, no runtime builder.
	var groups: Dictionary={}
	for child in root.get_children():
		if child is MeshInstance3D:
			var key: String=child.material_override.resource_path
			if not groups.has(key):groups[key]=[]
			groups[key].append(child)
	var merged:=ArrayMesh.new()
	for key: String in groups:
		var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);st.set_material(load(key))
		for child: MeshInstance3D in groups[key]:st.append_from(child.mesh,0,child.transform)
		st.commit(merged)
	for child in root.get_children():
		if child is MeshInstance3D:child.free()
	merged.take_over_path(OUT+name+".res");assert(ResourceSaver.save(merged,OUT+name+".res")==OK)
	var visual:=MeshInstance3D.new();visual.name="Surface";visual.mesh=merged;root.add_child(visual)
	for child in root.get_children():child.owner=root
	var packed:=PackedScene.new();assert(packed.pack(root)==OK);assert(ResourceSaver.save(packed,SCENES+name+".tscn")==OK);root.free()
func packet(name: String,id: String,title: String,code: String,color: String,width: float,height: float) -> void:
	var root:=Node3D.new();root.name=name.to_pascal_case()
	var body:=box(root,"Foil",Vector3(width,height,.024),Vector3(0,height*.5,0),color,.01)
	# Light edge creases, not a perfect cardboard cube; center remains a clean print area.
	var arrays: Array=body.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	for i in verts.size():
		var p:=verts[i];var edge:=smoothstep(width*.22,width*.46,absf(p.x));p.z+=sin(p.y*430+p.x*60)*.0016*edge;verts[i]=p
	arrays[Mesh.ARRAY_VERTEX]=verts;body.mesh=ArrayMesh.new();body.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	for y in [.005,height-.005]:
		box(root,"HeatSeal",Vector3(width*.95,.009,.026),Vector3(0,y,0),color,.001)
		for i in 25:box(root,"Crimp",Vector3(.001,.007,.0005),Vector3(-width*.45+i*width*.9/24,y,.0135),"seal",.0001)
	box(root,"Label",Vector3(width*.78,height*.55,.0008),Vector3(0,height*.53,.013),"cream",.001)
	text(root,title,Vector3(0,height*.59,.014),width*.0012,Color("24332f"))
	text(root,code,Vector3(0,height*.32,.014),width*.00050,Color("415751"))
	box(root,"BrandBar",Vector3(width*.78,height*.045,.001),Vector3(0,height*.77,.014),"orange" if color=="food_green" else "cable_blue",.0002)
	for i in 22:box(root,"LotBarcode",Vector3(width*(.003 if i%3 else .008),height*.055,.0004),Vector3(-width*.18+i*width*.016,height*.19,.014),"webbing",.0001)
	for x in [-1,1]:box(root,"TearNotch",Vector3(.003,.005,.026),Vector3(x*width*.49,height*.85,0),"seal",.001)
	save_asset(root,name,id)
func medkit() -> void:
	var root:=Node3D.new();root.name="FieldMedkit"
	box(root,"PaddedNylon",Vector3(.24,.16,.105),Vector3(0,.085,0),"nylon",.018)
	box(root,"FrontPocket",Vector3(.205,.115,.021),Vector3(0,.077,.058),"nylon_light",.012)
	for side in [-1,1]:
		box(root,"Webbing",Vector3(.018,.135,.004),Vector3(side*.077,.08,.071),"webbing",.002)
		box(root,"Buckle",Vector3(.026,.027,.006),Vector3(side*.077,.033,.074),"rubber",.003)
		box(root,"BuckleOpen",Vector3(.013,.012,.002),Vector3(side*.077,.033,.078),"nylon_light",.002)
	box(root,"Patch",Vector3(.092,.058,.003),Vector3(0,.09,.071),"cream",.004)
	text(root,"B07 / MED",Vector3(0,.099,.073),.00018,Color("293f39"))
	text(root,"FIELD KIT",Vector3(0,.079,.073),.00011,Color("293f39"))
	ellipse(root,"CarryHandle",Vector3(0,.173,-.01),Vector2(.047,.025),.006,"webbing",true)
	box(root,"ZipperTrack",Vector3(.184,.006,.004),Vector3(0,.14,.069),"rubber",.002)
	for i in 36:box(root,"ZipTooth",Vector3(.0018,.003,.002),Vector3(-.085+i*.0048,.14,.072),"steel",.0003)
	ellipse(root,"ZipperPull",Vector3(.084,.132,.078),Vector2(.006,.012),.0012,"steel",true)
	seam(root,.018,.069,.19);seam(root,.128,.069,.19)
	save_asset(root,"medkit","medical.medkit")
func electronics() -> void:
	var root:=Node3D.new();root.name="CircuitBoard"
	box(root,"Substrate",Vector3(.17,.112,.004),Vector3(0,.061,0),"pcb",.002)
	for row in 4:
		box(root,"IC",Vector3(.031,.015,.005),Vector3(-.035,.032+row*.022,.005),"rubber",.001)
		for pin in 8:
			for side in [-1,1]:box(root,"Pin",Vector3(.001,.003,.001),Vector3(-.048+pin*.0037,.032+row*.022+side*.009,.005),"steel",.0002)
	for i in 10:
		var y:=.019+i*.009
		line(root,"TraceA",Vector3(.001,y,.0027),Vector3(.022,y,.0027),.0009,"copper")
		line(root,"TraceB",Vector3(.022,y,.0027),Vector3(.039,y+.012,.0027),.0009,"copper")
		line(root,"TraceC",Vector3(.039,y+.012,.0027),Vector3(.07,y+.012,.0027),.0009,"copper")
	for i in 5:box(root,"Socket",Vector3(.012,.012,.014),Vector3(.059,.025+i*.019,.009),"cream",.001)
	for i in 18:box(root,"GoldFinger",Vector3(.003,.008,.0005),Vector3(-.07+i*.008,.009,.0027),"gold",.0001)
	text(root,"B07 / CTRL",Vector3(0,.108,.005),.00007)
	save_asset(root,"electronics","material.electronics")
func wiring() -> void:
	var root:=Node3D.new();root.name="InsulatedCable"
	for wire in 3:
		var path:=[]
		for i in 225:
			var a:=TAU*3*i/224;path.append(Vector3(cos(a)*.061,.009+float(i)/224*.03+wire*.004,sin(a)*.045))
		tube(root,"Coil",path,.003,["rubber","cable_blue","orange"][wire])
	for side in [-1,1]:
		box(root,"Wrap",Vector3(.015,.045,.023),Vector3(side*.056,.029,0),"webbing",.002)
	box(root,"Connector",Vector3(.024,.018,.038),Vector3(.055,.018,.058),"rubber",.003)
	for i in 4:box(root,"Contact",Vector3(.003,.008,.004),Vector3(.047+i*.005,.018,.079),"gold",.0006)
	text(root,"INSULATED / 03",Vector3(0,.044,.024),.00010)
	save_asset(root,"wiring","material.wiring")
func parts_asset() -> void:
	var root:=Node3D.new();root.name="MechanicalParts"
	box(root,"Tray",Vector3(.20,.014,.135),Vector3(0,.007,0),"coating",.006)
	for x in [-1,1]:box(root,"Rim",Vector3(.006,.033,.135),Vector3(x*.098,.022,0),"coating",.002)
	for z in [-1,1]:box(root,"Rim",Vector3(.20,.033,.006),Vector3(0,.022,z*.065),"coating",.002)
	for i in 3:
		var at:=Vector3(-.054+i*.05,.021,0)
		cylinder(root,"Bearing",.022,.022,at,"steel");ellipse(root,"Race",at+Vector3(0,.023,0),Vector2(.016,.016),.002,"rubber")
		for tooth in 16:
			var a:=TAU*tooth/16;var n:=box(root,"GearTooth",Vector3(.006,.015,.008),at+Vector3(cos(a)*.023,.011,sin(a)*.023),"steel",.001);n.rotation.y=-a
	for i in 4:
		var at:=Vector3(-.07+i*.044,.022,.043);cylinder(root,"Bolt",.005,.025,at,"steel");cylinder(root,"Head",.009,.005,at+Vector3(0,.025,0),"steel")
	text(root,"SERVICE PARTS",Vector3(0,.023,.069),.00014)
	save_asset(root,"parts","material.parts")
func device(name: String,id: String,recorder: bool) -> void:
	var root:=Node3D.new();root.name=name.to_pascal_case()
	var w:=.19 if recorder else .105;var h:=.12 if recorder else .067
	box(root,"Chassis",Vector3(w,h,.037),Vector3(0,h*.5,0),"coating",.009)
	for side in [-1,1]:box(root,"ShockGuard",Vector3(.014,h+.005,.044),Vector3(side*(w*.5-.006),h*.5,0),"rubber",.004)
	box(root,"Face",Vector3(w*.77,h*.78,.003),Vector3(0,h*.5,.020),"steel",.003)
	if recorder:
		box(root,"Screen",Vector3(.095,.049,.002),Vector3(-.023,.074,.023),"screen",.002)
		text(root,"L-02 / LOG\nARCHIVE",Vector3(-.023,.074,.025),.00011,Color("b8d9cf"))
		for i in 3:cylinder(root,"Connector",.006,.012,Vector3(.052,.02+i*.028,.021),"rubber").rotation=Vector3(PI/2,0,0)
		text(root,"EXPERIMENT RECORDER",Vector3(0,.025,.024),.000095)
		box(root,"TamperSeal",Vector3(.023,.037,.001),Vector3(.075,.095,.024),"orange",.001)
	else:
		box(root,"SealedLabel",Vector3(.063,.036,.001),Vector3(0,h*.52,.023),"cream",.002)
		text(root,"SEALED\nDATA",Vector3(0,h*.52,.025),.00014,Color("263a3c"))
	screws(root,w*.7,h,.024);save_asset(root,name,id)
func misc() -> void:
	var root:=Node3D.new();root.name="BallisticFabric"
	for i in 5:box(root,"Fold",Vector3(.17,.012,.108),Vector3((i%2)*.003,.009+i*.011,0),"fabric",.005)
	box(root,"Strap",Vector3(.028,.063,.115),Vector3(.026,.032,0),"webbing",.003)
	box(root,"LotLabel",Vector3(.025,.0006,.066),Vector3(.026,.065,0),"cream",.0001)
	text(root,"B07\nFIBER",Vector3(.026,.066,0),.00010,Color("263a3c"),Vector3(-90,0,0));save_asset(root,"fabric","material.fabric")
	root=Node3D.new();root.name="MetalScrap"
	for i in 4:
		var plate:=box(root,"BentPlate",Vector3(.14-i*.014,.008,.09),Vector3((i%2)*.012,.008+i*.014,0),"scrap",.001);plate.rotation_degrees=Vector3(0,i*17-20,i*4)
	for i in 2:cylinder(root,"SalvagedTube",.014,.14,Vector3(-.07,.062,-.035+i*.045),"steel").rotation=Vector3(0,PI/2,0)
	save_asset(root,"scrap","material.scrap")
	root=Node3D.new();root.name="SealedIndustrialCanister"
	cylinder(root,"SealedBody",.047,.13,Vector3.ZERO,"coating");cylinder(root,"Cap",.026,.018,Vector3(0,.131,0),"rubber")
	for i in 2:ellipse(root,"Ridge",Vector3(0,.024+i*.073,0),Vector2(.047,.047),.002,"steel")
	box(root,"WarningLabel",Vector3(.063,.057,.001),Vector3(0,.078,.047),"orange",.002);text(root,"SEALED\nINDUSTRIAL",Vector3(0,.078,.049),.00012,Color("27343a"))
	save_asset(root,"propellant","material.propellant")
	root=Node3D.new();root.name="RecoveredCore"
	box(root,"Module",Vector3(.25,.17,.16),Vector3(0,.095,0),"coating",.012)
	for side in [-1,1]:
		for i in 9:box(root,"CoolingFin",Vector3(.018,.135,.006),Vector3(side*.126,.1,-.064+i*.016),"steel",.001)
	box(root,"FrontPanel",Vector3(.19,.12,.004),Vector3(0,.095,.082),"rubber",.004)
	for i in 3:cylinder(root,"Port",.015,.008,Vector3(-.055+i*.055,.09,.083),"steel").rotation=Vector3(PI/2,0,0)
	text(root,"RECOVERED / B07",Vector3(0,.135,.086),.00015);save_asset(root,"salvage_core","loot.salvage_core_01")
func can_asset(name: String,id: String,tall: bool) -> void:
	var root:=Node3D.new();root.name=name.to_pascal_case();var h:=.135 if tall else .094;var r:=.032 if tall else .044
	cylinder(root,"Aluminium",r,h,Vector3.ZERO,"steel")
	cylinder(root,"PrintedWrap",r+.0004,h*.76,Vector3(0,h*.10,0),"cable_blue" if tall else "food_green")
	for y in [.003,h-.003]:ellipse(root,"RolledRim",Vector3(0,y,0),Vector2(r,r),.0018,"steel")
	cylinder(root,"TopInset",r*.87,.001,Vector3(0,h,0),"coating")
	ellipse(root,"PullTab",Vector3(0,h+.003,-.004),Vector2(.008,.014),.002,"steel")
	text(root,"CITRUS\nSPARK" if tall else "FIELD\nBEANS",Vector3(0,h*.53,r+.0015),.00019,Color("eee4c8"))
	text(root,"B07 / 330" if tall else "B07 / FOOD",Vector3(0,h*.22,r+.0015),.00008)
	save_asset(root,name,id)
func bottle() -> void:
	var root:=Node3D.new();root.name="BottledWater"
	var profile: Array=[Vector2(.0001,0),Vector2(.022,0),Vector2(.029,.008),Vector2(.031,.025)]
	for i in 7:profile.append_array([Vector2(.031,.027+i*.013),Vector2(.029,.030+i*.013),Vector2(.031,.034+i*.013)])
	profile.append_array([Vector2(.029,.126),Vector2(.023,.143),Vector2(.012,.155),Vector2(.012,.17),Vector2(.0001,.17)])
	var body:=revolve(root,"PETBottle",profile,Vector3.ZERO,materials.pet,96);body.rotation.x=-PI/2
	cylinder(root,"Cap",.014,.018,Vector3(0,.165,0),"cable_blue")
	for i in 32:
		var a:=TAU*i/32;box(root,"CapRib",Vector3(.001,.014,.001),Vector3(cos(a)*.014,.175,sin(a)*.014),"cable_blue",.0002)
	cylinder(root,"LabelBand",.0313,.038,Vector3(0,.071,0),"cream")
	text(root,"B07\nWATER",Vector3(0,.09,.032),.00017,Color("285361"));save_asset(root,"bottled_water","supply.bottled_water")
func run() -> void:
	assert(OS.get_environment("BUNNY_ART_AUTHORING")=="isolated" and not ProjectSettings.globalize_path("res://").replace("\\","/").begins_with("D:/bunny_team"))
	DirAccess.make_dir_recursive_absolute(OUT);DirAccess.make_dir_recursive_absolute(SCENES)
	for row in [["coating","303d43",.42,.48],["steel","79858a",.78,.36],["rubber","1a2224",0,.88],["nylon","465b50",0,.91],["nylon_light","596b5c",0,.88],["webbing","293d36",0,.94],["thread","b3b49a",0,.95],["cream","d9d6bf",0,.82],["orange","b97942",0,.68],["seal","56665b",.12,.63],["pcb","285346",.08,.54],["copper","a9986b",.7,.4],["gold","b4a476",.78,.36],["cable_blue","3d6674",.05,.56],["fabric","677566",0,.95],["scrap","68706b",.66,.72],["food_green","5b6851",.18,.51],["pet","779ea4",.02,.26],["screen","233e42",.04,.31]]:
		metal(row[0],row[1],row[2],row[3])
	for name in ["nylon","nylon_light","webbing","fabric"]:
		var noise:=FastNoiseLite.new();noise.seed=71;noise.frequency=.16
		var grain:=NoiseTexture2D.new();grain.width=128;grain.height=128;grain.seamless=true;grain.as_normal_map=true;grain.bump_strength=.35;grain.noise=noise
		var mat: StandardMaterial3D=materials[name];mat.normal_enabled=true;mat.normal_texture=grain;mat.normal_scale=.16;mat.uv1_scale=Vector3(3,3,1);assert(ResourceSaver.save(mat,OUT+name+".tres")==OK)
	medkit();electronics();wiring();parts_asset();device("data_drive","material.data_drive",false);device("experiment_recorder","story.experiment_recorder",true);misc()
	packet("field_dressing","medical.field_dressing","FIELD\nDRESSING","B07 / STERILE PACK","cream",.105,.14)
	packet("field_ration","supply.field_ration","FIELD\nRATION","B07 / SEALED MEAL","food_green",.14,.19)
	packet("energy_bar","supply.energy_bar","OAT\nBAR","B07 / FOOD","orange",.13,.057)
	can_asset("canned_beans","supply.canned_beans",false);can_asset("citrus_drink","supply.citrus_drink",true);bottle()
	get_root().get_node("AudioDirector").shutdown_for_test();print("SUPPLY_ART_BUILD: PASS / 16 static authored props, batched by material");quit()
