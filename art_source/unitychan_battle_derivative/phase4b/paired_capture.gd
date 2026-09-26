extends RefCounted
## Evidence only: swap materials on a frozen production actor. Never change transforms,
## skeleton, equipment, lighting, gameplay, source images or persistent scene resources.
static func capture(tree:SceneTree, player:Node3D, folder:String, label:String):
 var dir := OS.get_environment("BUNNY_PHASE4B")
 var source_model = load("res://assets/characters/unitychan_battle/battle_presentation.glb").instantiate()
 var old_materials := {}
 var old_profile:Dictionary = JSON.parse_string(FileAccess.get_file_as_string(dir.path_join("before/material_profile.json")))
 for mesh in source_model.find_children("*","MeshInstance3D",true,false):
  if not mesh.mesh:continue
  for i in mesh.mesh.get_surface_count():
   var source = mesh.get_active_material(i)
   if not source or old_materials.has(source.resource_name):continue
   var mat = source
   if old_profile.has(source.resource_name):
    mat = ShaderMaterial.new()
    mat.shader = load(dir.path_join("before/anime_surface.gdshader"))
    mat.set_shader_parameter("base_color",source.albedo_color)
    if source.albedo_texture:mat.set_shader_parameter("base_texture",source.albedo_texture)
    for key in old_profile[source.resource_name]:mat.set_shader_parameter(key,old_profile[source.resource_name][key])
   old_materials[source.resource_name] = mat
 var surfaces := []
 for mesh in player.find_children("*","MeshInstance3D",true,false):
  if not mesh.mesh:continue
  for i in mesh.mesh.get_surface_count():
   var material = mesh.get_active_material(i)
   if material and old_materials.has(material.resource_name):surfaces.append([mesh,i,material,old_materials[material.resource_name]])
 var paused_before := tree.paused
 var head = player.find_child("head_Def",true,false)
 var skeleton:Skeleton3D = player.character_skeleton
 var bone := skeleton.find_bone("Character1_Head")
 var bind_index := -1
 for i in head.skin.get_bind_count():
  if head.skin.get_bind_name(i) == &"Character1_Head" or head.skin.get_bind_bone(i) == bone:bind_index=i
 assert(bind_index >= 0)
 # Read the FINAL modifier pose at skeleton_updated, before Godot restores the
 # unmodified pose. This is camera analysis, never a skeleton/mesh write.
 var final_skin := [Transform3D.IDENTITY]
 var sampled := [false]
 var observer := func():
  final_skin[0] = skeleton.global_transform * skeleton.get_bone_global_pose(bone) * head.skin.get_bind_pose(bind_index)
  sampled[0] = true
 skeleton.skeleton_updated.connect(observer)
 await tree.process_frame
 await RenderingServer.frame_post_draw
 skeleton.skeleton_updated.disconnect(observer)
 assert(sampled[0])
 tree.paused = true
 var production_camera = tree.root.get_camera_3d()
 var records := []
 var close_camera := Camera3D.new()
 player.add_child(close_camera)
 close_camera.fov = 32
 var target:Vector3 = final_skin[0] * head.get_aabb().get_center()
 var head_frame:Basis = final_skin[0].basis.orthonormalized()
 for view in ["production","front","three_quarter","side"]:
  if view == "production":production_camera.make_current()
  else:
   var offset:Vector3 = {"front":Vector3(0,.04,-.8),"three_quarter":Vector3(.55,.04,-.65),"side":Vector3(.8,.04,0)}[view]
   close_camera.global_position = target + head_frame * offset
   close_camera.look_at(target,head_frame.y)
   close_camera.make_current()
  var camera = tree.root.get_camera_3d()
  var record := {"view":view,"camera":str(camera.global_transform),"fov":camera.fov,"player":str(player.global_transform),"body":str(player.body_visual.global_transform),"surface_count":surfaces.size()}
  for variant in ["before","after"]:
   for row in surfaces:row[0].set_surface_override_material(row[1],row[3] if variant == "before" else row[2])
   for frame in 4:await RenderingServer.frame_post_draw
   tree.root.get_texture().get_image().save_png(folder.path_join(label+"_"+view+"_"+variant+".png"))
   assert(str(camera.global_transform)==record.camera)
   assert(str(player.global_transform)==record.player)
   assert(str(player.body_visual.global_transform)==record.body)
  records.append(record)
 production_camera.make_current()
 close_camera.queue_free()
 source_model.free()
 tree.paused = paused_before
 var file = FileAccess.open(folder.path_join(label+"_pair.json"),FileAccess.WRITE)
 file.store_string(JSON.stringify({"method":"frozen identical lighting/camera/pose; material-only old production vs reconstructed; diagnostic close-ups separate from production camera","views":records},"  "))
