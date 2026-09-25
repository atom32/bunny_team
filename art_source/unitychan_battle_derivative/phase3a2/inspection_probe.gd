extends SceneTree
## Diagnostic scene only. No PlayerController, state machine or animation playback.
var scene: Node3D
var skeleton: Skeleton3D
var report := {}
var rendered_hands := {}

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var configs = JSON.parse_string(FileAccess.get_file_as_string("res://tools/phase3a1_poses.json"))
	for label in ["Pose_Rifle", "Pose_SMG", "Pose_Rocket"]:
		scene = Node3D.new()
		root.add_child(scene)
		var camera := Camera3D.new()
		scene.add_child(camera)
		camera.position = Vector3(2.1, 1.08, -0.15)
		camera.look_at(Vector3(0.0, 1.08, -0.15))
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = 0.65
		camera.current = true
		var world := WorldEnvironment.new()
		var env := Environment.new()
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.12, 0.15, 0.19)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color.WHITE
		env.ambient_light_energy = 0.65
		world.environment = env
		scene.add_child(world)
		var light := DirectionalLight3D.new()
		light.rotation_degrees = Vector3(-35, -30, 0)
		light.light_energy = 0.7
		scene.add_child(light)
		var model = load("res://assets/characters/unitychan_battle/battle_presentation.glb").instantiate()
		scene.add_child(model)
		skeleton = model.find_child("Skeleton3D", true, false)
		skeleton.modifier_callback_mode_process = Skeleton3D.MODIFIER_CALLBACK_MODE_PROCESS_MANUAL
		skeleton.reset_bone_poses()
		skeleton.skeleton_updated.connect(capture_modified_pose)
		var weapon = load("res://scenes/weapons/" + configs[label].scene + ".tscn").instantiate()
		scene.add_child(weapon)
		weapon.scale = Vector3.ONE * 0.44
		weapon.position = vec(configs[label].weapon_origin)
		var row := {"static": true, "animation_playback": false, "config": configs[label], "hands": {}}
		for side in ["Right", "Left"]:
			var shoulder := bone(side + "Arm")
			var elbow := bone(side + "ForeArm")
			var wrist := bone(side + "Hand")
			var marker = weapon.get_node("PrimaryGrip" if side == "Right" else "SupportGrip")
			var target := Marker3D.new()
			scene.add_child(target)
			target.global_transform = marker.global_transform
			var pole := Marker3D.new()
			scene.add_child(pole)
			pole.position = shoulder + Vector3(0.25 if side == "Right" else -0.25, -0.25, 0.10)
			var ik := TwoBoneIK3D.new()
			skeleton.add_child(ik)
			ik.setting_count = 1
			ik.set_root_bone_name(0, "Character1_" + side + "Arm")
			ik.set_middle_bone_name(0, "Character1_" + side + "ForeArm")
			ik.set_end_bone_name(0, "Character1_" + side + "Hand")
			ik.set_target_node(0, ik.get_path_to(target))
			ik.set_pole_node(0, ik.get_path_to(pole))
			ik.set_pole_direction(0, SkeletonModifier3D.SECONDARY_DIRECTION_PLUS_Z if side == "Right" else SkeletonModifier3D.SECONDARY_DIRECTION_MINUS_Z)
			row.hands[side] = {"arm_length_m": shoulder.distance_to(elbow) + elbow.distance_to(wrist), "shoulder_to_target_m": shoulder.distance_to(target.position), "target": [target.position.x, target.position.y, target.position.z], "wrist_frame_authored": false, "finger_contact_authored": false}
		for frame in 3:
			skeleton.advance(1.0 / 60.0)
			await process_frame
		for side in ["Right", "Left"]:
			var marker = weapon.get_node("PrimaryGrip" if side == "Right" else "SupportGrip")
			row.hands[side]["marker_to_wrist_m"] = marker.global_position.distance_to(rendered_hands[side])
		row["muzzle_direction_error_deg"] = rad_to_deg((-weapon.get_node("Muzzle").global_basis.z.normalized()).angle_to(Vector3.FORWARD))
		row["visual_acceptance"] = "NOT ACCEPTED: position-only diagnostic; no wrist/finger grasp definition"
		report[label] = row
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("BUNNY_EVIDENCE") + "/" + label + ".png")
		scene.free()
		await process_frame
	var f := FileAccess.open(OS.get_environment("BUNNY_EVIDENCE") + "/static_measurements.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "\t"))
	print("STATIC_POSE_GATE: BLOCKED — no position-only PASS")
	quit(1) # Gate A is not accepted; measurements completing is not a PASS.

func bone(suffix: String) -> Vector3:
	return skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("Character1_" + suffix)).origin)

func vec(a: Array) -> Vector3:
	return Vector3(a[0], a[1], a[2])

func capture_modified_pose() -> void:
	for side in ["Right", "Left"]:
		rendered_hands[side] = bone(side + "Hand")
