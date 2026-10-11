class_name HangerUI
extends CanvasLayer

signal weapon_selected(instance_id: String)
signal secondary_weapon_selected(instance_id: String)
signal armor_selected(instance_id: String)
signal backpack_selected(instance_id: String)
signal deploy_requested
signal equipment_changed

var weapon_option: OptionButton
var secondary_weapon_option: OptionButton
var armor_option: OptionButton
var backpack_option: OptionButton
var inventory: InventoryState
var loadout: LoadoutState
var warehouse_summary: Label
var armor_detail: Label
var stash_grid: WarehouseGrid
var warehouse_panel: Panel
var deployment_summary: Label
var packing: MedicalPacking


func configure(p_inventory: InventoryState, p_loadout: LoadoutState) -> void:
	inventory = p_inventory
	loadout = p_loadout
	if stash_grid:
		var profile := ProfileRuntime.get_profile()
		if profile.inventory != inventory or profile.loadout != loadout:
			profile = ProfileState.new(inventory, loadout)
		stash_grid.model = StashLayout.new(profile)


func _ready() -> void:
	if not inventory or not loadout:
		push_error("HangerUI requires InventoryState and LoadoutState before entering the scene tree")
		return
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = SliceUI.menu_theme()
	for kind in ["Button", "OptionButton"]:
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			var style := root.theme.get_stylebox(state, kind).duplicate() as StyleBoxFlat
			style.bg_color = Color("1d2327") if state == "normal" else Color("2b3338")
			style.border_color = Color("343d42") if state == "normal" else Color("aa9b72")
			style.set_content_margin_all(6)
			root.theme.set_stylebox(state, kind, style)
	var backdrop := ColorRect.new()
	backdrop.color = Color("0e1215")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(backdrop)
	add_child(root)

	var title := Label.new()
	title.position = Vector2(42, 28)
	title.size = Vector2(680, 50)
	title.text = "CHARACTER / STASH"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color("eceee9"))
	root.add_child(title)
	var subtitle := Label.new()
	subtitle.position = Vector2(44, 70)
	subtitle.size = Vector2(620, 40)
	subtitle.text = "EQUIP / ORGANIZE / PREPARE FOR SORTIE"
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color("8e999f"))
	root.add_child(subtitle)
	_build_warehouse_summary(root)

	var panel := Panel.new()
	panel.name = "EquipmentPanel"
	panel.position = Vector2(42, 110)
	panel.size = Vector2(300, 504)
	panel.add_theme_stylebox_override("panel", SliceUI.menu_style(Color("151b1f"), Color("151b1f")))
	root.add_child(panel)
	var heading := Label.new()
	heading.text = "EQUIPMENT"
	heading.position = Vector2(12, 10)
	heading.add_theme_font_size_override("font_size", 20)
	panel.add_child(heading)
	weapon_option = _add_inventory_option(panel, "PRIMARY WEAPON", &"weapon", LoadoutState.SLOT_WEAPON_PRIMARY, Vector2(12, 40), Vector2(276, 92))
	secondary_weapon_option = _add_inventory_option(panel, "SECONDARY WEAPON", &"weapon", LoadoutState.SLOT_WEAPON_SECONDARY, Vector2(12, 184), Vector2(276, 92))
	armor_option = _add_inventory_option(panel, "ARMOR", &"armor", LoadoutState.SLOT_ARMOR, Vector2(12, 328), Vector2(132, 92))
	backpack_option = _add_inventory_option(panel, "BACKPACK", &"backpack", LoadoutState.SLOT_BACKPACK, Vector2(156, 328), Vector2(132, 92))
	armor_detail = Label.new()
	armor_detail.name = "ArmorTradeoff"
	armor_detail.position = Vector2(12, 446)
	armor_detail.size = Vector2(276, 52)
	armor_detail.add_theme_font_size_override("font_size", 12)
	armor_detail.add_theme_color_override("font_color", Color("a7afb0"))
	panel.add_child(armor_detail)
	var deploy := Button.new()
	deploy.text = "DEPLOY"
	deploy.position = Vector2(978, 566)
	deploy.size = Vector2(260, 48)
	deploy.add_theme_font_size_override("font_size", 16)
	_compact_button(deploy)
	for state in ["normal", "hover", "pressed"]:
		deploy.add_theme_stylebox_override(state, SliceUI.menu_style(Color("b5a47b") if state == "normal" else Color("cec09a"), Color("b5a47b")))
		deploy.add_theme_color_override("font_color" if state == "normal" else "font_" + state + "_color", Color("13191c"))
	root.add_child(deploy)
	deploy.pressed.connect(func() -> void:
		AudioDirector.play_sfx(&"ui_confirm")
		deploy_requested.emit()
	)
	packing = MedicalPacking.new()
	packing.name = "MedicalPacking"
	packing.compact = true
	packing.position = Vector2(978, 110)
	packing.size = Vector2(260, 440)
	root.add_child(packing)
	packing.packing_changed.connect(_refresh_warehouse_summary)

	sync_loadout_selection()
	GameLanguage.language_changed.connect(sync_loadout_selection)
	weapon_option.item_selected.connect(func(index: int) -> void:
		AudioDirector.play_sfx(&"ui_click")
		weapon_selected.emit(_instance_id_at(weapon_option, index))
	)
	secondary_weapon_option.item_selected.connect(func(index: int) -> void:
		AudioDirector.play_sfx(&"ui_click")
		secondary_weapon_selected.emit(_instance_id_at(secondary_weapon_option, index))
	)
	armor_option.item_selected.connect(func(index: int) -> void:
		AudioDirector.play_sfx(&"ui_click")
		armor_selected.emit(_instance_id_at(armor_option, index))
	)
	backpack_option.item_selected.connect(func(index: int) -> void:
		AudioDirector.play_sfx(&"ui_click")
		backpack_selected.emit(_instance_id_at(backpack_option, index))
	)


