extends Node
## Rendered UI events and an explicit failure fixture, with isolated persistence.
var evidence := OS.get_environment("BUNNY_EVIDENCE")
var failures: Array[String] = []
var hub: Node3D
const PATH := "user://alpha_supply_graphical.json"

func _ready() -> void: _run.call_deferred()

func _run() -> void:
	if evidence.is_empty(): get_tree().quit(2); return
	if "--load" in OS.get_cmdline_user_args():
		check(ProfileRuntime.load_profile(PATH), "cross-process load")
		var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(evidence.path_join("expected.json")))
		# JSON numbers are floats; restore typed fields before comparing semantics.
		var expected_profile := ProfileState.from_dict(expected)
		check(expected_profile != null and ProfileRuntime.get_profile().to_dict() == expected_profile.to_dict(), "cross-process wallet, inventory, loadout, relief and loss counters unchanged")
		await _finish()
		return
	if DisplayServer.get_name() == "headless": get_tree().quit(2); return
	var surface := SubViewport.new()
	surface.size = Vector2i(1280,720)
	surface.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	surface.handle_input_locally = true
	get_tree().root.add_child(surface)
	var display := TextureRect.new()
	display.texture = surface.get_texture()
	display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_tree().root.add_child(display)
	reparent(surface)
	GameLanguage.set_language("zh_CN",false)
	var profile := ProfileRuntime.new_profile()
	hub = load("res://scenes/presentation/slice/hideout.tscn").instantiate()
	add_child(hub)
	hub.show_section("Workshop")
	var supply := hub.screen.get_node("SupplyPanel") as SupplyPanel
	supply.save_path = PATH
	await capture("01_supply_buy")
	await click_item(supply,0,&"weapon.pistol_01")
	check(profile.credits == 1250 and SupplyService.count(profile,&"weapon.pistol_01") == 1, "actual buy button spends credits and adds owned pistol")
	check(hub.hanger.hanger_ui.weapon_option.item_count == 4, "Hanger loadout options refresh after purchase")
	await click_item(supply,1,&"weapon.pistol_01")
	check(profile.credits == 1337 and SupplyService.count(profile,&"weapon.pistol_01") == 0, "actual sell button consumes pistol and refunds resale value")
	await capture("02_supply_sell")
	# Explicit recipe fixture, not claimed as looted through traversal.
	profile.inventory.add_item(ItemInstance.new(&"material.scrap",2))
	profile.inventory.add_item(ItemInstance.new(&"material.propellant",1))
	supply._refresh()
	var tabs := supply.find_child("*",true,false) # resolved by type below
	for node in supply.find_children("*","TabContainer",true,false): tabs = node
	tabs.current_tab = 2
	await capture("03_workshop_recipe")
	var before := SupplyService.count(profile,&"ammo.556_standard")
	var exchange: Button
	for button in tabs.get_child(2).find_children("*","Button",true,false):
		if not button.disabled: exchange = button; break
	await click(exchange)
	check(SupplyService.count(profile,&"ammo.556_standard") == before+30 and SupplyService.count(profile,&"material.scrap") == 0, "actual exchange button consumes materials and yields ammunition")
	hub.show_section("Operations")
	await capture("04_risk_briefing")
	# Failure via the real session/outcome path; combat traversal is separately verified.
	var plan := DeploymentPlan.build(profile)
	var session := SortieRuntime.start_sortie(profile.create_sortie_request(SortieRequest.PROTOTYPE_AREA_ID,SortieRequest.PROTOTYPE_MISSION_ID,plan.ammo_ids),profile)
	session.fail()
	var result := ResultUI.new()
	result.configure(SortieRuntime.get_outcome())
	add_child(result)
	hub.hide(); hub.ui.hide(); hub.hanger.hanger_ui.hide()
	await capture("05_loss_debrief")
	check(SortieRuntime.finalize_sortie(PATH) == OK and profile.loadout.to_dict().is_empty(), "loss settlement persists and clears carried equipment")
	result.queue_free(); hub.queue_free()
	await get_tree().process_frame
	profile.credits = 0 # Explicit bankruptcy fixture to exercise relief eligibility.
	hub = load("res://scenes/presentation/slice/hideout.tscn").instantiate()
	add_child(hub); hub.show_section("Workshop")
	supply = hub.screen.get_node("SupplyPanel")
	supply.save_path = PATH
	var relief: Button
	for button in supply.find_children("*","Button",true,false):
		if button.text == tr("EMERGENCY KIT / PISTOL + 45 ROUNDS"): relief = button
	await click(relief)
	check(SupplyService.count(profile,&"weapon.pistol_01") == 1 and not SupplyService.can_claim_relief(profile), "actual emergency button provides a once-per-loss recovery loadout")
	await capture("06_relief_claimed")
	hub.show_section("Hanger")
	await capture("07_recovered_loadout")
	check(hub.hanger.preview_character.weapon_data.id == &"weapon.pistol_01", "restored pistol displays on the production character")
	check(ProfileRuntime.save_profile(PATH) == OK, "base save persists the UI-reconciled stash layout as well")
	var file := FileAccess.open(evidence.path_join("expected.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(profile.to_dict(),"\t")); file.close()
	hub.queue_free()
	await get_tree().process_frame
	await _finish()

func click_item(supply: SupplyPanel, tab: int, id: StringName) -> void:
	var tabs := supply.find_children("*","TabContainer",true,false)[0] as TabContainer
	tabs.current_tab = tab
	# Wait for the newly visible scroll content to receive its actual layout.
	await get_tree().process_frame
	await get_tree().process_frame
	var target: Button
	for label in tabs.get_child(tab).find_children("*","Label",true,false):
		if label.text == GameLanguage.item_name(ContentDB.get_item(id).display_name):
			for node in label.get_parent().get_children():
				if node is Button: target = node
	if target: (tabs.get_child(tab) as ScrollContainer).ensure_control_visible(target)
	await get_tree().process_frame
	await click(target)

func click(button: Button) -> void:
	check(button != null and not button.disabled, "visible action available")
	if not button: return
	await get_tree().process_frame
	var at := button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new(); motion.position = at; motion.global_position = at
	get_viewport().push_input(motion)
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = at; event.global_position = at
		event.button_index = MOUSE_BUTTON_LEFT; event.pressed = pressed
		get_viewport().push_input(event)
		await get_tree().process_frame
	await get_tree().create_timer(.2).timeout

func capture(label: String) -> void:
	await get_tree().create_timer(.75).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(evidence.path_join(label+".png"))

func check(ok: bool, message: String) -> void:
	print("PASS / " if ok else "FAIL / ",message)
	if not ok: failures.append(message)

func _finish() -> void:
	SortieRuntime.clear_session()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(.2).timeout
	print("ALPHA_SUPPLY_PROBE: ", "PASS" if failures.is_empty() else "FAIL", " / ", failures)
	get_tree().quit(0 if failures.is_empty() else 1)
