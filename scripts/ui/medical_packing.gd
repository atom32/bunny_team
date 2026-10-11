class_name MedicalPacking
extends PanelContainer
## Actual deployment quantities, not a second inventory or equipment system.
signal packing_changed
var compact := false
var message := "Total rounds include magazines. The preview below shows actual packed supplies."

func _ready() -> void:
	theme = null if compact else UIFactory.theme()
	add_theme_stylebox_override("panel", SliceUI.menu_style(Color("151b1f"), Color("151b1f")) if compact else UIFactory.panel_style(Color("101d29ee"), Color("557895")))
	_refresh()

func _refresh() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var profile := ProfileRuntime.get_profile()
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8 if compact else 6)
	add_child(body)
	var heading := Label.new()
	heading.text = tr("SORTIE SUPPLIES") if compact else tr("AMMO + MEDICAL / PACK FOR THIS SORTIE")
	heading.add_theme_font_size_override("font_size", 18)
	if compact:
		var hint := Label.new()
		hint.text = tr("INCLUDES LOADED MAGAZINES")
		hint.add_theme_font_size_override("font_size", 10)
		hint.add_theme_color_override("font_color", SliceUI.MUTED)
		body.add_child(heading)
		body.add_child(hint)
		var rule := HSeparator.new()
		body.add_child(rule)
	if not compact: body.add_child(heading)
	var plan := DeploymentPlan.build(profile)
	var columns := HBoxContainer.new()
	body.add_child(columns)
	var supply_heading := Label.new()
	supply_heading.text = tr("SUPPLY / PACKED") if compact else tr("SUPPLY / ACTUAL LOAD")
	supply_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	supply_heading.add_theme_font_size_override("font_size", 12 if compact else 14)
	columns.add_child(supply_heading)
	var request_heading := Label.new()
	request_heading.text = tr("REQUESTED")
	request_heading.custom_minimum_size.x = 64 if compact else 92
	request_heading.add_theme_font_size_override("font_size", 12 if compact else 14)
	columns.add_child(request_heading)
	var defaults := DeploymentPlan.default_ammo_counts(profile)
	for id: String in defaults:
		var row := HBoxContainer.new()
		body.add_child(row)
		if compact: row.custom_minimum_size.y = 48
		var label := Label.new()
		label.add_theme_font_size_override("font_size", 14)
		if compact: label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.text = GameLanguage.item_name(ContentDB.get_item(StringName(id)).display_name) if compact else tr("%s / owned %d") % [GameLanguage.item_name(ContentDB.get_item(StringName(id)).display_name), SupplyService.count(profile,StringName(id))]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var details := VBoxContainer.new()
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		details.add_theme_constant_override("separation", 0)
		row.add_child(details)
		details.add_child(label)
		var amount := SpinBox.new()
		amount.name = "PackAmmo_" + id.replace(".","_")
		amount.min_value = 0
		amount.max_value = 1000
		amount.value = profile.ammo_pack.get(id,defaults[id])
		_add_status(details, id, int(amount.value), _packed_count(profile, plan, id), SupplyService.count(profile, StringName(id)))
		amount.custom_minimum_size.x = 64 if compact else 92
		amount.tooltip_text = tr("Total rounds including loaded magazines. Limited by owned stock and carry capacity.")
		row.add_child(amount)
		if compact:
			amount.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			var input := amount.get_line_edit()
			input.add_theme_font_size_override("font_size", 14)
			for state in ["normal", "focus"]:
				var style := input.get_theme_stylebox(state).duplicate() as StyleBoxFlat
				style.content_margin_top = 4
				style.content_margin_bottom = 4
				input.add_theme_stylebox_override(state, style)
		amount.value_changed.connect(func(value: float):
			var error := DeploymentPlan.set_ammo_count(id,int(value),FlowMenu.save_path)
			message = "PACKING SAVED / limited to owned supplies and carry capacity." if error == OK else "Could not save. Packing preference unchanged."
			packing_changed.emit()
			_refresh.call_deferred())
	for id: String in MedicalTreatment.IDS:
		var definition := ContentDB.get_item(StringName(id)) as MedicalDefinition
		var row := HBoxContainer.new()
		body.add_child(row)
		if compact: row.custom_minimum_size.y = 48
		var label := Label.new()
		label.add_theme_font_size_override("font_size", 14)
		if compact: label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.text = GameLanguage.item_name(definition.display_name) if compact else tr("%s / owned %d / %.2f kg") % [GameLanguage.item_name(definition.display_name), SupplyService.count(profile, StringName(id)), definition.weight]
		label.tooltip_text = tr(definition.description)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var details := VBoxContainer.new()
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		details.add_theme_constant_override("separation", 0)
		row.add_child(details)
		details.add_child(label)
		var amount := SpinBox.new()
		amount.name = "PackDressing" if id == MedicalTreatment.IDS[0] else "PackMedkit"
		amount.min_value = 0
		amount.max_value = 4
		amount.value = profile.medical_pack[id]
		_add_status(details, id, int(amount.value), _packed_count(profile, plan, id), SupplyService.count(profile, StringName(id)))
		amount.custom_minimum_size.x = 64 if compact else 92
		row.add_child(amount)
		if compact:
			amount.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			var input := amount.get_line_edit()
			input.add_theme_font_size_override("font_size", 14)
			for state in ["normal", "focus"]:
				var style := input.get_theme_stylebox(state).duplicate() as StyleBoxFlat
				style.content_margin_top = 4
				style.content_margin_bottom = 4
				input.add_theme_stylebox_override(state, style)
		amount.value_changed.connect(func(value: float):
			var error := DeploymentPlan.set_medical_count(id, int(value), FlowMenu.save_path)
			message = "PACKING SAVED / limited to owned supplies and carry capacity." if error == OK else "Could not save. Packing preference unchanged."
			packing_changed.emit()
			_refresh.call_deferred()
		)
	var info := Label.new()
	info.text = tr("Unpacked supplies stay at base.") if compact else tr("ACTUAL LOAD %.1f / %.0f kg. Extra supplies stay at base.") % [plan.weight, plan.capacity]
	if message == "Could not save. Packing preference unchanged.": info.text += "\n" + tr("Save failed. Request unchanged." if compact else message)
	if not plan.error.is_empty(): info.text += "\n" + tr(plan.error)
	info.custom_minimum_size.x = 224 if compact else 495
	info.name = "PackingInfo"
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_theme_font_size_override("font_size", 13)
	body.add_child(info)

