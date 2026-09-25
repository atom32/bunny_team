extends SceneTree
var player
var current_row: Dictionary
var samples: Array = []
var evidence := OS.get_environment("BUNNY_EVIDENCE")
var last_bones := {}
func _initialize():
 call_deferred("run")
func run():
 var world := Node3D.new()
 root.add_child(world)
 current_scene=world
 var env := Environment.new()
 env.background_mode=Environment.BG_COLOR
 env.background_color=Color(0.12,0.15,0.19)
 env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 env.ambient_light_color=Color.WHITE
 env.ambient_light_energy=0.65
 var we:=WorldEnvironment.new()
 we.environment=env
 world.add_child(we)
 var sun:=DirectionalLight3D.new()
 sun.rotation_degrees=Vector3(-35,-30,0)
 sun.light_energy=0.7
 world.add_child(sun)
 var cam:=Camera3D.new()
 world.add_child(cam)
 cam.position=Vector3(3,1.25,0) if OS.get_environment("BUNNY_SIDE")=="1" else Vector3(2.1,1.7,-3.2)
 cam.look_at(Vector3(0,0.8,-0.06))
 cam.projection=Camera3D.PROJECTION_ORTHOGONAL
 cam.size=1.9
 cam.current=true
 player=load("res://scenes/player/player.tscn").instantiate()
 player.preview_mode=false
 world.add_child(player)
 player.set_process(false)
 player.set_physics_process(false)
 player.animation_tree.active=false
 player.character_skeleton.skeleton_updated.connect(sample_modified)
 var rows:=[]
 var weapons: Array=JSON.parse_string(OS.get_environment("BUNNY_WEAPONS")) if not OS.get_environment("BUNNY_WEAPONS").is_empty() else ["Rifle","SMG","Rocket"]
 var states: Array=JSON.parse_string(OS.get_environment("BUNNY_STATES")) if not OS.get_environment("BUNNY_STATES").is_empty() else ["Idle_Gun","Walk","Run","Run_Shoot","Dodge","Reload","Recoil","Hit"]
 for weapon in weapons:
  var id: String={"Rifle":"weapon.assault_rifle_01","SMG":"weapon.smg_01","Rocket":"weapon.rocket_launcher_01"}[weapon]
  for state in states:
   player.equip_weapon(root.get_node("ContentDB").get_weapon(id))
   player.body_visual.transform=Transform3D.IDENTITY
   var clip_name: String=state if player.animation_player.has_animation(state) else "Idle_Gun"
   var clip_length: float=player.animation_player.get_animation(clip_name).length
   player.animation_player.play(clip_name)
   player.animation_player.seek(0,true)
   player.animation_player.pause()
   samples=[]
   last_bones={}
   current_row={"weapon":weapon,"state":state,"reload_visual_started":false,"max_hand_error_m":0.0,"max_bone_step_m":0.0,"nonfinite":false,"pose_selected":"","visual_result":"NOT REVIEWED","clip":clip_name,"clip_length":clip_length,"sampling":"explicit seek, fixed 60Hz source timestamps"}
   if state=="Reload":
    player.debug_reload_once()
    current_row.reload_visual_started=player.combat_rig.is_reloading()
   if state=="Hit":player.take_damage(1.0)
   var frame_count: int=maxi(72,ceili(clip_length*60)+1) if state in ["Idle_Gun","Walk","Run","Run_Shoot","Dodge"] else 72
   var capture_frames: Array[int]=[5,int(frame_count*0.33),int(frame_count*0.66),frame_count-2]
   current_row["frame_count"]=frame_count
   current_row["coverage"]= "full source clip" if state in ["Idle_Gun","Walk","Run","Run_Shoot","Dodge"] else "existing procedural response, 1.2 seconds"
   var strip:=Image.create(1280,180,false,Image.FORMAT_RGBA8)
   for frame in frame_count:
    if state in ["Run_Shoot","Recoil"] and frame in [4,22,40]:player._apply_weapon_recoil(Vector3.FORWARD)
    player.animation_player.seek(minf(float(frame)/60.0,clip_length),true)
    var dodge:=maxf(0,1.0-float(frame)/10.0) if state=="Dodge" else 0.0
    player.combat_rig.update_pose(Vector3(0,1.13,-20),Vector3.FORWARD,dodge,1.0/60.0,true)
    player.animation_source_skeleton.advance(1.0/60.0)
    player.combat_rig.apply_skeleton_ik(1.0/60.0)
    await create_timer(1.0/60.0).timeout
    if frame in capture_frames:
     await RenderingServer.frame_post_draw
     var im:=root.get_texture().get_image()
     if frame==capture_frames[1]:im.save_png(evidence+"/"+weapon+"_"+state+".png")
     im.resize(320,180)
     im.convert(Image.FORMAT_RGBA8)
     strip.blit_rect(im,Rect2i(0,0,320,180),Vector2i(capture_frames.find(frame)*320,0))
   strip.save_png(evidence+"/"+weapon+"_"+state+"_strip.png")
   current_row.samples=samples
   rows.append(current_row.duplicate(true))
   var f:=FileAccess.open(evidence+"/animation_matrix_raw.json",FileAccess.WRITE)
   f.store_string(JSON.stringify(rows,"\t"))
   print("CAPTURED ",weapon," ",state," error=",current_row.max_hand_error_m," step=",current_row.max_bone_step_m)
 print("ANIMATION_MATRIX_COLLECTED: visual review required")
 quit(0)
func sample_modified():
 if current_row.is_empty():return
 var sk: Skeleton3D=player.character_skeleton
 var max_step:=0.0
 for suffix in ["Hips","Head","LeftArm","LeftForeArm","LeftHand","RightArm","RightForeArm","RightHand","LeftFoot","RightFoot"]:
  var pos:=sk.get_bone_global_pose(sk.find_bone("Character1_"+suffix)).origin
  if not pos.is_finite():current_row.nonfinite=true
  if last_bones.has(suffix):max_step=maxf(max_step,pos.distance_to(last_bones[suffix]))
  last_bones[suffix]=pos
 var error:=maxf(player.combat_rig.get_hand_error(&"right"),player.combat_rig.get_hand_error(&"left"))
 current_row.max_hand_error_m=maxf(current_row.max_hand_error_m,error)
 current_row.max_bone_step_m=maxf(current_row.max_bone_step_m,max_step)
 current_row.pose_selected=player.combat_rig.selected_pose
 samples.append({"error_m":error,"bone_step_m":max_step,"pose":current_row.pose_selected})
