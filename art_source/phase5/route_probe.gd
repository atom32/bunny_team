extends SceneTree
## Run against the production project with isolated APPDATA and a COPY of a real save.
## BUNNY_EVIDENCE may be inside .gdignore authoring evidence. NOT manual acceptance.
## Normal AI, health, collision, production camera and outcome flow stay enabled.

var evidence := OS.get_environment("BUNNY_EVIDENCE")
var held := {}
var checks := {}
var battle: Node
var player: Node3D
var shots := 0
var combat_events := {}
var combat_captured := {}
var weapon_checks: Array = []
var persistence := OS.get_environment("BUNNY_PERSISTENCE")
var identity := {}
var saved_combat := {}
var enemy_positions := {}
var enemy_moved := false
var enemy_telegraphed := false
var enemy_fired := false
var profile_object_id: int
var actor_id: int
var session_id: String
var aim_logs := 0

func _write(path: String, data: Variant) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(data,"  "))
	f.close()


func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.content_scale_size=Vector2i(1280,720)
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT
	root.size=Vector2i(1280,720)
	root.grab_focus()
	if evidence.is_empty() or DisplayServer.get_name() == "headless":
		push_error("Requires an isolated profile, BUNNY_EVIDENCE and a real graphics renderer")
		quit(2)
		return
	print("PHASE5_ROUTE: AUTOMATED INPUT/API, NOT MANUAL; NORMAL AI; NO TELEPORT/INVULNERABILITY")
	var runtime = root.get_node("ProfileRuntime")
	checks["Existing save loaded"] = runtime.load_profile(persistence.path_join("profile.json"))
	if not checks["Existing save loaded"]:
		await _finish("Existing save failed to load")
		return
	profile_object_id = runtime.get_profile().get_instance_id()
	identity["loaded_profile"] = runtime.get_profile().to_dict()
	change_scene_to_file("res://scenes/presentation/slice/boot.tscn")
	await create_timer(0.7).timeout
	checks["Boot enters opening"] = current_scene.name == "Boot" and current_scene.opening
	await _capture("00_opening")
	if OS.get_environment("BUNNY_PRIMARY") == "Rifle":
		await create_timer(8.0).timeout
		await _capture("00_opening_operator")
		await create_timer(8.0).timeout
		await _capture("00_opening_mission")
		await create_timer(8.0).timeout
	else:
		await _tap(KEY_ENTER)
	checks["Opening completes or skips to menu"] = not current_scene.opening
	await _capture("00_menu")
	current_scene._settings()
	await _capture("00_settings")
	current_scene.show_menu()
	var start: Button
	for button in current_scene.find_children("*","Button",true,false):
		if button.text in ["START","CONTINUE"]: start = button
	checks["Main Menu Start available"] = start != null
	start.pressed.emit()
	await create_timer(1.7).timeout
	checks["Menu transitions into Hideout"] = current_scene.name == "Hideout"
	await _capture("00_hideout")
	for section in ["Workshop","Rest","Hanger"]:
		current_scene.show_section(section)
		await create_timer(0.8).timeout
		checks["Hideout "+section] = current_scene.section == section
		await _capture("00_hub_"+section)
	checks["Hanger launches"] = current_scene.hanger != null
	var profile = runtime.get_profile()
	for item in profile.inventory.get_items():
		if item.definition_id == (&"weapon.smg_01" if OS.get_environment("BUNNY_PRIMARY") == "SMG" else &"weapon.assault_rifle_01"):
			current_scene.hanger._on_weapon_selected(item.instance_id)
			break
	await create_timer(0.4).timeout
	await _capture("01_hanger")
	var terminal_button: Button
	for button in current_scene.hanger.hanger_ui.find_children("*","Button",true,false):
		if button.text == "MISSION TERMINAL": terminal_button=button
	checks["Loadout leads to mission terminal"] = terminal_button != null
	terminal_button.pressed.emit()
	await create_timer(0.8).timeout
	checks["Operations selected by loadout UI"] = current_scene.section == "Operations"
	await _capture("01_mission")
	identity["pre_sortie_profile"] = runtime.get_profile().to_dict()
	var deploy: Button
	for button in current_scene.find_children("*","Button",true,false):
		if button.text == "CONFIRM DEPLOYMENT": deploy=button
	checks["Mission confirmation available"] = deploy != null
	deploy.pressed.emit()
	await create_timer(1.8).timeout
	checks["Deployment sequence"] = current_scene.name == "Deployment"
	await _capture("01_deployment")
	await create_timer(4.3).timeout
	checks["Arrival camera"] = current_scene.name == "Battle" and root.get_camera_3d() != current_scene.camera
	await _capture("01_arrival")
	await create_timer(2.0).timeout
	battle = current_scene
	player = battle.get("player") as Node3D
	if not player:
		await _finish("Battle player missing")
		return
	actor_id = player.get_instance_id()
	session_id = root.get_node("SortieRuntime").get_current_session().session_id
	identity["session_id"] = session_id
	player.weapon_fired.connect(func(_recoil: float): shots += 1)
	battle.child_entered_tree.connect(_observe_fx)
	for enemy in get_nodes_in_group("enemies"):
		enemy.died.connect(_enemy_died)
	checks["Production camera"] = root.get_camera_3d() == battle.get("camera")
	checks["Drone production spawns"] = not get_nodes_in_group("enemies").is_empty()
	for unit in get_nodes_in_group("enemies"):
		checks["Drone production spawns"] = checks["Drone production spawns"] and unit.get("presentation") != null and unit.presentation.visual != null and unit.presentation.muzzle != null
	checks["No legacy Avatar loaded"] = not ResourceLoader.has_cached("res://assets/characters/vrm_avatar/avatar_sample_a.glb")
	checks["No enemy humanoid skeleton"] = true
	for unit in get_nodes_in_group("enemies"):
		checks["No enemy humanoid skeleton"] = checks["No enemy humanoid skeleton"] and unit.find_children("*","Skeleton3D",true,false).is_empty()
	var cover_presentation = battle.find_child("UrbanDefensePresentation",true,false)
	checks["Phase4C barriers retained"] = cover_presentation != null and cover_presentation.get_child_count()==8 and cover_presentation.original_meshes.size()==8
	if not await _move_to(Vector3(0,0,30.0)):
		await _finish("Could not approach supply case")
		return
	await create_timer(0.2).timeout
	var used_before: float = battle.session.inventory.get_used_capacity()
	var profile_before_loot = runtime.get_profile().to_dict()
	await _tap(KEY_E)
	var loot_ui = battle.get_node("SlicePresentation")
	checks["Cargo HUD within viewport"] = Rect2(Vector2.ZERO,Vector2(1280,720)).encloses(battle.hud.capacity_label.get_global_rect())
	checks["Container opened with E"] = is_instance_valid(loot_ui.panel) and loot_ui.container.opened
	await _capture("01_loot_open")
	if not checks["Container opened with E"]:
		await _finish("Loot UI did not open")
		return
	var take: Button
	for button in loot_ui.panel.find_children("*","Button",true,false):
		if button.text == "TAKE": take=button
	checks["Contents exposed"] = take != null
	var before_ui_shots := shots
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = take.get_global_rect().get_center()
	click.pressed = true
	Input.parse_input_event(click)
	await process_frame
	click = click.duplicate()
	click.pressed = false
	Input.parse_input_event(click)
	checks["Loot click does not fire weapon"] = shots == before_ui_shots
	await create_timer(0.2).timeout
	checks["Pickup changes carried cargo"] = battle.session.inventory.get_used_capacity() > used_before
	checks["Pickup does not change warehouse before extraction"] = runtime.get_profile().to_dict() == profile_before_loot
	await _capture("01_loot_taken")
	await _tap(KEY_E)
	checks["Container closes"] = not is_instance_valid(loot_ui.panel) and not loot_ui.container.opened
	checks["North districts added"] = battle.area_root.find_child("NorthDistricts",true,false) != null
	if not await _move_to(Vector3(-16.0, 0, 26.0)):
		await _finish("Could not approach Field Office")
		return
	checks["Player movement"] = true
	var door = battle.find_child("SouthAccessDoor", true, false)
	checks["Field Office entrance visible"] = door != null and not root.get_camera_3d().is_position_behind(door.global_position)
	await _capture("02_entrance")
	if not await _move_to(Vector3(-16.0, 0, 24.7)):
		await _finish("Door approach failed")
		return
	await _tap(KEY_E)
	checks["Door interaction"] = door.is_open()
	if not checks["Door interaction"]:
		await _finish("Door did not open through interaction input")
		return
	if not await _move_to(Vector3(-16.0, 0, 21.5)) or not await _move_to(Vector3(-19.5, 0, 21.0)):
		await _finish("Entrance traversal failed")
		return
	checks["Enter Field Office"] = true
	await _capture("03_inside")
	var initial_id: String = player.weapon_data.id
	for index in 4:
		await _tap(KEY_Q)
		var id: String = player.weapon_data.id
		var expected: String = "Rocket" if index % 2 == 0 else ("SMG" if OS.get_environment("BUNNY_PRIMARY") == "SMG" else "Rifle")
		var fired: bool = player.debug_fire_once()
		await create_timer(0.12).timeout
		var before: int = player.get_magazine_ammo()
		var reloaded: bool = player.reload_weapon()
		var after: int = player.get_magazine_ammo()
		weapon_checks.append({"id":id,"expected_pose":expected,"selected_pose":player.combat_rig.selected_pose,"fired":fired,"reload":reloaded,"ammo_before":before,"ammo_after":after})
		checks["switch_pose_"+str(index)] = player.combat_rig.selected_pose == expected
		checks["reload_"+str(index)] = reloaded and after > before
		await _capture("switch_"+str(index)+"_"+expected)
		await create_timer(1.0).timeout
	checks["Initial weapon restored"] = player.weapon_data.id == initial_id
	if not await _move_to(Vector3(-19.5, 0, 13.1)):
		await _finish("Interior traversal failed")
		return
	checks["Interior traversal"] = true
	var terminal = battle.find_child("PrototypeTerminal", true, false)
	checks["Terminal area reachable"] = player.global_position.distance_to(terminal.global_position) < 2.6
	await _capture("04_terminal")
	await _combat_window()
	await _tap(KEY_E)
	var active_session = root.get_node("SortieRuntime").get_current_session()
	var terminal_state = active_session.get_objective_state(terminal.objective_id)
	checks["Terminal interaction completed"] = terminal_state != null and terminal_state.status == ObjectiveState.Status.COMPLETED
	await _capture("04b_terminal_interacted")
	if not checks["Terminal interaction completed"]:
		await _finish("Terminal interaction did not complete objective")
		return
	if not await _move_to(Vector3(-19.5, 0, 21.0)) or not await _move_to(Vector3(-10.5, 0, 21.7)) or not await _move_to(Vector3(-16.0, 0, 21.5)) or not await _move_to(Vector3(-16.0, 0, 26.0)):
		await _finish("Exit traversal failed")
		return
	checks["Exit Field Office"] = true
	# Actual input-driven Dodge, not a pose or artificial state override.
	var before_dodge := player.global_position
	_key(KEY_D, true)
	_key(KEY_SPACE, true)
	var dodge_seen := false
	for frame in 14:
		await physics_frame
		dodge_seen = dodge_seen or player.get("_dodge_time") > 0.0
		if frame == 2: _key(KEY_SPACE, false)
	_release()
	checks["Dodge executed"] = dodge_seen and player.global_position.distance_to(before_dodge) > 0.3
	checks["Same sortie Player actor"] = player.get_instance_id() == actor_id
	checks["Same sortie session"] = root.get_node("SortieRuntime").get_current_session().session_id == session_id
	await _capture("05b_after_dodge")
	await _capture("05_exit")
	# Continuous production route: office exit -> normal west-road engagement -> extraction.
	for unit in get_nodes_in_group("enemies"):
		if not unit.died.is_connected(_enemy_died): unit.died.connect(_enemy_died)
	if not await _move_to(Vector3(-16,0,32)) or not await _move_to(Vector3(-30,0,32)):
		await _finish("Combat road approach failed")
		return
	var engagement_start := Time.get_ticks_msec()
	while combat_events.get("EnemyDied",0)<3 and Time.get_ticks_msec()-engagement_start<15000:
		await physics_frame
		if player.is_dead: break
		_aim_and_fire()
	_release()
	checks["Enemy hit and death in same sortie"] = combat_events.get("EnemyDied",0)>0
	await _capture("05c_enemy_engagement")
	if not await _move_to(Vector3(0, 0, 30.0)) or not await _move_to(Vector3(2.5, 0, 32.0)):
		await _finish("Return route failed")
		return
	checks["Return to original route"] = true
	await _tap(KEY_E)
	await create_timer(0.35).timeout
	checks["Extraction camera / confirmation"] = battle.ending and root.get_camera_3d() != battle.camera
	await _capture("05d_extraction")
	await create_timer(3.3).timeout
	var session = root.get_node("SortieRuntime").get_current_session()
	checks["Extraction"] = session != null and session.status == session.Status.COMPLETED
	checks["All mission objectives completed"] = session.mission_completed
	checks["Result"] = current_scene != null and current_scene.name == "Result"
	checks["Player hit by real enemy attack"] = session.damage_taken > 0.0
	print("OUTCOME enemies_defeated=", session.enemies_defeated, " damage_taken=", session.damage_taken, " mission_completed=", session.mission_completed)
	await _capture("06_result")
	saved_combat = {"shots": shots,"enemies_defeated":session.enemies_defeated,"damage_taken":session.damage_taken,"mission_completed":session.mission_completed}
	identity["outcome"] = current_scene.get("_pending_outcome").to_dict()
	checks["Result uses same session identity"] = identity["outcome"]["session_id"] == session_id
	current_scene.finalize_save_path = persistence.path_join("profile.json")
	# Same production UI signal as the Return button; commits and saves once.
	current_scene.result_ui.return_requested.emit()
	await create_timer(1.8).timeout
	checks["Returned to Hanger"] = current_scene != null and current_scene.name == "Hideout"
	checks["Session cleared after commit"] = root.get_node("SortieRuntime").get_current_session() == null
	checks["Same logical profile object"] = runtime.get_profile().get_instance_id() == profile_object_id
	checks["Presentation retained after return"] = current_scene.hanger.preview_character.combat_rig.get_script().resource_path == "res://scripts/presentation/unitychan/presentation_adapter.gd"
	identity["post_result_profile"] = runtime.get_profile().to_dict()
	_write(persistence.path_join("expected_after.json"),identity["post_result_profile"])
	_write(evidence.path_join("identity_flow.json"),identity)
	await _capture("07_return_hanger")
	await _finish("")