# Read the real deployment plan; never infer loaded amounts from requested values.
func _packed_count(profile: ProfileState, plan: DeploymentPlan, id: String) -> int:
	var count := 0
	for instance_id in plan.ammo_quantities:
		if profile.inventory.get_item(instance_id).definition_id == StringName(id):
			count += int(plan.ammo_quantities[instance_id])
	for instance_id in plan.medical_ids:
		if profile.inventory.get_item(instance_id).definition_id == StringName(id): count += 1
	return count

func _add_status(parent: Control, id: String, requested: int, packed: int, owned: int = 0) -> void:
	var status := Label.new()
	status.name = "Packed_" + id.replace(".", "_")
	status.add_theme_font_size_override("font_size", 12 if compact else 14)
	if compact: status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.text = tr("PACKED %d / SHORT %d") % [packed, maxi(0, requested-packed)]
	if packed < requested:
		status.add_theme_color_override("font_color", Color("ffcc80"))
		status.tooltip_text = tr("Short of requested load: check owned stock and carry capacity. Only PACKED supplies will deploy.")
	elif requested == 0:
		status.text = tr("NOT REQUESTED / PACKED 0")
	else:
		status.add_theme_color_override("font_color", Color("aab6ba") if compact else Color("80dfde"))
	if compact:
		status.text = tr("PACKED %d / OWNED %d") % [packed, owned] if requested > 0 else tr("NOT PACKED / OWNED %d") % owned
		if packed < requested: status.text += "\n" + tr("SHORT %d") % (requested - packed)
	parent.add_child(status)
