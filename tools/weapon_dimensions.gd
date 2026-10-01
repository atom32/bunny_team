extends Node3D
func _ready() -> void:
 for key in ["pistol","smg","assault_rifle","shotgun","sniper","lmg","rocket_launcher"]:
  var weapon: Node3D=load("res://scenes/weapons/"+key+".tscn").instantiate()
  add_child(weapon)
  var bounds := AABB()
  var initialized := false
  for mesh: MeshInstance3D in weapon.find_children("*","MeshInstance3D",true,false):
   if mesh.name=="MuzzleFlash": continue
   var box:=mesh.get_aabb()
   for corner in 8:
    var point: Vector3=weapon.to_local(mesh.to_global(box.get_endpoint(corner)))
    if not initialized:
     bounds=AABB(point,Vector3.ZERO);initialized=true
    else: bounds=bounds.expand(point)
  print("WEAPON_DIMENSIONS ",key," bounds=",bounds," length_m=",bounds.size.z)
  weapon.free()
 AudioDirector.shutdown_for_test()
 get_tree().quit()
