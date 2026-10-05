extends RefCounted
static func capture(tree: SceneTree, player: Node3D, folder: String, label: String):
 var original=load("res://assets/characters/unitychan_battle/battle_presentation.glb").instantiate()
 var materials: Dictionary={}
 for mesh in original.find_children("*","MeshInstance3D",true,false):
  if not mesh.mesh:continue
  for i in mesh.mesh.get_surface_count():
   var material=mesh.get_active_material(i)
   if material:materials[material.resource_name]=material
 var surfaces: Array=[]
 for mesh in player.find_children("*","MeshInstance3D",true,false):
  if not mesh.mesh:continue
  for i in mesh.mesh.get_surface_count():
   var material=mesh.get_active_material(i)
   if material and materials.has(material.resource_name):surfaces.append([mesh,i,material,materials[material.resource_name]])
 var sockets: Array=[]
 for name in ["Chest","Backpack"]:
  var node=player.find_child(name,true,false)
  sockets.append([node,node.transform])
 tree.paused=true
 var camera=tree.root.get_camera_3d()
 var record: Dictionary={"method":"paired frozen same production camera/lighting/pose; source materials + original socket frame vs integrated candidate","camera":str(camera.global_transform),"fov":camera.fov,"player":str(player.global_transform),"body":str(player.body_visual.global_transform)}
 for variant in ["before","after"]:
  for entry in surfaces:entry[0].set_surface_override_material(entry[1],entry[3] if variant=="before" else entry[2])
  for entry in sockets:entry[0].transform=Transform3D(Basis(Vector3.UP,PI),Vector3.ZERO)*entry[1] if variant=="before" else entry[1]
  for frame in 5:
   await tree.process_frame
   await RenderingServer.frame_post_draw
  var im=tree.root.get_texture().get_image()
  im.save_png(folder+"/"+label+"_"+variant+".png")
  if label=="hanger":im.get_region(Rect2i(570,220,150,180)).save_png(folder+"/"+label+"_"+variant+"_detail.png")
  assert(str(camera.global_transform)==record.camera)
  assert(str(player.global_transform)==record.player)
  assert(str(player.body_visual.global_transform)==record.body)
 var file=FileAccess.open(folder+"/"+label+"_pair.json",FileAccess.WRITE);file.store_string(JSON.stringify(record,"  "))
 original.free()
 tree.paused=false
