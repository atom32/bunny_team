class_name FieldManualStyle
extends RefCounted
## Opt-in field-manual presentation palette. Never changes item or save rules.
const PAPER := Color("f2f3ed")
const SURFACE := Color("fafbf7")
const INK := Color("1b2021")
const MUTED := Color("5d6869")
const LINE := Color("cdd2cb")
const ACCENT := Color("333e39") # Legacy text/trace accent; keep contrast on paper.
const SIGNAL := Color("e8f34a") # Action/current-state fills only.
const BLUE := Color("65736a")
const SUCCESS := Color("42574b")

static func panel(fill: Color = PAPER, border: Color = LINE) -> StyleBoxFlat:
	var result := UIFactory.panel_style(fill,border)
	result.set_corner_radius_all(0)
	return result

static func bar(fill: Color) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = fill
	result.set_corner_radius_all(0)
	return result

static func button_style(fill: Color, border: Color = LINE) -> StyleBoxFlat:
	var result := panel(fill,border)
	result.content_margin_left = 8
	result.content_margin_right = 8
	result.content_margin_top = 6
	result.content_margin_bottom = 6
	return result

static func cut_style(fill: Color, border: Color = LINE) -> StyleBox:
	var result := preload("res://scripts/ui/operation_cut_style.gd").new()
	result.fill = fill
	result.edge = border
	result.content_margin_left = 16
	result.content_margin_right = 24
	result.content_margin_top = 8
	result.content_margin_bottom = 8
	return result

static func theme() -> Theme:
	var result := UIFactory.theme()
	for type in ["Label","RichTextLabel","Button","OptionButton","PopupMenu"]:
		result.set_color("default_color" if type == "RichTextLabel" else "font_color",type,INK)
	for type in ["Button","OptionButton"]:
		result.set_color("font_hover_color",type,INK)
		result.set_color("font_pressed_color",type,INK)
		result.set_color("font_focus_color",type,INK)
		result.set_color("font_disabled_color",type,Color("929591"))
		result.set_stylebox("normal",type,button_style(SURFACE))
		result.set_stylebox("hover",type,button_style(SIGNAL,ACCENT))
		result.set_stylebox("pressed",type,button_style(SIGNAL,ACCENT))
		result.set_stylebox("disabled",type,button_style(Color("e1e4dc"),Color("d5d5ce")))
		result.set_stylebox("focus",type,button_style(Color.TRANSPARENT,ACCENT))
	result.set_stylebox("panel","PopupMenu",panel(SURFACE))
	result.set_stylebox("hover","PopupMenu",panel(SIGNAL,ACCENT))
	result.set_color("font_hover_color","PopupMenu",INK)
	result.set_color("font_disabled_color","PopupMenu",MUTED)
	for type in ["LineEdit", "TextEdit"]:
		result.set_color("font_color",type,INK)
		result.set_color("font_placeholder_color",type,MUTED)
		result.set_color("caret_color",type,ACCENT)
		result.set_stylebox("normal",type,button_style(SURFACE))
		result.set_stylebox("focus",type,button_style(SURFACE,ACCENT))
	for type in ["TabContainer", "TabBar"]:
		result.set_stylebox("tab_selected",type,button_style(SIGNAL,ACCENT))
		result.set_stylebox("tab_unselected",type,button_style(SURFACE))
		result.set_stylebox("panel",type,panel(SURFACE))
		result.set_color("font_selected_color",type,INK)
		result.set_color("font_unselected_color",type,MUTED)
	result.set_stylebox("separator","HSeparator",bar(LINE))
	for state in ["slider", "grabber_area", "grabber_area_highlight"]:
		var rail_style := bar(LINE if state == "slider" else ACCENT)
		rail_style.content_margin_top = 3
		rail_style.content_margin_bottom = 3
		result.set_stylebox(state,"HSlider",rail_style)
	var thumb := GradientTexture2D.new()
	thumb.width = 12
	thumb.height = 16
	thumb.gradient = Gradient.new()
	thumb.gradient.colors = PackedColorArray([ACCENT,ACCENT])
	for state in ["grabber", "grabber_highlight"]: result.set_icon(state,"HSlider",thumb)
	result.set_constant("table_h_separation","RichTextLabel",12)
	result.set_constant("table_v_separation","RichTextLabel",14)
	result.set_color("default_color","RichTextLabel",INK)
	var rail := panel(Color("d6d6cf"),Color("d6d6cf"))
	rail.content_margin_left = 4
	rail.content_margin_right = 4
	result.set_stylebox("scroll","VScrollBar",rail)
	for state in ["grabber","grabber_highlight","grabber_pressed"]:
		result.set_stylebox(state,"VScrollBar",panel(BLUE,BLUE))
	for type in ["CheckBox", "CheckButton"]:
		for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_hover_pressed_color"]:
			result.set_color(state,type,INK)
		result.set_color("font_disabled_color",type,MUTED)
	result.set_stylebox("panel","PanelContainer",panel())
	result.set_stylebox("background","ProgressBar",bar(LINE))
	result.set_stylebox("fill","ProgressBar",bar(INK))
	result.set_color("selection_color","TextEdit",Color("dce5b0"))
	result.set_color("font_selected_color","TextEdit",INK)
	return result

static func dark_theme() -> Theme:
	var result := theme()
	result.set_stylebox("panel","PanelContainer",panel(Color("191d1e"),Color("4e5858")))
	for type in ["Label","RichTextLabel"]:
		result.set_color("default_color" if type == "RichTextLabel" else "font_color",type,SURFACE)
	for type in ["Button","OptionButton"]:
		result.set_color("font_color",type,SURFACE)
		for state in ["font_hover_color","font_pressed_color","font_focus_color","font_hover_pressed_color"]: result.set_color(state,type,INK)
		result.set_stylebox("normal",type,button_style(Color("202627"),Color("4e5858")))
		result.set_stylebox("hover",type,button_style(SIGNAL,Color.TRANSPARENT))
		result.set_stylebox("pressed",type,button_style(SIGNAL,Color.TRANSPARENT))
		result.set_stylebox("focus",type,button_style(SIGNAL,Color.TRANSPARENT))
		result.set_stylebox("disabled",type,button_style(Color("252a2a"),Color("373e3e")))
	for type in ["TabContainer","TabBar"]:
		result.set_stylebox("panel",type,panel(Color("191d1e"),Color("4e5858")))
		result.set_stylebox("tab_unselected",type,button_style(Color("202627"),Color("4e5858")))
		result.set_color("font_unselected_color",type,Color("adb4af"))
	return result

static func primary(button: Button) -> void:
	for state in ["normal", "hover", "pressed"]:
		var fill := SIGNAL if state != "pressed" else Color("cfdb36")
		button.add_theme_stylebox_override(state, cut_style(fill, Color.TRANSPARENT))
		button.add_theme_color_override("font_" + ("color" if state == "normal" else state + "_color"), INK)
	button.add_theme_color_override("font_focus_color", INK)
	button.add_theme_color_override("font_hover_pressed_color", INK)