func sync_loadout_selection() -> void:
	if not loadout:
		return
	for option in [weapon_option, secondary_weapon_option, armor_option, backpack_option]:
		if not option: continue
		for index in range(1, option.item_count):
			var item := inventory.get_item(_instance_id_at(option, index))
			if item:
				var definition := ContentDB.get_item(item.definition_id)
				option.set_item_text(index, GameLanguage.item_name(definition.display_name))
				option.set_item_tooltip(index, tr(definition.description))
	_select_instance(weapon_option, loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY))
	_select_instance(secondary_weapon_option, loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_SECONDARY))
	_select_instance(armor_option, loadout.get_equipped_instance_id(LoadoutState.SLOT_ARMOR))
	_select_instance(backpack_option, loadout.get_equipped_instance_id(LoadoutState.SLOT_BACKPACK))
	var pack_label := backpack_option.get_meta("slot_label") as Label
	pack_label.text = tr("BACKPACK")
	backpack_option.tooltip_text = tr("BACKPACK / CAPACITY %.0f kg") % ProfileState.new(inventory, loadout).get_carried_capacity()
	_refresh_weapon_details(weapon_option)
	_refresh_weapon_details(secondary_weapon_option)
	_refresh_armor_details()
	armor_option.tooltip_text = armor_detail.tooltip_text
	_refresh_warehouse_summary()
	if stash_grid: stash_grid.refresh()
	for option in [weapon_option, secondary_weapon_option, armor_option, backpack_option]:
		option.queue_redraw()
		(option as StashSlot).drag_handle.tooltip_text = option.tooltip_text + "\n" + tr("Drag equipped item back to the warehouse.")
	if packing: packing._refresh()


func refresh_owned_items() -> void:
	for entry in [[weapon_option, &"weapon"], [secondary_weapon_option, &"weapon"], [armor_option, &"armor"], [backpack_option, &"backpack"]]:
		_populate_inventory_option(entry[0], entry[1])
	sync_loadout_selection()


func _populate_inventory_option(option: OptionButton, required_tag: StringName) -> void:
	option.clear()
	option.add_item(tr("NONE"))
	option.set_item_metadata(0, "")
	for item in inventory.get_items():
		var definition := ContentDB.get_item(item.definition_id)
		if not definition or not definition.has_tag(required_tag): continue
		option.add_item(GameLanguage.item_name(definition.display_name))
		option.set_item_metadata(option.item_count - 1, item.instance_id)
		option.set_item_tooltip(option.item_count - 1, tr(definition.description))


