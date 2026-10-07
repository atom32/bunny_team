class_name SliceUI
extends RefCounted
## Small composition helpers; game data and actions stay with their existing owners.
const CYAN := Color("c4b68a")
const MUTED := Color("96988b")

static func root(layer: CanvasLayer) -> Control:
	var control := Control.new()
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	control.theme = menu_theme()
	layer.add_child(control)
	return control

static func label(parent: Node, text: String, at: Vector2, font_size: int = 18, color: Color = Color.WHITE) -> Label:
	var item := Label.new()
	item.text = text
	item.position = at
	item.add_theme_font_size_override("font_size", font_size)
	item.add_theme_color_override("font_color", color)
	parent.add_child(item)
	return item

static func button(parent: Node, text: String, at: Vector2, size: Vector2, action: Callable) -> Button:
	var item := Button.new()
	item.text = text
	item.position = at
	item.size = size
	parent.add_child(item)
	item.pressed.connect(func():
		AudioDirector.play_sfx(&"ui_click")
		action.call()
	)
	return item

static func panel(parent: Node, at: Vector2, size: Vector2) -> Panel:
	var item := Panel.new()
	item.position = at
	item.size = size
	item.add_theme_stylebox_override("panel", menu_style(Color("171914f2"), Color("555749")))
	parent.add_child(item)
	return item

static func sign(parent: Node3D, text: String, at: Vector3, color: Color = CYAN) -> Label3D:
	var item := Label3D.new()
	item.font = UIFactory.FONT
	item.text = text
	item.position = at
	item.font_size = 48
	item.pixel_size = 0.008
	item.modulate = color
	parent.add_child(item)
	return item

static func prop(parent: Node3D, file: String, at: Vector3, scale_factor: float = 1.0) -> Node3D:
	var item := load(file).instantiate() as Node3D
	item.position = at
	item.scale = Vector3.ONE * scale_factor
	parent.add_child(item)
	if file.begins_with("res://assets/environment/kenney_space_station_kit/"):
		for mesh in item.find_children("*", "MeshInstance3D", true, false):
			mesh.material_override = load("res://resources/materials/office_palette.tres")
	return item


static func menu_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := UIFactory.panel_style(fill, border)
	style.set_corner_radius_all(0)
	return style

static func menu_theme() -> Theme:
	var result := UIFactory.theme()
	result.set_color("font_color", "Label", Color("ddd9ca"))
	for type in ["Button", "OptionButton"]:
		result.set_color("font_color", type, Color("ddd9ca"))
		result.set_color("font_hover_color", type, Color("f5ead0"))
		result.set_color("font_pressed_color", type, Color("f5ead0"))
		result.set_color("font_disabled_color", type, Color("73766a"))
		result.set_stylebox("normal", type, menu_style(Color("22251eea"), Color("555749")))
		result.set_stylebox("hover", type, menu_style(Color("383b2f"), CYAN))
		result.set_stylebox("pressed", type, menu_style(Color("151811"), CYAN))
		result.set_stylebox("disabled", type, menu_style(Color("1b1e18"), Color("33362d")))
		result.set_stylebox("focus", type, menu_style(Color.TRANSPARENT, CYAN))
	var rule := menu_style(Color("555749"), Color("555749"))
	rule.content_margin_left = 0
	rule.content_margin_right = 0
	rule.content_margin_top = 0
	rule.content_margin_bottom = 0
	result.set_stylebox("separator", "HSeparator", rule)
	for type in ["TabContainer", "TabBar"]:
		result.set_stylebox("tab_selected", type, menu_style(Color("383b2f"), CYAN))
		result.set_stylebox("tab_unselected", type, menu_style(Color("22251e"), Color("555749")))
		result.set_stylebox("panel", type, menu_style(Color("171914"), Color("555749")))
		result.set_color("font_selected_color", type, Color("ddd9ca"))
		result.set_color("font_unselected_color", type, MUTED)
	return result

static func divider(parent: Node, at: Vector2, width: float) -> ColorRect:
	var line := ColorRect.new()
	line.color = Color("555749")
	line.position = at
	line.size = Vector2(width, 1)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(line)
	return line
