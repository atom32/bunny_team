class_name StashSlot
extends OptionButton
var grid: WarehouseGrid
var slot_id: StringName
var drag_handle: StashSlotHandle
var remove_button: Button

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	drag_handle = StashSlotHandle.new()
	drag_handle.slot = self
	drag_handle.position = Vector2(6, 25)
	drag_handle.size = size - Vector2(38, 42)
	drag_handle.mouse_filter = Control.MOUSE_FILTER_STOP
	drag_handle.mouse_default_cursor_shape = Control.CURSOR_DRAG
	drag_handle.tooltip_text = "Drag equipped item back to the warehouse."
	add_child(drag_handle)
	remove_button = Button.new()
	remove_button.name = "Unequip"
	remove_button.text = "×"
	remove_button.position = Vector2(size.x - 28, 4)
	remove_button.size = Vector2(24, 24)
	remove_button.add_theme_font_size_override("font_size", 14)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style := FieldManualStyle.theme().get_stylebox(state,"Button").duplicate() as StyleBoxFlat
		style.set_content_margin_all(0)
		remove_button.add_theme_stylebox_override(state, style)
	remove_button.tooltip_text = "Return equipped item to warehouse."
	add_child(remove_button)
	remove_button.pressed.connect(func():
		grid.model.profile.loadout.unequip(slot_id)
		grid.refresh()
		grid.equipment_changed.emit())

func _draw() -> void:
	if not grid or not grid.model: return
	var item := grid.model.profile.loadout.get_item(slot_id, grid.model.profile.inventory)
	if remove_button: remove_button.visible = item != null
	if not item:
		draw_string(UIFactory.FONT, Vector2(10, size.y * 0.6), tr("NONE"), HORIZONTAL_ALIGNMENT_LEFT, size.x - 30, 13, FieldManualStyle.MUTED)
		return
	var definition := ContentDB.get_item(item.definition_id)
	draw_string(UIFactory.FONT, Vector2(10, 21), GameLanguage.item_name(definition.display_name), HORIZONTAL_ALIGNMENT_LEFT, size.x - 42, 14, FieldManualStyle.INK)
	if definition.icon:
		var area := size - Vector2(28, 36)
		var extent := Vector2(definition.icon.get_size())
		extent *= minf(area.x / extent.x, area.y / extent.y)
		draw_texture_rect(definition.icon, Rect2(Vector2(8, 25) + (area - extent) * 0.5, extent), false)
	draw_string(UIFactory.FONT, Vector2(10, size.y - 5), "%.1f kg" % item.total_weight(), HORIZONTAL_ALIGNMENT_LEFT, size.x - 20, 11, FieldManualStyle.MUTED)
	if not item.fitting.is_empty():
		draw_string(UIFactory.FONT, Vector2(80, size.y - 5), WeaponFitting.badge(item.fitting), HORIZONTAL_ALIGNMENT_RIGHT, size.x - 90, 11, FieldManualStyle.ACCENT)


func _get_drag_data(_at_position: Vector2) -> Variant:
	var instance_id := grid.model.profile.loadout.get_equipped_instance_id(slot_id)
	if instance_id.is_empty(): return null
	var ghost := StashTile.new()
	ghost.grid = grid
	ghost.instance_id = instance_id
	ghost.preview = true
	ghost.size = Vector2(grid.model.footprint(instance_id)) * WarehouseGrid.CELL
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_drag_preview(ghost)
	return {"stash": grid, "instance_id": instance_id, "rotated": false, "preview": ghost}

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.get("stash") == grid and grid.model.can_equip(data.get("instance_id", ""), slot_id)

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(Vector2.ZERO, data): return
	if grid.model.equip_item(data.instance_id, slot_id):
		grid.refresh()
		grid.equipment_changed.emit()
