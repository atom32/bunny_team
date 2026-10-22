extends Node
## Controlled presentation fixture; actual earned-profile route is separate.
const CONTACT=preload("res://scripts/presentation/bunny_master/rifle_contact.gd")
var checks:=0
var failures: Array[String]=[]
var room: Node3D
var capture:=false
var contacts:=[]
func check(ok: bool,text: String) -> void:
 checks+=1
 if not ok:failures.append(text);push_error(text)
func _ready() -> void:_run.call_deferred()
func step(seconds: float) -> void:
 for i in int(seconds*60):room._process(1.0/60)
 await get_tree().process_frame
func click(button: Button) -> void:
 if DisplayServer.get_name()=="headless":button.pressed.emit()
 else:
  await RenderingServer.frame_post_draw
  for pressed in [true,false]:
   var event:=InputEventMouseButton.new();event.position=button.get_global_rect().get_center();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed
   get_tree().root.push_input(event);await get_tree().process_frame
 await get_tree().process_frame
func shot(name: String) -> void:
 if not capture:return
 await RenderingServer.frame_post_draw
 check(get_tree().root.get_texture().get_image().save_png(OS.get_environment("BUNNY_EVIDENCE").path_join(name+".png"))==OK,"capture "+name)
func _wait(path: String) -> bool:
 var until:=Time.get_ticks_msec()+15000
 while Time.get_ticks_msec()<until:
  await get_tree().process_frame
  if is_instance_valid(get_tree().current_scene) and get_tree().current_scene.scene_file_path==path and not GameState.is_transitioning():return true
 return false
