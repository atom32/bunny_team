extends "res://tools/local_rifle_review.gd"
## Controlled 12-source-clip review. Actual input/event coverage is a separate run.
func _run() -> void:
 if not FileAccess.file_exists("res://local_motion/library.tres"):
  push_error("Install combat12 into an isolated project first");get_tree().quit(2);return
 player=load("res://scenes/player/player.tscn").instantiate();player.preview_mode=true;add_child(player)
 player.set_process(false);player.set_physics_process(false)
 player.equip_weapon(ContentDB.get_weapon(&"weapon.assault_rifle_01"))
 check(player._combat12,"12 purchased source clips installed locally")
 var world:=WorldEnvironment.new();world.environment=Environment.new()
 world.environment.background_mode=Environment.BG_COLOR;world.environment.background_color=Color("a7adb3")
 world.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;world.environment.ambient_light_energy=.7;add_child(world)
 var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-30,-150,0);light.shadow_enabled=true;add_child(light)
 var fill:=OmniLight3D.new();fill.position=Vector3(0,2,-3);fill.light_energy=1.8;fill.omni_range=7;add_child(fill)
 var floor:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(20,20);floor.mesh=plane
 var mat:=StandardMaterial3D.new();mat.albedo_color=Color("707a85");mat.roughness=1;floor.material_override=mat;floor.position.y=-.015;add_child(floor)
 camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=2.5;camera.current=true;add_child(camera)
 var layer:=CanvasLayer.new();add_child(layer);label=Label.new();label.position=Vector2(24,20);label.add_theme_font_size_override("font_size",22);label.add_theme_color_override("font_color",Color.BLACK);layer.add_child(label)
 for i in player.character_skeleton.get_bone_count():rest_before.append(player.character_skeleton.get_bone_rest(i))
 var arm_drop:={"Left":0.0,"Right":0.0}

 player.character_skeleton.get_node("BunnyGunHands").modification_processed.connect(func():
  var sk=player.character_skeleton
  error.right=0 if player.combat_rig.free_right_weight>0 else sk.to_global(CONTACT.palm(sk,"Right")).distance_to(player.combat_rig.right_hand_target.global_position)
  error.left=0 if player.combat_rig.free_left_weight>0 else sk.to_global(CONTACT.palm(sk,"Left")).distance_to(player.combat_rig.left_hand_target.global_position)
  for side in ["Left","Right"]:
   arm_drop[side]=sk.get_bone_global_pose(sk.find_bone("Character1_"+side+"Arm")).origin.y-sk.get_bone_global_pose(sk.find_bone("Character1_"+side+"Hand")).origin.y
  for i in sk.get_bone_count():
   var parent:=sk.get_bone_parent(i)
   if parent>=0:max_length_error=maxf(max_length_error,absf(sk.get_bone_global_pose(i).origin.distance_to(sk.get_bone_global_pose(parent).origin)-sk.get_bone_rest(i).origin.length())))
 check(player.combat_rig.validate_visual_integrity(),"original heroine/outfit retained")
 for state in ["Idle","WalkRelaxed","Run","AimIdle","Walk","WalkBack","Shoot","Reload","Hit","Dodge","TakeGun","PutGun","Holstered","HolsteredWalk","HolsteredRun","WalkReload"]:

  var alias: String="Walk" if state=="WalkReload" else ("Run" if state=="HolsteredRun" else ("WalkRelaxed" if state=="HolsteredWalk" else ("PutGun" if state=="Holstered" else state)))
  var clip: Animation=player._local_library.get_animation(alias)
  var duration: float=clip.length
  if state=="Shoot":duration=.4
  if state=="Hit":duration=.65
  if state=="Dodge":duration=.55
  evidence.states[state]={"source":clip.get_meta("source_clip"),"max_right_error":0.0,"max_left_error":0.0,"min_foot_y":INF,"max_foot_y":-INF,"free_left_frames":0,"free_right_frames":0}
  check(clip.get_meta("source_license")=="UNVERIFIED LOCAL REVIEW ONLY","accurate local-only source provenance")
  for side in ["front","side","game"]:
   camera.size=2.5 if side!="game" else 19.5
   camera.position={"front":Vector3(.3,1.15,-4),"side":Vector3(4,1.3,0),"game":Vector3(0,18,13)}[side];camera.look_at(Vector3(0,.9,0));fill.position=camera.position+Vector3.UP*.3
   player.combat_rig._update_reload(100.0);player._cancel_holster();player._shoot_elapsed=10;player._hit_elapsed=10;player._evade_elapsed=10
   player.locomotion_playback.start("Walk" if state=="WalkReload" else ("Run" if state=="HolsteredRun" else ("WalkRelaxed" if state=="HolsteredWalk" else ("AimIdle" if state in ["Shoot","Hit"] else state))),true)
   if state in ["Reload","WalkReload"]:player.combat_rig.reload_duration=duration;player.combat_rig.start_reload()
   for tick in int(ceil(duration*60)):
    var t:=tick/60.0
    Input.action_release("precision_walk");player.velocity=Vector3.ZERO;player._dodge_time=0
    if state in ["Walk","WalkBack","WalkReload","AimIdle"]:Input.action_press("precision_walk")
    if state in ["Walk","WalkReload"]:player.velocity=Vector3.FORWARD*2
    if state=="WalkBack":player.velocity=Vector3.BACK*2
    if state in ["Run","HolsteredRun"]:player.velocity=Vector3.FORWARD*7.8
    if state in ["WalkRelaxed","HolsteredWalk"]:player.velocity=Vector3.FORWARD*1.5
    if state=="Shoot":player._shoot_elapsed=t
    if state=="Hit":player._hit_elapsed=t
    if state=="Dodge":player._dodge_time=.16-t;player._evade_elapsed=t;player._was_dodging=true
    if state in ["TakeGun","PutGun"]:player._switch_clip=state;player._switch_elapsed=t
    if state in ["Holstered","HolsteredWalk","HolsteredRun"]:player._holstered=true
    player.aim_direction=Vector3.FORWARD
    player._animate_stride(0)
    player.animation_tree.advance(1.0/60)
    player.combat_rig.update_pose(Vector3(0,1.25,-20),Vector3.FORWARD,player._dodge_time,1.0/60,true)
    player.animation_source_skeleton.advance(1.0/60);player.combat_rig.apply_skeleton_ik(1.0/60)
    await get_tree().process_frame
    if state in ["Holstered","HolsteredWalk","HolsteredRun"] and tick==int(duration*30):
     for arm in ["Left","Right"]:
      check(arm_drop[arm]>.25,"released "+arm+" arm recovers below shoulder rather than staying in transition T-pose: "+str(arm_drop[arm]))
    var d: Dictionary=evidence.states[state]
    d.max_right_error=maxf(d.max_right_error,error.right);d.max_left_error=maxf(d.max_left_error,error.left)
    if player.combat_rig.free_left_weight>0:d.free_left_frames+=1
    if player.combat_rig.free_right_weight>0:d.free_right_frames+=1
    for foot in ["Character1_LeftFoot","Character1_RightFoot"]:
     var at: Vector3=player.character_skeleton.to_global(player.character_skeleton.get_bone_global_pose(player.character_skeleton.find_bone(foot)).origin)
     d.min_foot_y=minf(d.min_foot_y,at.y);d.max_foot_y=maxf(d.max_foot_y,at.y)
    if DisplayServer.get_name()!="headless" and side in ["front","side"] and tick%5==0:
     label.text="LOCAL COMBAT 12 / "+state+" / "+String(clip.get_meta("source_clip"))+"\nOriginal heroine · controlled source pose, not gameplay footage"
     await RenderingServer.frame_post_draw
     get_viewport().get_texture().get_image().save_png(out.path_join("frame_%s_%s_%03d.png"%[state,side,tick]))
    if DisplayServer.get_name()!="headless" and tick==int(duration*30):
     await RenderingServer.frame_post_draw
     get_viewport().get_texture().get_image().save_png(out.path_join(state+"_"+side+".png"))
   check(evidence.states[state].max_right_error<.02 and evidence.states[state].max_left_error<.02,"contact phases reach actual targets throughout "+state)
 Input.action_release("precision_walk")
 check(max_length_error<.0001,"all 52 target bone lengths preserved")
 for i in rest_before.size():check(player.character_skeleton.get_bone_rest(i)==rest_before[i],"original rest unchanged")
 evidence["max_length_error"]=max_length_error;evidence["max_weapon_fit_offset"]=player.combat_rig.max_weapon_fit_offset;evidence["max_authored_reload_delta"]=player.combat_rig.max_authored_reload_delta
 evidence["failures"]=failures
 var f:=FileAccess.open(out.path_join("review.json"),FileAccess.WRITE);f.store_string(JSON.stringify(evidence,"\t"));f.close()
 player.queue_free();await get_tree().process_frame;AudioDirector.shutdown_for_test()
 print("LOCAL_COMBAT_REVIEW: %s failures=%s"%["PASS" if failures.is_empty() else "FAIL",failures]);get_tree().quit(0 if failures.is_empty() else 1)
