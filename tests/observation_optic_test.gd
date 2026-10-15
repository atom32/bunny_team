extends Node3D
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message); push_error(message)
func _ready() -> void:
	SortieRuntime.clear_session()
	var profile := ProfileRuntime.new_profile(); profile.first_mission_completed=true
	var weapon_id := profile.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY)
	var item := ItemInstance.new(&"material.observation_optic_kit"); profile.inventory.add_item(item)
	check(WeaponFitting.install_kit(weapon_id,item.instance_id,"user://optic_test.json").error == OK, "Ready optic installs through real atomic service")
	var result := DeploymentPlan.deploy(profile,&"street_district",&"streets_recon","user://optic_test.json")
	check(result.error == OK, "Optic-equipped finite loadout deploys")
	var battle = load("res://scenes/battle/battle.tscn").instantiate()
	battle.result_transition_enabled=false; add_child(battle)
	battle.player.set_physics_process(false)
	for enemy in battle.enemy_container.get_children(): enemy.set_physics_process(false)
	await get_tree().physics_frame
	var player: PlayerController=battle.player
	player.global_position=Vector3.ZERO; player.aim_direction=Vector3.FORWARD
	var definition:=player.weapon_data; var original_range:=definition.weapon_range
	check(player.get_aim_camera_extension()==3 and battle.player_visibility.sight_range()==PlayerVisibility.VIEW_RANGE, "Optic extension remains inactive without precision input")
	check(not battle.player_visibility.in_view(Vector3(0,1,-34)), "Outside ordinary observation radius")
	Input.action_press("precision_walk")
	battle._process(1.0)
	check(battle.player_visibility.sight_range()==PlayerVisibility.VIEW_RANGE+3 and battle.player_visibility.in_view(Vector3(0,1,-34)), "Actual observation query gains exactly 3m with precision input")
	check(absf(battle.camera.size-(battle.PRECISION_CAMERA_BASE_SIZE+3))<.03, "Actual battle camera uses same extended view")
	check(not battle.player_visibility.in_view(Vector3(0,1,8)), "Optic does not remove forward view-angle restriction")
	var wall:=StaticBody3D.new();wall.collision_layer=4
	var shape:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(5,4,.3);shape.shape=box;wall.add_child(shape);add_child(wall);wall.position=Vector3(0,1,-10)
	await get_tree().physics_frame
	check(not battle.player_visibility.can_see_point(Vector3(0,1.1,-34)), "Extended view still respects physical walls")
	check(definition.weapon_range==original_range and definition.aim_camera_extension==0, "Shared ballistics and definition view are unchanged")
	var checkpoint:=SortieCheckpoint.capture_world(battle)
	check(SortieCheckpoint.validate_world(checkpoint,battle), "Actual world save accepts fitted weapon and current scope pose")
	check(player.switch_weapon(LoadoutState.SLOT_WEAPON_SECONDARY) and player.get_aim_camera_extension()==0, "Switching to the other weapon removes instance-only observation benefit")
	Input.action_release("precision_walk")
	wall.queue_free(); battle.queue_free(); await get_tree().process_frame
	SortieRuntime.clear_session();AudioDirector.shutdown_for_test()
	print("OBSERVATION_OPTIC_TEST: ","PASS" if failures.is_empty() else "FAIL")
	get_tree().quit(0 if failures.is_empty() else 1)
