class_name StashTile
extends Control
var grid: WarehouseGrid
var instance_id := ""
var rotated := false
var preview := false

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var item := grid.model.profile.inventory.get_item(instance_id)
	var definition := ContentDB.get_item(item.definition_id)
	tooltip_text = GameLanguage.item_name(definition.display_name) + "\n" + tr(definition.description)

func _draw() -> void:
	var item := grid.model.profile.inventory.get_item(instance_id)
	if not item: return
	var definition := ContentDB.get_item(item.definition_id)
	var color := Color("26352f") if definition.has_tag(&"weapon") else (Color("37342a") if definition.has_tag(&"ammo") else Color("29353d"))
	draw_rect(Rect2(Vector2.ONE, size - Vector2(2, 2)), color)
	draw_rect(Rect2(Vector2.ONE, size - Vector2(2, 2)), Color("b6ae8b") if grid.selected_id == instance_id else Color("58605b"), false, 1)
	if definition.icon:
		var icon_size := Vector2(definition.icon.get_size())
		if rotated: icon_size = Vector2(icon_size.y, icon_size.x)
		var area := size - Vector2(12, 24)
		var scale_factor := minf(area.x / icon_size.x, area.y / icon_size.y)
		var extent := icon_size * scale_factor
		if rotated:
			draw_set_transform(size * 0.5 + Vector2(0, 2), PI * 0.5)
			draw_texture_rect(definition.icon, Rect2(-Vector2(extent.y, extent.x) * 0.5, Vector2(extent.y, extent.x)), false)
			draw_set_transform(Vector2.ZERO)
		else:
			draw_texture_rect(definition.icon, Rect2((size - extent) * 0.5 + Vector2(0, 2), extent), false)
	var name_text := GameLanguage.item_name(definition.display_name)
	if definition.has_tag(&"ammo"):
		name_text = tr("RPG") if definition.id == &"ammo.rocket_standard" else definition.display_name.get_slice(" ", 0)
	draw_string(UIFactory.FONT, Vector2(6, 15), name_text, HORIZONTAL_ALIGNMENT_LEFT, size.x - 12, 11, Color("e0dfd0"))
	var count := str(item.quantity) if definition.stackable else ("%.0f%%" % item.durability)
	draw_string(UIFactory.FONT, Vector2(5, size.y - 5), count, HORIZONTAL_ALIGNMENT_RIGHT, size.x - 10, 11, Color("c7c7b7"))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		grid.select_item(instance_id)
		if event.double_click:
			grid.quick_equip(instance_id)

func _get_drag_data(_at_position: Vector2) -> Variant:
	if preview: return null
	grid.select_item(instance_id)
	var data := {"stash": grid, "instance_id": instance_id, "rotated": rotated}
	var ghost := StashTile.new()
	ghost.grid = grid
	ghost.instance_id = instance_id
	ghost.rotated = rotated
	ghost.preview = true
	ghost.size = size
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	data["preview"] = ghost
	set_drag_preview(ghost)
	return data

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return grid._can_drop_data(position + at_position, data)

func _drop_data(at_position: Vector2, data: Variant) -> void:
	grid._drop_data(position + at_position, data)
