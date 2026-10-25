class_name LoadoutInspector
extends PanelContainer
## Read-only comparison until an explicit equip action uses the existing stash model.
signal packing_requested
var grid: WarehouseGrid
var target_slot: StringName = LoadoutState.SLOT_WEAPON_PRIMARY
var body: VBoxContainer
var actions: VBoxContainer
var shown_id := ""

func _ready() -> void:
	add_theme_stylebox_override("panel", FieldManualStyle.panel(FieldManualStyle.SURFACE))
	var layout := VBoxContainer.new()
	layout.name = "Layout"
	layout.add_theme_constant_override("separation",8)
	add_child(layout)
	var scroll := ScrollContainer.new()
	scroll.name = "DetailsScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	scroll.add_child(body)
	actions = VBoxContainer.new()
	layout.add_child(actions)
	refresh()

func line(caption: String, font_size := 14) -> Label:
	var label := Label.new()
	label.text = caption
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	body.add_child(label)
	return label

func refresh() -> void:
	if not body or not grid or not grid.model: return
	for parent in [body,actions]:
		for child in parent.get_children():
			parent.remove_child(child)
			child.queue_free()
	if shown_id != grid.selected_id:
		shown_id = grid.selected_id
		(get_node("Layout/DetailsScroll") as ScrollContainer).scroll_vertical = 0
	var profile := grid.model.profile
	var item := profile.inventory.get_item(grid.selected_id)
	if not item:
		line(tr("Select an item to inspect"), 22)
		line(tr("Compare before replacing gear. Your stored items stay at base until packed."))
		return
	var definition := ContentDB.get_item(item.definition_id)
	line(GameLanguage.item_name(definition.display_name), 20).name = "InspectedName"
	line(tr("OWNED STACK %d / %.2f kg") % [item.quantity,item.total_weight()], 12)
	if definition.icon:
		var icon := TextureRect.new()
		icon.texture = definition.icon
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size.y = 58
		body.add_child(icon)
	var slots: Array[StringName] = []
	for slot in LoadoutState.SLOT_IDS:
		if grid.model.can_equip(item.instance_id,slot): slots.append(slot)
	if slots.is_empty():
		line(tr(definition.description), 13)
		if definition.has_tag(&"ammo") or definition is MedicalDefinition or definition.id == &"tool.portable_alarm":
			line(tr("Selecting is not packing. Set a requested quantity in Sortie supplies."),13)
			if definition.has_tag(&"ammo") and not DeploymentPlan.default_ammo_counts(profile).has(String(definition.id)):
				line(tr("Equip a compatible weapon before packing this ammunition."),13).name = "IncompatibleAmmoNote"
			var packing := Button.new()
			packing.name = "OpenInspectedPacking"
			packing.text = tr("OPEN SORTIE SUPPLIES")
			packing.custom_minimum_size.y = 44
			actions.add_child(packing)
			packing.pressed.connect(func(): packing_requested.emit())
		else: line(tr("This item stays in storage until a trade or delivery."),13)
		return
	if target_slot not in slots: target_slot = slots[0]
	var choice := OptionButton.new()
	choice.name = "ComparisonSlot"
	choice.custom_minimum_size.y = 40
	choice.fit_to_longest_item = false
	for slot in slots: choice.add_item(tr(_slot_caption(slot)))
	choice.select(slots.find(target_slot))
	body.add_child(choice)
	choice.item_selected.connect(func(index: int): target_slot = slots[index]; refresh())
	var current := profile.loadout.get_item(target_slot,profile.inventory)
	line(tr("EQUIPPED → SELECTED"),12)
	var comparison := line(_comparison(current,item),13)
	comparison.name = "EquipmentComparison"

	var equip := Button.new()
	equip.name = "EquipInspected"
	equip.custom_minimum_size.y = 44
	var short_slot: String = {LoadoutState.SLOT_WEAPON_PRIMARY:"PRIMARY",LoadoutState.SLOT_WEAPON_SECONDARY:"SECONDARY",LoadoutState.SLOT_ARMOR:"ARMOR",LoadoutState.SLOT_BACKPACK:"BACKPACK"}[target_slot]
	equip.text = tr("ALREADY EQUIPPED") if current == item else tr("EQUIP / %s") % tr(short_slot)
	equip.add_theme_font_size_override("font_size",15)
	equip.disabled = current == item or SortieRuntime.get_current_session() != null or not profile.sortie_checkpoint.is_empty() or ProfileRuntime.recovery_required
	actions.add_child(equip)
	equip.tooltip_text = tr("The replaced item returns to storage. No purchase or consumption.")
	FieldManualStyle.primary(equip)
	equip.pressed.connect(func():
		if SortieRuntime.get_current_session() != null or not profile.sortie_checkpoint.is_empty() or ProfileRuntime.recovery_required: return
		if grid.model.equip_item(item.instance_id,target_slot):
			grid.refresh()
			grid.equipment_changed.emit()
			AudioDirector.play_sfx(&"ui_confirm")
		refresh())

func _slot_caption(slot: StringName) -> String:
	return {LoadoutState.SLOT_WEAPON_PRIMARY:"PRIMARY WEAPON",LoadoutState.SLOT_WEAPON_SECONDARY:"SECONDARY WEAPON",LoadoutState.SLOT_ARMOR:"ARMOR",LoadoutState.SLOT_BACKPACK:"BACKPACK"}[slot]

func _damage(weapon: WeaponDefinition) -> String:
	var damage := weapon.damage * (1.1 if weapon.id == &"weapon.assault_rifle_01" and grid.model.profile.ar_damage_upgraded else 1.0)
	return "%.0f × %d" % [damage,weapon.pellets_per_shot] if weapon.pellets_per_shot > 1 else "%.0f" % damage

func _comparison(current: ItemInstance, selected: ItemInstance) -> String:
	var candidate := ContentDB.get_item(selected.definition_id)
	var previous := ContentDB.get_item(current.definition_id) if current else null
	var rows := [tr("Weight / %s → %s kg") % ["%.1f" % current.total_weight() if current else "—","%.1f" % selected.total_weight()]]
	if candidate is WeaponDefinition:
		var old := previous as WeaponDefinition
		rows.append(tr("Damage / %s → %s") % [_damage(old) if old else "—",_damage(candidate)])
		rows.append(tr("Magazine / %s → %d") % [str(old.magazine_capacity) if old else "—",candidate.magazine_capacity])
		rows.append(tr("Reload / %s → %.1fs") % ["%.1f" % (old.reload_seconds*WeaponFitting.reload_factor(current)) if old else "—",candidate.reload_seconds*WeaponFitting.reload_factor(selected)])
		rows.append(tr("Range / %s → %.0fm") % ["%.0f" % old.weapon_range if old else "—",candidate.weapon_range])
		if not selected.fitting.is_empty(): rows.append(WeaponFitting.discovery_text(selected))
		rows.append(tr("Weapon damage before ammunition effects."))
	elif candidate is EquipmentDefinition:
		var old := previous as EquipmentDefinition
		rows.append(tr("Protection / %s → %.0f%%") % ["%.0f%%" % (old.damage_reduction*100) if old else "—",candidate.damage_reduction*100])
		rows.append(tr("Capacity bonus / %s → %.0f kg") % ["%.0f" % old.carry_capacity_bonus if old else "—",candidate.carry_capacity_bonus])
		rows.append(tr("Movement modifier / %s → %+.1f") % ["%+.1f" % old.movement_modifier if old else "—",candidate.movement_modifier])
	return "\n".join(rows)
