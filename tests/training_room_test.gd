extends Node
var failures := 0
var checks := 0
var room: Node3D
var capture := false

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _ready() -> void:
	_run.call_deferred()

func step(seconds: float) -> void:
	for frame in int(seconds * 60.0):
		room.motion._process(1.0 / 60.0)
		room._process(1.0 / 60.0)
	await get_tree().process_frame

func select(id: String) -> void:
	room.select_station(id)
	var continuous := true
	var clear_of_bench := true
	for frame in 2400:
		var before: Vector3 = room.actor.position
		room.motion._process(1.0 / 60.0)
		room._process(1.0 / 60.0)
		continuous = continuous and before.distance_to(room.actor.position) < 0.08
		if room.motion.phase == "walk":
			clear_of_bench = clear_of_bench and not Rect2(1.6, -0.8, 1.8, 0.7).has_point(Vector2(room.actor.position.x, room.actor.position.z))
		if room.motion.pending_station.is_empty(): break
	check(room.motion.station == id and room.motion.pending_station.is_empty(), "station arrival completes: " + id)
	check(continuous, "station changes walk/stand without teleporting: " + id)
	check(clear_of_bench, "furniture routes go around bench instead of through seat: " + id)
	await get_tree().process_frame

func click(button: Button) -> void:
	if DisplayServer.get_name() == "headless":
		button.pressed.emit()
		return
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = button.get_global_rect().get_center()
		event.pressed = pressed
		Input.parse_input_event(event)
		await get_tree().process_frame

func shot(name: String) -> void:
	if not capture: return
	await RenderingServer.frame_post_draw
	var folder := OS.get_environment("BUNNY_EVIDENCE")
	check(not folder.is_empty() and get_viewport().get_texture().get_image().save_png(folder.path_join(name + ".png")) == OK, "capture " + name)

