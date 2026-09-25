extends SceneTree
var player
var records: Array=[]
var label: String
var frame_index:=0
var folder:=OS.get_environment("BUNNY_EVIDENCE")
func _initialize():call_deferred("run")
func run():
 var world:=Node3D.new()
 root.add_child(world)
 current_scene=world
 var ground:=StaticBody3D.new()
 world.add_child(ground)
 var col:=CollisionShape3D.new()
 var box:=BoxShape3D.new()
 box.size=Vector3(200,1,200)
 col.shape=box
 col.position.y=-0.5
 ground.add_child(col)
 var env:=Environment.new()
 env.background_mode=Environment.BG_COLOR
 env.background_color=Color(0.12,0.15,0.19)
 env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 env.ambient_light_color=Color.WHITE
 env.ambient_light_energy=0.7
 var we:=WorldEnvironment.new()
 we.environment=env
 world.add_child(we)
 var sun:=DirectionalLight3D.new()
 sun.rotation_degrees=Vector3(-35,-30,0)
 world.add_child(sun)
 var cam:=Camera3D.new()
 world.add_child(cam)
 cam.projection=Camera3D.PROJECTION_ORTHOGONAL
 cam.size=2.0
 cam.current=true
 var report: Array=[]
 for weapon in ["Rifle","SMG","Rocket"]:
  label=weapon
  player=load("res://scenes/player/player.tscn").instantiate()
  world.add_child(player)
  var id: String={"Rifle":"weapon.assault_rifle_01","SMG":"weapon.smg_01","Rocket":"weapon.rocket_launcher_01"}[weapon]
  player.equip_weapon(root.get_node("ContentDB").get_weapon(id))
  player.character_skeleton.skeleton_updated.connect(sample)
  records=[]
  var strip:=Image.create(1600,180,false,Image.FORMAT_RGBA8)
  var aim_actions: Array = ["aim_down", "aim_right"] if OS.get_environment("BUNNY_FRONT")=="1" else ["aim_up"]
  for action in aim_actions:Input.action_press(action)
  for frame in 105:
   frame_index=frame
   cam.position=player.global_position+Vector3(3,1.4,-2)
   cam.look_at(player.global_position+Vector3(0,0.8,0))
   if frame==15:Input.action_press("move_forward")
   if frame==30:Input.action_press("dodge")
   if frame==31:Input.action_release("dodge")
   if frame==45:Input.action_release("move_forward")
   await physics_frame
   await process_frame
   if frame in [30,35,40,50,90]:
    await RenderingServer.frame_post_draw
    var im:=root.get_texture().get_image()
    im.save_png(folder+"/"+weapon+"_"+str(frame)+".png")
    im.resize(320,180)
    im.convert(Image.FORMAT_RGBA8)
    strip.blit_rect(im,Rect2i(0,0,320,180),Vector2i([30,35,40,50,90].find(frame)*320,0))
  strip.save_png(folder+"/"+weapon+"_live_dodge_strip.png")
  report.append({"weapon":weapon,"samples":records.duplicate(true),"final_state":String(player.locomotion_playback.get_current_node()),"final_scale":str(player.body_visual.scale)})
  for action in aim_actions:Input.action_release(action)
  player.queue_free()
  await process_frame
 var file:=FileAccess.open(folder+"/live_dodge.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(report,"\t"))
 print("LIVE_DODGE_CAPTURE_COMPLETE: real input, physics, AnimationTree; review required")
 root.get_node("AudioDirector").shutdown_for_test()
 quit(0)
func sample():
 if not is_instance_valid(player):return
 records.append({"frame":frame_index,"node":String(player.locomotion_playback.get_current_node()),"position":player.locomotion_playback.get_current_play_position(),"dodge_remaining":player._dodge_time,"right_error":player.combat_rig.get_hand_error(&"right"),"left_error":player.combat_rig.get_hand_error(&"left")})
