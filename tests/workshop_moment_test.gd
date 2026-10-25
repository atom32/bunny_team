extends Node
## Controlled presentation fixtures, not a normal-start route or human playtest.
var checks := 0
var failures: Array[String] = []
var room: Node3D
var capture := false

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message); push_error(message)

func _ready() -> void: _run.call_deferred()

func step(seconds: float) -> void:
	for tick in int(seconds*60): room._process(1.0/60.0)
	await get_tree().process_frame

func click(button: Button) -> void:
	if DisplayServer.get_name() == "headless": button.pressed.emit()
	else:
		await RenderingServer.frame_post_draw
		for pressed in [true,false]:
			var event := InputEventMouseButton.new()
			event.position = button.get_global_rect().get_center()
			event.button_index = MOUSE_BUTTON_LEFT; event.pressed = pressed
			get_tree().root.push_input(event)
			await get_tree().process_frame
	await get_tree().process_frame

func shot(name: String) -> void:
	if not capture: return
	await RenderingServer.frame_post_draw
	var path := OS.get_environment("BUNNY_EVIDENCE").path_join(name+".png")
	check(get_tree().root.get_texture().get_image().save_png(path)==OK,"capture "+name)

func _wait_scene(path: String) -> bool:
	var until := Time.get_ticks_msec()+15000
	while Time.get_ticks_msec()<until:
		await get_tree().process_frame
		if is_instance_valid(get_tree().current_scene) and get_tree().current_scene.scene_file_path == path and not GameState.is_transitioning(): return true
	return false

