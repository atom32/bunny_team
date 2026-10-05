extends "res://spike/phase3a3_adapter.gd"
## Derivative-only material presentation; inherited pose/IK behavior unchanged.
const SURFACE=preload("res://spike/anime_surface.gdshader")
func setup(driver: Skeleton3D,target: Skeleton3D,retarget: RetargetModifier3D) -> void:
 super.setup(driver,target,retarget)
 _apply_materials.call_deferred()
 _apply_equipment_frames.call_deferred()
func _apply_materials():
 var profile: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://spike/material_profile.json"))
 var shared: Dictionary={}
 for mesh in display_skeleton.get_parent().find_children("*","MeshInstance3D",true,false):
  if not mesh.mesh:continue
  for surface in mesh.mesh.get_surface_count():
   var source=mesh.get_active_material(surface)
   if not source is StandardMaterial3D or not profile.has(source.resource_name):continue
   var key: String=source.resource_name
   if not shared.has(key):
    var material:=ShaderMaterial.new()
    material.resource_name=key
    material.shader=SURFACE
    material.set_shader_parameter("base_color",source.albedo_color)
    if source.albedo_texture:material.set_shader_parameter("base_texture",source.albedo_texture)
    for parameter in profile[key]:material.set_shader_parameter(parameter,profile[key][parameter])
    shared[key]=material
   mesh.set_surface_override_material(surface,shared[key])

func _apply_equipment_frames():
 var profile: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://spike/mount_profile.json"))
 for name in profile:
  var socket=display_skeleton.find_child(name,true,false)
  if socket and not socket.has_meta("unitychan_frame_corrected"):
   # Unity-chan torso local X/Z oppose the old-character equipment frame.
   # Rotate both offset and visual orientation; leave weapon/IK sockets alone.
   socket.transform=Transform3D(Basis(Vector3.UP,deg_to_rad(profile[name])),Vector3.ZERO)*socket.transform
   socket.set_meta("unitychan_frame_corrected",true)