func _move_to(target: Vector3) -> bool:
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < 12000:
		await physics_frame
		if not is_instance_valid(player) or player.get("is_dead") or current_scene != battle:
			_release()
			return false
		var offset := target - player.global_position
		offset.y = 0
		if offset.length() < 0.45:
			print("WAYPOINT ",target," reached ",player.global_position)
			_release()
			await create_timer(0.12).timeout
			return true
		_key(KEY_A, offset.x < -0.2)
		_key(KEY_D, offset.x > 0.2)
		_key(KEY_W, offset.z < -0.2)
		_key(KEY_S, offset.z > 0.2)
		_aim_and_fire()
	_release()
	print("WAYPOINT_TIMEOUT target=",target," position=",player.global_position," health=",player.get("health"))
	for i in player.get_slide_collision_count():
		var collision = player.get_slide_collision(i)
		print("BLOCKING_COLLIDER ",collision.get_collider().get_path()," normal=",collision.get_normal()," point=",collision.get_position())
	return false

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
	if target and aim_logs < 8:
		print("AIM_VERIFY expected=",screen," viewport=",root.get_mouse_position()," focus=",root.has_focus()," camera=",root.get_camera_3d().get_path())
		aim_logs += 1
	if player.get_magazine_ammo()==0:
		_key(KEY_R,true)
		_key(KEY_R,false)

