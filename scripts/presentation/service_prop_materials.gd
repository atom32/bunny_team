extends Node3D
## Approved service-prop palette multiplier; deliberately NOT a universal converter.
## Blender material metadata records the same linear base-color factor.
func _ready() -> void:
 var shared := {}
 for mesh in find_children("*", "MeshInstance3D", true, false):
  for i in mesh.mesh.get_surface_count():
   var source = mesh.get_active_material(i)
   if source is StandardMaterial3D and source.resource_name.begins_with("colormap"):
    if not shared.has(source):
     var material := source.duplicate() as StandardMaterial3D
     material.albedo_color = Color(0.26,0.30,0.32,1)
     material.roughness = 0.82
     material.metallic = 0.05
     shared[source] = material
    mesh.set_surface_override_material(i, shared[source])
