extends Node
## Run with isolated user:// storage. Exercises the real cache UI, not a second inventory.
var checks := 0
var failures: Array[String] = []

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message)

func _ready() -> void:
	await get_tree().process_frame
	_pickup_feedback()
	await _cache_ui()
	await _keyboard_cache()
	AudioDirector.shutdown_for_test()
	await get_tree().create_timer(.3).timeout
	for failure in failures: push_error(failure)
	print("CARRIED_BACKPACK_UI_TEST: %s (%d checks)" % ["PASS" if failures.is_empty() else "FAIL",checks])
	get_tree().quit(0 if failures.is_empty() else 1)

func _pickup_feedback() -> void:
	var inventory := InventoryState.new(.3)
	var session := SortieSession.new(inventory,LoadoutState.new())
	session.status = SortieSession.Status.ACTIVE
	var pickup := LootPickup.new()
	pickup.setup(ItemInstance.new(&"material.data_drive",3))
	var before := inventory.to_dict()
	var response := pickup.interact(null,session)
	check(response.result == LootPickup.PickupResult.CAPACITY_FULL,"whole overweight stack rejected even when some units fit")
	check(response.message.contains("0.45") and response.message.contains("0.30") and response.message.contains("Whole stacks only"),"feedback explains required and free weight and whole-stack rule")
	check(inventory.to_dict() == before and not pickup.consumed and pickup.item_instance.quantity == 3,"failed pickup neither removes nor partially transfers world stack")
	GameLanguage.set_language("zh_CN",false)
	response = pickup.interact(null,session)
	check(response.message.contains("负重不足") and response.message.contains("整堆"),"Chinese capacity feedback translated")
	GameLanguage.set_language("en",false)
	pickup.item_instance.fitting = "invalid-fitting"
	check(pickup.interact(null,session).result == LootPickup.PickupResult.INVALID_ITEM,"invalid fitting is not reported as overweight")
	pickup.setup(ItemInstance.new(&"weapon.assault_rifle_01",2))
	check(pickup.interact(null,session).result == LootPickup.PickupResult.INVALID_ITEM,"invalid non-stack quantity is not reported as overweight")
	pickup.setup(ItemInstance.new(&"material.data_drive",2))
	check(pickup.try_pickup(session) == LootPickup.PickupResult.SUCCESS,"exact weight limit accepted")
	before = inventory.to_dict()
	check(pickup.try_pickup(session) != LootPickup.PickupResult.SUCCESS and inventory.to_dict() == before,"repeated pickup cannot duplicate stack")
	pickup.free()
	var duplicate := LootPickup.new()
	duplicate.setup(ItemInstance.from_dict(inventory.get_items()[0].to_dict()))
	check(duplicate.try_pickup(session) == LootPickup.PickupResult.INVALID_ITEM,"duplicate owned ID rejected")
	check(not duplicate.consumed and inventory.to_dict() == before,"duplicate rejection preserves both sides")
	session.status = SortieSession.Status.FAILED
	check(duplicate.try_pickup(session) == LootPickup.PickupResult.INVALID_SESSION,"finished session rejects pickup")
	duplicate.free()

