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

func _ready() -> void:
	_setup.call_deferred()

func _setup() -> void:
	battle = get_parent()
	if not is_instance_valid(battle.get("player")): return
	var layer := CanvasLayer.new()
	layer.layer = 25
	add_child(layer)
	screen = SliceUI.root(layer)
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
		if not point.enabled: continue
		var crate := SliceLootContainer.new()
		point.add_child(crate)
		crates[point.get_instance_id()] = crate
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
		if is_instance_valid(target) and target is LootPickup and crates.has(target.get_parent().get_instance_id()):
			container = crates[target.get_parent().get_instance_id()]
			container.set_open(true)
			_show_loot()
			get_viewport().set_input_as_handled()

func _show_loot(feedback: String = "Inspect contents. Combat remains live.") -> void:
	battle.player.aim_input_captured = true
	battle.player.clear_buffered_input()
	Input.action_release("fire")
	if is_instance_valid(panel):
		screen.remove_child(panel)
		panel.queue_free()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	panel = SliceUI.panel(screen,Vector2(770,114),Vector2(490,510))
	SliceUI.label(panel,"SUPPLY CACHE / CONTENTS",Vector2(22,20),23,SliceUI.CYAN)
	var used: float = battle.session.inventory.get_used_capacity()
	SliceUI.label(panel,tr("CARGO  %.1f / %.1f kg") % [used,battle.session.inventory.capacity],Vector2(22,66),18)
	var choice := OptionButton.new()
	choice.position = Vector2(22,98)
	choice.size = Vector2(446,40)
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
		_show_loot()
	)
	panel.add_child(choice)
	var index := 0
	for pickup in container.contents():
		var definition := ContentDB.get_item(pickup.item_instance.definition_id)
		var item_label := SliceUI.label(panel,tr("%s × %d") % [GameLanguage.item_name(definition.display_name),pickup.item_instance.quantity],Vector2(22,150+index*70),17)
		item_label.size.x = 246
		item_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		item_label.tooltip_text = tr(definition.description)
		var stock := contract_stock(ProfileRuntime.get_profile(),battle.session,definition.id)
		if not stock.is_empty():
			item_label.modulate = Color("f5d581")
			item_label.tooltip_text += "\n" + tr("CONTRACT MATERIAL / Turn in at Hideout Overview after extraction.")
			var need := SliceUI.label(panel,tr("CONTRACT: base %d + cargo %d / %d; need %d") % [stock.base,stock.cargo,stock.required,stock.missing],Vector2(22,198+index*70),12,SliceUI.CYAN if stock.missing == 0 else Color("f5d581"))
			need.name = "ContractStock%d" % index
			need.size = Vector2(446,20)
			need.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			need.tooltip_text = tr("Cargo only counts after successful extraction.")
		SliceUI.label(panel,tr("SELL %d  /  %.2f kg") % [SupplyService.sell_price(pickup.item_instance)*pickup.item_instance.quantity,definition.weight*pickup.item_instance.quantity],Vector2(22,179+index*70),13,SliceUI.MUTED)
		SliceUI.button(panel,"TAKE",Vector2(278,152+index*70),Vector2(86,44),func(): _take(pickup))
		var swap := SliceUI.button(panel,"EXCHANGE",Vector2(370,152+index*70),Vector2(98,44),func(): _exchange(pickup))
		swap.add_theme_font_size_override("font_size",14)
		swap.size = Vector2(98,44)
		swap.disabled = exchange_id.is_empty()
		index += 1
	if index == 0: SliceUI.label(panel,"CACHE SECURED / EMPTY",Vector2(22,156),18,SliceUI.CYAN)
	var outgoing: ItemInstance = battle.session.inventory.get_item(exchange_id)
	var contract_exchange := outgoing != null and not contract_stock(ProfileRuntime.get_profile(),battle.session,outgoing.definition_id).is_empty()
	SliceUI.label(panel,"CONTRACT CARGO / Exchange leaves these supplies behind." if contract_exchange else "Cargo only counts after successful extraction.",Vector2(22,370),14,Color("f5d581") if contract_exchange else SliceUI.MUTED)
	var feedback_label := SliceUI.label(panel,feedback,Vector2(22,400),15,SliceUI.MUTED)
	feedback_label.size = Vector2(446,44)
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	SliceUI.button(panel,tr("CLOSE / %s or ESC") % ControlBindings.label("interact"),Vector2(22,448),Vector2(446,48),_close_loot)

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
