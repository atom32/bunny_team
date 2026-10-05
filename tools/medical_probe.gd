extends SceneTree
## Isolated production UI/API route. Injury is an explicit DamagePacket fixture;
## treatment duration runs in the real engine, not by stepping its timer manually.
var evidence := OS.get_environment("BUNNY_EVIDENCE")
var failures: Array[String] = []

func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	if evidence.is_empty() or DisplayServer.get_name() == "headless": quit(2); return
	DirAccess.make_dir_recursive_absolute(evidence)
	var profiles := root.get_node("ProfileRuntime")
	var flow := root.get_node("FlowMenu")
	var language := root.get_node("GameLanguage")
	var runtime := root.get_node("SortieRuntime")
	var med_ids := ["medical.field_dressing", "medical.medkit"]
	var saved_service = load("res://scripts/systems/save_service.gd")
	if "--load" in OS.get_cmdline_user_args():
		check(profiles.load_profile(), "new process loads suspended treatment")
	else:
		profiles.new_profile()
		check(profiles.save_profile() == OK, "isolated new player; no artificial medical grant")
	change_scene_to_file("res://scenes/presentation/slice/boot.tscn")
	await create_timer(1.7).timeout
	language.set_language("zh_CN", false)
	current_scene.show_menu()
	if "--load" in OS.get_cmdline_user_args():
		var pending: Dictionary = profiles.get_profile().sortie_checkpoint.duplicate(true)
		check(pending.world.medical.remaining > 0 and pending.world.medical.remaining < 5, "durable pending treatment, not a fresh use")
		check(_press(current_scene, "RESUME SORTIE"), "production resume button")
		await create_timer(1.1).timeout
		check(current_scene.scene_file_path == "res://scenes/battle/battle.tscn", "resume restores actual battle")
		var actor = current_scene.player
		check(actor.medical.is_active() and actor.health == pending.world.player.health, "resume did not grant health early")
		await _capture("05_resumed_treatment")
		await create_timer(5).timeout
		check(not actor.medical.is_active() and actor.medical.count(med_ids[1]) == 0 and is_equal_approx(actor.health, minf(actor.max_health, pending.world.player.health + 100)), "real-time resumed treatment heals exactly once")
		await _capture("06_treated")
		# Settlement check, not a full first-mission completion or traversal claim.
		check(current_scene.session.complete_extraction(), "explicit extraction fixture completes session")
		current_scene._transition_to_result()
		await create_timer(4.3).timeout
		check(current_scene.scene_file_path == "res://scenes/result/result.tscn", "normal Result reached")
		current_scene._return_to_hanger()
		await create_timer(1.8).timeout
		check(current_scene.scene_file_path == "res://scenes/presentation/slice/hideout.tscn", "normal Hideout reached")
		var profile = saved_service.load_profile()
		check(profile.sortie_checkpoint.is_empty(), "medical outcome clears checkpoint durably")
		var medical_left := 0
		for item in profile.inventory.get_items():
			if String(item.definition_id) in med_ids: medical_left += item.quantity
		check(medical_left == 0, "used medical supplies not refunded by Result")
		_finish()
		return
	check(_press(current_scene, "CONTINUE / BASE"), "normal menu enters base")
	await create_timer(1.8).timeout
	current_scene.show_section("Workshop")
	var supply := current_scene.find_child("SupplyPanel", true, false)
	for id in med_ids:
		var before: int = profiles.get_profile().credits
		var definition = root.get_node("ContentDB").get_item(id)
		# Locate actual buy row by its unique medicine display label.
		var bought := false
		for label in supply.find_children("*", "Label", true, false):
			if label.text != definition.display_name and label.text != TranslationServer.translate(definition.display_name): continue
			for button in label.get_parent().get_children():
				if button is Button and button.is_visible_in_tree() and not button.disabled:
					button.pressed.emit(); bought = true; break
			if bought: break
		check(bought, "production buy-row button: " + id)
		await process_frame
		check(profiles.get_profile().credits == before - definition.base_value, "purchase debits actual credits: " + id)
	await _capture("01_medical_shop")
	current_scene.show_section("Operations")
	var packing := current_scene.find_child("MedicalPacking", true, false)
	var count: SpinBox = packing.find_child("PackDressing", true, false)
	count.value = 1
	await process_frame
	check(profiles.get_profile().medical_pack[med_ids[0]] == 1, "packing UI saves count")
	await _capture("02_medical_packing")
	check(_press(current_scene, "CONFIRM DEPLOYMENT"), "real deployment includes packed medicine")
	await create_timer(1.8).timeout
	_press(current_scene, "SKIP  /  ENTER")
	await create_timer(2).timeout
	check(current_scene.scene_file_path == "res://scenes/battle/battle.tscn", "new first mission entered normally")
	var actor = current_scene.player
	check(actor.medical.count(med_ids[0]) == 1 and actor.medical.count(med_ids[1]) == 1, "actual deployed supplies match purchases and packing")
	actor.receive_damage(load("res://scripts/combat/damage_packet.gd").new(150))
	var wounded: float = actor.health
	_press_action("use_dressing")
	await create_timer(.5).timeout
	check(actor.medical.is_active() and actor.health == wounded, "H action starts timed treatment without instant health")
	await _capture("03_treatment_progress")
	Input.action_press("move_right")
	await create_timer(.12).timeout
	Input.action_release("move_right")
	await create_timer(.35).timeout
	check(not actor.medical.is_active() and actor.medical.count(med_ids[0]) == 1, "ordinary input movement interrupts and retains dressing")
	_press_action("use_dressing")
	await create_timer(2.8).timeout
	check(actor.health == wounded + 40 and actor.medical.count(med_ids[0]) == 0, "real-time dressing completes once")
	_press_action("use_medkit")
	await create_timer(.5).timeout
	flow.show_pause()
	check(actor.medical.is_active(), "medkit remains pending when pause opens")
	check(runtime.save_checkpoint() == OK, "pending medkit durably saved")
	await _capture("04_suspend_during_medkit")
	check(_press(flow, "SUSPEND / SAVE & QUIT"), "actual production suspend/quit")
	_finish(false)

func _press_action(action: String) -> void:
	var down := InputEventAction.new()
	down.action = action
	down.pressed = true
	Input.parse_input_event(down)
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)

func _press(node: Node, caption: String) -> bool:
	for button in node.find_children("*", "Button", true, false):
		if button.text == caption and button.is_visible_in_tree() and not button.disabled:
			button.pressed.emit()
			return true
	return false

func _capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(evidence.path_join(name + ".png")) == OK, "capture " + name)

func check(value: bool, message: String) -> void:
	print("MEDICAL_GRAPH %s: %s" % ["PASS" if value else "FAIL", message])
	if not value: failures.append(message)

func _finish(quit_now := true) -> void:
	root.get_node("AudioDirector").shutdown_for_test()
	print("MEDICAL_GRAPH: " + ("PASS" if failures.is_empty() else "FAIL"))
	if quit_now or not failures.is_empty(): quit(0 if failures.is_empty() else 1)
