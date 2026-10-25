class_name ContactPanel
extends PanelContainer
signal supplies_changed
signal contract_claimed
var contact_id := "tang_kui"
var selected_tab := "trade"
var save_path := SaveService.DEFAULT_SAVE_PATH
var content: Control

func _ready() -> void:
	theme = FieldManualStyle.theme()
	add_theme_stylebox_override("panel", FieldManualStyle.panel(FieldManualStyle.SURFACE))
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	add_child(body)
	var contacts := HBoxContainer.new()
	body.add_child(contacts)
	for id: String in ContactDefinition.CONTACTS:
		var button := Button.new()
		button.name = "Contact_" + id
		button.text = ContactDefinition.get_contact(id).display_name
		button.add_theme_font_size_override("font_size", 16)
		button.custom_minimum_size.y = 40
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		contacts.add_child(button)
		button.pressed.connect(func(): open_contact(id, selected_tab))
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 18)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(columns)
	var identity := VBoxContainer.new()
	identity.name = "Identity"
	identity.custom_minimum_size.x = 208
	columns.add_child(identity)
	content = VBoxContainer.new()
	content.name = "ContactContent"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(content)
	GameLanguage.language_changed.connect(_refresh_language)
	open_contact(contact_id, selected_tab)

func _refresh_language() -> void:
	for id: String in ContactDefinition.CONTACTS:
		find_child("Contact_" + id, true, false).text = ContactDefinition.get_contact(id).display_name
	open_contact(contact_id, selected_tab)

func open_contact(id: String, tab: String = "trade") -> void:
	contact_id = id
	selected_tab = tab
	for key: String in ContactDefinition.CONTACTS:
		var selector := find_child("Contact_"+key,true,false) as Button
		selector.toggle_mode = true
		selector.set_pressed_no_signal(key == id)
		selector.add_theme_color_override("font_hover_pressed_color",FieldManualStyle.INK)
		selector.add_theme_stylebox_override("normal",FieldManualStyle.cut_style(FieldManualStyle.SIGNAL if key == id else FieldManualStyle.PAPER))
	var identity := find_child("Identity", true, false)
	for child in identity.get_children(): identity.remove_child(child); child.queue_free()
	for child in content.get_children(): content.remove_child(child); child.queue_free()
	var contact := ContactDefinition.get_contact(id)
	var portrait := ContactPortrait.new()
	portrait.name = "Portrait"
	portrait.contact_id = id
	identity.add_child(portrait)
	for field in ["display_name", "title", "description"]:
		var label := Label.new()
		label.name = field
		label.text = contact[field]
		label.custom_minimum_size.x = 208
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 24 if field == "display_name" else 14)
		identity.add_child(label)
	var tabs := HBoxContainer.new()
	content.add_child(tabs)
	for key in ["trade", "quests"]:
		var button := Button.new()
		button.name = "ContactTrade" if key == "trade" else "ContactQuests"
		button.text = tr("TRADE" if key == "trade" else "REQUESTS")
		button.add_theme_font_size_override("font_size", 16)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = true
		button.set_pressed_no_signal(key == tab)
		button.custom_minimum_size.y = 40
		button.add_theme_color_override("font_hover_pressed_color",FieldManualStyle.INK)
		button.add_theme_stylebox_override("normal",FieldManualStyle.cut_style(FieldManualStyle.SIGNAL if key == tab else FieldManualStyle.PAPER))
		tabs.add_child(button)
		button.pressed.connect(func(): open_contact(contact_id, key))
	if tab == "trade":
		var shop := SupplyPanel.new()
		shop.name = "SupplyPanel"
		shop.contact_id = id
		shop.save_path = save_path
		shop.size_flags_vertical = Control.SIZE_EXPAND_FILL
		content.add_child(shop)
		shop.supplies_changed.connect(func(): supplies_changed.emit())
		shop.campus_delivery_requested.connect(func():open_contact("shen_yanshuang","quests"))
	else:
		var quests := CampaignPanel.new()
		quests.name = "CampaignPanel"
		quests.contact_id = id
		quests.save_path = save_path
		quests.size_flags_vertical = Control.SIZE_EXPAND_FILL
		content.add_child(quests)
		quests.contract_claimed.connect(func(): contract_claimed.emit())
		quests.campus_supplies_requested.connect(open_campus_supplies)

func open_campus_supplies() -> void:
	open_contact("shen_yanshuang","trade")
	var shop:=content.find_child("SupplyPanel",true,false) as SupplyPanel
	shop.open_campus_delivery()
