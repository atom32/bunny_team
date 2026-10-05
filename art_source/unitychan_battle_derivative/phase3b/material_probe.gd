extends SceneTree
var folder:=OS.get_environment("BUNNY_EVIDENCE")
var originals: Dictionary={}
var meshes: Array=[]
func _initialize():call_deferred("run")
func run():
 change_scene_to_file("res://scenes/hanger/hanger.tscn")
 await create_timer(1.0).timeout
 var player=current_scene.preview_character
 player.set_process(false)
 player.set_physics_process(false)
 player.animation_tree.active=false
 player.animation_player.pause()
 var report: Array=[]
 for mesh in player.find_children("*","MeshInstance3D",true,false):
  if not mesh.mesh:continue
  for index in mesh.mesh.get_surface_count():
   var mat=mesh.get_active_material(index)
   if mat is StandardMaterial3D and mat.resource_name.begins_with("Battle_"):
    meshes.append([mesh,index,mat])
    if not originals.has(mat.resource_name):
     originals[mat.resource_name]=mat
     report.append({"name":mat.resource_name,"albedo":str(mat.albedo_color),"texture":mat.albedo_texture.resource_path if mat.albedo_texture else "none","specular":mat.metallic_specular,"roughness":mat.roughness,"metallic":mat.metallic,"emission_enabled":mat.emission_enabled,"emission":str(mat.emission),"shading_mode":mat.shading_mode,"diffuse_mode":mat.diffuse_mode,"override":mesh.material_override!=null})
 var file:=FileAccess.open(folder+"/materials_before.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(report,"  "))
 for variant in ["baseline","face_specular0","face_albedo075","face_albedo055","face_albedo035","face_albedo045","hair_specular0","hair_albedo075","hair_albedo055","hair_albedo035","combined045_055","face_toon","hair_toon","face_soft","hair_soft","combined_soft","zero_light_diagnostic","soft_no_ambient_diagnostic","ambient_only_diagnostic"]:
  for entry in meshes:
   var mat: StandardMaterial3D=entry[2].duplicate()
   var face: bool=mat.resource_name=="Battle_face3_main" or mat.resource_name=="Battle_Unity2016_C_Skin"
   var hair: bool=mat.resource_name=="Battle_Unity2016_C_Hair_Spow"
   if (face and variant.begins_with("face_")) or (hair and variant.begins_with("hair_")):
    if variant.ends_with("toon"):mat.diffuse_mode=BaseMaterial3D.DIFFUSE_TOON
    if variant.ends_with("specular0"):mat.metallic_specular=0
    if variant.ends_with("albedo075"):mat.albedo_color=Color(mat.albedo_color.r*0.75,mat.albedo_color.g*0.75,mat.albedo_color.b*0.75,1)
    if variant.ends_with("albedo055"):mat.albedo_color=Color(mat.albedo_color.r*0.55,mat.albedo_color.g*0.55,mat.albedo_color.b*0.55,1)
    if variant.ends_with("albedo035"):mat.albedo_color=Color(mat.albedo_color.r*0.35,mat.albedo_color.g*0.35,mat.albedo_color.b*0.35,1)
    if variant.ends_with("albedo045"):mat.albedo_color=Color(mat.albedo_color.r*0.45,mat.albedo_color.g*0.45,mat.albedo_color.b*0.45,1)
   if variant=="combined045_055" and (face or hair):
    var factor:=0.45 if face else 0.55
    mat.albedo_color=Color(mat.albedo_color.r*factor,mat.albedo_color.g*factor,mat.albedo_color.b*factor,1)
   var final_mat: Material=mat
   if (face and variant=="face_soft") or (hair and variant=="hair_soft") or ((face or hair) and variant in ["combined_soft","zero_light_diagnostic","soft_no_ambient_diagnostic","ambient_only_diagnostic"]):
    var soft:=ShaderMaterial.new()
    soft.shader=load("res://spike/zero_light_diagnostic.gdshader" if variant=="zero_light_diagnostic" else "res://spike/soft_diffuse_trial.gdshader")
    if variant in ["soft_no_ambient_diagnostic","ambient_only_diagnostic"]:soft.shader=load("res://spike/"+variant+".gdshader")
    soft.set_shader_parameter("base_color",mat.albedo_color)
    if mat.albedo_texture:soft.set_shader_parameter("base_texture",mat.albedo_texture)
    final_mat=soft
   entry[0].set_surface_override_material(entry[1],final_mat)
  await create_timer(0.5).timeout
  for frame in 3:
   await process_frame
   await RenderingServer.frame_post_draw
  var im:=root.get_texture().get_image()
  im.save_png(folder+"/"+variant+".png")
  im.get_region(Rect2i(570,220,150,180)).save_png(folder+"/"+variant+"_detail.png")
  print("CAPTURE ",variant)
 root.get_node("AudioDirector").shutdown_for_test()
 quit(0)
