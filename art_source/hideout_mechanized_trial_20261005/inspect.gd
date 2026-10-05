extends SceneTree
func _initialize():
 call_deferred("run")
func run():
 for folder in ["concrete","furniture","polyhaven/steel_frame_shelves_01","polyhaven/metal_tool_chest"]:
  for file in DirAccess.get_files_at("res://"+folder):
   if not (file.ends_with(".glb") or file.ends_with(".gltf")):continue
   var node=load("res://"+folder+"/"+file).instantiate()
   root.add_child(node)
   var bounds=AABB()
   var first=true
   for mesh in node.find_children("*","MeshInstance3D",true,false):
    var box=mesh.global_transform*mesh.get_aabb()
    bounds=box if first else bounds.merge(box)
    first=false
   print(file, " BOUNDS ",bounds)
   node.free()
 quit()
