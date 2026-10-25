extends Node
## Actual production Controls; declared display/outcome fixtures, not human gameplay.
var checks := 0
var failures: Array[String] = []
var surface: SubViewport

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)

func frames(count := 5) -> void:
	for index in count: await get_tree().process_frame

func capture(name: String, whole_window := false) -> void:
	if DisplayServer.get_name() == "headless" or OS.get_environment("BUNNY_EVIDENCE").is_empty(): return
	await RenderingServer.frame_post_draw
	var viewport := get_viewport() if whole_window else surface
	check(viewport.get_texture().get_image().save_png(OS.get_environment("BUNNY_EVIDENCE").path_join(name+".png")) == OK,"rendered screenshot saved")

func click(button: Button, whole_window := false) -> void:
	check(button != null and button.is_visible_in_tree() and not button.disabled,"enabled native action is visible")
	if not button or button.disabled: return
	if DisplayServer.get_name() == "headless": button.pressed.emit()
	else:
		for pressed in [true,false]:
			var event := InputEventMouseButton.new()
			event.position = button.get_global_rect().get_center()
			event.button_index = MOUSE_BUTTON_LEFT
			event.pressed = pressed
			(get_viewport() if whole_window else surface).push_input(event)
			await get_tree().process_frame
	await frames()

func _ready() -> void:
	await frames()
	var cut := FieldManualStyle.cut_style(FieldManualStyle.SIGNAL,FieldManualStyle.INK)
	var copy := cut.duplicate()
	check(copy.get("fill") == FieldManualStyle.SIGNAL and copy.get("edge") == FieldManualStyle.INK,"cut-corner resources retain colors when duplicated")
	FlowMenu.save_path = "user://remake_completion.json"
	surface = SubViewport.new()
	surface.size = Vector2i(1280,720)
	surface.own_world_3d = true
	surface.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	surface.handle_input_locally = true
	add_child(surface)
	var display := TextureRect.new()
	display.texture = surface.get_texture()
	display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(display)
	await _combat()
	await _result()
	await _contacts()
	await _menus()
	SortieRuntime.clear_session()
	AudioDirector.shutdown_for_test()
	print("REMAKE_COMPLETION_UI_TEST: %s (%d checks; native input: %s)" % ["PASS" if failures.is_empty() else "FAIL",checks,DisplayServer.get_name() != "headless"])
	get_tree().quit(0 if failures.is_empty() else 1)

func _combat() -> void:
	var profile := ProfileRuntime.new_profile()
	profile.first_mission_completed = true
	var deployment := DeploymentPlan.deploy(profile,&"street_district",&"streets_recon","",false)
	check(deployment.error == OK,"real deployment prepares finite combat load")
	var battle = load("res://scenes/battle/battle.tscn").instantiate()
	battle.result_transition_enabled = false
	surface.add_child(battle)
	await frames(15)
	for enemy in battle.enemy_container.get_children(): enemy.set_physics_process(false)
	battle.player.set_physics_process(false)
	var hud: BattleHUD = battle.hud
	for language in ["zh_CN","en"]:
		GameLanguage.set_language(language,false)
		await frames()
		await capture("combat_"+language)
		for pressed in [true,false]:
			var event := InputEventAction.new()
			event.action = "route_map"
			event.pressed = pressed
			surface.push_input(event)
			await get_tree().process_frame
		check(battle.area_root.route_map.expanded,"normal map input opens the live route map")
		await capture("route_map_"+language)
		for pressed in [true,false]:
			var event := InputEventAction.new()
			event.action = "route_map"
			event.pressed = pressed
			surface.push_input(event)
			await get_tree().process_frame
		check(not battle.area_root.route_map.expanded,"normal map input closes without pausing the raid")
	# Freeze the binding owner only for declared low-health/reload display fixtures.
	battle.set_process(false)
	var before := SortieCheckpoint.session_data(battle.session)
	hud.set_health(25,260)
	hud.set_ammo(0,30,60)
	hud.set_reload_remaining(1.6)
	check(hud.reload_bar.visible and not hud.ammo_action.visible,"reload progress replaces the empty-magazine prompt")
	hud.set_reload_remaining(.8)
	check(is_equal_approx(hud.reload_bar.value,.8),"reload bar follows observed remaining time, not an invented duration")
	await capture("combat_reload_fixture")
	hud.set_reload_remaining(0)
	hud.set_ammo(0,30,0)
	check(hud.ammo_action.visible and hud.ammo_action.text == tr("NO AMMUNITION"),"no ammunition is distinguished from reloadable empty magazine")
	hud.set_ammo(0,30,10)
	check(hud.ammo_action.text.contains(ControlBindings.label("reload")),"empty magazine shows the current reload binding")
	check(SortieCheckpoint.session_data(battle.session) == before,"display state fixtures change no real ammunition, inventory or objectives")
	for extent in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(1920,1200),Vector2i(2560,1080)]:
		surface.size = extent
		await frames()
		var centre := Rect2(Vector2(extent)*Vector2(.34,.25),Vector2(extent)*Vector2(.32,.5))
		for name in ["Objectives","Vitals","Weapons"]:
			var panel := hud.get_child(0).get_node(name) as Control
			check(Rect2(Vector2.ZERO,Vector2(extent)).encloses(panel.get_global_rect()),"HUD panel stays in the viewport: "+name)
			check(not centre.intersects(panel.get_global_rect()),"HUD leaves action centre clear: "+name)
	battle.free()
	await frames()
	SortieRuntime.clear_session()
	surface.size = Vector2i(1280,720)

