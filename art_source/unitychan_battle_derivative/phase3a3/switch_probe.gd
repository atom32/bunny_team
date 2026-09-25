extends SceneTree
func _initialize():call_deferred("run")
func run():
 change_scene_to_file("res://scenes/hanger/hanger.tscn")
 await create_timer(0.8).timeout
 var p=current_scene.preview_character
 var reference: Dictionary={}
 var rows: Array=[]
 var failures: Array=[]
 var sequences=[["Rifle","SMG","Rocket","Rifle"],["Rifle","Rocket","SMG","Rocket","Rifle"]]
 var ids={"Rifle":"weapon.assault_rifle_01","SMG":"weapon.smg_01","Rocket":"weapon.rocket_launcher_01"}
 for repetition in 5:
  for sequence in sequences:
   for label in sequence:
    p.equip_weapon(root.get_node("ContentDB").get_weapon(ids[label]))
    await create_timer(0.25).timeout
    var rig=p.combat_rig
    var weapon: Node3D=rig.equipped_weapon if is_instance_valid(rig.equipped_weapon) else rig._socket_visual
    var local: Transform3D=p.body_visual.global_transform.affine_inverse()*weapon.global_transform
    var drift:=0.0
    var angle:=0.0
    if reference.has(label):
     drift=local.origin.distance_to(reference[label].origin)
     angle=local.basis.orthonormalized().get_rotation_quaternion().angle_to(reference[label].basis.orthonormalized().get_rotation_quaternion())
    else:reference[label]=local
    var row={"iteration":repetition,"expected":label,"selected":rig.selected_pose,"position_drift_m":drift,"rotation_drift_rad":angle,"right_error_m":rig.get_hand_error(&"right"),"left_error_m":rig.get_hand_error(&"left"),"reload_state":rig.is_reloading(),"has_weapon_semantics":rig.has_weapon()}
    if rig.selected_pose!=label or drift>0.01 or angle>0.03 or rig.is_reloading():failures.append(row)
    rows.append(row)
    if repetition==4:
     await RenderingServer.frame_post_draw
     root.get_texture().get_image().save_png(OS.get_environment("BUNNY_EVIDENCE")+"/switch_"+label+".png")
    # Leave presentation recoil in flight when switching away, exercising cleanup.
    p._apply_weapon_recoil(Vector3.FORWARD)
 var report={"method":"Hanger equip_weapon presentation API sequences; NOT three-slot gameplay switching","rows":rows,"failures":failures,"two_slot_gameplay_test":"pending existing weapon_switching_test"}
 var f=FileAccess.open(OS.get_environment("BUNNY_EVIDENCE")+"/switching.json",FileAccess.WRITE)
 f.store_string(JSON.stringify(report,"\t"))
 print("PRESENTATION_SWITCH_SEQUENCES: ","PASS" if failures.is_empty() else "FAIL"," samples=",rows.size())
 quit(0 if failures.is_empty() else 1)
