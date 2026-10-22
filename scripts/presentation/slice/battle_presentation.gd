extends Node
## Read-only battle observations plus UI calls into the existing pickup contract.
var battle: Node3D
var screen: Control
var panel: Panel
var container: SliceLootContainer
var crates := {}
var notice: Label
var arrival_camera: Camera3D
var arrival_time := 0.0
var exit_started := false
var _focused_world_label: Label3D
var exchange_id := ""
var carried_list: RichTextLabel
var carried_capacity: Label
var carried_bar: ProgressBar
var inspection_shade: ColorRect
var _cache_rows: Array[Dictionary] = []

func _ready() -> void:
	_setup.call_deferred()

func _setup() -> void:
	battle = get_parent()
	if not is_instance_valid(battle.get("player")): return
	var layer := CanvasLayer.new()
	layer.layer = 25
	add_child(layer)
	screen = SliceUI.root(layer)
	screen.theme = FieldManualStyle.theme()
	screen.resized.connect(func():
		if is_instance_valid(panel): _show_loot()
	)
	inspection_shade = ColorRect.new()
	inspection_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inspection_shade.color = Color(0.04,0.05,0.06,.38)
	inspection_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inspection_shade.hide()
	screen.add_child(inspection_shade)
	GameLanguage.language_changed.connect(func():
		if is_instance_valid(panel): _show_loot()
	)
	notice = SliceUI.label(screen,"",Vector2.ZERO,15,SliceUI.CYAN)
	notice.set_anchors_preset(Control.PRESET_CENTER_TOP)
	notice.offset_left = -240
	notice.offset_right = 240
	notice.offset_top = 82
	notice.offset_bottom = 130
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for point in battle.area_root.find_children("*","LootSpawnPoint",true,false):
		register_loot_cache(point as LootSpawnPoint)
	if GameState.arrival_pending:
		GameState.arrival_pending = false
		arrival_time = 1.8
		arrival_camera = Camera3D.new()
		arrival_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		arrival_camera.size = 30
		battle.add_child(arrival_camera)
		arrival_camera.current = true
		notice.text = tr("ARRIVAL / %s INTERACT / %s SWITCH") % [ControlBindings.label("interact"),ControlBindings.label("switch_weapon")]
		if battle.session.area_id == &"street_district": notice.text += "\n" + tr("%s / ROUTE MAP") % ControlBindings.label("route_map")
		AudioDirector.play_sfx(&"ui_confirm",-3)

func register_loot_cache(point: LootSpawnPoint) -> SliceLootContainer:
	if not point.enabled:return null
	if crates.has(point.get_instance_id()):return crates[point.get_instance_id()]
	var crate:=SliceLootContainer.new();crate.name="LootContainer"
	point.add_child(crate);crates[point.get_instance_id()]=crate
	return crate

func _process(delta: float) -> void:
	if not is_instance_valid(battle) or not is_instance_valid(battle.get("player")) or not screen: return
	_update_world_label_focus()
	if arrival_time > 0:
		arrival_time = maxf(0,arrival_time-delta)
		arrival_camera.global_transform = battle.camera.global_transform
		arrival_camera.size = lerpf(battle.camera.size,30,arrival_time/1.8)
		if arrival_time == 0:
			battle.camera.current = true
			arrival_camera.queue_free()
			notice.text = ""
	if battle.ending and not exit_started:
		exit_started = true
		_close_loot()
		var surviving: bool = not battle.player.is_dead
		notice.text = "EXTRACTION CONFIRMED / RETURN LINK OPEN" if surviving else "SIGNAL LOST / FLIGHT RECORDER RECOVERED"
		var camera := Camera3D.new()
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = battle.camera.size
		battle.add_child(camera)
		camera.global_transform = battle.camera.global_transform
		camera.current = true
		create_tween().tween_property(camera,"size",19.5,2.2)
	if is_instance_valid(panel):
		# Loot UI never pauses AI or grants safety. Walking away closes the case.
		if battle.ending or not is_instance_valid(container) or battle.player.global_position.distance_to(container.global_position) > battle.player.interaction_component.interaction_radius:
			_close_loot()
		else:
			Input.action_release("fire")
			_refresh_carried()
	elif not battle.ending:
		var target = battle.player.interaction_component._current_target
		if is_instance_valid(target) and target is LootPickup:
			battle.hud.set_interaction_prompt(tr("%s  OPEN SUPPLY CASE") % ControlBindings.label("interact"))