func _cache_ui() -> void:
	var profile := ProfileRuntime.new_profile()
	var base_only := ItemInstance.new(&"ammo.rocket_standard",1)
	profile.inventory.add_item_preserving_instance(base_only)
	profile.inventory.add_item_preserving_instance(ItemInstance.new(&"medical.medkit"))
	var deployed := DeploymentPlan.deploy(profile,SortieRequest.PROTOTYPE_AREA_ID,SortieRequest.PROTOTYPE_MISSION_ID,"",false)
	check(deployed.error == OK,"real deployment creates carried inventory")
	if deployed.error != OK: return
	var session: SortieSession = deployed.session
	var before_profile := profile.to_dict()
	var battle: Node3D = load("res://scenes/battle/battle.tscn").instantiate()
	add_child(battle)
	await get_tree().process_frame
	await get_tree().process_frame
	for enemy in battle.enemy_container.get_children(): enemy.process_mode = Node.PROCESS_MODE_DISABLED
	var ui: Node = battle.get_node("SlicePresentation")
	ui.container = ui.crates.values()[0]
	battle.player.global_position = ui.container.global_position + Vector3.RIGHT
	battle.player.velocity = Vector3.ZERO
	var cargo := ItemInstance.new(&"material.fabric",2)
	session.inventory.add_item_preserving_instance(cargo)
	# More than one screen of carried objects and cache rows must remain accessible.
	for index in 18:
		session.inventory.add_item_preserving_instance(ItemInstance.new(&"material.data_drive"))
	for index in 8:
		var pickup := LootSpawnPoint.LOOT_PICKUP_SCENE.instantiate() as LootPickup
		pickup.setup(ItemInstance.new(&"material.scrap"))
		ui.container.get_parent().add_child(pickup)
	var before_inventory := session.inventory.to_dict()
	var reserved := session.inventory.reserved_weight
	ui._show_loot()
	await get_tree().process_frame
	await get_tree().process_frame
	check(session.inventory.to_dict() == before_inventory and session.inventory.reserved_weight == reserved,"opening list changes no carried data or loaded weight")
	check(profile.to_dict() == before_profile,"opening carried list never modifies warehouse")
	check(not battle.hud.get_node("FieldManualHUD").visible and not get_tree().paused,"inspection hides duplicate HUD without pausing combat")
	check(ui.panel.get_theme_stylebox("panel").bg_color == FieldManualStyle.PAPER,"selected C palette uses opaque paper panels")
	var paper_luminance := FieldManualStyle.PAPER.srgb_to_linear().get_luminance()+.05
	check(paper_luminance/(FieldManualStyle.INK.srgb_to_linear().get_luminance()+.05) >= 4.5,"body text has readable contrast on paper")
	check(paper_luminance/(FieldManualStyle.ACCENT.srgb_to_linear().get_luminance()+.05) >= 4.5,"task accent has readable contrast on paper")
	check(1.05/(FieldManualStyle.ACCENT.srgb_to_linear().get_luminance()+.05) >= 4.5,"primary action text has readable contrast")
	check(ui.carried_list.bbcode_enabled and ui.carried_list.text.contains("[table=4]"),"carried view uses aligned icon/name/quantity/weight columns")
	check(ui.carried_bar.size.y <= 6 and is_equal_approx(ui.carried_bar.value,session.inventory.current_weight),"thin weight bar reads existing actual weight")
	for icon in ui.panel.find_children("*","TextureRect",true,false):
		if icon.has_meta("cache_item_icon"):
			check(icon.size.x <= 40 and icon.size.y <= 40,"cache thumbnail stays inside its row")
	check(ui.carried_list.text.contains("Medkit") and ui.carried_list.text.contains("Field Pack") and ui.carried_list.text.contains("EQUIPPED"),"list includes medical supplies and equipped backpack")
	check(not ui.carried_list.text.contains(ContentDB.get_item(base_only.definition_id).display_name),"warehouse-only ammunition absent from carried list")
	check(ui.carried_list.text.contains("LOADED:") and ui.carried_list.text.contains("5.56 Standard"),"loaded ammunition shown separately from reserve stock")
	check(ui.carried_capacity.text.contains("FREE") and ui.carried_capacity.text.contains("35.00"),"existing backpack capacity and free kg shown")
	check(ui.carried_list.get_content_height() > ui.carried_list.size.y and ui.carried_list.scroll_active,"long carried list scrolls")
	var cache_scroll := ui.panel.find_child("CacheScroll",true,false) as ScrollContainer
	check(cache_scroll != null and cache_scroll.get_child(0).custom_minimum_size.y > cache_scroll.size.y,"long cache list scrolls without overlapping footer")
	var actions_fit := true
	for action in ui.panel.find_children("*","Button",true,false):
		if action.text in ["TAKE","EXCHANGE"]:
			actions_fit = actions_fit and action.get_global_rect().end.x <= cache_scroll.get_global_rect().end.x-8
	check(actions_fit,"English action buttons fit inside the cache column without clipping")
	var weapon_id := session.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY)
	var text_before: String = ui.carried_list.text
	check(session.fire_weapon(weapon_id),"fixture fires through existing runtime logic")
	await get_tree().process_frame
	await get_tree().process_frame
	check(ui.carried_list.text != text_before,"open list refreshes changed magazine count without reopening")
	var pickup: LootPickup = ui.container.contents()[0]
	var quantity_before := _count(session.inventory,pickup.item_instance.definition_id)
	var incoming_id := pickup.item_instance.definition_id
	var amount := pickup.item_instance.quantity
	var capacity := session.inventory.capacity
	session.inventory.capacity = session.inventory.current_weight
	var full_before := session.inventory.to_dict()
	ui._take(pickup)
	check(session.inventory.to_dict() == full_before and not pickup.consumed,"full-capacity UI TAKE preserves inventory and world pickup")
	var feedback := ui.panel.find_child("PickupFeedback",true,false) as Label
	check(feedback.text.contains("Overweight:") and feedback.text.contains("Whole stacks only"),"real cache displays actionable capacity rejection")
	session.inventory.capacity = capacity
	ui._take(pickup)
	check(_count(session.inventory,incoming_id) == quantity_before + amount,"TAKE writes actual carried inventory")
	check(ui.carried_list.text.contains(GameLanguage.item_name(ContentDB.get_item(incoming_id).display_name)),"TAKE immediately refreshes carried view")
	ui._take(pickup)
	check(_count(session.inventory,incoming_id) == quantity_before + amount,"repeated UI TAKE cannot duplicate loot")
	pickup = ui.container.contents()[0]
	var incoming_instance := pickup.item_instance
	ui.exchange_id = cargo.instance_id
	ui._show_loot()
	ui._exchange(pickup)
	check(session.inventory.get_item(incoming_instance.instance_id) == incoming_instance and pickup.item_instance == cargo,"exchange retains incoming identity and leaves outgoing cargo in cache")
	check(not session.inventory.contains(cargo.instance_id) and not ui.carried_list.text.contains("Fabric × 2"),"exchanged-away cargo removed from live list")
	check(SortieCheckpoint.restore_session(SortieCheckpoint.session_data(session)) != null,"carried inventory and magazine remain checkpoint-compatible")
	await get_tree().process_frame
	var world := SortieCheckpoint.capture_world(battle)
	check(SortieCheckpoint.validate_world(world,battle),"world/session item ownership valid after pickup and exchange")
	GameLanguage.set_language("zh_CN",false)
	check(ui.carried_capacity.text.contains("剩余") and ui.carried_list.text.contains("已装备") and ui.carried_list.text.contains("弹匣"),"open carried view refreshes in Chinese")
	if "--capture" in OS.get_cmdline_user_args():
		await get_tree().create_timer(.3).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(OS.get_environment("BUNNY_EVIDENCE").path_join("carried_backpack_zh.png"))
	GameLanguage.set_language("en",false)
	check(profile.to_dict() == before_profile,"pickup and exchange leave warehouse snapshot unchanged until settlement")
	battle.session = SortieSession.new(InventoryState.new(18),LoadoutState.new())
	ui._refresh_carried()
	check(ui.carried_list.text == "No carried items." and ui.carried_capacity.text.contains("18.00"),"empty carried view uses existing base capacity and explicit empty state")
	battle.session = session
	ui._close_loot()
	check(not battle.player.aim_input_captured,"closing carried/cache panel releases aim capture")
	check(battle.hud.get_node("FieldManualHUD").visible,"closing inspection restores normal HUD")
	var objectives: Array[Dictionary] = [
		{"display_name":"first","progress":0,"target":1,"completed":false},
		{"display_name":"second","progress":0,"target":1,"completed":false},
		{"display_name":"third","progress":0,"target":1,"completed":false},
	]
	battle.hud.set_objectives(objectives)
	check(battle.hud.objective_label.text.contains("FIRST") and not battle.hud.objective_label.text.contains("SECOND"),"only the primary pending objective is expanded by default")
	check(battle.hud.objective_toggle.visible and not battle.hud.objective_details.visible,"other pending objectives remain available behind a compact toggle")
	var before_toggle := session.inventory.to_dict()
	Input.action_press("fire")
	battle.hud.objective_toggle.pressed.emit()
	check(battle.hud.objective_details.visible and battle.hud.objective_details.text.contains("SECOND") and not Input.is_action_pressed("fire"),"objective disclosure reveals details and releases click-fire input")
	check(session.inventory.to_dict() == before_toggle,"objective disclosure changes no inventory data")
	battle.hud.objective_toggle.pressed.emit()
	check(not battle.hud.objective_details.visible,"objective details can be collapsed again")
	if DisplayServer.get_name() != "headless":
		await get_tree().process_frame
		var click_at: Vector2 = battle.hud.objective_toggle.get_global_rect().get_center()
		var motion := InputEventMouseMotion.new()
		motion.position = click_at
		motion.global_position = click_at
		get_viewport().push_input(motion)
		var rounds_before: int = session.get_weapon_runtime_state(weapon_id).magazine_ammo
		for pressed in [true,false]:
			var click := InputEventMouseButton.new()
			click.position = click_at
			click.global_position = click_at
			click.button_index = MOUSE_BUTTON_LEFT
			click.pressed = pressed
			get_viewport().push_input(click)
			await get_tree().physics_frame
		check(battle.hud.objective_details.visible and session.get_weapon_runtime_state(weapon_id).magazine_ammo == rounds_before,"native objective click reveals details without firing the automatic weapon")
		battle.hud.objective_toggle.pressed.emit()
	battle._sync_objective_hud()
	GameLanguage.set_language("zh_CN",false)
	if "--capture" in OS.get_cmdline_user_args():
		await get_tree().create_timer(2.0).timeout
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(OS.get_environment("BUNNY_EVIDENCE").path_join("field_manual_hud_zh.png"))
	# Production layout must stay reachable at common desktop aspect ratios.
	for resolution in [Vector2i(1280,720),Vector2i(1440,900),Vector2i(1920,1080)]:
		get_window().size = resolution
		await get_tree().process_frame
		await get_tree().process_frame
		ui._show_loot()
		await get_tree().process_frame
		check(ui.screen.get_global_rect().encloses(ui.panel.get_global_rect()),"manual panel fits viewport at "+str(resolution))
		var close: Array = ui.panel.find_children("*","Button",true,false).filter(func(button): return button.text == "ESC")
		check(close.size() == 1 and ui.panel.get_global_rect().encloses(close[0].get_global_rect()),"close control stays inside panel at "+str(resolution))
		ui._close_loot()
	battle.free()
	SortieRuntime.clear_session()

