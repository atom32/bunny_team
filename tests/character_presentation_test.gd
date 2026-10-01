extends Node3D

var failures: Array[String] = []

func _ready() -> void:
	var human := EnemyController.new()
	check(human.configure_from_definition(ContentDB.get_enemy_definition(&"prototype_basic_enemy")), "basic patrol configures")
	add_child(human)
	human.set_physics_process(false)
	await get_tree().process_frame
	var presentation := human.presentation as HumanoidEnemyPresentation
	check(presentation != null, "basic patrol uses the imported humanoid presentation")
	check(presentation.model.find_child("Skeleton3D", true, false) != null, "humanoid is skinned")
	for clip in ["Idle_Gun_Pointing", "Run_Shoot", "Gun_Shoot", "Death"]:
		check(presentation.animation_player.has_animation(clip), "authored animation exists: " + clip)
	presentation.update_visual(Vector3(0, 1, -10), Vector3.FORWARD, 3, .2)
	check(presentation.animation_player.current_animation == "Run_Shoot", "moving patrol plays imported locomotion")
	presentation.update_visual(Vector3(0, 1, -10), Vector3.ZERO, 0, .2)
	presentation.fire_recoil()
	check(presentation.animation_player.current_animation == "Gun_Shoot", "stationary shot plays the imported firing clip")
	check(presentation.get_muzzle_position().is_finite() and is_equal_approx(presentation.get_muzzle_direction().length(),1), "humanoid has a valid firing ray")
	human.take_damage(5)
	check(human.health == human.max_health - 5, "imported presentation receives gameplay damage")
	human.take_damage(1000)
	await get_tree().process_frame
	check(is_instance_valid(presentation) and presentation.get_parent() == self, "death preserves the real model as a corpse")
	check(presentation.animation_player.current_animation == "Death", "humanoid death uses its authored animation")
	check(find_children("*", "RagdollProxy", true, false).is_empty(), "human death does not spawn a primitive humanoid")
	presentation.queue_free()
	var player := load("res://scenes/player/player.tscn").instantiate() as PlayerController
	player.preview_mode = true
	add_child(player)
	await get_tree().process_frame
	player.equip_weapon(ContentDB.get_weapon(&"weapon.assault_rifle_01"))
	player.set_process(false)
	player.set_physics_process(false)
	# Read final modified palm positions, including the slide clip and dodge scale.
	var grip_errors := {"right": INF, "left": INF}
	var hands := player.character_skeleton.get_node("BunnyGunHands") as SkeletonModifier3D
	hands.modification_processed.connect(func():
		var sk := player.character_skeleton
		var contact := preload("res://scripts/presentation/bunny_master/rifle_contact.gd")
		grip_errors.right = sk.to_global(contact.palm(sk,"Right")).distance_to(player.combat_rig.primary_grip.global_position)
		grip_errors.left = sk.to_global(contact.palm(sk,"Left")).distance_to(player.combat_rig.support_grip.global_position)
	)
	player.locomotion_playback.travel("Dodge")
	player.body_visual.scale = Vector3(.9, 1.06, .9)
	for frame in 12:
		player.animation_tree.advance(1.0 / 60.0)
		player.animation_source_skeleton.advance(1.0 / 60.0)
		player.combat_rig.update_pose(Vector3(0,1.25,-20), Vector3.FORWARD, 1, 1.0 / 60.0, false)
		player.combat_rig.apply_skeleton_ik(1.0 / 60.0)
		await get_tree().process_frame
	check(grip_errors.right < .015 and grip_errors.left < .015, "both hands remain on the weapon during scaled dodge: " + str(grip_errors))
	player.preview_mode = false
	player.take_damage(10000)
	await get_tree().process_frame
	var corpse := find_child("AuthoredPlayerCorpse", true, false)
	check(corpse != null and corpse.find_child("Skeleton3D", true, false) != null, "player defeat retains the imported skin")
	check(corpse.find_children("*", "MeshInstance3D", true, false).size() == 11, "player corpse retains the complete selected outfit")
	player.queue_free()
	corpse.queue_free()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(.2).timeout
	for failure in failures:
		push_error(failure)
	print("CHARACTER_PRESENTATION_TEST: ", "PASS" if failures.is_empty() else "FAIL")
	get_tree().quit(0 if failures.is_empty() else 1)

func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
