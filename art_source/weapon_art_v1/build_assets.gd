extends SceneTree
## Offline, asset-specific hard-surface authoring. Run ONLY in isolated author copy.
## Saves native meshes/scenes; no geometry is generated during gameplay.
const OUT := "res://assets/weapons/art_pack_v1/"
const SCENES := "res://scenes/weapons/art_pack_v1/"
var materials: Dictionary={}
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
	if mesh.resource_path.is_empty():
		mesh.take_over_path(OUT+name+".res");assert(ResourceSaver.save(mesh,OUT+name+".res")==OK)
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
func bolt(parent: Node3D,name: String,at: Vector3,rotation:=Vector3.ZERO) -> void:
	var node:=revolve(parent,name,[Vector2(.003,0),Vector2(.0034,.0006),Vector2(.0034,.0018),Vector2(.002,.0024),Vector2(.0016,.0024),Vector2(.0016,.001),Vector2(.001,0)],at,materials.steel,32)
	node.rotation=rotation
func save_scene(root: Node3D,name: String) -> void:
	for node in root.find_children("*","",true,false):
		if node.owner==null:node.owner=root
	var scene:=PackedScene.new();assert(scene.pack(root)==OK);assert(ResourceSaver.save(scene,SCENES+name+".tscn")==OK);root.free()
func component_root(parents: Array,index: int) -> int:
	while parents[index]!=index:index=parents[index]
	return index
func magazine_reference() -> Dictionary:
	var original:=load("res://assets/weapons/mocap_m4/M4_Rifle_01.fbx").instantiate() as Node3D
	var source: ArrayMesh=original.get_node("M4").mesh
	var arrays: Array=source.surface_get_arrays(0);var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
	var used: Dictionary={};var verts:=[];var norms:=[];var uvs:=[];var tangents:=PackedFloat32Array();var output:=[]
	var selected:=[];var parents:=[];var touching: Dictionary={}
	for i in range(0,indices.size(),3):
		var c: Vector3=(arrays[Mesh.ARRAY_VERTEX][indices[i]]+arrays[Mesh.ARRAY_VERTEX][indices[i+1]]+arrays[Mesh.ARRAY_VERTEX][indices[i+2]])/3.0
		if c.y>.012 or c.z<.035 or c.z>.205:continue
		var triangle: Array=[indices[i],indices[i+1],indices[i+2]]
		var id:=selected.size();selected.append(triangle);parents.append(id)
		for vertex: int in triangle:
			var v: Vector3=arrays[Mesh.ARRAY_VERTEX][vertex];var key:=Vector3i(roundi(v.x*100000),roundi(v.y*100000),roundi(v.z*100000))
			if touching.has(key):parents[component_root(parents,id)]=component_root(parents,touching[key])
			else:touching[key]=id
	var groups: Dictionary={}
	for i in selected.size():
		var id:=component_root(parents,i)
		if not groups.has(id):groups[id]=[]
		groups[id].append_array(selected[i])
	var largest: Array=[]
	for group: Array in groups.values():
		if group.size()>largest.size():largest=group
	var bottom_center:=Vector3.ZERO;var bottom_normal:=Vector3.ZERO;var bottom_area:=0.0
	for i in range(0,largest.size(),3):
		var a: Vector3=arrays[Mesh.ARRAY_VERTEX][largest[i]];var b: Vector3=arrays[Mesh.ARRAY_VERTEX][largest[i+1]];var c: Vector3=arrays[Mesh.ARRAY_VERTEX][largest[i+2]]
		var cross: Vector3=(b-a).cross(c-a);var n:=cross.normalized();var center: Vector3=(a+b+c)/3.0
		if n.dot(arrays[Mesh.ARRAY_NORMAL][largest[i]])<0:n=-n
		if n.y<-.5 and center.y<-.07:
			bottom_center+=center*cross.length();bottom_normal+=n*cross.length();bottom_area+=cross.length()
		for k in 3:
			var old: int=largest[i+k]
			if not used.has(old):
				used[old]=verts.size();verts.append(arrays[Mesh.ARRAY_VERTEX][old]);norms.append(arrays[Mesh.ARRAY_NORMAL][old]);uvs.append(arrays[Mesh.ARRAY_TEX_UV][old])
				for t in 4:tangents.append(arrays[Mesh.ARRAY_TANGENT][old*4+t])
			output.append(used[old])
	var result:=[];result.resize(Mesh.ARRAY_MAX);result[Mesh.ARRAY_VERTEX]=PackedVector3Array(verts);result[Mesh.ARRAY_NORMAL]=PackedVector3Array(norms);result[Mesh.ARRAY_TEX_UV]=PackedVector2Array(uvs);result[Mesh.ARRAY_TANGENT]=tangents;result[Mesh.ARRAY_INDEX]=PackedInt32Array(output)
	var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,result);mesh.take_over_path(OUT+"existing_magazine_reference.res");assert(ResourceSaver.save(mesh,OUT+"existing_magazine_reference.res")==OK)
	assert(bottom_area>0)
	bottom_center/=bottom_area;bottom_normal=bottom_normal.normalized()
	bottom_center=Vector3(-bottom_center.x,bottom_center.y,-bottom_center.z);bottom_normal=Vector3(-bottom_normal.x,bottom_normal.y,-bottom_normal.z)
	print("MAGAZINE_REFERENCE vertices=",verts.size()," triangles=",output.size()/3," bottom=",bottom_center," normal=",bottom_normal)
	original.free()
	return {"position":bottom_center+bottom_normal*.006,"rotation":Quaternion(Vector3.DOWN,bottom_normal)}