func _build_warehouse_summary(root: Control) -> void:
	var panel := Panel.new()
	warehouse_panel = panel
	panel.name = "WarehousePanel"
	panel.position = Vector2(354, 110)
	panel.size = Vector2(612, 504)
	panel.add_theme_stylebox_override("panel", SliceUI.menu_style(Color("151b1f"), Color("151b1f")))
	root.add_child(panel)
	var heading := Label.new()
	heading.text = "WAREHOUSE"
	heading.position = Vector2(16, 10)
	heading.add_theme_font_size_override("font_size", 20)
	panel.add_child(heading)
	stash_grid = WarehouseGrid.new()
	var profile := ProfileRuntime.get_profile()
	if profile.inventory != inventory or profile.loadout != loadout:
		profile = ProfileState.new(inventory, loadout)
	stash_grid.model = StashLayout.new(profile)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(10, 54)
	scroll.size = Vector2(592, 384)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	scroll.add_child(stash_grid)
	var count_label := Label.new()
	count_label.position = Vector2(170, 17)
	count_label.add_theme_font_size_override("font_size", 13)
	panel.add_child(count_label)
	stash_grid.count_label = count_label
	var sort_button := Button.new()
	sort_button.text = "SORT"
	sort_button.position = Vector2(506, 9)
	sort_button.size = Vector2(94, 34)
	_compact_button(sort_button)
	sort_button.add_theme_font_size_override("font_size", 14)
	panel.add_child(sort_button)
	sort_button.pressed.connect(func(): stash_grid.model.sort_items(); stash_grid.refresh())
	var detail := Label.new()
	detail.position = Vector2(12, 446)
	detail.size = Vector2(432, 40)
	detail.add_theme_font_size_override("font_size", 12)
	detail.add_theme_color_override("font_color", Color("b7c0c2"))
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.max_lines_visible = 2
	detail.clip_text = true
	panel.add_child(detail)
	stash_grid.detail = detail
	deployment_summary = Label.new()
	deployment_summary.name = "CarriedSummary"
	deployment_summary.position = Vector2(978, 42)
	deployment_summary.size = Vector2(260, 36)
	deployment_summary.add_theme_font_size_override("font_size", 14)
	deployment_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	deployment_summary.max_lines_visible = 1
	deployment_summary.clip_text = true
	root.add_child(deployment_summary)
	var rotate_button := Button.new()
	rotate_button.text = "ROTATE / R"
	rotate_button.position = Vector2(456, 444)
	rotate_button.size = Vector2(144, 36)
	_compact_button(rotate_button)
	rotate_button.add_theme_font_size_override("font_size", 14)
	panel.add_child(rotate_button)
	rotate_button.pressed.connect(stash_grid.rotate_selected)
	var hint := Label.new()
	hint.position = Vector2(12, 484)
	hint.size = Vector2(598, 18)
	hint.text = "DRAG TO ORGANIZE / DROP ON EQUIPMENT TO EQUIP"
	hint.add_theme_font_size_override("font_size", 11)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(hint)
	stash_grid.hint = hint
	stash_grid.equipment_changed.connect(func(): equipment_changed.emit())
	# Kept as the loadout summary API used by existing callers, outside the visible grid.
	warehouse_summary = Label.new()
	warehouse_summary.name = "WarehouseSummary"
	warehouse_summary.hide()
	panel.add_child(warehouse_summary)
	_refresh_warehouse_summary()