func _run() -> void:
 capture="--capture" in OS.get_cmdline_user_args()
 GameLanguage.set_language("en" if "--english" in OS.get_cmdline_user_args() else "zh_CN",false)
 get_tree().current_scene=null
 var profile:=ProfileRuntime.new_profile()
 var before:=JSON.stringify(profile.to_dict())
 room=load("res://scenes/presentation/slice/seat_moment.tscn").instantiate();get_tree().root.add_child(room);get_tree().current_scene=room;room.set_process(false)
 check(not room.eligible and room.phase=="locked" and not room.choices.visible,"fresh profile cannot play unearned return story")
 await step(10);check(before==JSON.stringify(profile.to_dict()),"locked scene grants nothing")
 room.free();get_tree().current_scene=null
 # Explicit unit fixture, never claimed as earned progress.
 profile.first_mission_completed=true;profile.narrative_slice.settled.Q01=true;profile.narrative_slice.q01_exits.assign(["streets_exit_0","streets_exit_1"])
 var hub=load("res://scenes/presentation/slice/hideout.tscn").instantiate();get_tree().root.add_child(hub);get_tree().current_scene=hub;hub.show_section("Rest")
 await get_tree().process_frame
 check(hub.screen.find_child("OpenSeatMoment",true,false)!=null,"Q01-return profile gets optional Rest entry")
 before=JSON.stringify(profile.to_dict());var saved:=FileAccess.get_sha256(SaveService.DEFAULT_SAVE_PATH)
 await click(hub.screen.find_child("OpenSeatMoment",true,false))
 if not await _wait("res://scenes/presentation/slice/seat_moment.tscn"):check(false,"real entry button opens scene");_finish();return
 room=get_tree().current_scene;room.set_process(false)
 var sk: Skeleton3D=room.actor.character_skeleton
 var rests:=[];var positions:=[];var scales:=[]
 for i in sk.get_bone_count():rests.append(sk.get_bone_rest(i));positions.append(sk.get_bone_pose_position(i));scales.append(sk.get_bone_pose_scale(i))
 var length_error:=0.0
 for branch in ["stay","rise"]:
  var continuous:=true
  for tick in 1800:
   var old: Vector3=room.actor.position;room._process(1.0/60);continuous=continuous and old.distance_to(room.actor.position)<.06
   if room.phase=="intro":break
  check(continuous and room.phase=="intro" and room.motion.seated,"actor walks around bench and completes real seating")
  check(room.actor.preview_mode and not room.actor.is_physics_processing() and not room.actor.animation_tree.active and not room.actor.combat_rig.visible,"story owns only relaxed presentation, no live combat")
  await shot("01_arrived_"+branch)
  for i in room.INTRO.size():
   check(room.dialogue.get_combined_minimum_size().y<=room.dialogue.size.y,"intro text fits");await click(room.next_button)
  await step(5);check(room.phase=="choice","choice waits without inventing player decision")
  await click(room.choices.get_node("Choice"+branch.capitalize()))
  if branch=="rise":
   var low: float=sk.to_global(sk.get_bone_global_pose(sk.find_bone("Character1_Hips")).origin).y
   for tick in 600:
    room._process(1.0/60)
    if room.phase=="hesitate":break
   var high: float=sk.to_global(sk.get_bone_global_pose(sk.find_bone("Character1_Hips")).origin).y
   check(room.phase=="hesitate" and not room.motion.seated and high-low>.2,"help choice really stands up before being called back")
   await shot("02_wait")
   for i in room.HESITATE.size():await click(room.next_button)
   for tick in 600:
    room._process(1.0/60)
    if room.phase=="reach":break
   check(room.phase=="reach" and room.motion.seated,"reply leads through actual sitting entry, not teleport")
  var error:=0.0
  var left_error:=0.0
  for tick in 240:
   room._process(1.0/60)
   if room.reach_weight>.999:
    error=maxf(error,sk.to_global(CONTACT.palm(sk,"Right")).distance_to(room.right_goal))
   if room.phase=="ending":left_error=maxf(left_error,sk.to_global(CONTACT.palm(sk,"Left")).distance_to(room.left_goal))
   for i in sk.get_bone_count():
    var parent:=sk.get_bone_parent(i)
    if parent>=0:length_error=maxf(length_error,absf(sk.get_bone_global_pose(i).origin.distance_to(sk.get_bone_global_pose(parent).origin)-sk.get_bone_rest(i).origin.length()))
   if capture and tick%15==0:await shot("path_%s_%03d"%[branch,tick])
  print("SEAT_CUP_CONTACT ",branch," error=",error," cup=",room.cup.position," right=",sk.to_global(CONTACT.palm(sk,"Right"))," goal=",room.right_goal)
  check(error<.035,"cup reach preserves actual palm contact along path")
  check(left_error<.035,"support hand contacts the held cup without stretching")
  contacts.append({"branch":branch,"right_palm_error":error,"left_palm_error":left_error,"max_bone_length_error":length_error})
  check(room.phase=="ending" and room.cup_held and room.cup.position.distance_to(room.cup_home)>.1,"both choices physically pick up and hold original cup")
  await shot("03_warm_cup_"+branch)
  get_tree().paused=true;room.set_process(true);var frozen: float=room.phase_elapsed;await get_tree().process_frame;check(room.phase_elapsed==frozen,"normal pause freezes story")
  get_tree().paused=false;await get_tree().process_frame;room.set_process(false)
  for i in room.ENDING.size():
   check(room.dialogue.get_combined_minimum_size().y<=room.dialogue.size.y,"ending text fits");await click(room.next_button)
  check(room.phase=="done" and room.exits.visible and room.dialogue.text==tr(room.ENDING[-1]),"ending keeps the final invitation alongside exit/replay")
  check(before==JSON.stringify(profile.to_dict()) and saved==FileAccess.get_sha256(SaveService.DEFAULT_SAVE_PATH),"no reward, relationship stat, profile or save mutation")
  await shot("04_ending_"+branch)
  if branch=="stay":await click(room.exits.get_node("ReplaySeat"))
 check(length_error<.0001,"all target bone lengths preserved")
 for i in sk.get_bone_count():check(sk.get_bone_rest(i)==rests[i] and sk.get_bone_pose_position(i).is_equal_approx(positions[i]) and sk.get_bone_pose_scale(i).is_equal_approx(scales[i]),"rest, translations and scales preserved")
 await click(room.exits.get_node("SeatReturn"))
 check(await _wait("res://scenes/presentation/slice/hideout.tscn") and get_tree().current_scene.section=="Rest","actual return goes to Rest without force-accepting anything")
 _finish()
func _finish() -> void:
 var out:=OS.get_environment("BUNNY_EVIDENCE")
 if not out.is_empty():
  var file:=FileAccess.open(out.path_join("seat_moment.json"),FileAccess.WRITE);file.store_string(JSON.stringify({"scope":"Controlled scene fixture and viewport inputs, not earned progress or human acceptance","checks":checks,"contacts":contacts,"failures":failures},"\t"));file.close()
 AudioDirector.shutdown_for_test();print("SEAT_MOMENT_TEST: %s (%d checks)"%["PASS" if failures.is_empty() else "FAIL",checks]);get_tree().quit(0 if failures.is_empty() else 1)
