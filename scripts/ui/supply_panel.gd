class_name SupplyPanel
extends PanelContainer
signal supplies_changed
var save_path := SaveService.DEFAULT_SAVE_PATH
var selected_tab := 0
var feedback := "BUY / SELL / BARTER. Supplies stay at base until deployed."
var _scrolls: Dictionary = {}
var _scroll_positions: Dictionary = {}

func _ready() -> void:
	theme = UIFactory.theme()
	add_theme_stylebox_override("panel", UIFactory.panel_style(Color("101d29f5"), Color("557895")))
	_refresh()

func _refresh() -> void:
	for caption in _scrolls:
		var scroll: ScrollContainer = _scrolls[caption]
		if is_instance_valid(scroll): _scroll_positions[caption] = scroll.scroll_vertical
	_scrolls.clear()
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var profile := ProfileRuntime.get_profile()
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	add_child(body)
	var heading := Label.new()
	heading.text = tr("QUARTERMASTER  /  %d CREDITS") % profile.credits
	heading.add_theme_font_size_override("font_size", 23)
	body.add_child(heading)
	var tabs := TabContainer.new()
	tabs.custom_minimum_size = Vector2(748, 302)
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(tabs)
	var buy := _list(tabs, "BUY SUPPLIES")
	for definition in SupplyService.stock(profile):
		_item_row(buy, definition, null)
	var sell := _list(tabs, "SELL RECOVERED")
	for item in profile.inventory.get_items():
		_item_row(sell, ContentDB.get_item(item.definition_id), item)
	var barter := _list(tabs, "WORKSHOP EXCHANGE")
	var recipes := SupplyService.recipes(profile)
	for recipe_id in recipes:
		var recipe: Dictionary = recipes[recipe_id]
		var row := HBoxContainer.new()
		barter.add_child(row)
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", 14)
		var inputs: Array[String] = []
		var available := true
		for id: StringName in recipe.inputs:
			var owned := SupplyService.count(profile,id)
			inputs.append("%s %d/%d" % [GameLanguage.item_name(ContentDB.get_item(id).display_name),owned,recipe.inputs[id]])
			available = available and owned >= recipe.inputs[id]
		label.text = tr(recipe.name) + "\n" + " / ".join(inputs)
		row.add_child(label)
		var button := _button(row, "EXCHANGE", func(): _trade("barter",recipe_id,1))
		button.disabled = not available
	_fittings(_list(tabs, "WEAPON FITTINGS"), profile)
	tabs.current_tab = selected_tab
	tabs.tab_changed.connect(func(index: int): selected_tab = index)
	var info := Label.new()
	info.text = tr(feedback)
	info.custom_minimum_size = Vector2(0, 44)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_theme_font_size_override("font_size", 13)
	body.add_child(info)
	var relief := _button(body, "EMERGENCY KIT / PISTOL + 45 ROUNDS", func(): _trade("relief","",1))
	relief.disabled = not SupplyService.can_claim_relief(profile)
	relief.tooltip_text = tr("Emergency kit: after a failed sortie, no weapon with ammunition, and fewer than 300 credits. One kit per failure.")