func _update_world_label_focus() -> void:
	var interaction = battle.player.interaction_component
	var target = interaction._current_target
	var label: Label3D
	if not battle.ending and is_instance_valid(target) and target is ObjectiveInteractable and not interaction._last_prompt.is_empty():
		label = target.get_node_or_null("WorldLabel") as Label3D
	if _focused_world_label == label: return
	if is_instance_valid(_focused_world_label): _focused_world_label.show()
	_focused_world_label = label
	if is_instance_valid(_focused_world_label): _focused_world_label.hide()

func _input(event: InputEvent) -> void:
	if not screen or not is_instance_valid(battle) or battle.ending: return
	if is_instance_valid(panel):
		if event is InputEventMouseButton:
			Input.action_release("fire") # UI focus, not weapon state/timing.
			if not panel.get_global_rect().has_point(event.position): get_viewport().set_input_as_handled()
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact"):
			_close_loot()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact"):
		var target = battle.player.interaction_component._current_target
		# A finite encounter can drop a cache after initial scene setup. Give its
		# real pickups the same inspection/capacity UI as pre-existing cases.
		if is_instance_valid(target) and target is LootPickup and target.get_parent() is LootSpawnPoint:
			register_loot_cache(target.get_parent() as LootSpawnPoint)
		if is_instance_valid(target) and target is LootPickup and crates.has(target.get_parent().get_instance_id()):
			container = crates[target.get_parent().get_instance_id()]
			container.set_open(true)
			_show_loot()
			get_viewport().set_input_as_handled()

