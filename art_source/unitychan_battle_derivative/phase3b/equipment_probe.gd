extends SceneTree
var folder:=OS.get_environment("BUNNY_EVIDENCE")
func _initialize():call_deferred("run")
func run():
 change_scene_to_file("res://scenes/hanger/hanger.tscn")
 await create_timer(1).timeout
 var player=current_scene.preview_character
 var report: Dictionary={"materials":[],"sockets":{}}
 for mesh in player.find_children("*","MeshInstance3D",true,false):
  if not mesh.mesh:continue
  for i in mesh.mesh.get_surface_count():
   var m=mesh.get_active_material(i)
   if m and m.resource_name.begins_with("Battle_"):report.materials.append({"mesh":str(mesh.get_path()),"name":m.resource_name,"type":m.get_class()})
 for name in ["Chest","ShoulderL","ShoulderR","Backpack","HipL","HipR","HandL","HandR"]:
  var socket=player.find_child(name,true,false)
  report.sockets[name]={"path":str(socket.get_path()),"position":str(socket.position),"basis":str(socket.basis),"body_local":str(player.body_visual.to_local(socket.global_position)),"body_relative_basis":str(player.body_visual.global_basis.inverse()*socket.global_basis),"children":[]}
  for child in socket.get_children():report.sockets[name].children.append({"name":child.name,"position":str(child.position),"scale":str(child.scale)})
 var perf: Array=[]
 for frame in 90:
  await process_frame
  await RenderingServer.frame_post_draw
  if frame>=30:perf.append({"process_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000.0,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"texture_memory_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),"video_memory_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)})
 report["performance"]={"scope":"entire Hanger production 1280x720 camera, not character-only GPU allocation; TIME_PROCESS is CPU process, not GPU time","samples":perf}
 var f:=FileAccess.open(folder+"/equipment.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "))
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(folder+"/hanger.png")
 player.set_process(false);player.set_physics_process(false);player.animation_tree.active=false;player.animation_player.pause()
 var production:=root.get_camera_3d()
 var camera:=Camera3D.new();current_scene.add_child(camera);camera.fov=35
 for direction in ["front","back","side"]:
  var offset: Vector3={"front":Vector3(0.8,1.1,-2.0),"back":Vector3(-0.8,1.1,2.0),"side":Vector3(2,1.1,0.0)}[direction]
  camera.global_position=player.global_position+player.body_visual.global_basis.orthonormalized()*offset
  camera.look_at(player.global_position+Vector3(0,0.85,0));camera.current=true
  for frame in 3:await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(folder+"/equipment_"+direction+".png")
 production.current=true
 root.get_node("AudioDirector").shutdown_for_test();quit(0)
