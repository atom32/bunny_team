class_name StashSlotHandle
extends Control
## A separate drag surface keeps OptionButton's popup click from swallowing drags.
var slot: StashSlot

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		slot.grid.select_item(slot.grid.model.profile.loadout.get_equipped_instance_id(slot.slot_id))
		accept_event()

func _get_drag_data(at_position: Vector2) -> Variant:
	return slot._get_drag_data(at_position)

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return slot._can_drop_data(at_position, data)

func _drop_data(at_position: Vector2, data: Variant) -> void:
	slot._drop_data(at_position, data)
