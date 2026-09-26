extends SceneTree
var dir := OS.get_environment("BUNNY_PHASE4B")
func _initialize():run.call_deferred()
func run():
 change_scene_to_file("res://scenes/hanger/hanger.tscn")
 await create_timer(1).timeout
 paused = true
 var report := {}
 for mesh in current_scene.preview_character.find_children("*","MeshInstance3D",true,false):
  if not mesh.mesh:continue
  var mat=mesh.get_active_material(0)
  if mat is ShaderMaterial and mat.resource_name.begins_with("Battle"):
   report[mat.resource_name]={}
   for name in ["base_color","shade1_color","bound_game_lights","base_texture","grade_texture"]:report[mat.resource_name][name]=str(mat.get_shader_parameter(name))
 var ls=current_scene.find_children("*","Light3D",true,false)
 for mode in ["all","directional","spot","none"]:
  for light in ls:light.visible=mode=="all" or (mode=="directional" and light is DirectionalLight3D) or (mode=="spot" and light is SpotLight3D)
  for i in 4:await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(dir.path_join("rejected_multilight_trial/"+mode+".png"))
 report["lights"]=ls.size()
 var f=FileAccess.open(dir.path_join("rejected_multilight_trial/diagnostic.json"),FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "))
 root.get_node("AudioDirector").shutdown_for_test();quit()
