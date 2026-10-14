class_name VisionOverlay
extends Control
## Read-only projection of the existing player sensor. Never drives visibility.
var boundary := PackedVector3Array()
var projected := PackedVector2Array()
var outer := PackedVector2Array()
var refresh_remaining := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func update_view(sensor: PlayerVisibility, camera: Camera3D) -> void:
	visible = is_instance_valid(sensor.actor) and not sensor.actor.is_dead
	if not visible: return
	refresh_remaining -= get_process_delta_time()
	if boundary.is_empty() or refresh_remaining <= 0.0:
		boundary = sensor.view_boundary()
		refresh_remaining = .05
	projected.clear()
	outer.clear()
	var center := camera.unproject_position(sensor.actor.global_position + Vector3.UP * .05)
	var reach := get_viewport_rect().size.length() * 3.0
	for point in boundary:
		var pixel := camera.unproject_position(point)
		projected.append(pixel)
		outer.append(center + (pixel - center).normalized() * reach)
	queue_redraw()

func _draw() -> void:
	# Radial quads leave the observed region clear and keep the surroundings
	# readable. The overlay sits below all HUD controls and never intercepts input.
	for index in range(projected.size() - 1):
		var a := projected[index]
		var b := outer[index]
		var c := outer[index + 1]
		var d := projected[index + 1]
		# Adjacent rays can project onto the same line. Skip zero-area triangles
		# instead of asking the renderer to triangulate a degenerate quad.
		if absf((b - a).cross(c - a)) > 0.01:
			draw_colored_polygon(PackedVector2Array([a, b, c]), Color(.025, .035, .045, .34))
		if absf((c - a).cross(d - a)) > 0.01:
			draw_colored_polygon(PackedVector2Array([a, c, d]), Color(.025, .035, .045, .34))
	if projected.size() > 1:
		draw_polyline(projected, Color(.78, .74, .55, .24), 1.0, true)
