extends SceneTree
var folder:=OS.get_environment("BUNNY_EVIDENCE")
func _initialize():call_deferred("run")
func run():
 change_scene_to_file("res://scenes/hanger/hanger.tscn")
 await create_timer(3.0).timeout
 var samples: Array=[]
 var start:=Time.get_ticks_usec()
 var last:=start
 while Time.get_ticks_usec()-start<3000000:
  await process_frame
  await RenderingServer.frame_post_draw
  var now:=Time.get_ticks_usec()
  samples.append({"wall_frame_ms":float(now-last)/1000.0,"process_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000.0,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"texture_memory_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),"video_memory_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)})
  last=now
 var file:=FileAccess.open(folder+"/performance_warm.json",FileAccess.WRITE);file.store_string(JSON.stringify({"warmup_seconds":3,"sample_seconds":3,"scope":"whole Hanger, production 1280x720; wall-frame intervals not GPU timer, CPU monitor separate","samples":samples},"  "))
 await load("res://spike/paired_capture.gd").capture(self,current_scene.preview_character,folder,"hanger")
 root.get_node("AudioDirector").shutdown_for_test();quit(0)
