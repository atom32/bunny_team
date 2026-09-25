class_name UIFactory
extends RefCounted


static func theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 18
	result.set_font_size("font_size", "Label", 18)
	result.set_font_size("font_size", "Button", 18)
	result.set_font_size("font_size", "OptionButton", 17)
	result.set_color("font_color", "Label", Color("e8f3ff"))
	result.set_color("font_color", "Button", Color("e8f3ff"))
	result.set_color("font_hover_color", "Button", Color.WHITE)
	result.set_color("font_color", "OptionButton", Color("e8f3ff"))
	result.set_stylebox("normal", "Button", panel_style(Color("26364b"), Color("4d7194")))
	result.set_stylebox("hover", "Button", panel_style(Color("32506c"), Color("65cde0")))
	result.set_stylebox("pressed", "Button", panel_style(Color("17283b"), Color("65cde0")))
	result.set_stylebox("normal", "OptionButton", panel_style(Color("1c2b3c"), Color("49647d")))
	result.set_stylebox("hover", "OptionButton", panel_style(Color("294259"), Color("65cde0")))
	return result


static func panel_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	return style

