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
var warehouse_button: Button


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
	add_child(root)

	var title := Label.new()
	title.position = Vector2(42, 24)
	title.size = Vector2(680, 50)
	title.text = "NEON BASTION"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color("eaf7ff"))
	root.add_child(title)
	var subtitle := Label.new()
	subtitle.position = Vector2(46, 70)
	subtitle.size = Vector2(620, 40)
	subtitle.text = "HANGER 07  /  COMBAT LOADOUT  /  ESC PAUSE"
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", SliceUI.CYAN)
	root.add_child(subtitle)
	_build_warehouse_summary(root)
	warehouse_button = Button.new()
	warehouse_button.name = "WarehouseToggle"
	warehouse_button.position = Vector2(42, 106)
	warehouse_button.size = Vector2(300, 36)
	root.add_child(warehouse_button)
	warehouse_button.pressed.connect(func():
		set_warehouse_open(not warehouse_panel.visible)
		AudioDirector.play_sfx(&"ui_click")
	)
	set_warehouse_open(false)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.position = Vector2(-402, 86)
	panel.size = Vector2(370, 548)
	panel.add_theme_stylebox_override("panel", SliceUI.menu_style(Color("171914f2"), Color("555749")))
	root.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 3)
	panel.add_child(content)

	var heading := Label.new()
	heading.text = "EQUIPMENT"
	heading.add_theme_font_size_override("font_size", 25)
	heading.add_theme_color_override("font_color", Color("edf8ff"))
	content.add_child(heading)
	var rule := HSeparator.new()
	content.add_child(rule)
	weapon_option = _add_inventory_option(content, "PRIMARY WEAPON", &"weapon", LoadoutState.SLOT_WEAPON_PRIMARY)
	secondary_weapon_option = _add_inventory_option(content, "SECONDARY WEAPON", &"weapon", LoadoutState.SLOT_WEAPON_SECONDARY)
	armor_option = _add_inventory_option(content, "ARMOR / MOBILITY vs PROTECTION", &"armor", LoadoutState.SLOT_ARMOR)
	armor_detail = Label.new()
	armor_detail.name = "ArmorTradeoff"
	armor_detail.add_theme_font_size_override("font_size", 13)
	armor_detail.add_theme_color_override("font_color", SliceUI.CYAN)
	content.add_child(armor_detail)
	backpack_option = _add_inventory_option(content, "BACKPACK", &"backpack", LoadoutState.SLOT_BACKPACK)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(spacer)
	var deploy := Button.new()
	deploy.text = "DEPLOY"
	deploy.custom_minimum_size = Vector2(0, 58)
	deploy.add_theme_font_size_override("font_size", 23)
	content.add_child(deploy)
	deploy.pressed.connect(func() -> void:
		AudioDirector.play_sfx(&"ui_confirm")
		deploy_requested.emit()
	)

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
	pack_label.text = tr("BACKPACK / CAPACITY %.0f kg") % ProfileState.new(inventory, loadout).get_carried_capacity()
	_refresh_weapon_details(weapon_option)
	_refresh_weapon_details(secondary_weapon_option)
	_refresh_armor_details()
	_refresh_warehouse_summary()
	if stash_grid: stash_grid.refresh()


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
		option.add_icon_item(definition.icon, GameLanguage.item_name(definition.display_name))
		option.set_item_metadata(option.item_count - 1, item.instance_id)
		option.set_item_tooltip(option.item_count - 1, tr(definition.description))


