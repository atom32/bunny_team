extends Node
## Rendered native Controls and input, not manual playtesting. Use isolated user://.
var checks := 0
var failures: Array[String] = []
var surface: SubViewport

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message)

func _ready() -> void:
	_run.call_deferred()

func _frames() -> void:
	for index in 4: await get_tree().process_frame

func _capture(name: String) -> void:
	if DisplayServer.get_name() == "headless" or not "--capture" in OS.get_cmdline_user_args(): return
	var page := surface.get_child(0)
	if page.has_method("show_section"):
		# Wait for the existing camera/idle transition, not a frame halfway through a wall.
		for index in 600:
			await get_tree().process_frame
			if page.camera.position.distance_to(page.section_camera_position) < .03 and page.relaxed_preview.phase == "idle": break
	await RenderingServer.frame_post_draw
	surface.get_texture().get_image().save_png(OS.get_environment("BUNNY_EVIDENCE").path_join(name + ".png"))

func _click(button: Button) -> void:
	if button == null:
		check(false,"required UI button exists")
		return
	if DisplayServer.get_name() == "headless":
		button.pressed.emit()
	else:
		var motion := InputEventMouseMotion.new()
		motion.position = button.get_global_rect().get_center()
		surface.push_input(motion)
		for pressed in [true, false]:
			var event := InputEventMouseButton.new()
			event.position = motion.position
			event.button_index = MOUSE_BUTTON_LEFT
			event.pressed = pressed
			surface.push_input(event)
			await get_tree().process_frame
	await _frames()

func _button(root: Node, caption: String) -> Button:
	for button in root.find_children("*", "Button", true, false):
		if button.text == caption or button.text == tr(caption): return button
	return null

func _run() -> void:
	await get_tree().process_frame
	var fixture := ProfileRuntime.new_profile()
	for spec in [[&"weapon.shotgun_01",1],[&"material.fabric",4],[&"material.scrap",12],[&"medical.field_dressing",1],[&"medical.medkit",1],[&"ammo.556_ap",60],[&"loot.salvage_core_01",1]]:
		check(fixture.inventory.add_item(ItemInstance.new(spec[0],spec[1])),"valid UI fixture item: "+str(spec[0]))
	FlowMenu.save_path = "user://base_manual_ui_test.json"
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
	var boot = load("res://scenes/presentation/slice/boot.tscn").instantiate()
	surface.add_child(boot)
	for language in ["zh_CN", "en"]:
		GameLanguage.set_language(language,false)
		boot.show_menu()
		await _frames()
		check(boot.screen.theme.get_color("font_color","Label") == FieldManualStyle.INK,"menu uses ink on paper")
		var before := ProfileRuntime.get_profile().to_dict()
		check(_button(boot.screen,"LOADOUT") == null,"equipment configuration belongs to the base, not the main menu")
		check(boot.screen.get_children().filter(func(child): return child is Button).size() == 4,"main menu has game entry, settings, quit and optional local feedback")
		check(_button(boot.screen,"SETTINGS") != null and _button(boot.screen,"QUIT") != null,"menu retains settings and quit")
		check(_button(boot.screen,"START") != null or _button(boot.screen,"CONTINUE / BASE") != null or _button(boot.screen,"RESUME SORTIE") != null,"menu retains the existing game entry")
		await _capture("base_menu_"+language)
		await _click(_button(boot.screen,"SETTINGS"))
		check(boot.settings_open and _button(boot.screen,"CONTROLS / KEY BINDINGS") != null,"settings click follows existing input path")
		check(boot.screen.theme.get_stylebox("slider","HSlider").get_minimum_size().y >= 6,"volume rail remains visible on paper")
		await _capture("base_settings_"+language)
		await _click(_button(boot.screen,"BACK"))
		check(not boot.settings_open and ProfileRuntime.get_profile().to_dict() == before,"settings and back preserve profile")
	boot.free()
	await _frames()
	var hub = load("res://scenes/presentation/slice/hideout.tscn").instantiate()
	surface.add_child(hub)
	hub.show_section("Hanger")
	await _frames()
	var ui: HangerUI = hub.hanger.hanger_ui
	var profile := ProfileRuntime.get_profile()
	var before := profile.to_dict()
	for language in ["zh_CN", "en"]:
		GameLanguage.set_language(language,false)
		for section in ["Overview", "Hanger", "Operations", "Workshop", "Rest"]:
			await _click(hub.screen.get_node("Nav"+section))
			check(hub.section == section,"native navigation opens "+section)
			check(ui.visible == (section == "Hanger"),"warehouse visibility follows section")
			check(profile.to_dict() == before,"navigation preserves instances, layout, loadout, credits and packing")
			await _capture("base_"+section.to_lower()+"_"+language)
			if section == "Hanger":
				check(ui.warehouse_panel.get_theme_stylebox("panel").bg_color == FieldManualStyle.SURFACE,"warehouse has opaque paper surface")
				check(ui.stash_grid.get_parent().get_global_rect().end.y < 632,"grid stays above navigation")
				check(ui.packing.get_child(0) is ScrollContainer,"all packing rows remain scroll accessible")
				check(ui.packing.find_children("PackAmmo_*","SpinBox",true,false).size() == DeploymentPlan.default_ammo_counts(profile).size(),"same actual ammo packing controls")
				var layout := profile.stash_layout.duplicate(true)
				ui.stash_grid.refresh()
				check(layout == profile.stash_layout,"refresh preserves manual placement")
			if section == "Overview":
				await _click(hub.screen.get_node("ContractsToggle"))
				check(hub.screen.get_node("CampaignPanel").visible,"contract records still open")
				check(not hub.screen.get_node("ContactsToggle").visible and not hub.screen.get_node("BaseBriefing").visible,"overview shortcuts never cover open records")
				await _capture("base_contracts_"+language)
				await _click(hub.screen.get_node("ContractsToggle"))
				check(hub.screen.get_node("ContactsToggle").visible,"closing records restores overview shortcut")
			if section == "Workshop":
				var contact: ContactPanel = hub.screen.get_node("ContactPanel")
				check(contact.theme.get_color("font_color","Label") == FieldManualStyle.INK,"contact content uses manual theme")
				await _click(contact.find_child("Contact_su_mi",true,false))
				check(contact.contact_id == "su_mi" and profile.to_dict() == before,"contact switch does not transact")
				await _capture("base_workshop_su_mi_"+language)
	for extent in [Vector2i(1440,900),Vector2i(1920,1080)]:
		surface.size = extent
		hub.show_section("Hanger")
		await _frames()
		check(Rect2(Vector2.ZERO,Vector2(extent)).encloses(ui.warehouse_panel.get_global_rect()),"warehouse inside "+str(extent))
		check(hub.screen.get_node("NavRest").get_global_rect().end.x <= extent.x,"navigation inside "+str(extent))
		if extent.x == 1440: await _capture("base_hanger_1440")
	hub.free()
	await _frames()
	AudioDirector.shutdown_for_test()
	for failure in failures: push_error(failure)
	print("BASE_MANUAL_UI_TEST: %s (%d checks; native mouse input: %s)" % ["PASS" if failures.is_empty() else "FAIL",checks,DisplayServer.get_name() != "headless"])
	get_tree().quit(0 if failures.is_empty() else 1)