func _list(tabs: TabContainer, caption: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = caption
	_scrolls[caption] = scroll
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(scroll)
	tabs.set_tab_title(tabs.get_tab_count()-1, tr(caption))
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation",8)
	scroll.add_child(list)
	_restore_scroll(scroll, int(_scroll_positions.get(caption, 0)))
	return list

static func _restore_scroll(scroll: ScrollContainer, position: int) -> void:
	# Wait for the rebuilt rows/container to establish their actual scroll range.
	# Static helper may outlive a panel that is closed during the layout pass.
	var tree := scroll.get_tree()
	await tree.process_frame
	await tree.process_frame
	if is_instance_valid(scroll): scroll.scroll_vertical = position

func _item_row(parent: VBoxContainer, definition: ItemDefinition, item: ItemInstance) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 50
	parent.add_child(row)
	var icon := TextureRect.new()
	icon.texture = definition.icon
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(64,48)
	row.add_child(icon)
	var label := Label.new()
	label.add_theme_font_size_override("font_size",15)
	label.text = GameLanguage.item_name(definition.display_name)
	label.tooltip_text = tr(definition.description)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var amount := SpinBox.new()
	amount.min_value = 1
	amount.max_value = item.quantity if item else (120 if definition.has_tag(&"ammo") else 1)
	amount.value = item.quantity if item else (30 if definition.has_tag(&"ammo") and definition.id != &"ammo.rocket_standard" else 1)
	amount.custom_minimum_size.x = 70
	row.add_child(amount)
	var unit := SupplyService.sell_price(item) if item else SupplyService.buy_price(definition, ProfileRuntime.get_profile())
	var action := "sell" if item else "buy"
	var id := item.instance_id if item else String(definition.id)
	var button := _button(row, "", func(): _trade(action,id,int(amount.value)))
	var update := func(_value: float): button.text = tr("SELL / %d" if item else "BUY / %d") % (unit*int(amount.value))
	amount.value_changed.connect(update)
	update.call(amount.value)
	if item and ProfileRuntime.get_profile().loadout.is_equipped(item.instance_id):
		button.disabled = true
		button.tooltip_text = tr("Unequip this item before selling it.")

func _button(parent: Node, caption: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = tr(caption)
	button.custom_minimum_size = Vector2(132,40)
	button.add_theme_font_size_override("font_size",14)
	parent.add_child(button)
	button.pressed.connect(action)
	return button

func _trade(action: String, id: String, amount: int) -> void:
	var result := SupplyService.transact(action,id,amount,save_path)
	feedback = result.message
	if result.error == OK:
		AudioDirector.play_sfx(&"ui_confirm")
		supplies_changed.emit()
	_refresh.call_deferred()

func _fittings(parent: VBoxContainer, profile: ProfileState) -> void:
	var note := Label.new()
	note.text = tr("One utility slot per weapon. Replacement consumes materials; removal gives no refund.")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(note)
	if not CampaignService.unlocked(profile, "workbench"):
		note.text = tr("Restore the workbench first.")
		return
	for item in profile.inventory.get_items():
		if not WeaponFitting.eligible(item): continue
		var title := Label.new()
		title.text = "%s [%s] / %s" % [GameLanguage.item_name(ContentDB.get_item(item.definition_id).display_name), item.instance_id.left(6), tr(WeaponFitting.caption(item.fitting))]
		parent.add_child(title)
		var row := HBoxContainer.new()
		parent.add_child(row)
		var choice := OptionButton.new()
		choice.custom_minimum_size.x = 190
		row.add_child(choice)
		var ids: Array = WeaponFitting.OPTIONS.keys()
		for id in ids: choice.add_item(tr(WeaponFitting.caption(id)))
		choice.selected = ids.find(item.fitting)
		var detail := Label.new()
		detail.add_theme_font_size_override("font_size", 13)
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(detail)
		var button := _button(row, "INSTALL", func():
			var result := WeaponFitting.install(item.instance_id, ids[choice.selected], save_path)
			feedback = result.message
			if result.error == OK:
				AudioDirector.play_sfx(&"ui_confirm")
				supplies_changed.emit()
			_refresh.call_deferred())
		button.name = "Fit_" + item.instance_id
		var update := func(index: int):
			var id: String = ids[index]
			var spec: Dictionary = WeaponFitting.OPTIONS[id]
			var text := tr("%.2f kg added / reload x%.2f / hearing x%.2f") % [spec.weight,spec.reload,spec.noise]
			text += "\n" + tr("%d CREDITS") % spec.credits
			for material: StringName in spec.inputs:
				text += " / %s %d/%d" % [GameLanguage.item_name(ContentDB.get_item(material).display_name),SupplyService.count(profile,material),spec.inputs[material]]
			detail.text = text
			button.disabled = WeaponFitting.prepare(profile,item.instance_id,id).error != OK
		choice.item_selected.connect(update)
		update.call(choice.selected)
