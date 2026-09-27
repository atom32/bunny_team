class_name SliceUI
extends RefCounted
## Small composition helpers; game data and actions stay with their existing owners.
const CYAN := Color("79e7e0")
const MUTED := Color("9caebc")

static func root(layer: CanvasLayer) -> Control:
	var control := Control.new()
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	control.theme = UIFactory.theme()
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
	item.add_theme_stylebox_override("panel", UIFactory.panel_style(Color("101c2aee"), Color("466777")))
	parent.add_child(item)
	return item

static func sign(parent: Node3D, text: String, at: Vector3, color: Color = CYAN) -> Label3D:
	var item := Label3D.new()
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
