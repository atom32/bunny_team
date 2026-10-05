class_name CampaignPanel
extends PanelContainer
signal contract_claimed
var save_path := SaveService.DEFAULT_SAVE_PATH
var selected := -1
var feedback := "Only the active contract advances. Claim it at base to begin the next."

func _ready() -> void:
	theme = UIFactory.theme()
	add_theme_stylebox_override("panel", UIFactory.panel_style(Color("101d29f5"), Color("557895")))
	_refresh()

func _refresh() -> void:
	for child in get_children(): remove_child(child); child.queue_free()
	var profile := ProfileRuntime.get_profile()
	if selected < 0: selected = mini(int(profile.campaign.stage), CampaignService.QUESTS.size() - 1)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	add_child(body)
	_label(body, "BASTION CONTRACTS / PERSISTENT PROGRESS", 22)
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
		button.modulate = Color("79f1e7") if index < profile.campaign.stage else (Color.WHITE if index == profile.campaign.stage else Color("8d9ba8"))
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
