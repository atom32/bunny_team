class_name ControlSettings
extends VBoxContainer
var draft := ControlBindings.current.duplicate()
var listening := ""
var feedback: Label
var buttons: Dictionary = {}
var save_path := ControlBindings.PATH

func _ready() -> void:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(540,280)
	add_child(scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)
	for action in ControlBindings.LABELS:
		var row := HBoxContainer.new()
		rows.add_child(row)
		var text := Label.new()
		text.text = ControlBindings.LABELS[action]
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text)
		var button := Button.new()
		button.name = action
		button.custom_minimum_size = Vector2(180,36)
		row.add_child(button)
		buttons[action] = button
		button.pressed.connect(func():
			listening = action
			feedback.text = "PRESS A KEY OR MOUSE BUTTON / ESC CANCELS"
			refresh()
		)
	feedback = Label.new()
	feedback.custom_minimum_size = Vector2(540,40)
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(feedback)
	refresh()

func refresh() -> void:
	for action in buttons:
		buttons[action].text = "..." if action == listening else ControlBindings.key_label(draft[action])

func capture(event: InputEvent) -> bool:
	if listening.is_empty(): return false
	if not event.is_pressed() or event.is_echo(): return true
	if event is InputEventKey and ControlBindings.code(event) == KEY_ESCAPE:
		listening = ""; feedback.text = "CANCELLED"; refresh(); return true
	var value := ControlBindings.code(event)
	var candidate := draft.duplicate()
	candidate[listening] = value
	if not ControlBindings.valid(candidate):
		feedback.text = "KEY ALREADY USED OR RESERVED / TRY ANOTHER"
		return true
	draft = candidate
	listening = ""
	feedback.text = "PRESS APPLY TO SAVE"
	refresh()
	return true

func apply() -> void:
	listening = ""
	var error := ControlBindings.apply(draft,save_path)
	feedback.text = "APPLIED / SAVED" if error == OK else tr("Could not save: ") + error_string(error)
	refresh()

func reset_draft() -> void:
	listening = ""
	draft = ControlBindings.defaults.duplicate()
	feedback.text = "PRESS APPLY TO SAVE"
	refresh()
