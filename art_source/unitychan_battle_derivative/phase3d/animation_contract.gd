extends SceneTree
var out := OS.get_environment("BUNNY_EVIDENCE")
func _initialize(): _run.call_deferred()
func _run():
 change_scene_to_file("res://scenes/hanger/hanger.tscn")
 await create_timer(0.5).timeout
 var p = current_scene.preview_character
 p.set_physics_process(false)
 p.preview_mode = false
 var rows := []
 for id in [&"weapon.assault_rifle_01", &"weapon.smg_01", &"weapon.rocket_launcher_01"]:
  p.equip_weapon(root.get_node("ContentDB").get_weapon(id))
  for state in ["Idle","Walk","Run","Run_Shoot","Recoil","Reload","Hit","Dodge"]:
   p.velocity = Vector3(2,0,0) if state in ["Walk","Run","Run_Shoot"] else Vector3.ZERO
   p._dodge_time = 0.1 if state == "Dodge" else 0.0
   if state == "Walk": Input.action_press("precision_walk")
   else: Input.action_release("precision_walk")
   p._animate_stride(1.0/60.0)
   if state in ["Run_Shoot","Recoil"]: p._apply_weapon_recoil(Vector3.FORWARD)
   if state == "Reload": p.debug_reload_once()
   if state == "Hit": p.take_damage(1.0)
   for f in 20:
    p.animation_tree.advance(1.0/60.0)
    p.combat_rig.update_pose(p.global_position+Vector3(0,1.13,-20),Vector3.FORWARD,p._dodge_time/0.16,1.0/60.0,false)
    p.animation_source_skeleton.advance(1.0/60.0)
    p.combat_rig.apply_skeleton_ik(1.0/60.0)
    await process_frame
   var expected: String = state if state in ["Idle","Walk","Run","Dodge"] else ("Run" if state=="Run_Shoot" else "Idle")
   var ok: bool = p.locomotion_playback.get_current_node() == StringName(expected) and p.combat_rig.validate_visual_integrity()
   for b in p.character_skeleton.get_bone_count(): ok = ok and p.character_skeleton.get_bone_global_pose(b).origin.is_finite()
   rows.append({"weapon":str(id),"state":state,"locomotion":str(p.locomotion_playback.get_current_node()),"pass":ok})
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png(out.path_join(str(id)+"_"+state+".png"))
 Input.action_release("precision_walk")
 var f := FileAccess.open(out.path_join("results.json"),FileAccess.WRITE)
 f.store_string(JSON.stringify(rows,"  ")); f.close()
 var ok := true
 for row in rows: ok = ok and row["pass"]
 print("PRODUCTION_ANIMATION_CONTRACT ",ok)
 root.get_node("AudioDirector").shutdown_for_test()
 quit(0 if ok else 1)
