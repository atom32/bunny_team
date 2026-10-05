extends Node
var failures: Array[String] = []
var path := "user://stash_probe_%s.json" % OS.get_process_id()
var embedded_input := "--embedded-input" in OS.get_cmdline_user_args()

func _ready() -> void:
	_start.call_deferred()

func _start() -> void:
	if embedded_input:
		# Render the real UI, but keep its test pointer independent of the Windows
		# desktop cursor. Window.warp_mouse can be ignored by an unfocused window.
		var surface := SubViewport.new()
		surface.size = Vector2i(1280, 720)
		surface.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		surface.handle_input_locally = true
		get_tree().root.add_child(surface)
		var display := TextureRect.new()
		display.texture = surface.get_texture()
		display.mouse_filter = Control.MOUSE_FILTER_IGNORE
		get_tree().root.add_child(display)
		reparent(surface)
	_run()

func _inject(event: InputEvent) -> void:
	if embedded_input: get_viewport().push_input(event)
	else: Input.parse_input_event(event)

func _check(condition: bool, message: String) -> void:
	print("PASS / " if condition else "FAIL / ", message)
	if not condition: failures.append(message)

func _capture(label: String) -> void:
	await get_tree().create_timer(0.2).timeout
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://docs/stash/" + label + ".png")

func _owned(profile: ProfileState, definition_id: StringName) -> String:
	for item in profile.inventory.get_items():
		if item.definition_id == definition_id: return item.instance_id
	return ""

func _drag(source: Control, target: Vector2, instance_id: String, grid: WarehouseGrid, rotated := false) -> void:
	if source is StashSlot: source = source.drag_handle
	var ghost := StashTile.new()
	ghost.grid = grid
	ghost.instance_id = instance_id
	ghost.rotated = rotated
	ghost.preview = true
	ghost.size = Vector2(grid.model.footprint(instance_id, rotated)) * WarehouseGrid.CELL
	var data := {"stash": grid, "instance_id": instance_id, "rotated": rotated, "preview": ghost}
	if source is StashTile or source is StashSlotHandle:
		ghost.free()
		var start := source.global_position + source.size * 0.5
		if not embedded_input: get_viewport().warp_mouse(start)
		var press := InputEventMouseButton.new()
		press.position = start
		press.global_position = start
		press.button_index = MOUSE_BUTTON_LEFT
		press.pressed = true
		_inject(press)
		await get_tree().process_frame
		if not embedded_input: get_viewport().warp_mouse(start + Vector2(24, 0))
		var drag_motion := InputEventMouseMotion.new()
		drag_motion.position = start + Vector2(24, 0)
		drag_motion.global_position = drag_motion.position
		drag_motion.relative = Vector2(24, 0)
		drag_motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		_inject(drag_motion)
		await get_tree().process_frame
		_check(get_viewport().gui_is_dragging(), "Mouse press and movement start an actual item drag")
		if rotated:
			var key := InputEventKey.new()
			key.keycode = KEY_R
			key.pressed = true
			_inject(key)
			await get_tree().process_frame
			_check(get_viewport().gui_get_drag_data().rotated, "R rotates the item while dragging")
	else:
		source.force_drag(data, ghost)
	await get_tree().process_frame
	if not embedded_input: get_viewport().warp_mouse(target)
	await get_tree().process_frame
	var motion := InputEventMouseMotion.new()
	motion.position = target
	motion.global_position = target
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	_inject(motion)
	await get_tree().process_frame
	var release := InputEventMouseButton.new()
	release.position = target
	release.global_position = target
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	_inject(release)
	await get_tree().process_frame
	await get_tree().process_frame