func _result() -> void:
	for language in ["zh_CN","en"]:
		GameLanguage.set_language(language,false)
		for ending in ["extract","fail","abandon"]:
			var profile := ProfileRuntime.new_profile()
			var session := SortieSession.create_from_profile(profile.create_sortie_request(),profile)
			check(session != null and session.activate(),"real session factory for result fixture")
			if ending == "extract": session.complete_extraction()
			elif ending == "fail": session.fail()
			else: session.abandon()
			var outcome := SortieOutcome.create_from_session(session)
			var before := profile.to_dict()
			var ui := ResultUI.new()
			ui.configure(outcome)
			surface.add_child(ui)
			await frames()
			var panel := ui.find_child("DebriefPanel",true,false) as Control
			check(panel.get_global_rect().encloses(ui.return_button.get_global_rect()),"return action remains outside the scrollable report")
			check(ui.find_child("SettlementNotice",true,false) != null,"settlement is explicitly pending until return")
			await capture("result_"+ending+"_"+language)
			ui.set_return_pending(true)
			ui._refresh_language()
			await frames()
			check(ui.return_button.disabled and ui.feedback_button.disabled,"language rebuild cannot re-enable a pending return")
			ui.show_return_error(tr("Could not save: ")+"TEST")
			ui._refresh_language()
			await frames()
			check(ui.return_error_label.visible and ui.return_error_label.text.contains("TEST"),"retry error survives a presentation rebuild")
			var activated := [0]
			ui.return_requested.connect(func(): activated[0] += 1)
			await click(ui.return_button)
			check(activated[0] == 1,"fixed footer return action activates exactly once")
			check(profile.to_dict() == before,"result inspection/callback does not settle rewards itself")
			await capture("result_retry_"+ending+"_"+language)
			ui.free()
			await frames()

func _contacts() -> void:
	var profile := ProfileRuntime.new_profile()
	profile.credits = 0
	for language in ["zh_CN","en"]:
		GameLanguage.set_language(language,false)
		var panel := ContactPanel.new()
		panel.position = Vector2(42,148)
		panel.size = Vector2(1196,474)
		surface.add_child(panel)
		await frames()
		var before := profile.to_dict()
		await click(panel.find_child("Contact_shen_yanshuang",true,false))
		var shop := panel.find_child("SupplyPanel",true,false) as SupplyPanel
		var blocked := shop.find_children("Supply_buy_*","Button",true,false)
		check(blocked.size() > 0 and blocked.all(func(button): return button.disabled and not button.tooltip_text.is_empty()),"unaffordable purchases explain their disabled state")
		await capture("contact_trade_"+language)
		await click(panel.find_child("ContactQuests",true,false))
		check(panel.selected_tab == "quests" and profile.to_dict() == before,"contact/tab navigation neither trades nor delivers")
		await capture("contact_requests_"+language)
		panel.free()
		await frames()

func _menus() -> void:
	for language in ["zh_CN","en"]:
		GameLanguage.set_language(language,false)
		for mode in ["pause","display","controls","language","feedback","recovery","unavailable"]:
			match mode:
				"pause": FlowMenu.show_pause()
				"display": FlowMenu.show_display_settings(false)
				"controls": FlowMenu.show_control_settings(false)
				"language": FlowMenu.show_language_settings(false)
				"feedback": FlowMenu.show_feedback(false)
				"recovery": FlowMenu.show_save_recovery()
				"unavailable": FlowMenu.show_error(tr("Profile is unavailable. Return to the menu to recover your save."))
			await frames()
			var panel := FlowMenu.screen.find_child("SystemMenu",true,false) as Control
			check(get_viewport().get_visible_rect().encloses(panel.get_global_rect()),"system menu remains inside window: "+mode)
			check(FlowMenu.screen.find_child("MenuScroll",true,false) is ScrollContainer,"long system menus scroll rather than overflow")
			await capture("system_"+mode+"_"+language,true)
			FlowMenu.close()