func _refresh_warehouse_summary() -> void:
	if not warehouse_summary or not inventory or not loadout:
		return
	var quantities: Dictionary = {}
	var display_names: Dictionary = {}
	var weights: Dictionary = {}
	var categories: Dictionary = {}
	var equipped_labels: Dictionary = {}
	for slot_id in LoadoutState.SLOT_IDS:
		var equipped_id := loadout.get_equipped_instance_id(slot_id)
		if not equipped_id.is_empty():
			equipped_labels[equipped_id] = _slot_label(slot_id)
	for item in inventory.get_items():
		var definition := ContentDB.get_item(item.definition_id, false)
		if not definition:
			continue
		quantities[item.definition_id] = int(quantities.get(item.definition_id, 0)) + item.quantity
		display_names[item.definition_id] = GameLanguage.item_name(definition.display_name)
		weights[item.definition_id] = float(weights.get(item.definition_id, 0.0)) + item.total_weight()
		categories[item.definition_id] = _category_for(definition)
	var lines: Array[String] = [
		tr("CAPACITY  %.2f / %.0f kg") % [inventory.get_used_capacity(), inventory.capacity],
	]
	for category in ["WEAPONS", "AMMO", "EQUIPMENT", "SALVAGE"]:
		var definition_ids: Array = []
		for definition_id in quantities:
			if categories[definition_id] == category:
				definition_ids.append(definition_id)
		definition_ids.sort_custom(func(a: StringName, b: StringName) -> bool: return str(display_names[a]) < str(display_names[b]))
		if definition_ids.is_empty():
			continue
		lines.append("")
		lines.append(tr(category))
		for definition_id in definition_ids:
			var slot_markers: Array[String] = []
			for item in inventory.get_items():
				if item.definition_id == definition_id and equipped_labels.has(item.instance_id):
					slot_markers.append(tr(equipped_labels[item.instance_id]))
			var equipped_text := tr("  [%s]") % ", ".join(slot_markers) if not slot_markers.is_empty() else ""
			lines.append(tr("%s  x%d  %.2f kg%s") % [display_names[definition_id], quantities[definition_id], weights[definition_id], equipped_text])
	var profile := ProfileRuntime.get_profile()
	var plan := DeploymentPlan.build(profile if profile.inventory == inventory else ProfileState.new(inventory, loadout))
	warehouse_summary.text = plan.message + "\n" + tr(plan.error) + "\n\n" + "\n".join(lines)
	if deployment_summary:
		deployment_summary.text = plan.message if plan.error.is_empty() else tr(plan.error)
		deployment_summary.tooltip_text = deployment_summary.text
		deployment_summary.add_theme_color_override("font_color", SliceUI.MUTED if plan.error.is_empty() else Color("e59c84"))


func _add_inventory_option(parent: Control, label_text: String, required_tag: StringName, slot_id: StringName, at: Vector2, extent: Vector2) -> OptionButton:
	var label := Label.new()
	label.text = label_text
	label.position = at
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color("9aa6ac"))
	parent.add_child(label)
	var option := StashSlot.new()
	option.set_meta("slot_label", label)
	option.grid = stash_grid
	option.slot_id = slot_id
	option.position = at + Vector2(0, 20)
	option.size = extent
	option.fit_to_longest_item = false
	option.clip_text = true
	# The popup remains an accessible alternative; the surface draws the equipped item.
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		option.add_theme_color_override(state, Color.TRANSPARENT)
	option.add_theme_constant_override("icon_max_width", 1)
	_compact_button(option)
	_populate_inventory_option(option, required_tag)
	parent.add_child(option)
	if required_tag == &"weapon":
		var detail := Label.new()
		detail.position = option.position + Vector2(0, extent.y + 4)
		detail.size = Vector2(extent.x, 28)
		detail.add_theme_font_size_override("font_size", 12)
		detail.add_theme_color_override("font_color", SliceUI.MUTED)
		parent.add_child(detail)
		option.set_meta("weapon_detail", detail)
	return option


func _compact_button(button: Button) -> void:
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style := SliceUI.menu_style(Color("1c2429") if state == "normal" else Color("29353b"), Color("34434a") if state == "normal" else Color("b5a47b"))
		style.set_content_margin_all(6)
		button.add_theme_stylebox_override(state, style)