func _run() -> void:
	get_window().size = Vector2i(1280, 720)
	GameLanguage.set_language("zh_CN", false)
	var profile := ArmoryFixture.grant(ProfileRuntime.new_profile(), false)
	FirstMissionPreparation.equip_starter_kit(profile)
	profile.inventory.add_item(ItemInstance.new(&"loot.salvage_core_01"))
	var original := profile.inventory.to_dict()
	var old_data := profile.to_dict()
	old_data.erase("stash_layout")
	var legacy := ProfileState.from_dict(old_data)
	var migrated := StashLayout.new(legacy)
	migrated.reconcile()
	_check(legacy.validate() and legacy.stash_layout.size() == legacy.inventory.get_items().size() - legacy.loadout.get_equipped_instance_ids().size(), "Old saves receive positions without changing ownership")
	legacy.stash_layout = {"bad": [999, -5, false], _owned(legacy, &"weapon.pistol_01"): ["bad", 0, false]}
	migrated.reconcile()
	_check(legacy.validate() and not legacy.stash_layout.has("bad"), "Malformed and stale presentation positions repair safely")
	var hideout = load("res://scenes/presentation/slice/hideout.tscn").instantiate()
	add_child(hideout)
	hideout.show_section("Hanger")
	await get_tree().process_frame
	var ui: HangerUI = hideout.hanger.hanger_ui
	_check(not ui.warehouse_panel.visible, "Hanger opens with an unobstructed character preview")
	ui.warehouse_button.pressed.emit()
	_check(ui.warehouse_panel.visible, "Warehouse opens through its visible button")
	var grid := ui.stash_grid
	var pistol := _owned(profile, &"weapon.pistol_01")
	var rifle := _owned(profile, &"weapon.assault_rifle_01")
	var smg := _owned(profile, &"weapon.smg_01")
	var core := _owned(profile, &"loot.salvage_core_01")
	var heavy := _owned(profile, &"armor.bulwark_plate_01")
	_check(not profile.stash_layout.has(rifle) and not profile.stash_layout.has(smg), "Equipped gear is excluded from the warehouse cells")
	grid.model.sort_items()
	grid.refresh()
	var core_rect := grid.model.rect_for(core)
	var before := profile.stash_layout.duplicate(true)
	_check(not grid.model.move_item(pistol, core_rect.position) and profile.stash_layout == before, "Occupied placement rejects without moving any item")
	_check(not grid.model.move_item(pistol, Vector2i(11, 0)), "Weapon extending past right edge rejects")
	_check(not grid.model.equip_item(core, LoadoutState.SLOT_ARMOR) and profile.loadout.get_item(LoadoutState.SLOT_ARMOR, profile.inventory) != null, "Incompatible equipment rejects without unequipping")
	await _capture("warehouse_zh")
	if DisplayServer.get_name() != "headless":
		var source: Control = grid.get_children().filter(func(tile): return tile is StashTile and tile.instance_id == pistol)[0]
		await _drag(source, grid.global_position + Vector2(10 * 48 + 4, 6 * 48 + 4), pistol, grid, true)
		_check(profile.stash_layout[pistol] == [10, 6, true], "Native GUI drag moves a rotated pistol to the requested cells")
		await _drag(ui.weapon_option, ui.secondary_weapon_option.global_position + Vector2(25, 20), rifle, grid)
		_check(profile.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY) == smg and profile.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_SECONDARY) == rifle, "Native GUI drag swaps occupied weapon slots atomically")
		await _drag(ui.secondary_weapon_option, grid.global_position + Vector2(0 * 48 + 4, 6 * 48 + 4), rifle, grid)
		_check(not profile.loadout.is_equipped(rifle) and profile.stash_layout.has(rifle), "Native GUI drag returns equipped gear to warehouse")
		var heavy_tile: Control = grid.get_children().filter(func(tile): return tile is StashTile and tile.instance_id == heavy)[0]
		await _drag(heavy_tile, ui.armor_option.global_position + Vector2(25, 20), heavy, grid)
		_check(profile.loadout.get_equipped_instance_id(LoadoutState.SLOT_ARMOR) == heavy, "Native GUI drag equips armor and updates the actual loadout")
		_check(ui.armor_detail.text.contains("40%"), "Armor HUD reflects heavy protection after drag equip")
	else:
		_check(grid.model.move_item(pistol, Vector2i(10, 6), true), "Rotated placement succeeds in available cells")
		_check(grid.model.equip_item(rifle, LoadoutState.SLOT_WEAPON_SECONDARY), "Occupied weapon swap succeeds")
		_check(grid.model.move_item(rifle, Vector2i(0, 6)), "Equipped weapon returns to stash")
		_check(grid.model.equip_item(heavy, LoadoutState.SLOT_ARMOR), "Armor equips from stash")
	ui.sync_loadout_selection()
	_check(profile.inventory.to_dict() == original and profile.validate(), "Transfers preserve every instance, quantity, durability and inventory capacity")
	_check(SaveService.save_profile(profile, path) == OK, "Grid layout and loadout save through the normal atomic save service")
	var restored := SaveService.load_profile(path)
	_check(restored != null and restored.stash_layout == profile.stash_layout and restored.loadout.to_dict() == profile.loadout.to_dict(), "Reload preserves exact cells, orientation and gear slots")
	grid.select_item(core)
	await _capture("warehouse_selected_zh")
	_check(grid.detail.text.contains("机械部件"), "Recovered salvage descriptions display in Chinese")
	GameLanguage.set_language("en", false)
	await _capture("warehouse_en")
	_check(ui.weapon_option.get_item_text(ui.weapon_option.selected).contains("Compact"), "Equipment selector names update back to English")
	for resolution in [Vector2i(1920, 1080), Vector2i(1440, 900)]:
		get_window().mode = Window.MODE_WINDOWED
		get_window().size = resolution
		await get_tree().process_frame
		await get_tree().process_frame
		_check(ui.weapon_option.get_global_rect().end.x <= get_viewport().get_visible_rect().size.x, "Equipment stays inside viewport at " + str(resolution))
		for button in ui.find_children("*", "Button", true, false):
			if button.text == "MISSION TERMINAL":
				_check(button.get_global_rect().end.y < 644, "Mission terminal stays above navigation at " + str(resolution))
		_check(grid.get_parent().get_global_rect().end.y < 644, "Warehouse scroll area stays above hub navigation at " + str(resolution))
	_check(grid.detail.text.contains("Salvage Core"), "Selected item details update live when language changes")
	for item in profile.inventory.get_items():
		var definition := ContentDB.get_item(item.definition_id)
		_check(definition.icon != null, "Inventory thumbnail exists for " + String(definition.id))
	for number in 12: profile.inventory.add_item(ItemInstance.new(&"loot.salvage_core_01"))
	grid.refresh()
	_check(grid.model.row_count() > 8 and profile.stash_layout.size() == profile.inventory.get_items().size() - profile.loadout.get_equipped_instance_ids().size(), "New loot automatically receives free cells and extends the scrollable warehouse")
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		if FileAccess.file_exists(path + suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	print("STASH_PROBE: ", "PASS" if failures.is_empty() else "FAIL", " / ", failures)
	hideout.queue_free()
	AudioDirector.shutdown_for_test()
	get_tree().quit(0 if failures.is_empty() else 1)