func _show_loot(feedback: String = "Inspect contents. Combat remains live.", focus_override: String = "") -> void:
	var focus := get_viewport().gui_get_focus_owner()
	var focus_name := "Take0"
	var focus_row := 0
	var scroll_y := 0
	if is_instance_valid(panel):
		if focus and panel.is_ancestor_of(focus):
			focus_name = String(focus.name)
			focus_row = int(focus.get_meta("cache_row", -1))
		var old_scroll := panel.find_child("CacheScroll", true, false) as ScrollContainer
		if old_scroll: scroll_y = old_scroll.scroll_vertical
	if not focus_override.is_empty():
		focus_name = focus_override
		focus_row = -1
	_cache_rows.clear()
	battle.player.aim_input_captured = true
	battle.player.clear_buffered_input()
	Input.action_release("fire")
	_set_inspection_visibility(true)
	if is_instance_valid(panel):
		screen.remove_child(panel)
		panel.queue_free()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var extent := Vector2(minf(1152,screen.size.x-48),minf(568,screen.size.y-64))
	panel = SliceUI.panel(screen,(screen.size-extent)*.5,extent)
	panel.add_theme_stylebox_override("panel",FieldManualStyle.panel())
	var column := (extent.x-80)*.5
	var right := 56+column
	SliceUI.label(panel,tr("CARRIED / BACKPACK"),Vector2(24,18),22,FieldManualStyle.INK)
	SliceUI.label(panel,"SUPPLY CACHE / CONTENTS",Vector2(right,18),22,FieldManualStyle.INK)
	var close := SliceUI.button(panel,"ESC",Vector2(extent.x-88,16),Vector2(64,34),_close_loot)
	close.name = "CloseCache"
	close.tooltip_text = tr("CLOSE / %s or ESC") % ControlBindings.label("interact")
	close.add_theme_font_size_override("font_size",14)
	carried_capacity = SliceUI.label(panel,"",Vector2(24,61),14,FieldManualStyle.MUTED)
	carried_capacity.tooltip_text = tr("Equipment and loaded rounds count toward weight.\nOnly unequipped loot can be exchanged; no free discard.")
	carried_bar = ProgressBar.new()
	carried_bar.step = 0.0
	carried_bar.name = "CarriedWeight"
	carried_bar.position = Vector2(24,91)
	carried_bar.size = Vector2(column,5)
	carried_bar.show_percentage = false
	carried_bar.add_theme_stylebox_override("background",FieldManualStyle.bar(FieldManualStyle.LINE))
	carried_bar.add_theme_stylebox_override("fill",FieldManualStyle.bar(FieldManualStyle.ACCENT))
	panel.add_child(carried_bar)
	carried_bar.set_deferred("size",Vector2(column,5))
	carried_list = RichTextLabel.new()
	carried_list.name = "CarriedList"
	carried_list.position = Vector2(24,138)
	carried_list.size = Vector2(column,extent.y-208)
	carried_list.bbcode_enabled = true
	carried_list.add_theme_font_size_override("normal_font_size",15)
	panel.add_child(carried_list)
	var choice := OptionButton.new()
	choice.name = "ExchangeCargo"
	choice.position = Vector2(right,58)
	choice.size = Vector2(column,36)
	choice.add_theme_font_size_override("font_size",14)
	choice.add_item(tr("EXCHANGE / Select carried salvage"))
	choice.set_item_metadata(0, "")
	for item in battle.session.inventory.get_items():
		var cargo_definition := ContentDB.get_item(item.definition_id)
		if not cargo_definition.has_tag(&"loot") or battle.session.loadout.is_equipped(item.instance_id): continue
		choice.add_item("%s × %d / %.1f kg%s" % [GameLanguage.item_name(cargo_definition.display_name),item.quantity,item.total_weight(),tr(" / CONTRACT") if not contract_stock(ProfileRuntime.get_profile(),battle.session,item.definition_id).is_empty() else ""])
		choice.set_item_metadata(choice.item_count-1,item.instance_id)
		if item.instance_id == exchange_id: choice.select(choice.item_count-1)
	exchange_id = str(choice.get_item_metadata(choice.selected))
	choice.item_selected.connect(func(index: int):
		exchange_id = str(choice.get_item_metadata(index))
		_show_loot("Inspect contents. Combat remains live.", "ExchangeCargo")
	)
	panel.add_child(choice)
	var row_width := column-16
	var weight_x := row_width-228
	var quantity_x := weight_x-40
	for x in [24.0,right]:
		SliceUI.label(panel,tr("ITEM"),Vector2(x,111),12,FieldManualStyle.MUTED)
		var qty_header := SliceUI.label(panel,tr("QTY"),Vector2(x+(column-114 if x == 24.0 else quantity_x),111),12,FieldManualStyle.MUTED)
		qty_header.size.x = 32
		if x == 24.0: qty_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		var kg_header := SliceUI.label(panel,tr("WEIGHT (kg)"),Vector2(x+(column-70 if x == 24.0 else weight_x),111),12,FieldManualStyle.MUTED)
		kg_header.size.x = 54
		var header_rule := ColorRect.new()
		header_rule.position = Vector2(x,131)
		header_rule.size = Vector2(column,1)
		header_rule.color = FieldManualStyle.LINE
		header_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(header_rule)
	var divider := ColorRect.new()
	divider.position = Vector2(right-16,24)
	divider.size = Vector2(1,extent.y-48)
	divider.color = FieldManualStyle.LINE
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(divider)
	var scroll := ScrollContainer.new()
	scroll.name = "CacheScroll"
	scroll.position = Vector2(right,138)
	scroll.size = Vector2(column,extent.y-248)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	panel.add_child(scroll)
	var rows := Control.new()
	rows.custom_minimum_size.x = row_width
	scroll.add_child(rows)
	var y := 0.0
	var index := 0
	for pickup in container.contents():
		var item := pickup.item_instance
		var definition := ContentDB.get_item(item.definition_id)
		var icon := TextureRect.new()
		icon.set_meta("cache_item_icon",true)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = definition.icon
		icon.position = Vector2(0,y)
		icon.size = Vector2(40,40)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rows.add_child(icon)
		var item_label := SliceUI.label(rows,GameLanguage.item_name(definition.display_name),Vector2(52,y),15,FieldManualStyle.INK)
		item_label.size.x = quantity_x-60
		item_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		item_label.tooltip_text = GameLanguage.item_name(definition.display_name)+"\n"+tr(definition.description)
		var modified := WeaponFitting.discovery_text(item)
		if modified.is_empty() and definition.has_tag(&"recovered_only"):
			modified = tr(definition.description)
		if not modified.is_empty(): item_label.tooltip_text += "\n" + modified
		var quantity := SliceUI.label(rows,str(item.quantity),Vector2(quantity_x,y+4),14,FieldManualStyle.INK)
		quantity.size.x = 32
		var weight := SliceUI.label(rows,"%.2f" % item.total_weight(),Vector2(weight_x,y+4),14,FieldManualStyle.INK)
		weight.size.x = 60
		var capacity_hint := SliceUI.label(rows,"",Vector2(52,y+26),11,FieldManualStyle.MUTED)
		capacity_hint.name = "CapacityHint%d" % index
		var take := SliceUI.button(rows,"TAKE",Vector2(row_width-156,y+2),Vector2(60,36),func(): _take(pickup))
		take.name = "Take%d" % index
		take.set_meta("cache_row", index)
		take.add_theme_font_size_override("font_size",14)
		FieldManualStyle.primary(take)
		take.set_deferred("size",Vector2(60,36))
		var swap := SliceUI.button(rows,"EXCHANGE",Vector2(row_width-88,y+2),Vector2(88,36),func(): _exchange(pickup))
		swap.name = "Swap%d" % index
		swap.set_meta("cache_row", index)
		swap.add_theme_font_size_override("font_size",13)
		swap.set_deferred("size",Vector2(88,36))
		swap.disabled = exchange_id.is_empty()
		_cache_rows.append({"pickup":pickup, "hint":capacity_hint, "take":take, "swap":swap})
		if not modified.is_empty():
			var find_note := SliceUI.label(rows,"",Vector2(52,y+47),12,FieldManualStyle.ACCENT)
			find_note.name = "ModifiedFind%d" % index
			find_note.size = Vector2(row_width-60,60)
			find_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			find_note.text = modified
			y += 68
		var stock := contract_stock(ProfileRuntime.get_profile(),battle.session,definition.id)
		if not stock.is_empty():
			var need := SliceUI.label(rows,tr("CONTRACT: base %d + cargo %d / %d; need %d") % [stock.base,stock.cargo,stock.required,stock.missing],Vector2(0,y+49),12,FieldManualStyle.SUCCESS if stock.missing == 0 else FieldManualStyle.ACCENT)
			need.name = "ContractStock%d" % index
			need.size = Vector2(row_width,20)
			need.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			item_label.add_theme_color_override("font_color",FieldManualStyle.ACCENT)
			y += 20
		y += 68
		var row_rule := ColorRect.new()
		row_rule.position = Vector2(0,y-8)
		row_rule.size = Vector2(row_width,1)
		row_rule.color = FieldManualStyle.LINE
		row_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rows.add_child(row_rule)
		index += 1
	rows.custom_minimum_size.y = maxf(scroll.size.y,y)
	if index == 0: SliceUI.label(rows,"CACHE SECURED / EMPTY",Vector2(0,8),16,FieldManualStyle.MUTED)
	var outgoing: ItemInstance = battle.session.inventory.get_item(exchange_id)
	var contract_exchange := outgoing != null and not contract_stock(ProfileRuntime.get_profile(),battle.session,outgoing.definition_id).is_empty()
	var hint := SliceUI.label(panel,"CONTRACT CARGO / Exchange leaves these supplies behind." if contract_exchange else "Cargo only counts after successful extraction.",Vector2(24,extent.y-42),12,FieldManualStyle.ACCENT if contract_exchange else FieldManualStyle.MUTED)
	hint.size.x = column
	hint.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var navigation := SliceUI.label(panel,tr("Arrows / Tab: navigate · Enter / A: select · %s / Esc: close") % ControlBindings.label("interact"),Vector2(24,extent.y-64),12,FieldManualStyle.MUTED)
	navigation.size.x = column
	navigation.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var feedback_label := SliceUI.label(panel,feedback,Vector2(right,extent.y-96),14,FieldManualStyle.MUTED)
	feedback_label.name = "PickupFeedback"
	feedback_label.size = Vector2(column,76)
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_refresh_carried()
	_restore_cache_focus.call_deferred(panel, focus_name, focus_row, scroll_y)


