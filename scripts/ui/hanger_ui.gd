class_name HangerUI
extends CanvasLayer

signal weapon_selected(instance_id: String)
signal secondary_weapon_selected(instance_id: String)
signal armor_selected(instance_id: String)
signal backpack_selected(instance_id: String)
signal deploy_requested

var weapon_option: OptionButton
var secondary_weapon_option: OptionButton
var armor_option: OptionButton
var backpack_option: OptionButton
var inventory: InventoryState
var loadout: LoadoutState
var warehouse_summary: Label


func configure(p_inventory: InventoryState, p_loadout: LoadoutState) -> void:
	inventory = p_inventory
	loadout = p_loadout


func _ready() -> void:
	if not inventory or not loadout:
		push_error("HangerUI requires InventoryState and LoadoutState before entering the scene tree")
		return
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = UIFactory.theme()
	add_child(root)

	var title := Label.new()
	title.position = Vector2(42, 34)
	title.size = Vector2(680, 96)
	title.text = "NEON BASTION"
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color("eaf7ff"))
	root.add_child(title)
	var subtitle := Label.new()
	subtitle.position = Vector2(46, 92)
	subtitle.size = Vector2(620, 40)
	subtitle.text = "HANGER 07  /  COMBAT LOADOUT"
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color("68dce5"))
	root.add_child(subtitle)
	_build_warehouse_summary(root)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	panel.position = Vector2(-402, -250)
	panel.size = Vector2(370, 500)
	panel.add_theme_stylebox_override("panel", UIFactory.panel_style(Color("0f1824ed"), Color("557895")))
	root.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 15)
	panel.add_child(content)

	var heading := Label.new()
	heading.text = "EQUIPMENT"
	heading.add_theme_font_size_override("font_size", 25)
	heading.add_theme_color_override("font_color", Color("edf8ff"))
	content.add_child(heading)
	var rule := HSeparator.new()
	content.add_child(rule)
	weapon_option = _add_inventory_option(content, "PRIMARY WEAPON", &"weapon")
	secondary_weapon_option = _add_inventory_option(content, "SECONDARY WEAPON", &"weapon")
	armor_option = _add_inventory_option(content, "ARMOR", &"armor")
	backpack_option = _add_inventory_option(content, "BACKPACK", &"backpack")

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
	_select_instance(weapon_option, loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_PRIMARY))
	_select_instance(secondary_weapon_option, loadout.get_equipped_instance_id(LoadoutState.SLOT_WEAPON_SECONDARY))
	_select_instance(armor_option, loadout.get_equipped_instance_id(LoadoutState.SLOT_ARMOR))
	_select_instance(backpack_option, loadout.get_equipped_instance_id(LoadoutState.SLOT_BACKPACK))
	_refresh_warehouse_summary()


func _build_warehouse_summary(root: Control) -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(42, 148)
	panel.size = Vector2(360, 460)
	panel.add_theme_stylebox_override("panel", UIFactory.panel_style(Color("0f1824d9"), Color("456478")))
	root.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)
	var heading := Label.new()
	heading.text = "WAREHOUSE"
	heading.add_theme_font_size_override("font_size", 18)
	heading.add_theme_color_override("font_color", Color("edf8ff"))
	content.add_child(heading)
	warehouse_summary = Label.new()
	warehouse_summary.name = "WarehouseSummary"
	warehouse_summary.add_theme_font_size_override("font_size", 13)
	warehouse_summary.add_theme_color_override("font_color", Color("a9c4d4"))
	warehouse_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(warehouse_summary)
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
		display_names[item.definition_id] = definition.display_name
		weights[item.definition_id] = float(weights.get(item.definition_id, 0.0)) + definition.weight * item.quantity
		categories[item.definition_id] = _category_for(definition)
	var lines: Array[String] = [
		"CAPACITY  %.2f / %.0f kg" % [inventory.get_used_capacity(), inventory.capacity],
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
		lines.append(category)
		for definition_id in definition_ids:
			var slot_markers: Array[String] = []
			for item in inventory.get_items():
				if item.definition_id == definition_id and equipped_labels.has(item.instance_id):
					slot_markers.append(equipped_labels[item.instance_id])
			var equipped_text := "  [%s]" % ", ".join(slot_markers) if not slot_markers.is_empty() else ""
			lines.append("%s  x%d  %.2f kg%s" % [display_names[definition_id], quantities[definition_id], weights[definition_id], equipped_text])
	warehouse_summary.text = "\n".join(lines)


func _add_inventory_option(parent: VBoxContainer, label_text: String, required_tag: StringName) -> OptionButton:
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color("8faabe"))
	parent.add_child(label)
	var option := OptionButton.new()
	option.custom_minimum_size = Vector2(0, 48)
	option.add_item("NONE")
	option.set_item_metadata(0, "")
	for item in inventory.get_items():
		var definition := ContentDB.get_item(item.definition_id)
		if not definition or not definition.has_tag(required_tag):
			continue
		option.add_item(definition.display_name)
		option.set_item_metadata(option.item_count - 1, item.instance_id)
	parent.add_child(option)
	return option


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
