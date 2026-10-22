class_name CombatFeedback
extends Control
## Transient observations only: no target references, health bars or saved state.
var camera: Camera3D
var active := true
var inspection_open := false
var hit_remaining := 0.0
var hit_defeated := false
var hit_world_point := Vector3.ZERO
var danger_remaining := 0.0
var incoming: Array[Dictionary] = []
var hit_label: Label
var danger_label: Label
var _hit_screen := Vector2.ZERO


func _ready() -> void:
	name = "CombatFeedback"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hit_label = _label(14, Vector2(130, 28))
	danger_label = _label(16, Vector2(240, 30))
	danger_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	danger_label.add_theme_color_override("font_color", Color("ff9c82"))
	GameLanguage.language_changed.connect(_refresh_text)
	_refresh_text()


func _label(font_size: int, extent: Vector2) -> Label:
	var label := Label.new()
	label.size = extent
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", UIFactory.FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color("172125"))
	label.add_theme_constant_override("outline_size", 4)
	label.hide()
	add_child(label)
	return label


func confirm_hit(world_point: Vector3, defeated: bool) -> void:
	if not active or not world_point.is_finite(): return
	# A simultaneous rocket blast or shotgun pellet must not erase its DOWN cue
	# with a later nonlethal contact in the same short confirmation window.
	if hit_remaining > 0.0 and hit_defeated and not defeated: return
	hit_world_point = world_point
	hit_defeated = defeated
	hit_remaining = .55 if defeated else .22
	_refresh_text()


func receive_hit(world_direction: Vector3) -> void:
	if not active: return
	danger_remaining = 1.1
	var flat := Vector3(world_direction.x, 0, world_direction.z)
	# Missing/vertical/debug impulses still show danger, never invent a bearing.
	if not flat.is_finite() or flat.length_squared() < .0001: return
	flat = flat.normalized()
	for event in incoming:
		if event.direction.dot(flat) > .94:
			event.remaining = 1.1
			return
	if incoming.size() == 4: incoming.pop_front()
	incoming.append({"direction":flat, "remaining":1.1})


func clear() -> void:
	active = false
	hit_remaining = 0.0
	danger_remaining = 0.0
	incoming.clear()
	hit_label.hide()
	danger_label.hide()
	queue_redraw()


static func screen_bearing(world_direction: Vector3, basis: Basis) -> Vector2:
	return Vector2(world_direction.dot(basis.x), -world_direction.dot(basis.y)).normalized()


func _refresh_text() -> void:
	hit_label.text = tr("TARGET DOWN" if hit_defeated else "CONFIRMED HIT")
	hit_label.add_theme_color_override("font_color", Color("ffd28a") if hit_defeated else Color.WHITE)
	danger_label.text = tr("UNDER ATTACK")


func _process(delta: float) -> void:
	hit_remaining = maxf(0.0, hit_remaining-delta)
	danger_remaining = maxf(0.0, danger_remaining-delta)
	for event in incoming: event.remaining = maxf(0.0, event.remaining-delta)
	incoming = incoming.filter(func(event): return event.remaining > 0.0)
	hit_label.visible = hit_remaining > 0.0 and not inspection_open and is_instance_valid(camera) and not camera.is_position_behind(hit_world_point)
	if hit_label.visible:
		_hit_screen = camera.unproject_position(hit_world_point)
		hit_label.visible = get_viewport_rect().has_point(_hit_screen)
		hit_label.position = (_hit_screen+Vector2(14,-28)).clamp(Vector2(12,12), size-hit_label.size-Vector2(12,12))
		hit_label.modulate.a = minf(1.0, hit_remaining/.15)
	danger_label.visible = danger_remaining > 0.0
	danger_label.position = Vector2((size.x-danger_label.size.x)*.5,24 if inspection_open else 116)
	danger_label.modulate.a = minf(1.0, danger_remaining/.25)
	queue_redraw()


func _draw() -> void:
	if hit_label and hit_label.visible:
		var color := Color("ffd28a") if hit_defeated else Color.WHITE
		color.a = hit_label.modulate.a
		var radius := 14.0 if hit_defeated else 10.0
		for direction in [Vector2(-1,-1),Vector2(1,-1),Vector2(-1,1),Vector2(1,1)]:
			draw_line(_hit_screen+direction*5, _hit_screen+direction*radius, Color(0.05,0.07,0.08,color.a), 5, true)
			draw_line(_hit_screen+direction*5, _hit_screen+direction*radius, color, 2, true)
	if not is_instance_valid(camera): return
	for event in incoming:
		var direction := screen_bearing(event.direction, camera.global_basis)
		if direction.is_zero_approx(): continue
		var half := size*.5-Vector2(70,70)
		var reach := minf(half.x/maxf(absf(direction.x),.001), half.y/maxf(absf(direction.y),.001))
		var center := size*.5+direction*reach
		var side := direction.orthogonal()*9
		var points := PackedVector2Array([center+direction*8,center-direction*10+side,center-direction*10-side])
		var alpha := minf(1.0, float(event.remaining)/.25)
		draw_polyline(PackedVector2Array([points[0],points[1],points[2],points[0]]), Color(0.05,0.07,0.08,alpha), 5, true)
		draw_colored_polygon(points, Color(1.0,.35,.23,alpha))
