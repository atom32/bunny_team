extends Node
## Fresh normal boot/menu/deployment. Scripted viewport clicks, NOT human playtest.
var out := OS.get_environment("BUNNY_EVIDENCE")
var failures: Array[String] = []
var tree: SceneTree
var checks := 0
var evidence := {"method":"Normal BOOT/default profile; headless callbacks or native viewport clicks; not human first-hour acceptance", "steps":[]}

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message); push_error(message)

func _ready() -> void: _run.call_deferred()

func _frames(count := 3) -> void:
	for tick in count: await tree.process_frame

func _capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	if tree.root.get_texture().get_image().save_png(out.path_join(name + ".png")) != OK: failures.append("Capture failed " + name)
	var texts := []
	for control in tree.current_scene.find_children("*", "Control", true, false):
		if control.is_visible_in_tree() and (control is Label or control is Button): texts.append(control.text)
	evidence.steps.append({"name":name,"scene":tree.current_scene.scene_file_path,"visible_text":texts})

func _click(button: Button) -> void:
	if not is_instance_valid(button): failures.append("Missing button"); return
	var presses := [0]
	var count_press := func(): presses[0] += 1
	button.pressed.connect(count_press)
	if DisplayServer.get_name() == "headless": button.pressed.emit()
	else:
		await RenderingServer.frame_post_draw
		await tree.process_frame
		for pressed in [true,false]:
			var event := InputEventMouseButton.new()
			event.position = button.get_global_rect().get_center()
			event.button_index = MOUSE_BUTTON_LEFT; event.pressed = pressed
			tree.root.push_input(event)
			await tree.process_frame
	await _frames()
	check(presses[0] == 1, "Button activates exactly once")

func _button(key: String) -> Button:
	for button in tree.current_scene.find_children("*", "Button", true, false):
		if button.text in [key, TranslationServer.translate(key)] and button.is_visible_in_tree(): return button
	return null

func _wait_scene(path: String, timeout_ms := 15000) -> bool:
	# Native Compatibility can render 600 frames before the five-second transit
	# finishes. Wait for the real scene/transition, not a renderer-dependent count.
	var deadline := Time.get_ticks_msec() + timeout_ms
	while Time.get_ticks_msec() < deadline:
		await tree.process_frame
		if is_instance_valid(tree.current_scene) and tree.current_scene.scene_file_path == path and not tree.root.get_node("GameState").is_transitioning(): return true
	var scene := tree.current_scene
	evidence["scene_wait_timeout"] = {"wanted":path,"actual":scene.scene_file_path if is_instance_valid(scene) else "","paused":tree.paused,"flow_mode":FlowMenu.mode,"transitioning":GameState.is_transitioning(),"window_focused":DisplayServer.window_is_focused() if DisplayServer.get_name() != "headless" else false}
	if is_instance_valid(scene) and "elapsed" in scene: evidence.scene_wait_timeout["scene_elapsed"] = scene.elapsed
	print("NORMAL_START_WAIT_TIMEOUT: ",JSON.stringify(evidence.scene_wait_timeout))
	check(false, "Timed out waiting for scene " + path)
	await _capture("wait_timeout")
	return false

