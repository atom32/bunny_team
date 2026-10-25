extends Node
## Production controls in a local viewport; finite fixtures, not earned gameplay.
var checks := 0
var failures: Array[String] = []
var surface: SubViewport
var ui: HangerUI

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)

func frames() -> void:
	for index in 5: await get_tree().process_frame

func click(control: Control) -> void:
	check(control != null and control.is_visible_in_tree(),"required control is visible")
	if not control: return
	if DisplayServer.get_name() == "headless":
		if control is Button: control.pressed.emit()
		elif control is StashTile: ui.stash_grid.select_item(control.instance_id)
	else:
		for pressed in [true,false]:
			var event := InputEventMouseButton.new()
			event.position = control.get_global_rect().get_center()
			event.button_index = MOUSE_BUTTON_LEFT
			event.pressed = pressed
			surface.push_input(event)
			await get_tree().process_frame
	await frames()

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless" or OS.get_environment("BUNNY_EVIDENCE").is_empty(): return
	await RenderingServer.frame_post_draw
	surface.get_texture().get_image().save_png(OS.get_environment("BUNNY_EVIDENCE").path_join(name+".png"))

func select_stored(id: String) -> void:
	for tile in ui.stash_grid.get_children():
		if tile is StashTile and tile.instance_id == id:
			(ui.stash_grid.get_parent() as ScrollContainer).ensure_control_visible(tile)
			await frames()
			await click(tile)
			return
	check(false,"stored item has a visible tile")