func _run() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	if capture and not "--english" in OS.get_cmdline_user_args(): GameLanguage.set_language("zh_CN", false)
	var profile := ProfileRuntime.new_profile()
	var hub = load("res://scenes/presentation/slice/hideout.tscn").instantiate()
	get_tree().root.add_child(hub)
	get_tree().current_scene = hub
	hub.show_section("Rest")
	await get_tree().process_frame
	var before := JSON.stringify(profile.to_dict())
	var entry := hub.screen.find_child("OpenTrainingRoom", true, false) as Button
	check(entry != null and entry.visible, "quarters exposes training entry")
	entry.pressed.emit()
	for frame in 240:
		await get_tree().process_frame
		if get_tree().current_scene and get_tree().current_scene.scene_file_path.ends_with("training_room.tscn") and not GameState.is_transitioning(): break
	room = get_tree().current_scene
	check(room != null and room.scene_file_path.ends_with("training_room.tscn"), "real base button transitions into training room")
	if not room or not room.has_method("select_station"):
		get_tree().quit(1)
		return
	room.set_process(false)
	room.motion.set_process(false)
	var motion = room.motion
	var actor: PlayerController = room.actor
	var sk := actor.character_skeleton
	check(actor.preview_mode and not actor.is_physics_processing() and not actor.is_processing(), "training actor never runs combat or movement controller")
	check(not actor.combat_rig.visible and not actor.animation_tree.active and not actor.retarget_modifier.active, "unarmed driver owns skeleton without combat overwrite")
	check(motion.semantics.size() == 52, "existing body and finger map reused")
	check(room.has_node("Environment/Equipment/Treadmill/BeltMarks") and room.camera != null, "complete physical equipment scene and active camera loaded")
	var translations: Array[Vector3] = []
	for i in sk.get_bone_count(): translations.append(sk.get_bone_pose_position(i))
	await select("stretch")
	await step(4.5)
	var hand_left := sk.get_bone_global_pose(sk.find_bone("Character1_LeftHand")).origin
	var hand_right := sk.get_bone_global_pose(sk.find_bone("Character1_RightHand")).origin
	var head := sk.get_bone_global_pose(sk.find_bone("Character1_Head")).origin
	check(hand_left.y > head.y and hand_right.y > head.y, "overhead stretch raises both hands above head")
	# The headless display uses a square viewport; framing assertions belong to actual 1280×720 rendering.
	if DisplayServer.get_name() != "headless":
		for name in ["LeftHand", "RightHand", "Head", "LeftFoot", "RightFoot"]:
			var world := sk.to_global(sk.get_bone_global_pose(sk.find_bone("Character1_" + name)).origin)
			check(Rect2(348, 112, 538, 512).has_point(room.camera.unproject_position(world)), "full-body default clears interface: " + name)
	await shot("stretch_front")
	if capture:
		var tab := InputEventKey.new()
		tab.physical_keycode = KEY_TAB
		tab.pressed = true
		Input.parse_input_event(tab)
		await get_tree().process_frame
		check(not room.screen.visible, "Tab hides interface even with station button focus")
		await shot("stretch_clean")
		Input.parse_input_event(tab)
		await get_tree().process_frame
		check(room.screen.visible, "Tab restores interface")
	var q := sk.get_bone_pose_rotation(sk.find_bone("Character1_Spine1"))
	await step(5.0)
	check(q.angle_to(sk.get_bone_pose_rotation(sk.find_bone("Character1_Spine1"))) > 0.1, "side bend changes from left to right")
	room.yaw = PI / 2.0
	room._update_camera(0.0)
	await shot("stretch_side")
	var time: float = motion.exercise_elapsed
	var pose := sk.get_bone_pose_rotation(sk.find_bone("Character1_LeftArm"))
	room.toggle_pause()
	await step(2.0)
	check(is_equal_approx(time, motion.exercise_elapsed) and pose.is_equal_approx(sk.get_bone_pose_rotation(sk.find_bone("Character1_LeftArm"))), "pause freezes actual pose and timer")
	room.toggle_pause()
	motion.playback_speed = 0.5
	await step(2.0)
	check(absf(motion.exercise_elapsed - time - 1.0) < 0.001, "half-speed affects motion and timer equally")
	motion.playback_speed = 1.0
	await click(room.station_buttons.treadmill)
	check(motion.pending_station == "treadmill", "real treadmill button callback selects station")
	await select("treadmill")
	await step(2.0)
	check(absf(actor.position.x) < 0.01 and actor.position.y > 0.1, "walking clip aligned to elevated treadmill belt")
	var travel: float = room.belt_travel
	var leg := sk.get_bone_pose_rotation(sk.find_bone("Character1_LeftUpLeg"))
	await step(0.3)
	check(not is_equal_approx(travel, room.belt_travel) and leg.angle_to(sk.get_bone_pose_rotation(sk.find_bone("Character1_LeftUpLeg"))) > 0.03, "belt and actual gait both move")
	room.yaw = PI / 2.0
	room._update_camera(0.0)
	await shot("treadmill_side")
	await select("bench")
	await step(3.0)
	check(motion.seated, "bench uses full authored sitting entry")
	room.reset_camera()
	room._update_camera(0.0)
	await shot("bench_seated")
	var hip_y: float = (sk.global_transform * sk.get_bone_global_pose(sk.find_bone("Character1_Hips"))).origin.y
	check(hip_y > 0.42 and hip_y < 0.78, "seated pelvis aligned with physical training bench")
	await step(13.0)
	check(motion.repetitions >= 1, "bench completes real sit/stand cycles")
	# Interrupt the sit/stand loop while seated, then exit safely before changing furniture.
	await select("rest")
	await step(5.0)
	check(motion.seated and motion.clip_name == "Sitting_Idle", "rest settles on furniture instead of exercising forever")
	await step(5.0)
	check(motion.repetitions == 0, "rest has no fake exercise count")
	await select("stretch")
	await step(4.0)
	# Interrupt the lateral bench approach, exactly on its front waypoint row.
	motion.select_station("bench")
	var reached_front := false
	for frame in 1800:
		motion._process(1.0 / 60.0)
		if actor.position.x > 2.55 and actor.position.x < 3.3 and absf(actor.position.z - 1.25) < 0.001:
			reached_front = true
			break
	check(reached_front, "bench approach reaches front aisle for interruption check")
	motion.select_station("treadmill")
	await select("treadmill")
	await select("idle")
	await step(1.0)
	check(motion.station == "idle" and not motion.seated and actor.position.x < -2.0, "finish set returns to mat edge without weapons")
	for i in sk.get_bone_count():
		check(sk.get_bone_pose_scale(i).is_equal_approx(Vector3.ONE) and sk.get_bone_pose_position(i).is_equal_approx(translations[i]), "no bone length/scale/translation edits: " + sk.get_bone_name(i))
	room.auto_orbit = true
	var old_yaw: float = room.yaw
	room._process(1.0)
	check(room.yaw != old_yaw, "orbit rotates camera, not character")
	room.reset_camera()
	check(not room.auto_orbit and is_equal_approx(room.distance, 4.4), "full body resets orbit and distance")
	for id in ["stretch", "treadmill", "bench"]:
		for index in 24:
			room.camera_focus = motion.STATIONS[id] + Vector3(0, 1, 0)
			room.yaw = TAU * index / 24.0
			# Use the real camera computation at each station, including the widest allowed distance.
			var old_position: Vector3 = actor.position
			actor.position = motion.STATIONS[id]
			room.distance = 4.6
			room._update_camera(0.0)
			check(absf(room.camera.position.x) < 8.3 and room.camera.position.z > -6.9, "orbit stays inside authored room walls")
			actor.position = old_position
	room.reset_camera()
	check(JSON.stringify(profile.to_dict()) == before, "all exercises preserve inventory, body identity, progression and save payload")
	room.return_to_quarters()
	for frame in 240:
		await get_tree().process_frame
		if get_tree().current_scene and get_tree().current_scene.scene_file_path.ends_with("hideout.tscn") and not GameState.is_transitioning(): break
	check(get_tree().current_scene and get_tree().current_scene.scene_file_path.ends_with("hideout.tscn") and get_tree().current_scene.section == "Rest", "real return transition restores personal quarters")
	check(JSON.stringify(profile.to_dict()) == before, "return does not write new profile fields or consume resources")
	print("TRAINING_ROOM_TEST: ", "PASS" if failures == 0 else "FAIL", " / ", checks, " checks")
	AudioDirector.shutdown_for_test()
	get_tree().quit(0 if failures == 0 else 1)