func run() -> void:
	assert(OS.get_environment("BUNNY_ART_AUTHORING")=="isolated" and not ProjectSettings.globalize_path("res://").replace("\\","/").begins_with("D:/bunny_team"))
	DirAccess.make_dir_recursive_absolute(OUT);DirAccess.make_dir_recursive_absolute(SCENES)
	metal("coated_alloy","303c43",.42,.48);metal("polymer","3b4237",.02,.73);metal("rubber","171d20",0,.88);metal("steel","67737a",.78,.36);metal("brass","bba36a",.72,.39);metal("copper","956c46",.76,.4);metal("paper","71745c",0,.86);metal("label","d4cfb8",0,.82)
	var glass:=metal("optical_glass","335d65",.08,.16);glass.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;glass.albedo_color.a=.62;glass.cull_mode=BaseMaterial3D.CULL_DISABLED;assert(ResourceSaver.save(glass,OUT+"optical_glass.tres")==OK)
	var fit:=magazine_reference()
	var quick:=Node3D.new();quick.name="QuickloaderAdapter";quick.position=fit.position;quick.quaternion=fit.rotation
	bevel_box(quick,"MagazineBoot",Vector3(.039,.024,.079),Vector3.ZERO,materials.rubber,.005)
	bevel_box(quick,"BootInset",Vector3(.041,.008,.064),Vector3(0,-.008,0),materials.polymer,.002)
	var vertices:=[];var normals:=[];var uvs:=[];var indices:=[]
	for i in 65:
		var u:=TAU*i/64
		for j in 13:
			var v:=TAU*j/12;var n:=Vector3(cos(v),sin(v)*cos(u),sin(v)*sin(u))
			vertices.append(Vector3(0,-.031+.018*cos(u),.025*sin(u))+n*.004);normals.append(n);uvs.append(Vector2(float(i)/64,float(j)/12))
	for i in 64:
		for j in 12:
			var a:=i*13+j;var b:=a+13;indices.append_array([a,b+1,b,a,a+1,b+1])
	add_mesh(quick,"RubberPullLoop",mesh_arrays(vertices,normals,uvs,indices),materials.rubber)
	for side in [-1,1]:bevel_box(quick,"BootGrip"+str(side),Vector3(.003,.012,.036),Vector3(side*.020,0,0),materials.polymer,.001)
	save_scene(quick,"quickloader_adapter")
	var suppressor:=Node3D.new();suppressor.name="ReflexSuppressor"
	revolve(suppressor,"SuppressorShell",[Vector2(.018,-.163),Vector2(.022,-.160),Vector2(.023,-.155),Vector2(.023,-.018),Vector2(.026,-.010),Vector2(.026,0),Vector2(.012,0),Vector2(.012,-.150),Vector2(.007,-.158),Vector2(.007,-.163)],Vector3(0,.09,-.468),materials.coated_alloy)
	for j in 3:
		var z:=float(j)*.022-.122
		revolve(suppressor,"HeatBand"+str(j),[Vector2(.023,z-.004),Vector2(.024,z-.002),Vector2(.024,z+.002),Vector2(.023,z+.004)],Vector3(0,.09,-.468),materials.coated_alloy)
	revolve(suppressor,"MountCollar",[Vector2(.025,-.006),Vector2(.027,-.004),Vector2(.027,.004),Vector2(.024,.006)],Vector3(0,.09,-.468),materials.steel,64)
	save_scene(suppressor,"suppressor")
	var optic:=Node3D.new();optic.name="ObservationOptic"
	bevel_box(optic,"OpticRailAdapter",Vector3(.054,.014,.115),Vector3(0,.185,-.13),materials.steel,.003)
	for side in [-1,1]:bevel_box(optic,"MountLeg"+str(side),Vector3(.014,.027,.072),Vector3(side*.022,.202,-.13),materials.coated_alloy,.003)
	bevel_box(optic,"PrismHousing",Vector3(.065,.056,.115),Vector3(0,.237,-.13),materials.coated_alloy,.009)
	revolve(optic,"ObjectiveHood",[Vector2(.026,-.035),Vector2(.029,-.031),Vector2(.029,-.004),Vector2(.027,0),Vector2(.022,0),Vector2(.022,-.035)],Vector3(0,.238,-.19),materials.coated_alloy)
	revolve(optic,"OcularRing",[Vector2(.024,-.006),Vector2(.026,0),Vector2(.026,.018),Vector2(.022,.021),Vector2(.018,.021),Vector2(.018,-.006)],Vector3(0,.238,-.071),materials.rubber)
	for side in [-1,1]:
		var lens:=revolve(optic,"OpticalLens"+str(side),[Vector2(.0001,0),Vector2(.020,.001),Vector2(.020,.002),Vector2(.0001,.002)],Vector3(0,.238,-.218 if side<0 else -.052),glass,96);lens.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var turret:=revolve(optic,"ElevationDial",[Vector2(.010,0),Vector2(.012,.003),Vector2(.012,.011),Vector2(.010,.013),Vector2(.001,.013),Vector2(.001,0)],Vector3(0,.261,-.13),materials.coated_alloy,48);turret.rotation.x=-PI/2
	for side in [-1,1]:
		bolt(optic,"ClampScrew"+str(side),Vector3(side*.029,.196,-.13),Vector3(0,side*PI/2,0))
	for side in [-1,1]:
		bevel_box(optic,"ServiceCover"+str(side),Vector3(.002,.029,.074),Vector3(side*.033,.238,-.13),materials.polymer,.0008)
		for j in 2:bolt(optic,"CoverFastener"+str(side)+str(j),Vector3(side*.035,.238,-.157+j*.054),Vector3(0,side*PI/2,0))
	for child in optic.get_children():child.position.y-=.07
	save_scene(optic,"observation_optic")
	var magazine:=Node3D.new();magazine.name="QuickloaderMagazine"
	var reference:=MeshInstance3D.new();reference.name="ExistingMagazine";reference.mesh=load(OUT+"existing_magazine_reference.res");reference.rotation.y=PI;reference.material_override=load(OUT+"m4_finish.tres");magazine.add_child(reference)
	magazine.add_child(ResourceLoader.load(SCENES+"quickloader_adapter.tscn","",ResourceLoader.CACHE_MODE_REPLACE).instantiate());save_scene(magazine,"quickloader_magazine")
	var round:=Node3D.new();round.name="Standard556Reference";round.set_meta("presentation_definition_id","ammo.556_standard")
	revolve(round,"CartridgeCase",[Vector2(.0047,0),Vector2(.0047,.001),Vector2(.0042,.002),Vector2(.0042,.028),Vector2(.0034,.032),Vector2(.0029,.034),Vector2(.0029,.036),Vector2(.0001,.036),Vector2(.0001,0)],Vector3.ZERO,materials.brass,80)
	revolve(round,"ProjectileReference",[Vector2(.00288,.036),Vector2(.0029,.042),Vector2(.0025,.047),Vector2(.0018,.051),Vector2(.0008,.055),Vector2(.0001,.056),Vector2(.0001,.036)],Vector3.ZERO,materials.copper,80)
	save_scene(round,"ammo_556_round")
	var box:=Node3D.new();box.name="Standard556Box";box.set_meta("presentation_definition_id","ammo.556_standard")
	bevel_box(box,"AmmunitionCarton",Vector3(.105,.05,.072),Vector3(0,.025,0),materials.paper,.0015)
	bevel_box(box,"CartonLid",Vector3(.106,.003,.073),Vector3(0,.051,0),materials.paper,.0007)
	bevel_box(box,"PaperLabel",Vector3(.072,.0005,.044),Vector3(0,.053,0),materials.label,.0001)
	var label:=Label3D.new();label.name="ExistingCaliberLabel";label.text="5.56 STANDARD";label.font=load("res://resources/fonts/game_ui.tres")
	label.font_size=32;label.pixel_size=.00014;label.position=Vector3(0,.0535,0);label.rotation_degrees=Vector3(-90,0,0);label.modulate=Color("28332b");label.outline_size=0;box.add_child(label)
	bevel_box(box,"FrontPaperLabel",Vector3(.085,.032,.0005),Vector3(0,.026,.0366),materials.label,.0001)
	var front:=Label3D.new();front.name="ExistingAmmunitionLabel";front.text="5.56 STANDARD\nRIFLE AMMUNITION";front.font=label.font;front.font_size=32;front.pixel_size=.00013;front.position=Vector3(0,.026,.037);front.modulate=Color("28332b");front.outline_size=0;box.add_child(front)
	save_scene(box,"ammo_556_box")
	get_root().get_node("AudioDirector").shutdown_for_test();print("WEAPON_ART_BUILD: PASS / native meshes, original M4 geometry unchanged");quit()
