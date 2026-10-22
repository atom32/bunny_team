class_name ContactConversation
extends PanelContainer
## Optional, replayable base conversation. No dialogue flags, rewards or transactions.
var scene_data: Dictionary
var line_index := 0
var opened := false
var line_label: Label
var speaker_label: Label
var title_button: Button
var advance_button: Button
var close_button: Button
var exchange: VBoxContainer

func _ready() -> void:
	name = "ContactConversation"
	add_theme_stylebox_override("panel", FieldManualStyle.panel(FieldManualStyle.PAPER))
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 6)
	add_child(body)
	title_button = Button.new()
	title_button.name = "OpenConversation"
	title_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	title_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_button.pressed.connect(func(): opened = not opened; _refresh())
	body.add_child(title_button)
	exchange = VBoxContainer.new()
	body.add_child(exchange)
	speaker_label = Label.new()
	speaker_label.add_theme_color_override("font_color", FieldManualStyle.ACCENT)
	exchange.add_child(speaker_label)
	line_label = Label.new()
	line_label.name = "ConversationLine"
	line_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line_label.custom_minimum_size.y = 52
	line_label.add_theme_font_size_override("font_size", 16)
	exchange.add_child(line_label)
	var buttons := HBoxContainer.new()
	exchange.add_child(buttons)
	advance_button = Button.new()
	advance_button.name = "NextLine"
	advance_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	advance_button.pressed.connect(func(): line_index = (line_index + 1) % scene_data.lines.size(); _refresh())
	buttons.add_child(advance_button)
	close_button = Button.new()
	close_button.name = "CloseConversation"
	close_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close_button.pressed.connect(func(): opened = false; _refresh(); title_button.grab_focus())
	buttons.add_child(close_button)
	GameLanguage.language_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	if scene_data.is_empty(): hide(); return
	title_button.text = tr("A WORD / %s") % tr(scene_data.title)
	exchange.visible = opened
	var line: Dictionary = scene_data.lines[line_index]
	speaker_label.text = tr(CampusConversations.SPEAKERS[line.speaker]) + "  %d / %d" % [line_index + 1, scene_data.lines.size()]
	line_label.text = tr(line.text)
	advance_button.text = tr("HEAR IT AGAIN" if line_index == scene_data.lines.size() - 1 else "NEXT LINE")
	close_button.text = tr("BACK TO BUSINESS")