func _refresh_weapon_details(option: OptionButton) -> void:
	if not option or not option.has_meta("weapon_detail"):
		return
	var detail: Label = option.get_meta("weapon_detail")
	var item := inventory.get_item(_instance_id_at(option, option.selected))
	var weapon := ContentDB.get_weapon(item.definition_id, false) if item else null
	if not weapon:
		detail.text = "No weapon equipped"
		detail.tooltip_text = ""
		option.tooltip_text = ""
		return
	var ammo := ContentDB.get_ammo(weapon.get_runtime_ammo_definition_id(), false)
	var damage := tr("%d x %d") % [roundi(weapon.damage), weapon.pellets_per_shot] if weapon.pellets_per_shot > 1 else str(roundi(weapon.damage))
	if weapon.id == &"weapon.assault_rifle_01" and ProfileRuntime.get_profile().ar_damage_upgraded:
		damage = tr("%.0f (+10%%)") % (weapon.damage * 1.1)
	detail.tooltip_text = tr("%s / %s / MAG %d\nDMG %s / %.1fs RELOAD / %.0fm") % [GameLanguage.item_name(ammo.display_name) if ammo else "", tr("AUTO" if weapon.fire_mode == &"automatic" else "SINGLE"), weapon.magazine_capacity, damage, weapon.reload_seconds * WeaponFitting.reload_factor(item), weapon.weapon_range]
	if not item.fitting.is_empty(): detail.tooltip_text += " / " + tr(WeaponFitting.caption(item.fitting))
	detail.text = tr("DMG %s  /  MAG %d  /  %s") % [damage, weapon.magazine_capacity, tr("AUTO" if weapon.fire_mode == &"automatic" else "SINGLE")]
	option.tooltip_text = GameLanguage.item_name(weapon.display_name) + "\n" + detail.tooltip_text


func _select_instance(option: OptionButton, instance_id: String) -> void:
	if not option:
		return
	for index in option.item_count:
		if _instance_id_at(option, index) == instance_id:
			option.select(index)
			return


func _instance_id_at(option: OptionButton, index: int) -> String:
	return str(option.get_item_metadata(index))


func _category_for(definition: ItemDefinition) -> String:
	if definition.has_tag(&"weapon"):
		return "WEAPONS"
	if definition.has_tag(&"ammo"):
		return "AMMO"
	if definition.has_tag(&"equipment"):
		return "EQUIPMENT"
	return "SALVAGE"


func _slot_label(slot_id: StringName) -> String:
	match slot_id:
		LoadoutState.SLOT_WEAPON_PRIMARY:
			return "PRIMARY"
		LoadoutState.SLOT_WEAPON_SECONDARY:
			return "SECONDARY"
		LoadoutState.SLOT_ARMOR:
			return "ARMOR"
		LoadoutState.SLOT_BACKPACK:
			return "BACKPACK"
	return String(slot_id).to_upper()


func _refresh_armor_details() -> void:
	if not armor_detail: return
	var armor_item := loadout.get_item(LoadoutState.SLOT_ARMOR, inventory)
	var armor := ContentDB.get_item(armor_item.definition_id) as EquipmentDefinition if armor_item else null
	var pack_item := loadout.get_item(LoadoutState.SLOT_BACKPACK, inventory)
	var pack := ContentDB.get_item(pack_item.definition_id) as EquipmentDefinition if pack_item else null
	var weapon_item := loadout.get_item(LoadoutState.SLOT_WEAPON_PRIMARY, inventory)
	if not weapon_item: weapon_item = loadout.get_item(LoadoutState.SLOT_WEAPON_SECONDARY, inventory)
	var weapon := ContentDB.get_weapon(weapon_item.definition_id) if weapon_item else null
	armor_detail.tooltip_text = tr("MOBILITY  %.1f m/s (primary equipped)\nPROTECTION  %.0f%% incoming damage reduction\nCARRY WEIGHT  %.1f kg (armor)") % [PlayerController.movement_speed_for(weapon, armor, pack), clampf(armor.damage_reduction, 0.0, 0.8) * 100.0 if armor else 0.0, armor.weight if armor else 0.0]

	armor_detail.text = tr("MOBILITY / PROTECTION / ARMOR") + "\n" + "%.1f m/s  /  %.0f%%  /  %.1f kg" % [PlayerController.movement_speed_for(weapon, armor, pack), clampf(armor.damage_reduction, 0.0, 0.8) * 100.0 if armor else 0.0, armor.weight if armor else 0.0]
