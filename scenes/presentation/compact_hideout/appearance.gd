extends Node3D
## Instance-local tint for existing imported equipment panels. No model/character edits.
func _ready():
 for label in ["EntranceDoor","ServicePanel","EquipmentLocker"]:
  for mesh in get_node(label).find_children("*","MeshInstance3D",true,false):
   for i in mesh.mesh.get_surface_count():
    var original=mesh.get_active_material(i)
    if original is StandardMaterial3D:
     var mat=original.duplicate()
     mat.albedo_color=Color(.25,.30,.28,1)
     mat.roughness=.82
     mesh.set_surface_override_material(i,mat)
