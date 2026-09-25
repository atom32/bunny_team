extends Node3D
## Regression for shared weapon identity, imported art and presentation-only fixtures.
var failures: Array[String] = []
var capture_dir := OS.get_environment("VISUAL_SLICE_CAPTURE_DIR")

func _ready() -> void:
	var profile := ProfileRuntime.new_profile()
	var hanger: Node3D = load("res://scenes/hanger/hanger.tscn").instantiate()
	add_child(hanger)
	await get_tree().process_frame
	for id in [&"weapon.assault_rifle_01", &"weapon.smg_01", &"weapon.rocket_launcher_01"]:
		var item: ItemInstance
		for candidate in profile.inventory.get_items():
			if candidate.definition_id == id:
				item = candidate
		var ui := hanger.hanger_ui as HangerUI
		ui.secondary_weapon_selected.emit("")
		ui.weapon_selected.emit(item.instance_id)
		await get_tree().create_timer(0.35).timeout
		var player := hanger.preview_character as PlayerController
		check(player.weapon_data.id == id, "Hanger selection retains definition identity")
		check(player.equipped_weapon_visual.get_meta("equipment_id") == id, "shared scene receives definition identity")
		check(player.equipped_weapon_visual.has_node("Art/Model"), "weapon uses an imported GLB")
		check(player.combat_rig.has_weapon() == player.weapon_data.uses_combat_rig, "socket pose correction preserves the production weapon path")
		check(player.equipped_weapon_visual.find_children("*", "MeshInstance3D", true, false).size() > 1, "GLB has renderable geometry")
		check(player.equipped_weapon_visual.find_children("*", "CollisionObject3D", true, false).is_empty(), "weapon art adds no collision")
		check(player.animation_tree.active and player.animation_player.get_animation(&"Idle_Gun").loop_mode == Animation.LOOP_PINGPONG, "idle remains active and ping-pong")
		check(ui.warehouse_summary.text.contains("[PRIMARY]") and ui.warehouse_summary.text.contains(player.weapon_data.display_name), "Warehouse reflects equipped identity")
		await capture("hanger_" + String(id).trim_prefix("weapon.").trim_suffix("_01"))
	hanger.queue_free()
	await get_tree().process_frame
	profile = ProfileRuntime.new_profile()
	var ammo: Array[String] = []
	for item in profile.inventory.get_items():
		if ContentDB.get_item(item.definition_id).has_tag(&"ammo"):
			ammo.append(item.instance_id)
	var session := SortieRuntime.start_sortie(profile.create_sortie_request(SortieRequest.PROTOTYPE_AREA_ID, SortieRequest.PROTOTYPE_MISSION_ID, ammo), profile)
	var battle: Node3D = load("res://scenes/battle/battle.tscn").instantiate()
	battle.result_transition_enabled = false
	add_child(battle)
	await get_tree().process_frame
	await get_tree().physics_frame
	var player := battle.player as PlayerController
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
		enemy.set_process(false)
	var building := battle.area_root.find_child("FieldOffice", true, false) as Node3D
	var art := building.get_node("OfficeArt")
	check(art.find_children("*", "CollisionObject3D", true, false).is_empty(), "OfficeArt has no collision bodies")
	var door := battle.area_root.find_child("SouthAccessDoor", true, false) as Door
	check(door.door_collision.shape.size == Vector3(2.2, 2.4, .24), "door shape remains 2.2 x 2.4m")
	check(door.get_node("DoorLeaf/DoorBody/DoorMesh").get_child_count() > 0, "door reskin follows real rotating leaf")
	var barrier := battle.area_root.find_child("DestructibleBarrier", true, false) as DestructibleWorldObject
	check(barrier.visual.get_child_count() > 0, "barrier decorations inherit real visual visibility")
	player.global_position = building.to_global(Vector3(0, .1, 12))
	player.set_physics_process(false)
	battle.set_process(false)
	battle.hud.hide()
	battle.camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	battle.camera.fov = 48
	battle.camera.global_position = building.to_global(Vector3(15, 11, 20))
	battle.camera.look_at(building.global_position + Vector3(0,1,0))
	for frame in 15:
		await get_tree().process_frame
	check(art.get_node("RoofShell").visible, "roof renders at exterior distance")
	await capture("office_exterior")
	player.global_position = building.to_global(Vector3(-3, .1, 3))
	battle.camera.global_position = building.to_global(Vector3(-9, 12, 12))
	battle.camera.look_at(building.global_position + Vector3(0,.7,-.7))
	for frame in 15:
		await get_tree().process_frame
	check(not art.get_node("RoofShell").visible, "interior cutaway leaves route visible")
	await capture("office_interior")
	# All three visual scenes through the actual gameplay player; this does not change definitions.
	for id in [&"weapon.assault_rifle_01", &"weapon.smg_01", &"weapon.rocket_launcher_01"]:
		player.equip_weapon(ContentDB.get_weapon(id))
		player.global_position = building.to_global(Vector3(-3, .1, 3))
		player.rotation.y = 0.0
		player.body_visual.rotation.y = 0.0
		player.aim_direction = Vector3.FORWARD
		player.aim_world_point = player.global_position + Vector3(0,1.25,-20)
		battle.camera.global_position = player.global_position + Vector3(2.4,2.3,-3.8)
		battle.camera.look_at(player.global_position + Vector3(0,1,-.25))
		for frame in 12:
			# A fixed camera capture with the same pose evaluation as PlayerController.
			player.animation_tree.advance(1.0 / 60.0)
			player.animation_source_skeleton.advance(1.0 / 60.0)
			player.combat_rig.update_pose(player.aim_world_point, player.aim_direction, 0, 1.0 / 60.0, false)
			player.combat_rig.apply_skeleton_ik(1.0 / 60.0)
			await get_tree().process_frame
		check(player.equipped_weapon_visual.has_node("Art/Model"), "gameplay uses the same imported model")
		await capture("gameplay_" + String(id).trim_prefix("weapon.").trim_suffix("_01"))
	barrier.receive_damage(DamagePacket.new(0, 0, 999))
	await get_tree().physics_frame
	await get_tree().process_frame
	check(not barrier.visual.is_visible_in_tree() and barrier.collision_shape.disabled, "barrier decoration disappears with destroyed collision")
	battle.queue_free()
	await get_tree().process_frame
	SortieRuntime.clear_session()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(.2).timeout
	if failures.is_empty():
		print("VISUAL_SLICE_ASSETS_TEST: PASS")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)

func capture(label: String) -> void:
	if capture_dir.is_empty() or DisplayServer.get_name() == "headless":
		return
	DirAccess.make_dir_recursive_absolute(capture_dir)
	await RenderingServer.frame_post_draw
	check(get_viewport().get_texture().get_image().save_png(capture_dir.path_join(label + ".png")) == OK, "capture is saved")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
