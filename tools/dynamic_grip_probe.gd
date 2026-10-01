extends Node3D
var failures: Array[String] = []
var errors := Vector2.ZERO
func _ready() -> void:
 run.call_deferred()
func run() -> void:
 get_tree().root.size=Vector2i(1600,1000)
 var environment := WorldEnvironment.new()
 environment.environment=RenderProfile.create_environment(Color("1d2530"))
 add_child(environment)
 var light := DirectionalLight3D.new()
 light.rotation_degrees=Vector3(-35,-30,0)
 light.light_energy=2.0
 add_child(light)
 var fill := OmniLight3D.new()
 fill.position=Vector3(-1,2,-2)
 fill.light_energy=2.0
 add_child(fill)
 var camera := Camera3D.new()
 camera.position=Vector3(-1,1.5,-1.5)
 camera.fov=42
 add_child(camera)
 var right_detail:= "--right-hand-detail" in OS.get_cmdline_user_args()
 if right_detail:
  camera.position=Vector3(.85,1.3,-.7)
  camera.fov=38
 camera.look_at(Vector3(.08,1.24,-.1) if right_detail else Vector3(0,1.22,-.25))
 camera.current=true
 var player: PlayerController=load("res://scenes/player/player.tscn").instantiate()
 player.preview_mode=true
 add_child(player)
 for tick in 4: await get_tree().physics_frame
 player.set_process(false)
 player.set_physics_process(false)
 var contact=preload("res://scripts/presentation/bunny_master/rifle_contact.gd")
 var hands:=player.character_skeleton.get_node("BunnyGunHands") as SkeletonModifier3D
 hands.modification_processed.connect(func():
  var sk:=player.character_skeleton
  errors=Vector2(sk.to_global(contact.palm(sk,"Right")).distance_to(player.combat_rig.right_hand_target.global_position),sk.to_global(contact.palm(sk,"Left")).distance_to(player.combat_rig.left_hand_target.global_position))
 )
 for id in ModernArsenal.WEAPON_IDS:
  player.equip_weapon(ContentDB.get_weapon(id))
  for state in ["Idle","Walk","Reload","Dodge"]:
   player.body_visual.scale=Vector3(.9,1.06,.9) if state=="Dodge" else Vector3.ONE
   player.locomotion_playback.travel("Walk" if state=="Reload" else state)
   if state=="Reload": player.combat_rig.start_reload()
   for tick in (60 if state=="Reload" else 18):
    player.animation_tree.advance(1./60.)
    player.animation_source_skeleton.advance(1./60.)
    player.combat_rig.update_pose(Vector3(0,1.25,-20),Vector3.FORWARD,1. if state=="Dodge" else 0.,1./60.,false)
    var positions: Array[Vector3]=[]
    for bone in player.character_skeleton.get_bone_count(): positions.append(player.character_skeleton.get_bone_pose_position(bone))
    player.combat_rig.apply_skeleton_ik(1./60.)
    for bone in player.character_skeleton.get_bone_count():
     if player.character_skeleton.get_bone_pose_position(bone).distance_to(positions[bone])>.0001 or not player.character_skeleton.get_bone_global_pose(bone).basis.is_finite():
      failures.append("%s %s invalid/stretched %s"%[id,state,player.character_skeleton.get_bone_name(bone)])
    await get_tree().process_frame
    if errors.x>.015 or errors.y>.015:
     failures.append("%s %s tick %s contact %s"%[id,state,tick,errors]);break
    if id==&"weapon.assault_rifle_01" and tick==17 and DisplayServer.get_name()!="headless":
     await RenderingServer.frame_post_draw
     get_viewport().get_texture().get_image().save_png("/tmp/dynamic_m4_"+state.to_lower()+("_right" if right_detail else "")+".png")
   print("DYNAMIC_GRIP ",id," ",state," errors=",errors)
 if "--grip-fit-grid" in OS.get_cmdline_user_args():
  player.equip_weapon(ContentDB.get_weapon(&"weapon.assault_rifle_01"))
  player.body_visual.scale=Vector3.ONE
  player.locomotion_playback.travel("Idle")
  var primary: Vector3 = player.combat_rig.primary_grip.position
  var offsets: Array[Vector3]=[Vector3(0,.015,.04),Vector3(0,.015,.075),Vector3(0,0,.05),Vector3(0,.005,.09)]
  for variant in offsets.size():
   player.combat_rig.primary_grip.position=primary+offsets[variant]
   for tick in 18:
    player.animation_tree.advance(1./60.)
    player.animation_source_skeleton.advance(1./60.)
    player.combat_rig.update_pose(Vector3(0,1.25,-20),Vector3.FORWARD,0.,1./60.,false)
    player.combat_rig.apply_skeleton_ik(1./60.)
    await get_tree().process_frame
   await RenderingServer.frame_post_draw
   get_viewport().get_texture().get_image().save_png("/tmp/m4_grip_variant_%d.png"%variant)
 player.queue_free()
 await get_tree().process_frame
 AudioDirector.shutdown_for_test()
 print("DYNAMIC_GRIP_TEST failures=",failures)
 get_tree().quit(0 if failures.is_empty() else 1)
