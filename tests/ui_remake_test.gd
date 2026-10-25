extends Node
## Controlled UI fixtures and native viewport clicks; not a human playtest.
var checks := 0
var failures: Array[String] = []
var surface: SubViewport

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message); push_error(message)

func frames() -> void:
	for index in 5: await get_tree().process_frame

func click(button: Button) -> void:
	check(button != null and not button.disabled, "required enabled action exists")
	if button == null or button.disabled: return
	if DisplayServer.get_name() == "headless": button.pressed.emit()
	else:
		for pressed in [true,false]:
			var event := InputEventMouseButton.new()
			event.position = button.get_global_rect().get_center()
			event.button_index = MOUSE_BUTTON_LEFT
			event.pressed = pressed
			surface.push_input(event)
			await get_tree().process_frame
	await frames()

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless" or OS.get_environment("BUNNY_EVIDENCE").is_empty(): return
	var page := surface.get_child(0)
	if page.has_method("show_section"):
		for index in 600:
			await get_tree().process_frame
			if page.camera.position.distance_to(page.section_camera_position) < .03 and page.relaxed_preview.phase == "idle": break
	await RenderingServer.frame_post_draw
	surface.get_texture().get_image().save_png(OS.get_environment("BUNNY_EVIDENCE").path_join(name+".png"))

func _ready() -> void:
	await get_tree().process_frame
	FlowMenu.save_path = "user://ui_remake_test.json"
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
	var profile := ProfileRuntime.new_profile()
	var boot = load("res://scenes/presentation/slice/boot.tscn").instantiate()
	surface.add_child(boot)
	for language in ["zh_CN","en"]:
		GameLanguage.set_language(language,false)
		boot.show_menu()
		await frames()
		var before := profile.to_dict()
		check(boot.screen.get_node("EnterGame").has_focus(),"primary menu action has keyboard focus")
		await capture("menu_"+language)
		boot._settings()
		await frames()
		check(boot.screen.find_child("MusicVolume",true,false) != null,"settings expose labeled audio controls")
		await capture("settings_"+language)
		boot.show_menu()
		check(profile.to_dict() == before,"menu and preferences never mutate gameplay")
	boot.free()
	await frames()
	# Explicit incomplete-equipment fixture; do not remove owned finite items.
	profile.bunny_selected = false
	profile.loadout.unequip(LoadoutState.SLOT_WEAPON_PRIMARY)
	profile.loadout.unequip(LoadoutState.SLOT_WEAPON_SECONDARY)
	var hub = load("res://scenes/presentation/slice/hideout.tscn").instantiate()
	surface.add_child(hub)
	await frames()
	var inventory_before := profile.inventory.to_dict()
	for language in ["zh_CN","en"]:
		GameLanguage.set_language(language,false)
		hub.show_section("Overview")
		await frames()
		await capture("onboarding_"+language)
		check(hub.screen.get_node("FirstMissionPanel").visible,"new-player next action is visible without toggling")
	GameLanguage.set_language("zh_CN",false)
	hub.show_section("Overview")
	await click(hub.screen.find_child("FirstSortieNext",true,false))
	check(profile.bunny_selected,"first action explicitly selects operator")
	await click(hub.screen.find_child("FirstSortieNext",true,false))
	check(FirstMissionPreparation.has_starter_kit(profile),"second action equips actually owned starter weapons")
	check(profile.inventory.to_dict() == inventory_before,"onboarding creates or consumes no items")
	await click(hub.screen.find_child("FirstSortieNext",true,false))
	check(hub.section == "Operations","next action opens mission review directly")
	check(not hub.screen.find_child("ConfirmDeployment",true,false).disabled,"valid finite load can deploy")
	await capture("mission_review_zh_CN")
	profile.ammo_pack = {"ammo.556_standard":0,"ammo.9mm_standard":0}
	hub.show_section("Operations")
	await frames()
	check(hub.screen.find_child("ConfirmDeployment",true,false).disabled,"dry first sortie is blocked before a wasted click")
	check(not hub.screen.find_child("ConfirmDeployment",true,false).tooltip_text.is_empty(),"blocked deployment explains its reason")
	await capture("mission_blocked_zh_CN")
	var before := profile.to_dict()
	hub.show_section("Overview")
	await click(hub.screen.get_node("ContractsToggle"))
	check(not hub.screen.get_node("FirstMissionPanel").visible,"records cannot obscure a live preparation action")
	await click(hub.screen.get_node("ContractsToggle"))
	check(hub.screen.get_node("FirstMissionPanel").visible,"closing records restores preparation")
	for section in ["Hanger","Operations","Workshop","Rest","Overview"]:
		hub.show_section(section)
		await frames()
	check(profile.to_dict() == before,"navigation and preflight do not mutate loadout or packing")
	# Later-campaign fixture: presentation must remain read-only, not claim progress.
	profile.first_mission_completed = true
	hub.show_section("Overview")
	await frames()
	check(hub.screen.has_node("SortiePreparation"),"returning players see actual carried weight and edit shortcut")
	await capture("returning_overview_zh_CN")
	await click(hub.screen.find_child("EditPreparation",true,false))
	check(hub.section == "Hanger","edit shortcut opens the real warehouse")
	hub.free()
	await frames()
	AudioDirector.shutdown_for_test()
	print("UI_REMAKE_TEST: %s (%d checks; native input: %s)" % ["PASS" if failures.is_empty() else "FAIL",checks,DisplayServer.get_name() != "headless"])
	get_tree().quit(0 if failures.is_empty() else 1)