func _ready() -> void:
	await get_tree().process_frame
	FlowMenu.save_path = "user://loadout_remake.json"
	var profile := ProfileRuntime.new_profile()
	var shotgun := ItemInstance.new(&"weapon.shotgun_01")
	check(profile.inventory.add_item(shotgun),"finite owned shotgun fixture")
	check(profile.inventory.add_item(ItemInstance.new(&"tool.portable_alarm")),"finite owned tool fixture")
	surface = SubViewport.new()
	surface.size = Vector2i(1280,720)
	surface.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	surface.handle_input_locally = true
	add_child(surface)
	var display := TextureRect.new()
	display.texture = surface.get_texture()
	display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(display)
	ui = load("res://scenes/ui/hanger_ui.tscn").instantiate()
	ui.configure(profile.inventory,profile.loadout)
	surface.add_child(ui)
	ui.equipment_changed.connect(ui.sync_loadout_selection)
	await frames()
	var before := profile.to_dict()
	var old_primary := profile.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY)
	for language in ["zh_CN","en"]:
		GameLanguage.set_language(language,false)
		await select_stored(shotgun.instance_id)
		check(ui.right_mode == "inspect" and ui.inspector.visible and not ui.packing.visible,"single click opens details without covering storage")
		check(profile.to_dict() == before,"selection and language switching change no inventory, layout or equipment")
		var comparison := ui.inspector.find_child("EquipmentComparison",true,false) as Label
		check(comparison != null and comparison.text.contains("→"),"current-to-selected comparison is visible")
		check(comparison.text.contains("×"),"shotgun damage is represented per pellet, not a fake single bullet")
		await capture("warehouse_compare_"+language)
	var inventory_before := profile.inventory.to_dict()
	var equip := ui.inspector.find_child("EquipInspected",true,false) as Button
	await frames()
	await click(equip)
	check(profile.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY) == shotgun.instance_id,"explicit action equips chosen instance to chosen slot")
	check(profile.inventory.to_dict() == inventory_before,"replacement preserves every owned instance and quantity")
	check(profile.stash_layout.has(old_primary) and not profile.stash_layout.has(shotgun.instance_id),"old weapon returns to storage and equipped weapon leaves storage grid")
	check((ui.inspector.find_child("EquipInspected",true,false) as Button).disabled,"already equipped action is disabled")
	var choice := ui.inspector.find_child("ComparisonSlot",true,false) as OptionButton
	choice.item_selected.emit(1)
	await frames()
	check(ui.inspector.target_slot == LoadoutState.SLOT_WEAPON_SECONDARY,"comparison target can explicitly select secondary slot")
	await click(ui.inspector.find_child("EquipInspected",true,false))
	check(profile.loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_SECONDARY) == shotgun.instance_id,"selected target, not an implicit default, receives the item")
	check(profile.inventory.to_dict() == inventory_before,"atomic equipment swap preserves all instance quantities")
	await select_stored(old_primary)
	profile.sortie_checkpoint = {"controlled_pending":true}
	ui.inspector.refresh()
	check((ui.inspector.find_child("EquipInspected",true,false) as Button).disabled,"pending sortie locks the new equip control")
	var locked := profile.to_dict()
	(ui.inspector.find_child("EquipInspected",true,false) as Button).pressed.emit()
	check(profile.to_dict() == locked,"even a stale/programmatic activation cannot bypass the pending-sortie guard")
	profile.sortie_checkpoint = {}
	for item in profile.inventory.get_items():
		if item.definition_id == &"ammo.556_standard":
			await select_stored(item.instance_id)
			check(ui.inspector.find_child("IncompatibleAmmoNote",true,false) != null,"unused caliber explains why it has no packing row")
			await click(ui.inspector.find_child("OpenInspectedPacking",true,false))
			check(ui.right_mode == "packing","inspection links to actual packing rather than equipping ammunition")
			break
	for item in profile.inventory.get_items():
		if item.definition_id == &"tool.portable_alarm":
			await select_stored(item.instance_id)
			check(ui.inspector.find_child("EquipInspected",true,false) == null,"field tool cannot be mistaken for wearable equipment")
			await click(ui.inspector.find_child("OpenInspectedPacking",true,false))
			check((ui.packing.find_child("PackAlarm",true,false) as CheckBox).has_focus(),"tool shortcut scrolls to and focuses the actual packing control")
			break
	profile.ammo_pack["ammo.9mm_standard"] = 1000
	ui.sync_loadout_selection()
	await click(ui.packing_tab)
	check(ui.packing.visible and not ui.inspector.visible,"packing tab remains independently accessible")
	var status := ui.packing.find_child("Packed_ammo_9mm_standard",true,false) as Label
	check(status != null and status.text.contains(tr("SHORT %d") % (1000-SupplyService.count(profile,&"ammo.9mm_standard"))),"requested and finite actual load stay distinct")
	GameLanguage.set_language("zh_CN",false)
	await frames()
	check(ui.right_mode == "packing","refresh does not steal the active packing tab")
	await capture("warehouse_packing_zh_CN")
	var count := ui.packing.find_child("PackDressing",true,false) as SpinBox
	(ui.packing.get_child(0) as ScrollContainer).ensure_control_visible(count)
	count.get_line_edit().grab_focus()
	await frames()
	var previous_scroll := (ui.packing.get_child(0) as ScrollContainer).scroll_vertical
	count.value = 0
	await frames()
	check((ui.packing.find_child("PackDressing",true,false) as SpinBox).get_line_edit().has_focus(),"packing edit preserves keyboard focus after status refresh")
	check((ui.packing.get_child(0) as ScrollContainer).scroll_vertical == previous_scroll,"packing edit preserves scroll position instead of jumping to the top")
	check(profile.medical_pack[MedicalTreatment.IDS[0]] == 0,"request control reaches the original save transaction")
	check(profile.inventory.to_dict() == inventory_before,"changing packing never consumes or splits warehouse items")
	check(SaveService.load_profile(FlowMenu.save_path,false).medical_pack[MedicalTreatment.IDS[0]] == 0,"request is persisted")
	for extent in [Vector2i(1280,720),Vector2i(1440,900),Vector2i(1920,1080)]:
		surface.size = extent
		await frames()
		for control in [ui.warehouse_panel,ui.packing,ui.inspector]:
			check(Rect2(Vector2.ZERO,Vector2(extent)).encloses(control.get_global_rect()),"equipment workspace stays in viewport")
	ui.free()
	await frames()
	AudioDirector.shutdown_for_test()
	print("LOADOUT_REMAKE_TEST: %s (%d checks; native clicks: %s)" % ["PASS" if failures.is_empty() else "FAIL",checks,DisplayServer.get_name() != "headless"])
	get_tree().quit(0 if failures.is_empty() else 1)