func _run() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	if capture: GameLanguage.set_language("en" if "--english" in OS.get_cmdline_user_args() else "zh_CN",false)
	var presentation_language := TranslationServer.get_locale()
	get_tree().current_scene = null
	var profile := ProfileRuntime.new_profile()
	var before := JSON.stringify(profile.to_dict())
	room = load("res://scenes/presentation/slice/workshop_moment.tscn").instantiate()
	get_tree().root.add_child(room); get_tree().current_scene = room
	room.set_process(false)
	check(room.phase == "locked" and not room.eligible and not room.choices.visible,"unearned direct entry cannot offer completed-upgrade story")
	await step(20)
	check(JSON.stringify(profile.to_dict())==before,"locked scene does not grant a core, upgrade or profile fields")
	room.free(); get_tree().current_scene = null
	profile.first_mission_completed = true # Explicit unit fixture; real earning covered by first_sortie_run.
	check(profile.inventory.add_item_preserving_instance(ItemInstance.new(&"loot.salvage_core_01")),"controlled returned-core fixture fits warehouse")
	check(FirstMissionPreparation.upgrade_weapon()==OK and profile.ar_damage_upgraded,"fixture uses actual durable upgrade transaction")
	var hub = load("res://scenes/presentation/slice/hideout.tscn").instantiate()
	get_tree().root.add_child(hub); get_tree().current_scene = hub
	hub.show_section("Workshop")
	await get_tree().process_frame
	var replay := hub.screen.get_node_or_null("ReplayWorkshopMoment") as Button
	check(replay != null and replay.is_visible_in_tree(),"already-upgraded profile gets optional workshop replay without force-opening")
	before = JSON.stringify(profile.to_dict())
	var saved := FileAccess.get_sha256(SaveService.DEFAULT_SAVE_PATH)
	await click(replay)
	if not await _wait_scene("res://scenes/presentation/slice/workshop_moment.tscn"):
		check(false,"real replay button opens fitting"); _finish(); return
	room = get_tree().current_scene
	room.set_process(false)
	check(room.eligible and room.phase == "approach","saved upgrade enters ordinary approach, not a skipped pose")
	var sk: Skeleton3D = room.actor.character_skeleton
	var translations := []
	var scales := []
	for i in sk.get_bone_count():
		translations.append(sk.get_bone_pose_position(i)); scales.append(sk.get_bone_pose_scale(i))
	var continuous := true
	for tick in 900:
		var old: Vector3 = room.actor.position
		room._process(1.0/60.0)
		continuous = continuous and room.actor.position.distance_to(old)<0.06
		if room.phase == "intro": break
	check(continuous and room.actor.position.distance_to(room.BENCH)<0.04,"actor really walks to bench without a presentation teleport")
	check(absf(wrapf(room.actor.body_visual.rotation.y,-PI,PI))<0.05,"arrival turns actor toward the actual workbench")
	check(room.actor.preview_mode and not room.actor.is_physics_processing() and not room.actor.animation_tree.active and not room.actor.combat_rig.visible,"fitting skeleton never runs gameplay controls or fires")
	await shot("01_arrival")
	for branch in ["tidy","tap"]:
		await step(15)
		check(room.phase == "intro" and room.line_index == 0 and room.next_button.has_focus(),"intro waits on the first line with a keyboard-accessible next button")
		check(room.knock_count == 0,"initial entry and replay start without remembered knocks")
		for i in room.INTRO.size():
			for language in ["en", "zh_CN"]:
				GameLanguage.set_language(language,false)
				check(room.dialogue.get_combined_minimum_size().y<=room.dialogue.size.y,"intro text fits actual label in "+language)
			GameLanguage.set_language(presentation_language,false)
			await click(room.next_button)
		check(room.phase == "choice" and room.choices.visible,"intro reaches explicit spare-screw choice")
		await step(15)
		check(room.phase == "choice","choice waits for player instead of inventing a branch")
		await shot("02_choice_"+branch)
		await click(room.choices.get_node("Choice"+branch.capitalize()))
		var gesture_error := 0.0
		var actual_knocks := 0
		for tick in 220:
			var previous_knocks: int = room.knock_count
			var voice: int = AudioDirector._next_sfx_player
			room._process(1.0/60.0)
			if room.knock_count > previous_knocks:
				actual_knocks += 1
				check(room.phase == "gesture" and room.bolt.position.is_equal_approx(room.SPARE),"each tap physically lands the spare back on the bench")
				check(room.right_target.is_equal_approx(room.SPARE+Vector3(0,0.19,0)),"wrist and spare share each exact contact")
				check(AudioDirector.last_cue == &"workshop_knock" and AudioDirector._next_sfx_player == (voice+1)%AudioDirector._sfx_players.size(),"each landing dispatches exactly one existing metal-impact voice")
			if room.phase == "gesture" and room.reach_weight>0.999:
				var actual := sk.to_global(sk.get_bone_global_pose(sk.find_bone("Character1_RightHand")).origin)
				gesture_error = maxf(gesture_error,actual.distance_to(room.right_target))
			if tick == 102:
				check(room.phase == "gesture" and room.branch == branch,"actual branch button starts its hand gesture")
				await shot("03_gesture_"+branch)
		print("WORKSHOP_GESTURE max hand error ",branch," ",gesture_error)
		check(gesture_error<0.035,"spare-screw gesture stays within real arm reach across the whole path")
		check(room.phase == "fit" and room.tool.visible,"gesture leads into physical driver/bench action")
		check(room.knock_count == (2 if branch == "tap" else 0) and actual_knocks == room.knock_count,"tap has exactly two landings; tidying does not count as knocking")
		check(room.bolt.position.is_equal_approx(room.SPARE if branch == "tap" else room.TRAY),"each branch leaves the physical spare in its own final location")
		var voice_after_gesture: int = AudioDirector._next_sfx_player
		room._refresh_language(); room._refresh_language()
		check(AudioDirector._next_sfx_player == voice_after_gesture,"refreshing subtitles does not replay the knocks")
		await step(1)
		var hand := sk.to_global(sk.get_bone_global_pose(sk.find_bone("Character1_RightHand")).origin)
		print("WORKSHOP_CONTACT ",branch," ",hand," goal ",room.WORK_HAND," error ",hand.distance_to(room.WORK_HAND))
		var shoulder := sk.to_global(sk.get_bone_global_pose(sk.find_bone("Character1_RightArm")).origin)
		var elbow := sk.to_global(sk.get_bone_global_pose(sk.find_bone("Character1_RightForeArm")).origin)
		print("WORKSHOP_REACH shoulder=",shoulder," length=",shoulder.distance_to(elbow)+elbow.distance_to(hand)," requested=",shoulder.distance_to(room.WORK_HAND))
		check(hand.distance_to(room.WORK_HAND)<0.035,"actual hand reaches workbench driver without bone stretching")
		if DisplayServer.get_name() != "headless":
			var clear := Rect2(24,96,1232,426)
			var head := sk.to_global(sk.get_bone_global_pose(sk.find_bone("Character1_Head")).origin)
			check(clear.has_point(room.camera.unproject_position(head+Vector3.UP*0.38)),"medium shot keeps head and ear allowance below top banner")
			check(clear.has_point(room.camera.unproject_position(room.WORK_HAND-Vector3.UP*0.17)),"actual driver tip stays above subtitle panel")
		await shot("04_fitting_"+branch)
		get_tree().paused = true
		room.set_process(true)
		var frozen: float = room.phase_elapsed
		await get_tree().process_frame
		check(room.phase_elapsed == frozen,"scene timeline obeys normal tree pause")
		get_tree().paused = false
		await get_tree().process_frame
		await get_tree().process_frame
		check(room.phase_elapsed>frozen,"unpausing resumes actual scene processing")
		room.set_process(false)
		await step(8)
		check(room.phase == "ending" and room.next_button.visible and not room.tool.visible,"physical fitting leads into player-paced character response")
		await step(15)
		check(room.phase == "ending" and room.line_index == 0 and room.next_button.has_focus(),"ending does not race past unread dialogue")
		check(room.knock_count == actual_knocks and AudioDirector._next_sfx_player == voice_after_gesture,"waiting through the ending does not repeat a knock")
		for i in room._ending_lines().size():
			check(room.dialogue.text == tr(room._ending_lines()[i]),"ending uses the selected branch, not a shared claimed response")
			for language in ["en", "zh_CN"]:
				GameLanguage.set_language(language,false)
				check(room.dialogue.get_combined_minimum_size().y<=room.dialogue.size.y,"ending line fits actual subtitle panel in "+language)
			GameLanguage.set_language(presentation_language,false)
			await click(room.next_button)
		check(room.phase == "done" and room.exits.visible and not room.next_button.visible,"read ending exposes explicit next actions")
		await shot("05_homecoming_"+branch)
		check(JSON.stringify(profile.to_dict())==before and FileAccess.get_sha256(SaveService.DEFAULT_SAVE_PATH)==saved,"branch/replay does not re-charge, reward, save or alter profile")
		if branch == "tidy": await click(room.exits.get_node("ReplayFitting"))
	var preserved := true
	for i in sk.get_bone_count(): preserved = preserved and sk.get_bone_pose_position(i).is_equal_approx(translations[i]) and sk.get_bone_pose_scale(i).is_equal_approx(scales[i])
	check(preserved,"only rotations change; original model bone translations and scales retained")
	await click(room.exits.get_node("NextRequest"))
	check(await _wait_scene("res://scenes/presentation/slice/hideout.tscn") and get_tree().current_scene.section == "Operations","next request uses normal operations; it does not accept a contract")
	_finish()

func _finish() -> void:
	AudioDirector.shutdown_for_test()
	print("WORKSHOP_MOMENT_TEST: %s (%d checks)" % ["PASS" if failures.is_empty() else "FAIL",checks])
	get_tree().quit(0 if failures.is_empty() else 1)