func _key(key: int, pressed: bool) -> void:
	if held.get(key, false) == pressed: return
	held[key] = pressed
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = pressed
	Input.parse_input_event(event)

func _tap(key: int) -> void:
	_key(key, true)
	await physics_frame
	_key(key, false)
	await create_timer(0.15).timeout

func _release() -> void:
	for key in held.keys(): _key(key, false)
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = false
	Input.parse_input_event(event)

func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	checks["1280x720 evidence"] = img.get_size()==Vector2i(1280,720)
	var code := img.save_png(evidence.path_join(label + ".png"))
	print("CAPTURE ",label," ",img.get_size()," error=",code)

func _finish(reason: String) -> void:
	_release()
	checks["Combat still works"] = shots > 0
	checks["Enemy moved"] = enemy_moved
	checks["Enemy attack telegraph"] = enemy_telegraphed
	checks["Enemy actual muzzle flash"] = enemy_fired
	if not reason.is_empty():
		print("ROUTE_FAIL ", reason)
		await _capture("failure")
	var session = root.get_node("SortieRuntime").get_current_session()
	var combat := {"shots": shots, "enemies_defeated": session.enemies_defeated if session else 0, "damage_taken": session.damage_taken if session else 0}
	var report := {"method": "automated input/API, not manual", "checks": checks, "failure": reason, "combat": saved_combat if not saved_combat.is_empty() else combat, "weapon_checks": weapon_checks,
		"combat_scope": "normal AI + input/API route; additional 8 second terminal firefight; effects observed from production tree",
		"combat_events":combat_events,
		"mission_completed": saved_combat.get("mission_completed",false)}
	var f := FileAccess.open(evidence.path_join("route_result.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  "))
	f.close()
	print(JSON.stringify(report))
	root.get_node("AudioDirector").shutdown_for_test()
	await create_timer(0.2).timeout
	quit(0 if reason.is_empty() and checks.get("Extraction", false) and checks.get("Result", false) and not checks.values().has(false) else 1)