func _count(inventory: InventoryState, id: StringName) -> int:
	var quantity := 0
	for item in inventory.get_items():
		if item.definition_id == id: quantity += item.quantity
	return quantity


func _ui_frames() -> void:
	for frame in 5: await get_tree().process_frame


func _ui_action(action: String) -> void:
	var keys := {"ui_accept":KEY_ENTER, "ui_up":KEY_UP, "ui_down":KEY_DOWN, "ui_focus_next":KEY_TAB, "ui_cancel":KEY_ESCAPE, "interact":KEY_E}
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = keys[action]
		event.physical_keycode = keys[action]
		event.pressed = pressed
		get_viewport().push_input(event)
		await get_tree().process_frame
	await _ui_frames()


func _pad_button(button: JoyButton) -> void:
	for pressed in [true, false]:
		var event := InputEventJoypadButton.new()
		event.button_index = button
		event.pressed = pressed
		Input.parse_input_event(event)
		await get_tree().physics_frame
		await get_tree().process_frame
	await _ui_frames()


func _keyboard_cache() -> void:
	# Explicit cache fixture: input/ownership regression, not normal-AI playtesting.
	if DisplayServer.get_name() != "headless":
		get_window().size = Vector2i(1280, 720)
		await _ui_frames()
	GameLanguage.set_language("en", false)
	var profile := ProfileRuntime.new_profile()
	var deployed := DeploymentPlan.deploy(profile, SortieRequest.PROTOTYPE_AREA_ID, SortieRequest.PROTOTYPE_MISSION_ID, "", false)
	check(deployed.error == OK, "keyboard cache fixture deploys normally")
	if deployed.error != OK: return
	var battle: Node3D = load("res://scenes/battle/battle.tscn").instantiate()
	battle.result_transition_enabled = false
	add_child(battle)
	await _ui_frames()
	battle.player.set_physics_process(false)
	for enemy in battle.enemy_container.get_children(): enemy.process_mode = Node.PROCESS_MODE_DISABLED
	var ui: Node = battle.get_node("SlicePresentation")
	ui.container = ui.crates.values()[0]
	battle.player.global_position = ui.container.global_position + Vector3.RIGHT
	for pickup in ui.container.contents(): pickup.free()
	for index in 14:
		var pickup := LootPickup.new()
		pickup.setup(ItemInstance.new(&"material.data_drive", 3))
		ui.container.get_parent().add_child(pickup)
	var session: SortieSession = battle.session
	var exchange_cargo := ItemInstance.new(&"material.fabric", 2)
	check(session.inventory.add_item_preserving_instance(exchange_cargo), "keyboard exchange fixture carries real salvage")
	var capacity := session.inventory.capacity
	session.inventory.capacity = session.inventory.current_weight + .45
	var weapon_id: String = session.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY)
	var rounds: int = session.get_weapon_runtime_state(weapon_id).magazine_ammo
	var before_profile := profile.to_dict()
	await get_tree().physics_frame
	await get_tree().physics_frame
	await _ui_action("interact")
	check(is_instance_valid(ui.panel), "physical interaction key opens the actual nearby cache")
	if not is_instance_valid(ui.panel):
		battle.free(); SortieRuntime.clear_session(); return
	var focus := get_viewport().gui_get_focus_owner()
	check(focus != null and ui.panel.is_ancestor_of(focus), "opening supply cache immediately gives keyboard/controller a usable focus")
	if focus == null or not ui.panel.is_ancestor_of(focus):
		ui._close_loot(); battle.free(); SortieRuntime.clear_session(); return
	check(focus.name == &"Take0", "initial cache focus is the first TAKE, not a background control")
	check(focus.get_theme_stylebox("focus").border_color == FieldManualStyle.INK and focus.get_theme_stylebox("focus").border_width_left == 2, "focused cache action has a distinct dark outline over the orange TAKE button")
	var before_count := _count(session.inventory, &"material.data_drive")
	await _ui_action("ui_accept")
	check(_count(session.inventory, &"material.data_drive") == before_count + 3, "actual UI accept takes exactly one whole stack")
	check(get_viewport().gui_get_focus_owner() != null and get_viewport().gui_get_focus_owner().name == &"Take0", "taking a row keeps focus on the next remaining row")
	var hint := ui.panel.find_child("CapacityHint0", true, false) as Label
	check(hint != null and hint.text == tr("SHORT BY %.2f kg") % .45, "cache announces exact shortfall before another TAKE")
	var before_full := session.inventory.to_dict()
	await _ui_action("ui_accept")
	check(session.inventory.to_dict() == before_full, "keyboard overweight rejection never splits or duplicates a stack")
	check(ui.panel.find_child("PickupFeedback", true, false).text.contains("Overweight:"), "keyboard user can read the ordinary capacity rejection")
	check(get_viewport().gui_get_focus_owner() != null and get_viewport().gui_get_focus_owner().name == &"Take0", "failed TAKE does not strand keyboard focus")
	session.inventory.capacity = capacity
	await _ui_frames()
	hint = ui.panel.find_child("CapacityHint0", true, false) as Label
	check(hint != null and not hint.text.contains("SHORT BY"), "weight hints refresh while case stays open when carried weight/capacity changes")
	var scroll := ui.panel.find_child("CacheScroll", true, false) as ScrollContainer
	var deep_row := ui.panel.find_child("Take11", true, false) as Button
	check(deep_row != null, "long cache contains offscreen keyboard action")
	if deep_row:
		deep_row.grab_focus()
		await _ui_frames()
		check(scroll.scroll_vertical > 0 and scroll.get_global_rect().encloses(deep_row.get_global_rect()), "keyboard focus automatically scrolls the chosen row into view")
		ui._show_loot()
		await _ui_frames()
		check(get_viewport().gui_get_focus_owner() != null and get_viewport().gui_get_focus_owner().name == &"Take11", "refresh preserves chosen row instead of jumping to the first item")
		await _ui_action("ui_up")
		check(get_viewport().gui_get_focus_owner() != null and get_viewport().gui_get_focus_owner().name == &"Take10", "directional controller navigation follows cache rows")
		await _pad_button(JOY_BUTTON_DPAD_UP)
		check(get_viewport().gui_get_focus_owner() != null and get_viewport().gui_get_focus_owner().name == &"Take9", "physical D-pad event navigates the actual cache")
		await _ui_action("ui_focus_next")
		focus = get_viewport().gui_get_focus_owner()
		check(focus != null and ui.panel.is_ancestor_of(focus), "Tab traversal remains inside the live cache")
	GameLanguage.set_language("zh_CN", false)
	session.inventory.capacity = session.inventory.current_weight
	await _ui_frames()
	hint = ui.panel.find_child("CapacityHint0", true, false) as Label
	check(hint != null and hint.text == tr("SHORT BY %.2f kg") % .45 and not hint.text.contains("SHORT BY"), "Chinese shortfall is localized and live")
	check(get_viewport().gui_get_focus_owner() != null and ui.panel.is_ancestor_of(get_viewport().gui_get_focus_owner()), "language rebuild retains keyboard focus")
	if DisplayServer.get_name() != "headless" and "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(OS.get_environment("BUNNY_EVIDENCE").path_join("cache_keyboard_shortfall_zh.png"))
	GameLanguage.set_language("en", false)
	session.inventory.capacity = capacity
	var choice := ui.panel.find_child("ExchangeCargo", true, false) as OptionButton
	choice.grab_focus()
	await _ui_action("ui_accept")
	await _ui_action("ui_down")
	await _ui_action("ui_accept")
	check(ui.exchange_id == exchange_cargo.instance_id, "real keyboard popup selects the carried exchange stack")
	check(get_viewport().gui_get_focus_owner() != null and get_viewport().gui_get_focus_owner().name == &"ExchangeCargo", "exchange selection rebuild returns focus to its selector")
	var first_pickup: LootPickup = ui.container.contents()[0]
	var incoming := first_pickup.item_instance
	var swap := ui.panel.find_child("Swap0", true, false) as Button
	check(swap != null and not swap.disabled, "selecting salvage enables the actual exchange action")
	if swap and not swap.disabled:
		swap.grab_focus()
		battle.player.set_physics_process(true)
		await get_tree().physics_frame
		var before_position: Vector3 = battle.player.global_position
		await _pad_button(JOY_BUTTON_A)
		check(session.inventory.get_item(incoming.instance_id) == incoming and first_pickup.item_instance == exchange_cargo, "keyboard exchange transfers incoming identity and leaves outgoing stack recoverable")
		check(not session.inventory.contains(exchange_cargo.instance_id), "keyboard exchange does not duplicate outgoing salvage")
		check(battle.player._dodge_cooldown_time <= 0.0 and Vector2(before_position.x-battle.player.global_position.x,before_position.z-battle.player.global_position.z).length() < .15, "live-physics controller A confirms without triggering the overlapping dodge binding")
	for pickup in ui.container.contents(): ui._take(pickup)
	await _ui_frames()
	check(get_viewport().gui_get_focus_owner() != null and get_viewport().gui_get_focus_owner().name == &"CloseCache", "empty cache focuses close instead of a freed item")
	check(profile.to_dict() == before_profile, "keyboard cache leaves warehouse and rewards untouched")
	check(session.get_weapon_runtime_state(weapon_id).magazine_ammo == rounds and not get_tree().paused, "keyboard cache neither fires weapon nor pauses combat")
	await _pad_button(JOY_BUTTON_B)
	check(not is_instance_valid(ui.panel) and not battle.player.aim_input_captured, "cancel closes cache and restores aiming")
	check(not get_tree().paused and not FlowMenu.is_open(), "controller cancel does not leak through into the pause menu")
	await _pad_button(JOY_BUTTON_A)
	check(battle.player._dodge_cooldown_time > 0.0, "normal controller dodge remains available after cache closes")
	battle.free()
	SortieRuntime.clear_session()