func _build_warehouse_summary(root: Control) -> void:
	var panel := Panel.new()
	warehouse_panel = panel
	panel.name = "WarehousePanel"
	panel.position = Vector2(42, 148)
	panel.size = Vector2(800, 460)
	panel.add_theme_stylebox_override("panel", SliceUI.menu_style(Color("171914f2"), Color("555749")))
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
	scroll.position = Vector2(16, 54)
	scroll.size = Vector2(598, 384)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	scroll.add_child(stash_grid)
	var count_label := Label.new()
	count_label.position = Vector2(184, 16)
	count_label.add_theme_font_size_override("font_size", 13)
	panel.add_child(count_label)
	stash_grid.count_label = count_label
	var sort_button := Button.new()
	sort_button.text = "SORT"
	sort_button.position = Vector2(688, 9)
	sort_button.size = Vector2(94, 34)
	sort_button.add_theme_font_size_override("font_size", 14)
	panel.add_child(sort_button)
	sort_button.pressed.connect(func(): stash_grid.model.sort_items(); stash_grid.refresh())
	var detail := Label.new()
	detail.position = Vector2(634, 56)
	detail.size = Vector2(148, 288)
	detail.add_theme_font_size_override("font_size", 13)
	detail.add_theme_color_override("font_color", Color("c8cfbf"))
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.max_lines_visible = 14
	detail.clip_text = true
	panel.add_child(detail)
	stash_grid.detail = detail
	var rotate_button := Button.new()
	rotate_button.text = "ROTATE / R"
	rotate_button.position = Vector2(634, 350)
	rotate_button.size = Vector2(148, 36)
	rotate_button.add_theme_font_size_override("font_size", 14)
	panel.add_child(rotate_button)
	rotate_button.pressed.connect(stash_grid.rotate_selected)
	var hint := Label.new()
	hint.position = Vector2(634, 394)
	hint.size = Vector2(148, 48)
	hint.text = "DRAG / EQUIP"
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


func set_warehouse_open(opened: bool) -> void:
	if warehouse_panel: warehouse_panel.visible = opened
	if warehouse_button:
		warehouse_button.text = "BACK TO CHARACTER" if opened else "WAREHOUSE / ORGANIZE"


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


func _add_inventory_option(parent: VBoxContainer, label_text: String, required_tag: StringName, slot_id: StringName) -> OptionButton:
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", SliceUI.MUTED)
	parent.add_child(label)
	var option := StashSlot.new()
	option.set_meta("slot_label", label)
	option.grid = stash_grid
	option.slot_id = slot_id
	option.custom_minimum_size = Vector2(0, 40)
	option.expand_icon = true
	option.fit_to_longest_item = false
	option.clip_text = true
	option.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	option.add_theme_constant_override("icon_max_width", 56)
	_populate_inventory_option(option, required_tag)
	parent.add_child(option)
	if required_tag == &"weapon":
		var detail := Label.new()
		detail.add_theme_font_size_override("font_size", 12)
		detail.add_theme_color_override("font_color", SliceUI.MUTED)
		parent.add_child(detail)
		option.set_meta("weapon_detail", detail)
	return option


func _refresh_weapon_details(option: OptionButton) -> void:
	if not option or not option.has_meta("weapon_detail"):
		return
	var detail: Label = option.get_meta("weapon_detail")
	var item := inventory.get_item(_instance_id_at(option, option.selected))
	var weapon := ContentDB.get_weapon(item.definition_id, false) if item else null
	if not weapon:
		detail.text = "No weapon equipped"
		return
	var ammo := ContentDB.get_ammo(weapon.get_runtime_ammo_definition_id(), false)
	var damage := tr("%d x %d") % [roundi(weapon.damage), weapon.pellets_per_shot] if weapon.pellets_per_shot > 1 else str(roundi(weapon.damage))
	if weapon.id == &"weapon.assault_rifle_01" and ProfileRuntime.get_profile().ar_damage_upgraded:
		damage = tr("%.0f (+10%%)") % (weapon.damage * 1.1)
	detail.text = tr("%s / %s / MAG %d\nDMG %s / %.1fs RELOAD / %.0fm") % [GameLanguage.item_name(ammo.display_name) if ammo else "", tr("AUTO" if weapon.fire_mode == &"automatic" else "SINGLE"), weapon.magazine_capacity, damage, weapon.reload_seconds * WeaponFitting.reload_factor(item), weapon.weapon_range]
	if not item.fitting.is_empty(): detail.text += " / " + tr(WeaponFitting.caption(item.fitting))


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
	armor_detail.text = tr("MOBILITY  %.1f m/s (primary equipped)\nPROTECTION  %.0f%% incoming damage reduction\nCARRY WEIGHT  %.1f kg (armor)") % [PlayerController.movement_speed_for(weapon, armor, pack), clampf(armor.damage_reduction, 0.0, 0.8) * 100.0 if armor else 0.0, armor.weight if armor else 0.0]