func _restore_cache_focus(expected: Panel, focus_name: String, focus_row: int, scroll_y: int) -> void:
	# Rebuilds happen after TAKE, exchange selection, resize and language changes.
	# A deferred restore must not grab a newer panel or a case the player closed.
	if not is_instance_valid(expected) or expected != panel: return
	var close := panel.find_child("CloseCache", true, false) as Button
	var choice := panel.find_child("ExchangeCargo", true, false) as OptionButton
	var controls: Array[Control] = [close, choice]
	for row in _cache_rows:
		controls.append(row.take)
		if not row.swap.disabled: controls.append(row.swap)
	var focus_style := FieldManualStyle.button_style(Color.TRANSPARENT, FieldManualStyle.INK)
	focus_style.set_border_width_all(2)
	for index in controls.size():
		controls[index].add_theme_stylebox_override("focus", focus_style)
		controls[index].focus_next = controls[index].get_path_to(controls[(index+1) % controls.size()])
		controls[index].focus_previous = controls[index].get_path_to(controls[posmod(index-1, controls.size())])
	close.focus_neighbor_bottom = close.get_path_to(choice)
	choice.focus_neighbor_top = choice.get_path_to(close)
	choice.focus_neighbor_bottom = choice.get_path_to(_cache_rows[0].take if not _cache_rows.is_empty() else close)
	for index in _cache_rows.size():
		var row: Dictionary = _cache_rows[index]
		for key in ["take", "swap"]:
			var action: Button = row[key]
			if action.disabled: continue
			action.focus_neighbor_top = action.get_path_to(_cache_rows[index-1][key] if index > 0 else choice)
			action.focus_neighbor_bottom = action.get_path_to(_cache_rows[index+1][key] if index+1 < _cache_rows.size() else close)
			var across: Control = row.take if key == "swap" else (row.swap if not row.swap.disabled else choice)
			action.focus_neighbor_left = action.get_path_to(across)
			action.focus_neighbor_right = action.get_path_to(across)
	var target := panel.find_child(focus_name, true, false) as Control
	if not target and focus_row >= 0 and not _cache_rows.is_empty():
		target = _cache_rows[mini(focus_row, _cache_rows.size()-1)].take
	if not target or (target is BaseButton and target.disabled): target = close
	var scroll := panel.find_child("CacheScroll", true, false) as ScrollContainer
	scroll.scroll_vertical = scroll_y
	target.grab_focus()
	if scroll.is_ancestor_of(target): scroll.ensure_control_visible(target)

