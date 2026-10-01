class_name StashSlot
extends OptionButton
var grid: WarehouseGrid
var slot_id: StringName
var drag_handle: StashSlotHandle

func _ready() -> void:
	drag_handle = StashSlotHandle.new()
	drag_handle.slot = self
	drag_handle.position = Vector2(12, 4)
	drag_handle.size = Vector2(64, 36)
	drag_handle.mouse_filter = Control.MOUSE_FILTER_STOP
	drag_handle.mouse_default_cursor_shape = Control.CURSOR_DRAG
	drag_handle.tooltip_text = "Drag equipped item back to the warehouse."
	add_child(drag_handle)


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
