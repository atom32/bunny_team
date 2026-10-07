class_name CampaignPanel
extends PanelContainer
signal contract_claimed
var save_path := SaveService.DEFAULT_SAVE_PATH
var contact_id := ""
var selected := -1
var feedback := "Only the active contract advances. Claim it at base to begin the next."

func _ready() -> void:
	theme = SliceUI.menu_theme()
	add_theme_stylebox_override("panel", SliceUI.menu_style(Color("171914fa"), Color("555749")))
	_refresh()

func _refresh() -> void:
	for child in get_children(): remove_child(child); child.queue_free()
	var profile := ProfileRuntime.get_profile()
	if selected < 0: selected = mini(int(profile.campaign.stage), CampaignService.QUESTS.size() - 1)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	if contact_id.is_empty():
		_label(body, "委托记录 / FIELD FILES", 22)
		_heading(body, "叙事委托 / NARRATIVE")
	else:
		_label(body, ContactDefinition.get_contact(contact_id).display_name + " / 委托", 18)
	if contact_id == "su_mi": _label(body, "暂无新的维修委托", 16)
	if ContactDefinition.owns_quest(contact_id, "Q01"):
		_publisher(body, "Q01")
		_label(body, NarrativeSlice.status_text(profile) if profile.first_mission_completed else "Q01 / 完成首任务后可进行出口观察", 14)
		if not profile.narrative_slice.settled.Q01: _label(body, "查看本局分配的两处出口铭牌，再从合法出口成功撤离。", 14)
	if contact_id == "tang_kui" and not profile.narrative_slice.settled.Q01:
		_publisher(body, "Q02")
		_label(body, "Q02 今晚的药 / 尚未开放；需要先完成 Q01", 14)
		_publisher(body, "Q04")
		_label(body, "Q04 账上已经送到 / 尚未开放；需要先完成 Q02", 14)
	if ContactDefinition.owns_quest(contact_id, "Q02") and profile.narrative_slice.settled.Q01:
		_publisher(body, "Q02")
		if not profile.narrative_slice.settled.Q02: _label(body, NarrativeSlice.Q02_REQUEST, 14)
		_label(body, NarrativeSlice.q02_status(profile), 14)
		if not profile.narrative_slice.settled.Q04 and (contact_id.is_empty() or not profile.narrative_slice.settled.Q02):
			var submit := Button.new()
			submit.name = "SubmitQ02"
			submit.text = "交付仓库内尚需的材料 / 保存（支持部分交付）"
			submit.disabled = NarrativeSlice.prepare_q02_delivery(profile).error != OK
			body.add_child(submit)
			submit.pressed.connect(_submit_q02)
		if not profile.narrative_slice.settled.Q04 and not profile.narrative_slice.q02.message.is_empty(): _label(body, profile.narrative_slice.q02.message, 14)
	if contact_id == "tang_kui" and profile.narrative_slice.settled.Q01 and not profile.narrative_slice.settled.Q02:
		_publisher(body, "Q04")
		_label(body, "Q04 账上已经送到 / 尚未开放；需要先完成 Q02", 14)
	if ContactDefinition.owns_quest(contact_id, "Q04") and profile.narrative_slice.settled.Q02:
		_publisher(body, "Q04")
		_label(body, NarrativeSlice.q04_status(profile), 14)
		if profile.narrative_slice.settled.Q04:
			_label(body, profile.narrative_slice.q04.log, 14)
		else:
			var submit_q04 := Button.new()
			submit_q04.name = "SubmitQ04"
			submit_q04.text = "提交 MED-TK-071 两项记录 / 保存"
			submit_q04.disabled = NarrativeSlice.prepare_q04_submission(profile).error != OK
			body.add_child(submit_q04)
			submit_q04.pressed.connect(_submit_q04)
	if not contact_id.is_empty():
		if not feedback.begins_with("Only the active"): _label(body, feedback, 14)
		return # Anonymous base-development contracts stay on the existing board.
	_heading(body, "基地发展 / BASE DEVELOPMENT")
	_label(body, tr("%d / %d contracts claimed / %d credits") % [profile.campaign.stage, CampaignService.QUESTS.size(), profile.credits], 15)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 20)
	body.add_child(columns)
	var list := VBoxContainer.new()
	list.custom_minimum_size.x = 270
	list.add_theme_constant_override("separation", 10)
	columns.add_child(list)
	for index in CampaignService.QUESTS.size():
		var quest: Dictionary = CampaignService.QUESTS[index]
		var button := Button.new()
		button.name = quest.id
		button.text = tr(quest.title)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(270, 48)
		button.add_theme_font_size_override("font_size", 14)
		button.tooltip_text = tr("CLAIMED" if index < profile.campaign.stage else ("ACTIVE" if index == profile.campaign.stage else "LOCKED"))
		button.modulate = SliceUI.CYAN if index < profile.campaign.stage else (Color.WHITE if index == profile.campaign.stage else SliceUI.MUTED)
		list.add_child(button)
		button.pressed.connect(func(): selected = index; _refresh.call_deferred())
	var detail := VBoxContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation", 8)
	columns.add_child(detail)
	var quest: Dictionary = CampaignService.QUESTS[selected]
	var available := selected == int(profile.campaign.stage) and profile.first_mission_completed
	_label(detail, quest.title, 20)
	_label(detail, quest.detail, 15)
	if not profile.first_mission_completed:
		_label(detail, "First recover the home signal in First Mission. Existing equipment and tutorial progress are preserved.", 15)
	elif profile.campaign.stage == CampaignService.QUESTS.size():
		_label(detail, "BASTION ESTABLISHED / All contracts claimed. Facilities stay online. Continue free sorties or prepare another loadout.", 16)
	elif not available:
		_label(detail, "CLAIMED" if selected < profile.campaign.stage else "LOCKED / Claim preceding contracts first.", 16)
	elif quest.target > 0:
		_label(detail, tr("SETTLED PROGRESS / %d / %d") % [profile.campaign.progress, quest.target], 18)
	for id: StringName in quest.inputs:
		_label(detail, "%s / %d / %d" % [GameLanguage.item_name(ContentDB.get_item(id).display_name), SupplyService.count(profile, id), quest.inputs[id]], 15)
	_label(detail, tr("REWARD / %s") % tr(quest.reward), 15)
	var claim_button := Button.new()
	claim_button.name = "ClaimContract"
	claim_button.text = tr("TURN IN / CLAIM & SAVE")
	claim_button.custom_minimum_size.y = 44
	claim_button.disabled = not available or not CampaignService.ready(profile)
	detail.add_child(claim_button)
	claim_button.pressed.connect(func(): _claim(quest.id))
	_label(body, feedback, 14)
	_label(body, tr("FACILITIES / Clinic %s / Ammunition bench %s / Supplier %s") % [tr("ONLINE" if CampaignService.unlocked(profile, "clinic") else "LOCKED"), tr("ONLINE" if CampaignService.unlocked(profile, "workbench") else "LOCKED"), tr("ONLINE" if CampaignService.unlocked(profile, "supplier") else "LOCKED")], 13)