func _refresh_carried() -> void:
	var session: SortieSession = battle.session
	carried_capacity.text = tr("WEIGHT %.2f / %.2f kg | FREE %.2f kg") % [session.inventory.current_weight,session.inventory.capacity,session.inventory.get_remaining_capacity()]
	carried_bar.max_value = maxf(.001,session.inventory.capacity)
	carried_bar.value = session.inventory.current_weight
	var cells: PackedStringArray = []
	for item in session.inventory.get_items():
		var definition := ContentDB.get_item(item.definition_id)
		var icon := "[img=40x40]%s[/img]" % definition.icon.resource_path if definition.icon and not definition.icon.resource_path.is_empty() else ""
		var caption := GameLanguage.item_name(definition.display_name).replace("[","[lb]")
		if not item.fitting.is_empty(): caption += "\n[color=#626b70][font_size=11]"+tr(WeaponFitting.caption(item.fitting))+"[/font_size][/color]"
		if session.loadout.is_equipped(item.instance_id): caption += "\n[color=#626b70][font_size=11]"+tr(" / EQUIPPED")+"[/font_size][/color]"
		var weapon = session.get_weapon_runtime_state(item.instance_id)
		if weapon and weapon.magazine_ammo > 0:
			var ammo := ContentDB.get_ammo(weapon.ammo_definition_id)
			caption += "\n[color=#626b70][font_size=11]"+(tr("  LOADED: %s × %d / %.2f kg") % [GameLanguage.item_name(ammo.display_name),weapon.magazine_ammo,ammo.weight*weapon.magazine_ammo])+"[/font_size][/color]"
		cells.append("[cell]%s[/cell][cell expand=1 shrink=false]%s[/cell][cell padding=0,0,24,0][right]%d[/right][/cell][cell][right]%.2f[/right][/cell]" % [icon,caption,item.quantity,item.total_weight()])
	var text := "[table=4]"+"".join(cells)+"[/table]" if not cells.is_empty() else tr("No carried items.")
	if carried_list.text != text: carried_list.text = text
	for row in _cache_rows:
		if not is_instance_valid(row.pickup) or row.pickup.consumed: continue
		var item: ItemInstance = row.pickup.item_instance
		var shortfall := item.total_weight()-session.inventory.get_remaining_capacity()
		row.hint.text = tr("SHORT BY %.2f kg") % shortfall if shortfall > .0001 else tr("VALUE %d") % (SupplyService.sell_price(item)*item.quantity)
		row.hint.add_theme_color_override("font_color", FieldManualStyle.ACCENT if shortfall > .0001 else FieldManualStyle.MUTED)
		row.take.tooltip_text = tr("Whole stack: %.2f kg / free %.2f kg.") % [item.total_weight(), session.inventory.get_remaining_capacity()]

