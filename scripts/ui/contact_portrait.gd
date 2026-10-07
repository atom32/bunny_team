class_name ContactPortrait
extends PanelContainer
## Shared generated portrait and face crop; presentation only, no save changes.
var contact_id := "tang_kui"
var compact := false

func _ready() -> void:
	var contact := ContactDefinition.get_contact(contact_id)
	var style := SliceUI.menu_style(Color("24271f"), Color("555749"))
	if contact.portrait:
		style.content_margin_left = 4
		style.content_margin_right = 4
		style.content_margin_top = 4
		style.content_margin_bottom = 4
	add_theme_stylebox_override("panel", style)
	custom_minimum_size = Vector2(40, 40) if compact else Vector2(208, 220)
	tooltip_text = contact.display_name + " / " + contact.title
	if contact.portrait:
		var art := TextureRect.new()
		art.texture = contact.portrait
		if compact:
			var face := AtlasTexture.new()
			face.atlas = contact.portrait
			var dimensions: Vector2 = contact.portrait.get_size()
			face.region = Rect2(dimensions * Vector2(.30, 0), dimensions * Vector2(.44, .35))
			art.texture = face
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		add_child(art)
	else:
		var mark := Label.new()
		mark.text = contact.display_name.left(1) if compact else contact.display_name + "\n\n人物立绘待补"
		mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		mark.add_theme_font_size_override("font_size", 16 if compact else 24)
		mark.add_theme_color_override("font_color", SliceUI.CYAN)
		add_child(mark)
