class_name ResultUI
extends CanvasLayer

const STORY_SURFACE := FieldManualStyle.PAPER
const STORY_TEXT := FieldManualStyle.INK

signal return_requested
signal bucket_return_requested
signal rescue_return_requested

var outcome: SortieOutcome
var status_label: Label
var recovery_label: Label
var mission_label: Label
var mission_completion_label: Label
var objective_labels: Array[Label] = []
var return_button: Button
var bucket_button: Button
var rescue_button: Button
var return_error_label: Label
var feedback_button: Button
var _return_pending := false
var _return_error := ""


func configure(p_outcome: SortieOutcome) -> void:
	outcome = p_outcome


func _ready() -> void:
	GameLanguage.language_changed.connect(_refresh_language)
	_build_ui()

func _refresh_language() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	objective_labels.clear()
	_build_ui()

func _build_ui() -> void:
	bucket_button=null;rescue_button=null
	if not outcome:
		push_error("ResultUI requires a SortieOutcome")
		return
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = FieldManualStyle.theme()
	add_child(root)
	feedback_button = Button.new()
	feedback_button.name = "PlaytestFeedbackButton"
	feedback_button.text = "PLAYTEST FEEDBACK"
	feedback_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	feedback_button.position = Vector2(-208,10)
	feedback_button.size = Vector2(184,34)
	feedback_button.add_theme_font_size_override("font_size",14)
	feedback_button.pressed.connect(func(): FlowMenu.show_feedback(false))
	root.add_child(feedback_button)

	var panel := PanelContainer.new()
	panel.name = "DebriefPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(70, -310)
	panel.size = Vector2(530, 620)
	panel.add_theme_stylebox_override("panel", FieldManualStyle.panel())
	root.add_child(panel)
	OperationUI.block(root,Vector2(28,24),Vector2(406,176),OperationUI.DARK)
	OperationUI.eyebrow(root,"FIELD RECORDER",Vector2(50,42),true)
	var wordmark := OperationUI.text(root,"DEBRIEF",Vector2(48,80),46,Color.WHITE,true)
	wordmark.add_theme_font_override("font",OperationUI.typeface(800,112))
	OperationUI.text(root,tr("BASTION 07 / RETURN CHANNEL"),Vector2(50,156),13,Color("adb4af"))
	var extracted := outcome.result_type == SortieOutcome.ResultType.COMPLETED
	var primary := SortieGuidance.debrief(outcome)
	var facts := ""
	if outcome.result_type == SortieOutcome.ResultType.COMPLETED: facts = BlockadeStory.ending(outcome) if outcome.area_id == BlockadeStory.AREA else WaterworksStory.ending(outcome)
	if MaintenanceStory.returned(outcome):facts=MaintenanceStory.ending(outcome)
	if FinaleStory.returned(outcome):facts=FinaleStory.ending(outcome)
	if outcome.result_type == SortieOutcome.ResultType.COMPLETED:
		if not outcome.exit_observations.is_empty():
			facts = "Q01 / 已查看出口 %d / 2\n回基地后计入进度。两处都已查看，奖励 150 信用点。" % outcome.exit_observations.size()
		elif outcome.q04_active:
			facts = tr("Legacy logistics sortie / carried possessions and rewards settle normally. No new campus story progress is granted.")
		elif outcome.q02_active:
			facts = tr("Q02 / Supplies recovered. Deliver dressings and fabric to Tang Kui at base; no delivery records required.")
	if not primary.is_empty():
		facts = primary[0] + "\n\n" + primary[1]
		facts += "\n\n" + tr("Return to base to save the result. This screen does not settle rewards.")
	if not facts.is_empty():
		_ensure_story_readout(root)
		var heading := SliceUI.label(root, tr("STORY COMMISSION") if not primary.is_empty() else "出击与委托", Vector2(50, 235), 16, FieldManualStyle.INK)
		heading.name = "CommissionHeading"
		# Configure wrapping/bounds before text, including legacy result notes.
		var notes := SliceUI.label(root, "", Vector2(50, 275), 18 if not primary.is_empty() else 16, STORY_TEXT)
		notes.name = "ReturnFacts"
		notes.size = Vector2(360, 300 if not primary.is_empty() or MaintenanceStory.returned(outcome) or FinaleStory.returned(outcome) else 135)
		notes.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		notes.text = facts
	if GameState.presentation_enabled and not WaterworksStory.returned_branch(outcome).is_empty():
		bucket_button=SliceUI.button(root,"BRING THE BUCKET UPSTAIRS",Vector2(50,600),Vector2(360,44),func():bucket_return_requested.emit())
		bucket_button.name="WaterBucketReturn"
	if GameState.presentation_enabled and MaintenanceStory.returned(outcome):
		rescue_button=SliceUI.button(root,"KEEP THE DOOR OPEN",Vector2(50,600),Vector2(360,44),func():rescue_return_requested.emit())
		rescue_button.name="RescueDoorReturn"
	var profile := ProfileRuntime.get_profile()
	if profile.first_mission_completed and primary.is_empty() and outcome.area_id not in [MaintenanceStory.AREA,FinaleStory.AREA]:
		var preview := ProfileState.from_dict(profile.to_dict())
		# Preview only; real progress waits for the atomic result/save transaction.
		if outcome.outcome_id not in preview.settled_outcomes: CampaignService.record_outcome(preview, outcome)
		var quest := CampaignService.current(preview)
		if not quest.is_empty():
			_ensure_story_readout(root)
			var text := tr("ON RETURN / BASTION CONTRACT") + "\n\n" + tr(quest.title)
			text += "\n\n" + (tr("PROJECTED ON RETURN / %d / %d") % [preview.campaign.progress, quest.target] if quest.target > 0 else tr("Turn in warehouse materials at Hideout Overview."))
			var contract := SliceUI.label(root, "", Vector2(50, 420), 16, STORY_TEXT)
			contract.name = "CampaignPreview"
			contract.size = Vector2(360, 170)
			contract.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			contract.text = text
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation",12)
	panel.add_child(layout)
	var scroll := ScrollContainer.new()
	scroll.name = "DebriefScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",10)
	scroll.add_child(content)
	var footer := VBoxContainer.new()
	footer.add_theme_constant_override("separation",8)
	layout.add_child(footer)
	var pending_note := Label.new()
	pending_note.name = "SettlementNotice"
	pending_note.text = tr("Return to base to save the result. This screen does not settle rewards.")
	pending_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pending_note.add_theme_font_size_override("font_size",13)
	pending_note.add_theme_color_override("font_color",FieldManualStyle.MUTED)
	footer.add_child(pending_note)

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
	status_label.add_theme_font_size_override("font_size", 26)
	status_label.add_theme_stylebox_override("normal",FieldManualStyle.button_style(FieldManualStyle.SIGNAL,Color.TRANSPARENT))
	status_label.add_theme_color_override("font_color", FieldManualStyle.INK)
	content.add_child(status_label)
	var mission := ContentDB.get_mission(outcome.mission_id, false)
	mission_label = Label.new()
	mission_label.name = "MissionName"
	mission_label.text = tr("OPTIONAL OPERATION / %s" if not primary.is_empty() else "MISSION  /  %s") % (GameLanguage.item_name(mission.display_name) if mission else String(outcome.mission_id))
	mission_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mission_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mission_label.add_theme_color_override("font_color", FieldManualStyle.MUTED)
	content.add_child(mission_label)
	mission_completion_label = Label.new()
	mission_completion_label.name = "MissionCompletion"
	mission_completion_label.text = tr("OPTIONAL OPERATION COMPLETE" if outcome.mission_completed else "OPTIONAL OPERATION NOT COMPLETED") if not primary.is_empty() else ("MISSION COMPLETE" if outcome.mission_completed else "MISSION INCOMPLETE")
	mission_completion_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mission_completion_label.add_theme_color_override("font_color", FieldManualStyle.INK)
	content.add_child(mission_completion_label)
	var objective_heading := Label.new()
	objective_heading.name = "ObjectiveHeading"
	objective_heading.text = tr("OPTIONAL OBJECTIVES") if not primary.is_empty() else "OBJECTIVES"
	objective_heading.add_theme_color_override("font_color", FieldManualStyle.MUTED)
	content.add_child(objective_heading)
	for summary in outcome.get_objective_summaries():
		var definition := mission.get_objective(StringName(summary.get("objective_id", ""))) if mission else null
		var completed := int(summary.get("status", ObjectiveState.Status.PENDING)) == ObjectiveState.Status.COMPLETED
		var objective_label := Label.new()
		objective_label.text = tr("%s  %s    %d / %d") % [
			tr("COMPLETE" if completed else "INCOMPLETE"),
			GameLanguage.item_name(definition.display_name) if definition else str(summary.get("objective_id", "Unknown")),
			int(summary.get("progress", 0)),
			int(summary.get("target", 0)),
		]
		objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		objective_label.add_theme_font_size_override("font_size",15)
		objective_label.add_theme_color_override("font_color", FieldManualStyle.INK if completed else FieldManualStyle.MUTED)
		content.add_child(objective_label)
		objective_labels.append(objective_label)
	if outcome.result_type == SortieOutcome.ResultType.FAILED:
		var failure_message := Label.new()
		failure_message.text = "You were eliminated."
		failure_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		failure_message.add_theme_color_override("font_color", FieldManualStyle.MUTED)
		content.add_child(failure_message)
		recovery_label = Label.new()
		recovery_label.name = "RecoveryStatus"
		recovery_label.text = "RECOVERED: NOTHING"
		recovery_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		recovery_label.add_theme_color_override("font_color", FieldManualStyle.MUTED)
		content.add_child(recovery_label)
	var divider := HSeparator.new()
	content.add_child(divider)
	_add_stat(content, "SURVIVAL", "EXTRACTED" if extracted else "UNIT LOST")
	# Outcome inventory is recovered cargo, never a snapshot of carried gear at death.
	_add_stat(content, "RECOVERED CARGO", tr("%.1f / %.1f kg") % [outcome.inventory.get_used_capacity(), outcome.inventory.capacity])
	var recovered := 0
	for quantity in SortieOutcomeService.recovered_quantities(outcome,ProfileRuntime.get_profile()).values(): recovered += int(quantity)
	_add_stat(content, "NEW SUPPLIES", str(recovered))
	var reward := SortieOutcomeService.credit_reward(outcome,ProfileRuntime.get_profile())
	_add_stat(content, "LOOT / CREDIT REWARD", "0 / NO NEW SUPPLIES" if extracted and reward == 0 else str(reward))
	if not extracted:
		_add_stat(content, "DEPLOYED STACKS LOST", str(outcome.initial_carried_instance_ids.size()))
	if outcome.mission_id == &"first_mission" and extracted:
		var cores := 0
		for item in outcome.inventory.get_items():
			if item.definition_id == &"loot.salvage_core_01": cores += item.quantity
		_add_stat(content, "SALVAGE → WAREHOUSE ON RETURN", str(cores))
		_add_stat(content, "NEXT", "WORKSHOP / FIRST UPGRADE" if outcome.mission_completed else "RETRY FIRST MISSION")
	_add_stat(content, "ENEMIES DEFEATED", str(outcome.enemies_defeated))
	_add_stat(content, "DAMAGE TAKEN", str(outcome.damage_taken))
	var weapon_item := outcome.loadout.get_item(LoadoutState.SLOT_WEAPON_PRIMARY, outcome.inventory)
	var weapon := ContentDB.get_weapon(weapon_item.definition_id, false) if weapon_item else null
	if weapon:
		_add_stat(content, "PRIMARY WEAPON", GameLanguage.item_name(weapon.display_name))
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 4
	content.add_child(spacer)
	return_error_label = Label.new()
	return_error_label.name = "ReturnError"
	return_error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return_error_label.add_theme_color_override("font_color", FieldManualStyle.INK)
	return_error_label.visible = false
	return_error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.add_child(return_error_label)
	return_button = Button.new()
	return_button.name = "ReturnButton"
	return_button.text = "RETURN TO HIDEOUT" if GameState.presentation_enabled else "RETURN TO HANGER"
	return_button.custom_minimum_size = Vector2(0, 52)
	footer.add_child(return_button)
	FieldManualStyle.primary(return_button)
	return_button.pressed.connect(func() -> void:
		AudioDirector.play_sfx(&"ui_confirm")
		return_requested.emit()
	)
	set_return_pending(_return_pending)
	if not _return_error.is_empty() and not _return_pending:
		return_error_label.text = _return_error
		return_error_label.show()