func _observe_fx(node: Node) -> void:
	if str(node.name).begins_with("MuzzleFlash"): _classify_flash.call_deferred(node.get_instance_id())
	for label in ["MuzzleFlash", "HitEffect", "ImpactSmoke", "DodgeStreak", "RocketTrail", "Explosion", "Ragdoll"]:
		if str(node.name).begins_with(label):
			combat_events[label] = combat_events.get(label, 0) + 1
			if not combat_captured.has(label):
				combat_captured[label] = true
				_capture("combat_"+label)

func _combat_window() -> void:
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec()-start<8000:
		await physics_frame
		if not is_instance_valid(player) or player.is_dead: break
		_aim_and_fire()
	_release()
	await _capture("04_combat_completed")

func _enemy_died(_enemy: Node) -> void:
	combat_events["EnemyDied"] = combat_events.get("EnemyDied",0)+1
	_capture("combat_enemy_death_"+str(combat_events["EnemyDied"]))

func _classify_flash(instance_id: int) -> void:
	var flash := instance_from_id(instance_id) as Node3D
	if not is_instance_valid(flash): return
	var jet := flash.get_node_or_null("DirectionalFlash") as MeshInstance3D
	if jet and jet.material_override is ShaderMaterial:
		var tint: Color = jet.material_override.get_shader_parameter("tint")
		if tint.is_equal_approx(Color("ff3658")):
			enemy_fired=true
			if not combat_captured.has("EnemyFire") and flash.global_position.z > 25.0 and Rect2(80,80,1120,560).has_point(root.get_camera_3d().unproject_position(flash.global_position)):
				combat_captured["EnemyFire"]=true
				_capture("combat_enemy_fire")

func _process(_delta: float) -> bool:
	if not is_instance_valid(battle) or current_scene != battle: return false
	for unit in get_nodes_in_group("enemies"):
		var id := unit.get_instance_id()
		if not enemy_positions.has(id): enemy_positions[id]=unit.global_position
		if unit.global_position.distance_to(enemy_positions[id])>.1: enemy_moved=true
		if unit._is_telegraphing: enemy_telegraphed=true
	return false
