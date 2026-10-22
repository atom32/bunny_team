extends "res://tests/first_sortie_run.gd"
## Normal boot and original combat, with local animation-only controls.
var awaiting_hit_ticks:=0
var demo_done:=false
func _process(_delta: float) -> void:
 if is_instance_valid(battle) and is_instance_valid(battle.player):
  evidence["local_motion_usage"]=battle.player.local_motion_usage.duplicate()
  evidence["local_motion_events"]=battle.player.local_motion_events.duplicate()
func _release() -> void:
 Input.action_release("precision_walk")
 Input.action_release("dodge")
 super._release()
func _controls(at: Vector3) -> void:
 super._controls(at)
 Input.action_press("precision_walk")
 var director=battle.get_node("FirstMissionDirector")
 if director.stage==director.Stage.PMC and battle.player.local_motion_events.damage==0 and awaiting_hit_ticks<720:
  # Leave the real patrol alive to obtain a genuine enemy hit. No damage calls.
  Input.action_release("fire");awaiting_hit_ticks+=1
func _capture(name: String) -> void:
 if name=="10_patrol_defeated" and not demo_done and failures.is_empty():
  demo_done=true
  check(battle.player.local_motion_events.damage>0,"Authored Hit triggered by actual original AI damage")
  await _motion_demo()
 if is_instance_valid(battle) and is_instance_valid(battle.player):
  evidence["local_motion_usage"]=battle.player.local_motion_usage.duplicate()
  evidence["local_motion_events"]=battle.player.local_motion_events.duplicate()
  evidence["max_authored_reload_delta"]=battle.player.combat_rig.max_authored_reload_delta
  evidence["max_weapon_fit_offset"]=battle.player.combat_rig.max_weapon_fit_offset
 if name=="16_loop_complete":
  for alias in ["Idle","WalkRelaxed","Run","AimIdle","Walk","WalkBack","Shoot","Reload","Hit","Dodge","TakeGun","PutGun"]:
   check(int(evidence.local_motion_usage.get(alias,0))>0,"Actual normal-input/event use of "+alias)
 await super._capture(name)
func _wait_ticks(count: int) -> void:
 for tick in count:await tree.physics_frame
func _motion_demo() -> void:
 var p=battle.player
 _release()
 Input.action_press("aim_up");Input.action_press("precision_walk")
 await _wait_ticks(18)
 Input.action_press("move_back");await _wait_ticks(18)
 _release();Input.action_press("move_forward",.35);await _wait_ticks(32)
 _release();await _wait_ticks(20)
 await _tap("local_holster");await _wait_ticks(65)
 check(p._holstered and not p.equipped_weapon_visual.visible,"Source release event hides the gun after normal V holster")
 Input.action_press("move_left",.35);await _wait_ticks(20);_release()
 Input.action_press("move_right",.35);await _wait_ticks(20);_release()
 Input.action_press("move_left");await _wait_ticks(12)
 check(p.locomotion_playback.get_current_node()==&"Run" and not p.equipped_weapon_visual.visible,"Full-speed holstered movement uses Run rather than accelerating the walking clip")
 _release();Input.action_press("move_right");await _wait_ticks(12);_release()
 await super._capture("10a_source_put_gun")
 var hidden_shots:=shots
 await _tap("fire")
 check(shots>hidden_shots and not p._holstered and p.equipped_weapon_visual.visible,"Fire from fully holstered state restores the real weapon before consuming a shot")
 await _tap("local_holster");await _wait_ticks(65)
 await _tap("local_holster");await _wait_ticks(120)
 check(not p._holstered and p.equipped_weapon_visual.visible,"Source draw event restores actual held rifle")
 await _tap("local_holster");await _wait_ticks(12)
 var before_shots:=shots
 await _tap("fire")
 check(shots>before_shots and not p._holstered and p._switch_clip.is_empty() and p.equipped_weapon_visual.visible,"Real fire immediately interrupts holster; actual shot/ammo logic remains active")
 _release();Input.action_press("move_right");await _tap("dodge");await _wait_ticks(40);_release()
 check(p.local_motion_events.dodge>0,"Normal dodge input drives authored source evade and original dash")
 await super._capture("10b_mobility_and_interrupt")
