extends Node3D
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message); push_error(message)
func _ready() -> void:
	var model_before := FileAccess.get_sha256(PlayerController.CHARACTER_SCENE_PATH)
	var player := load("res://scenes/player/player.tscn").instantiate() as PlayerController
	player.preview_mode = true; add_child(player)
	player.set_process(false); player.set_physics_process(false)
	await get_tree().process_frame
	var style := PlayerController.HEROINE_MOTION_STYLE
	check(style.target_demographic == "young adult female" and style.style == "natural, light, combat practical", "Chosen heroine demographic/style is explicit")
	for clip in ["Idle_Gun","Walk","Run","Run_Shoot","Dodge"]:
		check(player.animation_player.get_animation(clip).get_meta("motion_style_id") == String(style.id), "Production clip receives authored style metadata: " + clip)
	var fixture := Animation.new(); var track := fixture.add_track(Animation.TYPE_ROTATION_3D)
	fixture.track_set_path(track,NodePath(".:Character1_Hips"))
	var rest := player.animation_source_skeleton.get_bone_rest(player.animation_source_skeleton.find_bone("Character1_Hips")).basis.get_rotation_quaternion()
	fixture.rotation_track_insert_key(track,0,rest * Quaternion.from_euler(Vector3(.4,.15,.3)))
	style.apply(fixture,player.animation_source_skeleton,&"Walk")
	var result: Vector3 = (rest.inverse() * fixture.track_get_key_value(track,0)).get_euler()
	check(is_equal_approx(result.x,.4) and is_equal_approx(result.y,.12) and is_equal_approx(result.z,.24), "Real hip keys reduce lateral sway while retaining sagittal stride")
	var contact := preload("res://scripts/presentation/bunny_master/rifle_contact.gd")
	var errors := {"right": INF,"left": INF}
	var hands := player.character_skeleton.get_node("BunnyGunHands") as SkeletonModifier3D
	hands.modification_processed.connect(func():
		var sk := player.character_skeleton
		errors.right = sk.to_global(contact.palm(sk,"Right")).distance_to(player.combat_rig.right_hand_target.global_position)
		errors.left = sk.to_global(contact.palm(sk,"Left")).distance_to(player.combat_rig.left_hand_target.global_position)
	)
	for weapon_id in WeaponWorkbench.IDS:
		player.equip_weapon(ContentDB.get_weapon(weapon_id))
		for state in ["Idle","Walk","Run","Dodge","Reload"]:
			player.locomotion_playback.travel("Idle" if state == "Reload" else state)
			if state == "Reload":
				player.combat_rig.reload_duration = 1.0
				check(player.combat_rig.start_reload(), "Real reload rig starts")
			for frame in 24:
				player.animation_tree.advance(1.0/60.0)
				player.animation_source_skeleton.advance(1.0/60.0)
				player.combat_rig.update_pose(Vector3(0,1.25,-20),Vector3.FORWARD,1.0 if state == "Dodge" else 0.0,1.0/60.0,false)
				player.combat_rig.apply_skeleton_ik(1.0/60.0)
				await get_tree().process_frame
			check(errors.right < .015 and errors.left < .015, "%s/%s retains both palms on actual weapon targets: %s" % [weapon_id,state,errors])
			if state == "Reload":
				for frame in 90: player.combat_rig.update_pose(Vector3(0,1.25,-20),Vector3.FORWARD,0,1.0/60.0,false)
	check(player.combat_rig.validate_visual_integrity(), "Selected heroine model, skin, outfit,52-bone rig remain intact")
	check(FileAccess.get_sha256(PlayerController.CHARACTER_SCENE_PATH) == model_before, "Original heroine asset is byte-identical")
	player.queue_free(); await get_tree().process_frame
	AudioDirector.shutdown_for_test()
	print("HEROINE_MOTION_STYLE_TEST: ", "PASS" if failures.is_empty() else "FAIL")
	get_tree().quit(0 if failures.is_empty() else 1)
