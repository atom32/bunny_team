class_name SliceTransition
extends CanvasLayer

func travel(scene: PackedScene, caption: String) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	var screen := SliceUI.root(self)
	var black := ColorRect.new()
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black.color = Color("070e16")
	screen.add_child(black)
	SliceUI.label(screen, "NEON BASTION  /  FIELD OPERATIONS", Vector2(64, 542), 16, SliceUI.CYAN)
	SliceUI.label(screen, caption, Vector2(64, 578), 32)
	screen.modulate.a = 0.0
	await create_tween().tween_property(screen, "modulate:a", 1.0, 0.4).finished
	var error := get_tree().change_scene_to_packed(scene)
	await get_tree().process_frame
	await get_tree().create_timer(0.35).timeout
	await create_tween().tween_property(screen, "modulate:a", 0.0, 0.5).finished
	queue_free()
	if error != OK:
		FlowMenu.call_deferred("show_error", "Scene transition failed: %s. Retry from exit options." % error_string(error))