func _ensure_story_readout(root: Control) -> void:
	if root.has_node("StoryReadout"): return
	# An opaque backing makes the pending story result legible over both the
	# dark sky and the lit 3D floor, without moving or hiding the heroine.
	var backing := Panel.new()
	backing.name = "StoryReadout"
	backing.position = Vector2(28, 220)
	backing.size = Vector2(406, 442)
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backing.add_theme_stylebox_override("panel", FieldManualStyle.panel(STORY_SURFACE))
	root.add_child(backing)


func set_return_pending(pending: bool) -> void:
	_return_pending = pending
	if is_instance_valid(feedback_button):feedback_button.disabled=pending
	if is_instance_valid(bucket_button):bucket_button.disabled=pending
	if is_instance_valid(rescue_button):rescue_button.disabled=pending
	if return_button:
		return_button.disabled = pending
		return_button.text = "FINALIZING..." if pending else ("RETURN TO HIDEOUT" if GameState.presentation_enabled else "RETURN TO HANGER")
	if pending and return_error_label:
		return_error_label.visible = false


func show_return_error(message: String) -> void:
	_return_error = message
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
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size",15)
	name_label.add_theme_color_override("font_color", FieldManualStyle.MUTED)
	row.add_child(name_label)
	var value_label := Label.new()
	value_label.text = value_text
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value_label.add_theme_font_size_override("font_size",15)
	value_label.add_theme_color_override("font_color", FieldManualStyle.INK)
	row.add_child(value_label)
