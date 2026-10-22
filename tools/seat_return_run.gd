extends "res://tests/normal_start_test.gd"
## Real earned Q01 profile, no new_profile, manufactured flags or inventory grants.
func _ready() -> void:
 get_tree().create_timer(150,true).timeout.connect(func():failures.append("Seat return route deadline");_finish())
 super._ready()
func _phase(wanted: String) -> bool:
 for tick in 1800:
  await tree.physics_frame
  if tree.current_scene.phase==wanted:return true
 return false
func _run() -> void:
 tree=get_tree();tree.current_scene=null
 GameLanguage.set_language("en" if "--english" in OS.get_cmdline_user_args() else "zh_CN",true)
 var profile:=ProfileRuntime.get_profile()
 check(SaveService.save_exists() and not ProfileRuntime.recovery_required and profile.first_mission_completed and profile.narrative_slice.settled.Q01 and profile.sortie_checkpoint.is_empty(),"load real completed campus-exit return without fixture flags")
 if not failures.is_empty():_finish();return
 var before:=JSON.stringify(profile.to_dict());var hash_before:=FileAccess.get_sha256(SaveService.DEFAULT_SAVE_PATH)
 var pre_boot:=profile.to_dict().duplicate(true)
 evidence["input_profile_sha256"]=hash_before;evidence["successful_sorties"]=profile.successful_sorties;evidence["method"]="Actual earned Q01 return save copied into isolated app; normal BOOT, continue, Rest, real viewport buttons; no injected progress, not human acceptance"
 if "--read" in OS.get_cmdline_user_args():
  check(preload("res://scripts/presentation/slice/seat_moment.gd").available(profile),"independent process retains actual eligibility without a scene reward")
  _finish();return
 tree.change_scene_to_file("res://scenes/presentation/slice/boot.tscn");await _frames(10)
 if tree.current_scene.opening:await _click(_button("SKIP OPENING  /  ENTER"))
 await _click(_button("CONTINUE / BASE"))
 if not await _wait_scene("res://scenes/presentation/slice/hideout.tscn"):check(false,"normal continue reaches base");_finish();return
 await _click(tree.current_scene.find_child("NavRest",true,false))
 # Ordinary base entry reconciles previously unarranged warehouse cells. The
 # story contract begins here, not before the existing base initialization.
 var at_rest:=profile.to_dict().duplicate(true)
 evidence["normal_base_stash_layout_reconciled"]=pre_boot.stash_layout!=at_rest.stash_layout
 pre_boot.erase("stash_layout");at_rest.erase("stash_layout")
 check(pre_boot==at_rest,"normal base entry changes no gameplay progress beyond existing stash layout reconciliation")
 before=JSON.stringify(profile.to_dict());hash_before=FileAccess.get_sha256(SaveService.DEFAULT_SAVE_PATH)
 evidence["rest_profile_sha256"]=hash_before
 await _capture("01_rest_entry")
 await _click(tree.current_scene.find_child("OpenSeatMoment",true,false))
 if not await _wait_scene("res://scenes/presentation/slice/seat_moment.tscn"):check(false,"earned Rest action opens scene");_finish();return
 await _capture("02_arrival")
 # Leaving during the approach must also be safe, not only after the ending.
 await _click(tree.current_scene.screen.find_child("SkipSeatMoment",true,false))
 if not await _wait_scene("res://scenes/presentation/slice/hideout.tscn"):check(false,"early skip returns to ordinary Rest");_finish();return
 check(tree.current_scene.section=="Rest" and JSON.stringify(profile.to_dict())==before,"early skip neither commits story state nor charges a reward")
 await _click(tree.current_scene.find_child("OpenSeatMoment",true,false))
 if not await _wait_scene("res://scenes/presentation/slice/seat_moment.tscn"):check(false,"can reopen after early skip");_finish();return
 if not await _phase("intro"):check(false,"actual walking/sitting completes in normal time");_finish();return
 var room=tree.current_scene
 check(room.motion.seated,"normal scene actually sits before the conversation")
 await _capture("03_seated")
 for i in room.INTRO.size():await _click(room.next_button)
 check(room.phase=="choice","actual Next buttons reach unforced choice")
 var branch:="stay" if "--stay" in OS.get_cmdline_user_args() else "rise"
 await _click(room.choices.get_node("Choice"+branch.capitalize()))
 if branch=="rise":
  if not await _phase("hesitate"):check(false,"normal stand-up reaches call-back line");_finish();return
  check(not room.motion.seated,"help choice visibly stands rather than changing only text")
  await _capture("04_wait")
  for i in room.HESITATE.size():await _click(room.next_button)
 if not await _phase("ending"):check(false,"normal re-seat and cup pickup finish");_finish();return
 check(room.motion.seated and room.cup_held,"normal presentation physically holds the cup")
 await _capture("05_warm_cup")
 for i in room.ENDING.size():await _click(room.next_button)
 check(room.phase=="done" and room.dialogue.text==tr(room.ENDING[-1]),"all actual subtitle clicks retain the final invitation")
 await _capture("06_ending")
 await _click(room.exits.get_node("SeatReturn"))
 if not await _wait_scene("res://scenes/presentation/slice/hideout.tscn"):check(false,"actual return reaches base");_finish();return
 check(tree.current_scene.section=="Rest","story exits to normal Rest")
 check(JSON.stringify(profile.to_dict())==before and hash_before==FileAccess.get_sha256(SaveService.DEFAULT_SAVE_PATH),"early skip, full branch and return leave earned profile bytes unchanged")
 evidence["branch"]=branch;evidence["output_profile_sha256"]=FileAccess.get_sha256(SaveService.DEFAULT_SAVE_PATH);evidence["profile_unchanged"]=JSON.stringify(profile.to_dict())==before
 await _capture("07_returned")
 _finish()
func _finish() -> void:
 evidence["checks"]=checks;evidence["failures"]=failures
 var f:=FileAccess.open(out.path_join("seat_return.json"),FileAccess.WRITE);f.store_string(JSON.stringify(evidence,"\t"));f.close()
 AudioDirector.shutdown_for_test();print("SEAT_RETURN_RUN: %s (%d checks)"%["PASS" if failures.is_empty() else "FAIL",checks]);tree.quit(0 if failures.is_empty() else 1)
