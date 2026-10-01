extends StaticBody3D
## Original compact sedan mesh. Dimensions and collision use metres.
func build(paint: Color, damaged: bool) -> void:
 add_to_group("streets_vehicle")
 collision_layer=4
 collision_mask=0
 var metal := VisualFactory.material(paint,.3,.83)
 var glass := VisualFactory.material(Color("253131"),.25,.29)
 var rubber := VisualFactory.material(Color("232521"),0,.97)
 # Body loft: bonnet and boot taper toward the bumpers.
 var stations: Array[Vector3]=[Vector3(-2.05,.77,.71),Vector3(-1.05,.86,.88),Vector3(1.15,.86,.88),Vector3(2.05,.77,.76)]
 var faces: Array[PackedVector3Array]=[]
 for i in range(stations.size()-1):
  var a:=stations[i];var b:=stations[i+1]
  faces.append(PackedVector3Array([Vector3(-a.y,a.z,a.x),Vector3(a.y,a.z,a.x),Vector3(b.y,b.z,b.x),Vector3(-b.y,b.z,b.x)]))
  for side in [-1.,1.]: faces.append(PackedVector3Array([Vector3(side*a.y,.38,a.x),Vector3(side*b.y,.38,b.x),Vector3(side*b.y,b.z,b.x),Vector3(side*a.y,a.z,a.x)]))
 for station in [stations.front(),stations.back()]: faces.append(PackedVector3Array([Vector3(-station.y,.38,station.x),Vector3(station.y,.38,station.x),Vector3(station.y,station.z,station.x),Vector3(-station.y,station.z,station.x)]))
 _surface(faces,metal,"SedanBody")
 var cabin: Array[Vector3]=[Vector3(-.82,.80,.89),Vector3(-.32,.68,1.43),Vector3(.58,.68,1.43),Vector3(1.08,.80,.89)]
 faces=[]
 for i in range(cabin.size()-1):
  var a:=cabin[i];var b:=cabin[i+1]
  _surface([PackedVector3Array([Vector3(-a.y,a.z,a.x),Vector3(a.y,a.z,a.x),Vector3(b.y,b.z,b.x),Vector3(-b.y,b.z,b.x)])],metal if i==1 else glass,"Roof" if i==1 else "Windscreen")
 for side in [-1.,1.]:
  var points:=PackedVector3Array()
  for point in cabin: points.append(Vector3(side*(point.y+.005),point.z,point.x))
  _surface([points],glass,"SideWindows")
  _beam(Vector3(side*.81,.89,-.82),Vector3(side*.69,1.45,-.32),.045,metal,"APillar")
  _beam(Vector3(side*.81,.89,1.08),Vector3(side*.69,1.45,.58),.06,metal,"CPillar")
  _beam(Vector3(side*.805,.9,.15),Vector3(side*.69,1.45,.15),.055,metal,"BPillar")
  _beam(Vector3(side*.81,.89,-.82),Vector3(side*.81,.89,1.08),.045,metal,"WindowTrim")
  for z in [-.65,.25,1.13]: _part(Vector3(.008,.37,.018),Vector3(side*.863,.62,z),rubber,"DoorSeam")
  for z in [-.05,.91]: _part(Vector3(.035,.045,.14),Vector3(side*.882,.83,z),rubber,"DoorHandle")
  _part(Vector3(.16,.11,.20),Vector3(side*.93,1.04,-.60),metal,"Mirror")
  for z in [-1.28,1.28]:
   var tire:=VisualFactory.cylinder(self,.32,.20,Vector3(side*.85,.32,z),Color.WHITE,"Tire")
   tire.rotation.z=PI*.5;tire.material_override=rubber
   var hub:=VisualFactory.cylinder(self,.17,.022,Vector3(side*.96,.32,z),Color("7e8078"),"WheelHub")
   hub.rotation.z=PI*.5
   for spoke in range(5):
    var angle:=spoke*TAU/5.
    var bar:=_part(Vector3(.03,.035,.27),Vector3(side*.978,.32,z),rubber,"HubSlot")
    bar.rotation.x=angle
 for z in [-2.07,2.07]:
  _part(Vector3(1.58,.15,.12),Vector3(0,.45,z),rubber,"Bumper")
  _part(Vector3(.34,.12,.025),Vector3(0,.57,z+signf(z)*.065),VisualFactory.material(Color("9b9d8c")),"NumberPlate")
 for x in [-.55,.55]:
  _part(Vector3(.33,.15,.045),Vector3(x,.64,-2.067),VisualFactory.material(Color("bdbea8"),.1,.43),"Headlamp")
  _part(Vector3(.31,.14,.045),Vector3(x,.65,2.067),VisualFactory.material(Color("6c3931"),.1,.51),"TailLamp")
 _part(Vector3(.55,.14,.03),Vector3(0,.64,-2.083),rubber,"Grille")
 for x in [-.22,-.1,.02,.14,.26]: _part(Vector3(.018,.12,.015),Vector3(x,.64,-2.104),VisualFactory.material(Color("84887f")),"GrilleSlat")
 for z in [-.81,1.08]:
  var a:=Vector3(-.8,.89,z);var b:=Vector3(.8,.89,z)
  _beam(a,b,.025,metal,"WindowBase")
 if damaged:
  for side in [-1.,1.]:
   for n in 5:
    var patch:=_part(Vector3(.01,.08,.19),Vector3(side*.868,.46+n*.048,-.7+n*.31),VisualFactory.material(Color("654b36")),"RustPatch")
    patch.rotation.x=.2*n
  for n in 3: _beam(Vector3(-.42+n*.16,1.03,-.70),Vector3(.04+n*.13,1.35,-.38),.008,VisualFactory.material(Color("858e88")),"CrackedGlass")
 var collision:=CollisionShape3D.new()
 var shape:=ConvexPolygonShape3D.new()
 var hull:=PackedVector3Array()
 for station in stations:
  for side in [-1.,1.]:
   hull.append(Vector3(side*station.y,.08,station.x));hull.append(Vector3(side*station.y,station.z,station.x))
 for point in cabin:
  for side in [-1.,1.]: hull.append(Vector3(side*point.y,point.z,point.x))
 shape.points=hull;collision.shape=shape;add_child(collision)

func _part(size: Vector3,at: Vector3,mat: Material,title: String) -> MeshInstance3D:
 var mesh:=VisualFactory.box(self,size,at,Color.WHITE,title);mesh.material_override=mat;return mesh

func _beam(a: Vector3,b: Vector3,width: float,mat: Material,title: String) -> void:
 var mesh:=_part(Vector3(width,width,a.distance_to(b)),a.lerp(b,.5),mat,title)
 mesh.look_at(global_transform*b)

func _surface(faces: Array,mat: Material,title: String) -> void:
 var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 for face in faces:
  for index in [0,1,2,0,2,3]: st.add_vertex(face[index])
 st.generate_normals()
 var mesh:=MeshInstance3D.new();mesh.name=title;mesh.mesh=st.commit();mesh.material_override=mat
 # The loft has both side windings; disable culling for these thin panels.
 var panel_mat:=mat.duplicate() as StandardMaterial3D
 panel_mat.cull_mode=BaseMaterial3D.CULL_DISABLED
 mesh.material_override=panel_mat
 add_child(mesh)