func _run() -> void:
	tree = get_tree()
	tree.current_scene = null # Keep this coordinator through actual scene changes.
	var resume := "--resume" in OS.get_cmdline_user_args()
	var profile = ProfileRuntime.get_profile()
	check(not ProfileRuntime.recovery_required, "Normal profile initialization needs no recovery")
	check(not profile.sortie_checkpoint.is_empty() if resume else not SaveService.save_exists(), "Expected actual suspended profile or fresh user directory")
	if "--english" in OS.get_cmdline_user_args(): check(GameLanguage.set_language("en", true) == OK, "Set isolated player language preference")
	tree.change_scene_to_file("res://scenes/presentation/slice/boot.tscn")
	await _frames(10)
	var boot = tree.current_scene
	# The backdrop legitimately initializes presentation-only warehouse cells.
	# Watching the cards afterwards must not mutate even those cells.
	var before: Dictionary = profile.to_dict()
	if resume and boot.opening: await _click(_button("SKIP OPENING  /  ENTER"))
	if not resume:
		check(boot.opening, "Fresh normal BOOT shows opening without a fixture flag")
		for index in 3:
			check(boot.intro_card == index, "Real opening timer reaches card " + str(index))
			var found_dialogue := false
			for label in boot.find_children("*", "Label", true, false):
				if label.text == boot.INTRO[index][1]:
					found_dialogue = true
					check(label.get_parent().get_global_rect().encloses(label.get_global_rect()), "Three spoken lines fit inside the actual opening panel")
					check(label.get_combined_minimum_size().y <= label.size.y, "Translated text fits its label")
			check(found_dialogue, "Actual opening contains the authored spoken exchange")
			check(TranslationServer.translate(boot.INTRO[index][1]) != boot.INTRO[index][1] if TranslationServer.get_locale() == "zh_CN" else TranslationServer.translate(boot.INTRO[index][1]) == boot.INTRO[index][1], "Opening has real bilingual text")
			await _capture("0%d_opening" % (index+1))
			if index < 2: await tree.create_timer(8.1).timeout
		check(profile.to_dict() == before, "Watching the opening invents no inventory or story progress")
		await _click(_button("SKIP OPENING  /  ENTER"))
		check(not boot.opening, "Real skip button opens menu")
	await _capture("04_menu")
	await _click(_button("RESUME SORTIE" if resume else "START"))
	if not resume:
		if not await _wait_scene("res://scenes/presentation/slice/hideout.tscn"): failures.append("START did not reach base"); _finish(); return
		await _frames(15)
		await _capture("05_base")
		await _click(tree.current_scene.find_child("NavOperations", true, false))
		await _capture("06_operation")
		await _click(_button("CONFIRM DEPLOYMENT"))
	if not await _wait_scene("res://scenes/battle/battle.tscn"): failures.append("Deployment/resume did not reach battle"); _finish(); return
	await tree.create_timer(3.0).timeout # Arrival zoom has actually ended.
	var battle = tree.current_scene
	var director = battle.get_node_or_null("FirstMissionDirector")
	var beacon = battle.area_root.find_child("ExtractionPoint",true,false)
	check(battle.session.area_id == &"first_mission_area" and battle.session.mission_id == &"first_mission", "Normal menu flow deploys/resumes actual first sortie")
	check(director != null and director.stage == director.Stage.MOVE, "No test teleport or forced tutorial progression")
	check(battle.player.is_physics_processing() and battle.player.health == battle.player.max_health, "Production player remains active with normal health")
	check(not beacon.can_extract(battle.session) and not beacon.is_in_group("interactable") and beacon.get_interaction_prompt(battle.player,battle.session).is_empty(), "Locked link neither advertises a later lesson nor steals interact focus")
	for visual in beacon.get_children():
		if visual is VisualInstance3D: check(not visual.is_visible_in_tree(), "Locked return visual cannot cover spawn")
	check(tree.root.get_camera_3d() == battle.camera and is_equal_approx(battle.camera.size,19.5), "Arrival ends at unmodified production camera")
	check(battle.checkpoint_layout_signature == "bdcfc65416908d80105ab4a6b91e68efbd9b1fae401fc1ebdd9b7defa6481333", "Physical layout matches actual pre-change normal-deployment baseline")
	check(SortieRuntime.save_checkpoint() == OK, "Normal first sortie really saves for independent resume")
	evidence["tutorial_stage"] = director.stage if director else -1
	evidence["area"] = battle.session.area_id
	evidence["mission"] = battle.session.mission_id
	evidence["health"] = battle.player.health
	evidence["layout"] = battle.checkpoint_layout_signature
	await _capture("07_first_mission")
	_finish()

func _finish() -> void:
	evidence["failures"] = failures
	evidence["checks"] = checks
	if out.is_empty(): out = ProjectSettings.globalize_path("user://")
	var file := FileAccess.open(out.path_join("normal_start.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(evidence,"\t")); file.close()
	tree.root.get_node("AudioDirector").shutdown_for_test()
	print("NORMAL_START_TEST: %s (%d checks)" % ["PASS" if failures.is_empty() else "FAIL", checks])
	tree.quit(0 if failures.is_empty() else 1)

# QA-only count adjustment from the orchestrator's actual Q02 outing evidence.
# It never changes a profile. Old signed fixtures keep the default zero offset.
func _expected_returns(canonical: int) -> int:
	var extra := 0
	for arg in OS.get_cmdline_user_args():
		if not arg.begins_with("--campaign-extra-returns="):continue
		var value:=arg.get_slice("=",1)
		if not value.is_valid_int() or int(value)<0 or int(value)>2:
			check(false,"invalid QA return offset, expected0..2 actual extra Q02 outings")
			return -1
		extra=int(value)
	return canonical+extra
