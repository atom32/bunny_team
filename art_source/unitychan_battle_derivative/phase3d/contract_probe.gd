extends SceneTree
func _initialize() -> void:
	_run.call_deferred()
func v(a: Vector3) -> Array:
	return [a.x,a.y,a.z]
func _run() -> void:
	change_scene_to_file("res://scenes/hanger/hanger.tscn")
	await create_timer(0.3).timeout
	var actor = current_scene.preview_character
	actor.set_physics_process(false)
	actor.set_process(false)
	actor.body_visual.transform = Transform3D.IDENTITY
	actor.aim_direction = Vector3.FORWARD
	actor.aim_world_point = actor.global_position + Vector3(0,1,-20)
	var rows := []
	for id in [&"weapon.assault_rifle_01", &"weapon.smg_01", &"weapon.rocket_launcher_01"]:
		actor.equip_weapon(root.get_node("ContentDB").get_item(id))
		var rig = actor.combat_rig
		for frame in 90:
			if frame == 20: rig.fire_recoil(0.5)
			if frame == 30: rig.start_reload()
			rig.update_pose(actor.aim_world_point,Vector3.FORWARD,0.5 if frame >= 80 else 0.0,1.0/60.0,false)
			var origin: Vector3 = rig.get_muzzle_position() if rig.has_weapon() else actor.global_position + Vector3.UP*1.25+actor.aim_direction*0.55
			rows.append({"weapon":str(id),"frame":frame,"has_weapon":rig.has_weapon(),"reloading":rig.is_reloading(),"state":str(rig.get_upper_body_state_name()),"origin":v(origin),"direction":v(actor._shot_direction_from(origin))})
	var f := FileAccess.open(OS.get_environment("BUNNY_CONTRACT_OUTPUT"),FileAccess.WRITE)
	f.store_string(JSON.stringify(rows,"  ")); f.close()
	root.get_node("AudioDirector").shutdown_for_test()
	await create_timer(0.1).timeout
	quit()
