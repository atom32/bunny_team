extends Node3D
var player: PlayerController
var camera: Camera3D
var label: Label
var failures:=[]
var evidence:={"scope":"Controlled pose/weapon review, not normal play or human acceptance","states":{}}
var out:=OS.get_environment("BUNNY_EVIDENCE")
var error:={"right":0.0,"left":0.0}
var max_length_error:=0.0
var min_gaze_alignment:=1.0
var rest_before:=[]
const CONTACT=preload("res://scripts/presentation/bunny_master/rifle_contact.gd")
func check(ok: bool,message: String) -> void:
 if not ok:failures.append(message);push_error(message)
func _ready() -> void:_run.call_deferred()
func _run() -> void:
 if not FileAccess.file_exists("res://local_motion/library.tres"):
  push_error("Install the local-only trial in an isolated project first");get_tree().quit(2);return
 player=load("res://scenes/player/player.tscn").instantiate();player.preview_mode=true;add_child(player)
 player.set_process(false);player.set_physics_process(false)
 player.equip_weapon(ContentDB.get_weapon(&"weapon.assault_rifle_01"))
 var world:=WorldEnvironment.new();world.environment=Environment.new()
 world.environment.background_mode=Environment.BG_COLOR;world.environment.background_color=Color("a7adb3")
 world.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;world.environment.ambient_light_energy=.7;add_child(world)
 var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-30,-150,0);light.shadow_enabled=true;add_child(light)
 var fill:=OmniLight3D.new();fill.position=Vector3(0,2,-3);fill.light_energy=1.8;fill.omni_range=7;add_child(fill)
 var floor:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(20,20);floor.mesh=plane
 var mat:=StandardMaterial3D.new();mat.albedo_color=Color("707a85");mat.roughness=1;floor.material_override=mat;floor.position.y=-.015;add_child(floor)
 camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=2.25;camera.current=true;add_child(camera)
 var layer:=CanvasLayer.new();add_child(layer);label=Label.new();label.position=Vector2(24,20);label.add_theme_font_size_override("font_size",22);label.add_theme_color_override("font_color",Color.BLACK);layer.add_child(label)
 for i in player.character_skeleton.get_bone_count():rest_before.append(player.character_skeleton.get_bone_rest(i))
 var hands=player.character_skeleton.get_node("BunnyGunHands")
 hands.modification_processed.connect(func():
  var sk=player.character_skeleton
  error.right=sk.to_global(CONTACT.palm(sk,"Right")).distance_to(player.combat_rig.right_hand_target.global_position)
  error.left=sk.to_global(CONTACT.palm(sk,"Left")).distance_to(player.combat_rig.left_hand_target.global_position)
  min_gaze_alignment=minf(min_gaze_alignment,player.combat_rig.gaze.alignment)
  for i in sk.get_bone_count():
   var parent:=sk.get_bone_parent(i)
   if parent>=0:
    var length:=sk.get_bone_global_pose(i).origin.distance_to(sk.get_bone_global_pose(parent).origin)
    max_length_error=maxf(max_length_error,absf(length-sk.get_bone_rest(i).origin.length())))
 check(player.combat_rig.validate_visual_integrity(),"original 52-bone heroine and outfit intact")
 for state in ["Idle","Walk","Reload","WalkReload"]:
  var clip:=player.animation_player.get_animation("Idle_Gun" if state=="Idle" else ("Walk" if state=="WalkReload" else state))
  evidence.states[state]={"source":clip.get_meta("source_clip"),"max_right_error":0.0,"max_left_error":0.0,"min_foot_y":INF,"max_foot_y":-INF}
  check(clip.get_meta("source_license")=="UNVERIFIED LOCAL REVIEW ONLY","motion carries accurate local-only provenance")
  for side in ["front","side","game"]:
   camera.size=2.5 if side!="game" else 19.5
   camera.position={"front":Vector3(.3,1.15,-4),"side":Vector3(4,1.3,0),"game":Vector3(0,18,13)}[side]
   camera.look_at(Vector3(0,.9,0))
   fill.position=camera.position+Vector3.UP*.3
   player.locomotion_playback.start("Walk" if state=="WalkReload" else state,true)
   if state in ["Reload","WalkReload"]:player.combat_rig.reload_duration=clip.length;player.combat_rig.start_reload()
   for tick in int(ceil(clip.length*60)):
    if state=="WalkReload":
     player.velocity=Vector3(0,0,-2);Input.action_press("precision_walk");player._animate_stride(1.0/60)
    else:player.velocity=Vector3.ZERO;Input.action_release("precision_walk")
    player.animation_tree.advance(1.0/60)
    player.combat_rig.update_pose(Vector3(0,1.25,-20),Vector3.FORWARD,0,1.0/60,true)
    player.animation_source_skeleton.advance(1.0/60);player.combat_rig.apply_skeleton_ik(1.0/60)
    await get_tree().process_frame
    var d: Dictionary=evidence.states[state]
    d.max_right_error=maxf(d.max_right_error,error.right);d.max_left_error=maxf(d.max_left_error,error.left)
    if error.left>.02 and not d.has("first_miss"):
     var sk=player.character_skeleton
     var positions:={}
     for bone in ["LeftArm","LeftForeArm","LeftHand","RightArm"]:
      positions[bone]=str(sk.to_global(sk.get_bone_global_pose(sk.find_bone("Character1_"+bone)).origin))
     d.first_miss={"tick":tick,"bones":positions,"goal":str(player.combat_rig.left_hand_target.global_position),"palm":str(sk.to_global(CONTACT.palm(sk,"Left"))),"offset":player.combat_rig.max_weapon_fit_offset}

    for foot in ["Character1_LeftFoot","Character1_RightFoot"]:
     var at: Vector3=player.character_skeleton.to_global(player.character_skeleton.get_bone_global_pose(player.character_skeleton.find_bone(foot)).origin)
     d.min_foot_y=minf(d.min_foot_y,at.y);d.max_foot_y=maxf(d.max_foot_y,at.y)
    if side in ["front","side"] and tick%5==0 and DisplayServer.get_name()!="headless":
     label.text="LOCAL MOTION TRIAL  /  "+state+"  /  "+String(clip.get_meta("source_clip"))+(" + Rifle_Reload" if state=="WalkReload" else "")+"\nOriginal heroine · source motion + contact adaptation · local only"
     await RenderingServer.frame_post_draw
     get_viewport().get_texture().get_image().save_png(out.path_join("frame_%s_%s_%03d.png"%[state,side,tick]))
    if tick==int(clip.length*30):
     label.text="LOCAL MOTION TRIAL  /  "+state+"  /  "+String(clip.get_meta("source_clip"))+(" + Rifle_Reload" if state=="WalkReload" else "")+"\nOriginal heroine · same weapon · local only · "+side
     if DisplayServer.get_name()!="headless":
      await RenderingServer.frame_post_draw
      get_viewport().get_texture().get_image().save_png(out.path_join(state+"_"+side+".png"))
   check(evidence.states[state].max_right_error<.02 and evidence.states[state].max_left_error<.02,"both palms reach actual weapon/animated hand targets throughout "+state)
 check(min_gaze_alignment>.99,"rest-relative gaze follows actual aim rather than bowing at the feet")
 evidence["min_gaze_alignment"]=min_gaze_alignment
 check(max_length_error<.0001,"contact solve preserves all target bone lengths")
 for i in rest_before.size():check(player.character_skeleton.get_bone_rest(i)==rest_before[i],"original rest transform unchanged")
 evidence["max_length_error"]=max_length_error
 evidence["max_weapon_fit_offset"]=player.combat_rig.max_weapon_fit_offset
 evidence["max_authored_reload_delta"]=player.combat_rig.max_authored_reload_delta
 check(evidence.max_authored_reload_delta>.05,"actual source reload hand trajectory contributes more than five centimeters")
 evidence["failures"]=failures
 var f:=FileAccess.open(out.path_join("review.json"),FileAccess.WRITE);f.store_string(JSON.stringify(evidence,"\t"));f.close()
 player.queue_free();await get_tree().process_frame;AudioDirector.shutdown_for_test()
 print("LOCAL_RIFLE_REVIEW: %s failures=%s"%["PASS" if failures.is_empty() else "FAIL",failures]);get_tree().quit(0 if failures.is_empty() else 1)