func _label(parent: Node, text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = tr(text)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label

func _claim(id: String) -> void:
	var result := CampaignService.claim(id, save_path)
	feedback = result.message
	if result.error == OK:
		selected = -1
		AudioDirector.play_sfx(&"ui_confirm")
		contract_claimed.emit()
	_refresh.call_deferred()


func _submit_q02() -> void:
	var result := NarrativeSlice.submit_q02(save_path)
	feedback = result.message
	if result.error == OK: contract_claimed.emit()
	_refresh.call_deferred()


func _submit_q04() -> void:
	var result := NarrativeSlice.submit_q04(save_path)
	feedback = result.message
	if result.error == OK: contract_claimed.emit()
	_refresh.call_deferred()


func _heading(parent: Node, text: String) -> void:
	parent.add_child(HSeparator.new())
	var heading := _label(parent, text, 13)
	heading.add_theme_color_override("font_color", SliceUI.CYAN)


func _publisher(parent: Node, quest_id: String) -> void:
	var id: String = ContactDefinition.QUEST_OWNERS[quest_id]
	var row := HBoxContainer.new()
	row.name = "Publisher_" + quest_id
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var avatar := ContactPortrait.new()
	avatar.compact = true
	avatar.contact_id = id
	row.add_child(avatar)
	var label := _label(row, ContactDefinition.get_contact(id).display_name + " / " + quest_id, 16)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", SliceUI.CYAN)