func _set_inspection_visibility(opened: bool) -> void:
	if is_instance_valid(inspection_shade): inspection_shade.visible = opened
	if is_instance_valid(notice): notice.visible = not opened
	if not is_instance_valid(battle): return
	if is_instance_valid(battle.get("hud")): battle.hud.set_inspection_open(opened)
	var director := battle.get_node_or_null("FirstMissionDirector")
	if director:
		for child in director.get_children():
			if child is CanvasLayer: child.visible = not opened

func _exchange(pickup: LootPickup) -> void:
	if not is_instance_valid(pickup) or battle.ending: return
	if battle.player.global_position.distance_to(pickup.global_position) > battle.player.interaction_component.interaction_radius:
		_close_loot()
		return
	var result := pickup.exchange_cargo(battle.session,exchange_id)
	var success := result == LootPickup.PickupResult.SUCCESS
	var message := tr("Cargo exchanged. Previous salvage left in cache.") if success else tr("Exchange failed / Check capacity and selected cargo.")
	battle.player.interaction_component.interaction_finished.emit(message,success)
	AudioDirector.play_sfx(&"ui_confirm" if success else &"ui_click",-3)
	_show_loot(message)

func _take(pickup: LootPickup) -> void:
	if not is_instance_valid(pickup) or battle.ending: return
	if battle.player.global_position.distance_to(pickup.global_position) > battle.player.interaction_component.interaction_radius:
		_close_loot()
		return
	var result := pickup.interact(battle.player,battle.session)
	battle.player.interaction_component.interaction_finished.emit(result.message,result.success)
	AudioDirector.play_sfx(&"ui_confirm" if result.success else &"ui_click",-3)
	_show_loot(result.message)

func _close_loot() -> void:
	_cache_rows.clear()
	_set_inspection_visibility(false)
	_release_aim_input()
	if is_instance_valid(panel):
		panel.queue_free()
		panel = null
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	if is_instance_valid(container) and container.opened: container.set_open(false)

func _release_aim_input() -> void:
	if is_instance_valid(battle) and is_instance_valid(battle.get("player")):
		battle.player.aim_input_captured = false
		battle.player.clear_buffered_input()
	Input.action_release("fire")

func _exit_tree() -> void:
	_set_inspection_visibility(false)
	if is_instance_valid(_focused_world_label): _focused_world_label.show()
	_release_aim_input()


# Profile still contains the pre-sortie carried instances. Count only items left
# at base, then the current cargo; exchanged-away stacks must not count twice.
static func contract_stock(profile: ProfileState, session: SortieSession, item_id: StringName) -> Dictionary:
	if not profile or not session or not profile.first_mission_completed: return {}
	var contract := CampaignService.current(profile)
	if contract.is_empty() or not contract.inputs.has(item_id): return {}
	var base := 0
	var cargo := 0
	var carried := session.get_initial_carried_instance_ids()
	for item in profile.inventory.get_items():
		if item.definition_id == item_id and item.instance_id not in carried: base += item.quantity
	for item in session.inventory.get_items():
		if item.definition_id == item_id: cargo += item.quantity
	var required := int(contract.inputs[item_id])
	return {"base":base,"cargo":cargo,"required":required,"missing":maxi(0,required-base-cargo)}
