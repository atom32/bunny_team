extends "route_probe.gd"
## Supplemental normal-AI combat lane: no teleport, HP override or direct damage.
## The office route covers traversal/save; this run seeks unobstructed combat.
var aim_samples := []

func _run() -> void:
	var runtime = root.get_node("ProfileRuntime")
	checks["existing save loaded"] = runtime.load_profile(persistence.path_join("profile.json"))
	change_scene_to_file("res://scenes/hanger/hanger.tscn")
	await create_timer(.8).timeout
	for item in runtime.get_profile().inventory.get_items():
		if item.definition_id == (&"weapon.smg_01" if OS.get_environment("BUNNY_PRIMARY")=="SMG" else &"weapon.assault_rifle_01"):
			current_scene._on_weapon_selected(item.instance_id)
			break
	for button in current_scene.find_children("*","Button",true,false):
		if button.text=="DEPLOY":
			button.pressed.emit()
			break
	await create_timer(.6).timeout
	battle=current_scene
	player=battle.player
	battle.child_entered_tree.connect(_observe_fx)
	player.weapon_fired.connect(func(_recoil: float): shots+=1)
	for enemy in get_nodes_in_group("enemies"): enemy.died.connect(_enemy_died)
	checks["road waypoint 1"] = await _move_to(Vector3(0,0,32))
	checks["road waypoint 2"] = await _move_to(Vector3(-30,0,32))
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec()-start<18000 and not player.is_dead and combat_events.get("EnemyDied",0)==0:
		await physics_frame
		_aim_and_fire()
	_release()
	await _capture("combat_lane_final")
	checks["normal gameplay enemy death observed"] = combat_events.get("EnemyDied",0)>0
	checks["normal HP player survived"] = not player.is_dead
	checks["shots fired"] = shots>0
	_write(evidence.path_join("combat_lane.json"),{"checks":checks,"shots":shots,"effects":combat_events,"aim_samples":aim_samples,
		"method":"production Hanger/Sortie, normal AI and damage; scripted input on existing west road; no teleport/HP override/direct damage/save writes"})
	root.get_node("AudioDirector").shutdown_for_test()
	quit(1 if checks.values().has(false) else 0)

func _aim_and_fire() -> void:
	var target: Node3D
	var distance := 14.0
	var muzzle: Vector3 = player.combat_rig.get_muzzle_position()
	for enemy in get_nodes_in_group("enemies"):
		if enemy.is_dead: continue
		var d: float = player.global_position.distance_to(enemy.global_position)
		if d>=distance: continue
		var projected := root.get_camera_3d().unproject_position(enemy.global_position+Vector3.UP)
		if not Rect2(64,64,1152,592).has_point(projected): continue
		var query := PhysicsRayQueryParameters3D.create(muzzle,enemy.global_position+Vector3.UP,6)
		query.exclude=[player.get_rid()]
		var hit := player.get_world_3d().direct_space_state.intersect_ray(query)
		if hit.get("collider")!=enemy: continue
		target=enemy
		distance=d
	var screen := root.get_mouse_position()
	if target:
		screen=root.get_camera_3d().unproject_position(target.global_position+Vector3.UP)
		Input.warp_mouse(screen)
		var motion := InputEventMouseMotion.new()
		motion.position=screen
		motion.global_position=screen
		Input.parse_input_event(motion)
	var fire := InputEventMouseButton.new()
	fire.button_index=MOUSE_BUTTON_LEFT
	fire.position=screen
	fire.global_position=screen
	fire.pressed=target!=null
	Input.parse_input_event(fire)
	Input.flush_buffered_events()
	if target and aim_samples.size()<16:
		aim_samples.append({"aim":str(player.aim_world_point),"enemy":str(target.global_position),"hp":target.health,"mouse":str(root.get_mouse_position()),"requested":str(screen)})
	if player.get_magazine_ammo()==0:
		_key(KEY_R,true)
		_key(KEY_R,false)
