class_name WarehouseGrid
extends Control
signal equipment_changed
const CELL := 48.0
var model: StashLayout
var selected_id := ""
var detail: Label
var hint: Label
var count_label: Label
var drop_rect := Rect2()
var drop_allowed := false
var placement_overlay: Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	refresh()

func refresh() -> void:
	if not model: return
	model.reconcile()
	for child in get_children():
		remove_child(child)
		child.queue_free()
	custom_minimum_size = Vector2(StashLayout.COLUMNS * CELL, model.row_count() * CELL)
	size = custom_minimum_size
	for instance_id in model.profile.stash_layout:
		var tile := StashTile.new()
		tile.grid = self
		tile.instance_id = instance_id
		tile.rotated = model.profile.stash_layout[instance_id][2]
		var rect := model.rect_for(instance_id)
		tile.position = Vector2(rect.position) * CELL
		tile.size = Vector2(rect.size) * CELL
		add_child(tile)
	placement_overlay = Control.new()
	placement_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	placement_overlay.draw.connect(func():
		if not drop_rect.has_area(): return
		placement_overlay.draw_rect(drop_rect, Color(0.3, 0.85, 0.5, 0.22) if drop_allowed else Color(0.95, 0.25, 0.2, 0.25))
		placement_overlay.draw_rect(drop_rect, Color("83c997") if drop_allowed else Color("d96b5f"), false, 2)
	)
	add_child(placement_overlay)
	if count_label:
		count_label.text = tr("%d ITEMS  /  %.1f kg") % [model.profile.stash_layout.size(), model.profile.inventory.get_used_capacity()]
	select_item(selected_id)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("111817f5"))
	for x in range(StashLayout.COLUMNS + 1):
		draw_line(Vector2(x * CELL, 0), Vector2(x * CELL, size.y), Color("38413b"))
	for y in range(model.row_count() + 1):
		draw_line(Vector2(0, y * CELL), Vector2(size.x, y * CELL), Color("38413b"))

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not event is InputEventKey or not event.pressed or event.echo or event.keycode != KEY_R: return
	var data: Variant = get_viewport().gui_get_drag_data()
	if typeof(data) == TYPE_DICTIONARY and data.get("stash") == self:
		data.rotated = not data.rotated
		var ghost: StashTile = data.get("preview")
		if is_instance_valid(ghost):
			ghost.rotated = data.rotated
			ghost.size = Vector2(model.footprint(data.instance_id, data.rotated)) * CELL
			ghost.queue_redraw()
		_can_drop_data(get_local_mouse_position(), data)
	else:
		rotate_selected()
	get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if not drop_rect.has_area(): return
	if not get_viewport().gui_is_dragging(): drop_rect = Rect2()
	if is_instance_valid(placement_overlay): placement_overlay.queue_redraw()

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY or data.get("stash") != self: return false
	var cell := Vector2i(floor(at_position.x / CELL), floor(at_position.y / CELL))
	drop_rect = Rect2(Vector2(cell) * CELL, Vector2(model.footprint(data.instance_id, data.rotated)) * CELL)
	drop_allowed = model.can_place(data.instance_id, cell, data.rotated)
	if is_instance_valid(placement_overlay): placement_overlay.queue_redraw()
	return drop_allowed

func _drop_data(at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(at_position, data): return
	var equipped := model.profile.loadout.is_equipped(data.instance_id)
	var cell := Vector2i(floor(at_position.x / CELL), floor(at_position.y / CELL))
	if model.move_item(data.instance_id, cell, data.rotated):
		selected_id = data.instance_id
		drop_rect = Rect2()
		refresh()
		if equipped: equipment_changed.emit()
		AudioDirector.play_sfx(&"ui_click")

func select_item(instance_id: String) -> void:
	selected_id = instance_id
	for child in get_children(): child.queue_redraw()
	if not detail: return
	var item := model.profile.inventory.get_item(instance_id)
	if not item:
		detail.text = tr("SELECT AN ITEM\n\nDrag to organize.\nDrop gear on an equipment slot.\n\nR / Rotate\nDouble-click / Equip")
		return
	var definition := ContentDB.get_item(item.definition_id)
	var footprint_size := model.footprint(instance_id, model.profile.stash_layout.get(instance_id, [0, 0, false])[2])
	detail.text = GameLanguage.item_name(definition.display_name) + "\n\n" + tr("%d × %d CELLS\n%.2f kg\nQuantity / %d\nCondition / %.0f%%") % [footprint_size.x, footprint_size.y, definition.weight * item.quantity, item.quantity, item.durability] + "\n\n" + tr(definition.description)

func rotate_selected() -> void:
	if model.rotate_item(selected_id):
		refresh()
		if hint: hint.text = tr("ITEM ROTATED")
	elif hint: hint.text = tr("NOT ENOUGH SPACE TO ROTATE")

func quick_equip(instance_id: String) -> void:
	for slot in LoadoutState.SLOT_IDS:
		if model.can_equip(instance_id, slot) and not model.profile.loadout.has_slot(slot):
			if model.equip_item(instance_id, slot): refresh(); equipment_changed.emit()
			return
	for slot in LoadoutState.SLOT_IDS:
		if model.can_equip(instance_id, slot):
			if model.equip_item(instance_id, slot): refresh(); equipment_changed.emit()
			return
	if hint: hint.text = tr("THIS ITEM STAYS IN THE WAREHOUSE")
