extends SceneTree
func _initialize():
 call_deferred("run")
func run():
 var folder=OS.get_environment("BUNNY_EVIDENCE")
 var world=Node3D.new()
 root.add_child(world)
 var env=Environment.new()
 env.background_mode=Environment.BG_COLOR
 env.background_color=Color(0.12,0.15,0.19)
 env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 env.ambient_light_color=Color.WHITE
 env.ambient_light_energy=0.65
 var we=WorldEnvironment.new()
 we.environment=env
 world.add_child(we)
 var sun=DirectionalLight3D.new()
 sun.rotation_degrees=Vector3(-35,-30,0)
 sun.light_energy=0.7
 world.add_child(sun)
 var cam=Camera3D.new()
 world.add_child(cam)
 cam.projection=Camera3D.PROJECTION_ORTHOGONAL
 cam.size=1.1
 cam.current=true
 for weapon in ["Rifle","SMG","Rocket"]:
  var doc=GLTFDocument.new()
  var state=GLTFState.new()
  var err=doc.append_from_file(folder+"/Pose_"+weapon+".glb",state)
  if err!=OK:
   push_error("GLB load failed "+str(err))
   quit(2)
   return
  var model=doc.generate_scene(state)
  world.add_child(model)
  for view in ["A_front","B_weapon","C_side","D_support","E_primary_close"]:
   cam.position={"A_front":Vector3(2,1.5,-3),"B_weapon":Vector3(3,1.35,-1.5),"C_side":Vector3(3,1.15,0),"D_support":Vector3(-3,1.35,-1.5),"E_primary_close":Vector3(3,1.2,-1)}[view]
   cam.size=0.45 if view=="E_primary_close" else 1.1
   cam.look_at(Vector3(0,1.02,-0.13))
   for i in 3:await process_frame
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png(folder+"/"+weapon+"_"+view+".png")
  model.free()
 var comparison=Image.create(3840,720,false,Image.FORMAT_RGBA8)
 var index=0
 for weapon in ["Rifle","SMG","Rocket"]:
  var source=Image.load_from_file(folder+"/"+weapon+"_A_front.png")
  source.convert(Image.FORMAT_RGBA8)
  comparison.blit_rect(source,Rect2i(0,0,1280,720),Vector2i(index*1280,0))
  index+=1
 comparison.save_png(folder+"/Comparison.png")
 print("EVIDENCE_CAPTURE_COMPLETE: not a visual acceptance test")
 quit(0)
