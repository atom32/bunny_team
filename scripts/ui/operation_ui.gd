class_name OperationUI
extends RefCounted
## Composition only. All inventory, deployment and save actions stay with their owners.
const SIGNAL := FieldManualStyle.SIGNAL
const DARK := Color("191d1e")
const WIDE_FONT := preload("res://assets/fonts/saira/Saira.ttf")

static func typeface(weight := 600.0, width := 125.0) -> FontVariation:
	var font := FontVariation.new()
	font.base_font = WIDE_FONT
	font.variation_opentype = {2003265652:weight, 2003072104:width}
	font.fallbacks = [UIFactory.FONT]
	return font

static func text(parent: Node, caption: String, at: Vector2, size := 16, color := FieldManualStyle.INK, wide := false) -> Label:
	var label := SliceUI.label(parent, caption, at, size, color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if wide: label.add_theme_font_override("font", typeface())
	return label

static func block(parent: Node, at: Vector2, extent: Vector2, fill := FieldManualStyle.PAPER) -> ColorRect:
	var block := ColorRect.new()
	block.position = at
	block.size = extent
	block.color = fill
	block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(block)
	return block

static func rule(parent: Node, at: Vector2, width: float) -> void:
	block(parent, at, Vector2(width,1), FieldManualStyle.LINE)

static func eyebrow(parent: Node, caption: String, at: Vector2, light := false) -> Label:
	return text(parent, "// " + caption, at, 12, Color("adb4af") if light else FieldManualStyle.MUTED, true)

static func action(parent: Node, caption: String, at: Vector2, extent: Vector2, callback: Callable, primary := false) -> Button:
	var button := SliceUI.button(parent, caption, at, extent, callback)
	button.add_theme_font_size_override("font_size", 17)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var fill := FieldManualStyle.SURFACE if state == "normal" else SIGNAL
		if state == "disabled": fill = Color("e1e4dc")
		if state == "focus": fill = Color.TRANSPARENT
		button.add_theme_stylebox_override(state, FieldManualStyle.cut_style(fill, FieldManualStyle.INK if state == "focus" else FieldManualStyle.LINE))
	if primary: FieldManualStyle.primary(button)
	return button

static func heading(parent: Node, english: String, title: String, at: Vector2) -> void:
	eyebrow(parent, english, at)
	var label := text(parent, title, at + Vector2(0,22), 30)
	var bold := FontVariation.new()
	bold.base_font = preload("res://assets/fonts/noto_sans_sc/NotoSansSC.ttf")
	bold.variation_opentype = {2003265652:700.0}
	label.add_theme_font_override("font", bold)
