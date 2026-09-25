class_name ResultUI
extends CanvasLayer

signal return_requested

var outcome: SortieOutcome
var status_label: Label
var recovery_label: Label
var mission_label: Label
var mission_completion_label: Label
var objective_labels: Array[Label] = []
var return_button: Button
var return_error_label: Label


func configure(p_outcome: SortieOutcome) -> void:
	outcome = p_outcome


func _ready() -> void:
	if not outcome:
		push_error("ResultUI requires a SortieOutcome")
		return
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = UIFactory.theme()
	add_child(root)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-320, -310)
	panel.size = Vector2(640, 620)
	panel.add_theme_stylebox_override("panel", UIFactory.panel_style(Color("101925f2"), Color("587994")))
	root.add_child(panel)
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)

	var extracted := outcome.result_type == SortieOutcome.ResultType.COMPLETED
	status_label = Label.new()
	status_label.name = "OutcomeStatus"
	match outcome.result_type:
		SortieOutcome.ResultType.COMPLETED:
			status_label.text = "EXTRACTION SUCCESSFUL"
		SortieOutcome.ResultType.FAILED:
			status_label.text = "SORTIE FAILED"
		SortieOutcome.ResultType.ABANDONED:
			status_label.text = "SORTIE ABANDONED"
		_:
			status_label.text = "SORTIE ENDED"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 38)
	status_label.add_theme_color_override("font_color", Color("79f1e7") if extracted else Color("ff5b6f"))
	content.add_child(status_label)
	var mission := ContentDB.get_mission(outcome.mission_id, false)
	mission_label = Label.new()
	mission_label.name = "MissionName"
	mission_label.text = "MISSION  /  %s" % (mission.display_name if mission else String(outcome.mission_id))
	mission_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mission_label.add_theme_color_override("font_color", Color("a9c4d4"))
	content.add_child(mission_label)
	mission_completion_label = Label.new()
	mission_completion_label.name = "MissionCompletion"
	mission_completion_label.text = "MISSION COMPLETE" if outcome.mission_completed else "MISSION INCOMPLETE"
	mission_completion_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mission_completion_label.add_theme_color_override("font_color", Color("79f1e7") if outcome.mission_completed else Color("ffbd72"))
	content.add_child(mission_completion_label)
	var objective_heading := Label.new()
	objective_heading.text = "OBJECTIVES"
	objective_heading.add_theme_color_override("font_color", Color("76deea"))
	content.add_child(objective_heading)
	for summary in outcome.get_objective_summaries():
		var definition := mission.get_objective(StringName(summary.get("objective_id", ""))) if mission else null
		var completed := int(summary.get("status", ObjectiveState.Status.PENDING)) == ObjectiveState.Status.COMPLETED
		var objective_label := Label.new()
		objective_label.text = "%s  %s    %d / %d" % [
			"COMPLETE" if completed else "INCOMPLETE",
			definition.display_name if definition else str(summary.get("objective_id", "Unknown")),
			int(summary.get("progress", 0)),
			int(summary.get("target", 0)),
		]
		objective_label.add_theme_color_override("font_color", Color("79f1e7") if completed else Color("c4d2dc"))
		content.add_child(objective_label)
		objective_labels.append(objective_label)
	if outcome.result_type == SortieOutcome.ResultType.FAILED:
		var failure_message := Label.new()
		failure_message.text = "You were eliminated."
		failure_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		failure_message.add_theme_color_override("font_color", Color("c4d2dc"))
		content.add_child(failure_message)
		recovery_label = Label.new()
		recovery_label.name = "RecoveryStatus"
		recovery_label.text = "RECOVERED: NOTHING"
		recovery_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		recovery_label.add_theme_color_override("font_color", Color("ffbd72"))
		content.add_child(recovery_label)
	var divider := HSeparator.new()
	content.add_child(divider)
	_add_stat(content, "ENEMIES DEFEATED", str(outcome.enemies_defeated))
	_add_stat(content, "DAMAGE TAKEN", str(outcome.damage_taken))
	var weapon_item := outcome.loadout.get_item(LoadoutState.SLOT_WEAPON_PRIMARY, outcome.inventory)
	var weapon := ContentDB.get_weapon(weapon_item.definition_id, false) if weapon_item else null
	if weapon:
		_add_stat(content, "PRIMARY WEAPON", weapon.display_name)
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 24
	content.add_child(spacer)
	return_error_label = Label.new()
	return_error_label.name = "ReturnError"
	return_error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return_error_label.add_theme_color_override("font_color", Color("ff7a8d"))
	return_error_label.visible = false
	content.add_child(return_error_label)
	return_button = Button.new()
	return_button.name = "ReturnButton"
	return_button.text = "RETURN TO HANGER"
	return_button.custom_minimum_size = Vector2(0, 58)
	content.add_child(return_button)
	return_button.pressed.connect(func() -> void:
		AudioDirector.play_sfx(&"ui_confirm")
		return_requested.emit()
	)


func set_return_pending(pending: bool) -> void:
	if return_button:
		return_button.disabled = pending
		return_button.text = "FINALIZING..." if pending else "RETURN TO HANGER"
	if pending and return_error_label:
		return_error_label.visible = false


func show_return_error(message: String) -> void:
	set_return_pending(false)
	if return_error_label:
		return_error_label.text = message
		return_error_label.visible = true


func _add_stat(parent: VBoxContainer, name_text: String, value_text: String) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var name_label := Label.new()
	name_label.text = name_text
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_color_override("font_color", Color("8da8bb"))
	row.add_child(name_label)
	var value_label := Label.new()
	value_label.text = value_text
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_color_override("font_color", Color("eef8ff"))
	row.add_child(value_label)
