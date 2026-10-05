extends Node
const PATH := "user://test_controls.cfg"
var checks := 0
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
func key(value: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = value
	event.keycode = value
	event.pressed = true
	return event
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	if "--read" in OS.get_cmdline_user_args():
		ControlBindings.initialize(PATH)
		check(ControlBindings.current.interact == KEY_F,"second process loads custom interaction")
		check(InputMap.event_is_action(key(KEY_F),"interact"),"loaded binding actually drives input action")
		check(not InputMap.event_is_action(key(KEY_E),"interact"),"old keyboard binding is removed after restart")
	else:
		await exercise()
	FlowMenu.close()
	ControlBindings._publish(ControlBindings.defaults)
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(.3).timeout
	for failure in failures: push_error("CONTROL_SETTINGS: "+failure)
	print("CONTROL_SETTINGS_TEST: %s (%d checks)" % ["PASS" if failures.is_empty() else "FAIL",checks])
	get_tree().quit(0 if failures.is_empty() else 1)

func exercise() -> void:
	check(ControlBindings.valid(ControlBindings.defaults),"project defaults form complete valid control map")
	var joy := InputEventJoypadButton.new()
	joy.button_index = JOY_BUTTON_X
	check(InputMap.event_is_action(joy,"interact"),"existing controller interaction present")
	var draft := ControlBindings.defaults.duplicate()
	draft.interact = KEY_F
	draft.use_dressing = KEY_K
	draft.route_map = KEY_N
	Input.action_press("interact")
	check(ControlBindings.apply(draft,PATH) == OK,"binding configuration saves")
	check(not Input.is_action_pressed("interact"),"applying releases held action")
	check(InputMap.event_is_action(key(KEY_F),"interact") and not InputMap.event_is_action(key(KEY_E),"interact"),"new key works and old key no longer triggers action")
	check(InputMap.event_is_action(joy,"interact"),"keyboard replacement preserves controller event")
	check(InputMap.event_is_action(key(KEY_K),"use_dressing"),"medical action uses custom key")
	check(InputMap.event_is_action(key(KEY_N),"route_map"),"map is an actual remappable action")
	var duplicate := draft.duplicate()
	duplicate.reload = KEY_F
	check(ControlBindings.apply(duplicate,PATH) == ERR_INVALID_PARAMETER,"duplicate assignment rejected")
	check(ControlBindings.current == draft,"invalid assignment does not mutate runtime")
	for value in [0,KEY_ESCAPE,KEY_F11,-4,-5,KEY_UNKNOWN+1]:
		var invalid := draft.duplicate(); invalid.interact = value
		check(not ControlBindings.valid(invalid),"invalid/reserved input rejected")
	var missing := draft.duplicate(); missing.erase("fire")
	check(not ControlBindings.valid(missing),"incomplete map rejected")
	var extra := draft.duplicate(); extra.fake = KEY_P
	check(not ControlBindings.valid(extra),"unknown action rejected")
	var old_disk := FileAccess.get_file_as_string(PATH)
	check(ControlBindings.apply(ControlBindings.defaults,"user://missing_controls_dir/controls.cfg") != OK,"save failure reported")
	check(ControlBindings.current == draft and FileAccess.get_file_as_string(PATH) == old_disk,"save failure preserves running bindings and previous file")
	var config := ConfigFile.new()
	config.set_value("controls","bindings",duplicate)
	config.save("user://bad_controls.cfg")
	ControlBindings.initialize("user://bad_controls.cfg")
	check(ControlBindings.current == ControlBindings.defaults,"corrupt/conflicting saved map falls back safely as a whole")
	ControlBindings.initialize(PATH)
	check(ControlBindings.current == draft,"valid saved map reloads exactly")
	FlowMenu.show_control_settings(false)
	var panel: ControlSettings = FlowMenu.controls_panel
	panel.save_path = PATH
	check(get_tree().paused and panel.buttons.size() == ControlBindings.LABELS.size(),"real settings pauses simulation and exposes every action")
	panel.buttons.reload.pressed.emit()
	FlowMenu._input(key(KEY_ESCAPE))
	check(FlowMenu.mode == "controls" and panel.listening.is_empty(),"Escape cancels capture, not entire settings")
	panel.buttons.reload.pressed.emit()
	FlowMenu._input(key(KEY_F))
	check(panel.listening == "reload" and panel.draft.reload == KEY_R,"conflict shows feedback without losing existing action")
	FlowMenu._input(key(KEY_T))
	check(panel.draft.reload == KEY_T and ControlBindings.current.reload == KEY_R,"successful capture edits only draft before apply")
	panel.apply()
	check(InputMap.event_is_action(key(KEY_T),"reload"),"actual settings Apply publishes saved binding")
	panel.reset_draft()
	check(panel.draft == ControlBindings.defaults and ControlBindings.current.reload == KEY_T,"restore defaults remains draft until applied")
	panel.apply()
	check(ControlBindings.current == ControlBindings.defaults,"default restoration applied")
	ControlBindings.apply(draft,PATH)
	FlowMenu.close()
	check(not get_tree().paused,"leaving settings resumes simulation")
	var hud := BattleHUD.new(); add_child(hud)
	var treatment := MedicalTreatment.new()
	hud.set_medical(treatment)
	check(hud.medical_label.text.begins_with("K /"),"medical HUD shows real binding")
	treatment.free();hud.free()
	await production_inputs()
	if "--capture" in OS.get_cmdline_user_args():
		for locale in ["en","zh_CN"]:
			GameLanguage.set_language(locale,false)
			FlowMenu.show_control_settings(false)
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(OS.get_environment("BUNNY_EVIDENCE").path_join("controls_"+locale+".png"))

func production_inputs() -> void:
	var p := ProfileRuntime.new_profile()
	var deployed := DeploymentPlan.deploy(p,&"street_district",&"streets_recon","user://controls_sortie.json",false)
	check(deployed.error == OK,"production input probe deploys existing gameplay")
	var battle = load("res://scenes/battle/battle.tscn").instantiate()
	add_child(battle)
	battle.result_transition_enabled = false
	battle.player.set_physics_process(false)
	for enemy in battle.enemy_container.get_children(): enemy.set_physics_process(false)
	var terminal: Node3D = battle.area_root.get_node("StreetTerminal")
	battle.player.global_position = terminal.global_position + Vector3(1,0,0)
	battle.player.interaction_component._physics_process(0.0)
	check(battle.player.interaction_component._last_prompt.begins_with("F  "),"actual terminal proximity prompt uses F")
	Input.parse_input_event(key(KEY_F))
	await get_tree().process_frame
	check(terminal.remaining > 0 and not terminal.urgent,"remapped input starts local work")
	var echo := key(KEY_F);echo.echo = true;Input.parse_input_event(echo)
	await get_tree().process_frame
	check(not terminal.urgent,"holding interaction key cannot accidentally opt into noisy uplink")
	terminal.tick(8)
	var state: ObjectiveState = battle.session.get_objective_state(&"streets_terminal")
	check(state.status == ObjectiveState.Status.COMPLETED,"real remapped input reaches terminal gameplay interaction")
	var release := key(KEY_F);release.pressed = false;Input.parse_input_event(release)
	Input.parse_input_event(key(KEY_N))
	await get_tree().process_frame
	check(battle.area_root.route_map.expanded,"real remapped input opens route map")
	release = key(KEY_N);release.pressed = false;Input.parse_input_event(release)
	Input.parse_input_event(key(KEY_M))
	await get_tree().process_frame
	check(battle.area_root.route_map.expanded,"old map key no longer toggles it")
	release = key(KEY_M);release.pressed = false;Input.parse_input_event(release)
	battle.free()
	SortieRuntime.clear_session()
