extends Node3D
## Original sparse deciduous tree: tapered branches and instanced leaf geometry.
var canopy: Area3D
var rng := RandomNumberGenerator.new()
func build(seed_value: int) -> void:
 rng.seed=seed_value
 canopy=Area3D.new();canopy.name="CameraCanopy"
 canopy.collision_layer=4;canopy.collision_mask=0
 canopy.monitoring=false;canopy.monitorable=false
 add_child(canopy)
 var canopy_shape:=CollisionShape3D.new()
 var sphere:=SphereShape3D.new();sphere.radius=2.65
 canopy_shape.shape=sphere;canopy_shape.position=Vector3(0,3.15,0);canopy.add_child(canopy_shape)
 _branch(Vector3.ZERO,Vector3(.05,1.35,.03),.17,.11)
 _branch(Vector3(.05,1.35,.03),Vector3(-.08,2.55,0),.11,.07)
 _branch(Vector3(-.08,2.55,0),Vector3(.12,4.1,.05),.07,.015)
 var leaf_mesh:=_leaf_mesh()
 var multimesh:=MultiMesh.new()
 multimesh.transform_format=MultiMesh.TRANSFORM_3D;multimesh.use_colors=true
 multimesh.mesh=leaf_mesh;multimesh.instance_count=2100
 var leaves:=MultiMeshInstance3D.new();leaves.name="CanopyLeaves";leaves.multimesh=multimesh
 leaves.material_override=_leaf_material();canopy.add_child(leaves)
 for limb in range(7):
  var angle:=limb*TAU/7.+rng.randf_range(-.2,.2)
  var start:=Vector3(0,1.55+limb*.22,0)
  var tip:=Vector3(cos(angle)*1.35,2.7+limb*.13,sin(angle)*1.35)
  _branch(start,tip,.075,.018)
  for twig in 3:
   var end:=tip+Vector3(rng.randf_range(-.5,.5),rng.randf_range(.2,.7),rng.randf_range(-.5,.5))
   _branch(start.lerp(tip,.6),end,.022,.006)
  for index in 300:
   var offset:=Vector3(rng.randf_range(-1.,1.),rng.randf_range(-1.,1.),rng.randf_range(-1.,1.))
   while offset.length_squared()>1.:
    offset=Vector3(rng.randf_range(-1.,1.),rng.randf_range(-1.,1.),rng.randf_range(-1.,1.))
   var at:=tip+offset*Vector3(.82,.65,.82)
   var basis:=Basis.from_euler(Vector3(rng.randf_range(-1.,1.),rng.randf_range(0,TAU),rng.randf_range(-1.,1.)))
   basis=basis.scaled(Vector3.ONE*rng.randf_range(.7,1.3))
   var instance:=limb*300+index
   multimesh.set_instance_transform(instance,Transform3D(basis,at))
   multimesh.set_instance_color(instance,[Color("526047"),Color("64704f"),Color("79734c"),Color("536549")][rng.randi_range(0,3)].srgb_to_linear())
 var trunk:=StaticBody3D.new();trunk.name="TrunkCollision";trunk.collision_layer=4;trunk.collision_mask=0;add_child(trunk)
 var collision:=CollisionShape3D.new();var cylinder:=CylinderShape3D.new()
 cylinder.radius=.18;cylinder.height=2.6;collision.shape=cylinder;collision.position=Vector3(0,1.3,0);trunk.add_child(collision)
 # Fallen leaves lie above the courtyard paving, with no gameplay collision.
 var litter:=MultiMesh.new();litter.transform_format=MultiMesh.TRANSFORM_3D;litter.use_colors=true
 litter.mesh=leaf_mesh;litter.instance_count=130
 var litter_mesh:=MultiMeshInstance3D.new();litter_mesh.name="FallenLeaves";litter_mesh.multimesh=litter;litter_mesh.material_override=_leaf_material();add_child(litter_mesh)
 for index in 130:
  var angle:=rng.randf_range(0,TAU);var radius:=sqrt(rng.randf())*2.5
  var basis:=Basis(Vector3.UP,angle).scaled(Vector3.ONE*rng.randf_range(.55,.9))
  litter.set_instance_transform(index,Transform3D(basis,Vector3(cos(angle)*radius,.078+index*.00001,sin(angle)*radius)))
  litter.set_instance_color(index,[Color("81704c"),Color("655b3e"),Color("747047")][rng.randi_range(0,2)].srgb_to_linear())

func _branch(a: Vector3,b: Vector3,bottom: float,top: float) -> void:
 var mesh:=CylinderMesh.new();mesh.bottom_radius=bottom;mesh.top_radius=top;mesh.height=a.distance_to(b);mesh.radial_segments=8
 var instance:=MeshInstance3D.new();instance.name="TaperedBranch";instance.mesh=mesh
 instance.position=a.lerp(b,.5);instance.basis=Basis(Quaternion(Vector3.UP,a.direction_to(b)))
 instance.material_override=VisualFactory.material(Color("544b3c"),0,.98);canopy.add_child(instance)

func _leaf_mesh() -> ArrayMesh:
 var points:=PackedVector3Array([Vector3.ZERO,Vector3(-.065,.015,.11),Vector3(-.045,0,.21),Vector3(0,.012,.28),Vector3(.045,0,.21),Vector3(.065,-.008,.11)])
 var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 for triangle in [[0,1,2],[0,2,3],[0,3,4],[0,4,5]]:
  for index in triangle: st.add_vertex(points[index])
 st.generate_normals();return st.commit()

func _leaf_material() -> StandardMaterial3D:
 var mat:=VisualFactory.material(Color.WHITE,0,.98)
 mat.vertex_color_use_as_albedo=true;mat.cull_mode=BaseMaterial3D.CULL_DISABLED
 mat.backlight_enabled=true;mat.backlight=Color(.17,.2,.1)
 return mat
