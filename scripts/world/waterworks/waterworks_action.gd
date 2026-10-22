class_name WaterworksAction
extends ObjectiveInteractable

@export_enum("radio", "battery", "pump", "decoy", "public", "tanker") var kind := "battery"
const DURATION := 8.0
var remaining := 0.0
var actor: PlayerController
var session: SortieSession
var observed_health := 0.0
var choice_layer: CanvasLayer
var previous_mouse_mode: int

func _ready() -> void:
	super._ready()
	GameLanguage.language_changed.connect(refresh)
	refresh()

func _exit_tree() -> void: _close_choice()

func _input(event: InputEvent) -> void:
	if is_instance_valid(choice_layer) and event.is_action_pressed("ui_cancel") and not event.is_echo():
		_close_choice(); get_viewport().set_input_as_handled()

func bind_actor(player: PlayerController, current: SortieSession) -> void:
	actor = player; session = current; observed_health = actor.health
	if not actor.health_changed.is_connected(_health_changed): actor.health_changed.connect(_health_changed)

func _near() -> bool:
	return is_instance_valid(actor) and not actor.is_dead and session and session.status == SortieSession.Status.ACTIVE and actor.global_position.distance_to(global_position) <= actor.interaction_component.interaction_radius

func available(current: SortieSession) -> bool:
	if not current or current.status != SortieSession.Status.ACTIVE or current.mission_id != WaterworksStory.MISSION: return false
	if kind == "radio": return true
	if kind == "battery" and WaterworksStory.battery(current): return false
	if WaterworksStory.done(current, objective_id): return false
	if kind in ["public", "tanker"]: return WaterworksStory.done(current, &"water_pump") and not WaterworksStory.done(current, &"water_delivery") and (current.waterworks.is_empty() or current.waterworks.branch.is_empty())
	return true

func interact(player: Node3D, current: SortieSession) -> Dictionary:
	if not player is PlayerController or not available(current): return {"success":false,"message":"Waterworks action unavailable."}
	bind_actor(player, current)
	if not _near(): return {"success":false,"message":"Move closer to the waterworks equipment."}
	if kind == "radio": return {"success":true,"message":"Water tower / radio log","information":tr(WaterworksStory.INTRO)}
	if kind == "battery":
		var item := ItemInstance.new(WaterworksStory.CELL)
		if not current.inventory.add_item_preserving_instance(item): return {"success":false,"message":"Battery needs 8kg free capacity. Leave other cargo or return better prepared."}
		current.record_objective_interaction(objective_id)
		get_parent().refresh_waterworks()
		objective_interacted.emit(objective_id); SortieRuntime.request_checkpoint()
		return {"success":true,"message":"Pump battery loaded / 8kg","information":tr(WaterworksStory.FOUND)}
	if kind == "decoy":
		current.record_objective_interaction(objective_id)
		var speaker: Node3D = get_parent().get_node("Loudspeaker")
		CombatNoise.emit_at(self, speaker.global_position, 42, &"alarm")
		var sensor := PlayerVisibility.observer(self)
		var gain := sensor.hear(speaker.global_position, 42, &"alarm") if sensor else 1.0
		if gain > 0: AudioDirector.play_sfx(&"water_horn", linear_to_db(gain))
		objective_interacted.emit(objective_id); SortieRuntime.request_checkpoint(); refresh()
		return {"success":true,"message":"Loudspeaker sounded at the square. Unengaged nearby enemies investigate that sound, not your position."}
	if kind == "pump":
		if not WaterworksStory.battery(current): return {"success":false,"message":"Bring the battery from the west garage first."}
		if remaining > 0: return {"success":false,"message":"Pump installation already active."}
		remaining = DURATION
		CombatNoise.emit_at(self, global_position, 24, &"repair")
		SortieRuntime.request_checkpoint()
		return {"success":true,"message":"Pump installation / 8s / damage or leaving cancels; battery spent only on completion."}
	_open_choice()
	return {"success":true,"message":"Inspect the delivery route before confirming."}

func _health_changed(health: float, _maximum: float) -> void:
	if health < observed_health:
		_cancel("Pump work interrupted by damage. Battery retained.")
		_close_choice()
	observed_health = health

func _cancel(message: String) -> void:
	if remaining <= 0: return
	remaining = 0
	if _near(): actor.interaction_component.interaction_finished.emit(tr(message), false)
	SortieRuntime.request_checkpoint()

func _process(delta: float) -> void:
	if is_instance_valid(choice_layer) and not _near(): _close_choice()
	if remaining <= 0 or get_tree().paused: return
	if not _near(): _cancel("Pump work interrupted: return to the pump and restart. Battery retained."); return
	if not available(session) or not WaterworksStory.battery(session): remaining = 0; return
	remaining = maxf(0, remaining - delta)
	if remaining > 0: return
	var cell := WaterworksStory.battery(session)
	if not session.record_objective_interaction(objective_id): return
	session.inventory.remove_item(cell.instance_id)
	get_parent().refresh_waterworks()
	objective_interacted.emit(objective_id)
	actor.interaction_component.information_read.emit(tr(WaterworksStory.PUMP_REPLY))
	SortieRuntime.request_checkpoint()

func _open_choice() -> void:
	if is_instance_valid(choice_layer): return
	previous_mouse_mode = Input.mouse_mode; Input.mouse_mode = Input.MOUSE_MODE_VISIBLE; actor.aim_input_captured = true
	choice_layer = CanvasLayer.new(); choice_layer.name = "WaterDeliveryChoice"; choice_layer.layer = 28; add_child(choice_layer)
	var panel := PanelContainer.new(); panel.name = "DeliveryConfirmation"; panel.position = Vector2(280,150); panel.size = Vector2(720,0)
	panel.theme = FieldManualStyle.theme()
	panel.add_theme_stylebox_override("panel",FieldManualStyle.panel(FieldManualStyle.PAPER))
	choice_layer.add_child(panel)
	var body := VBoxContainer.new(); body.add_theme_constant_override("separation",12); panel.add_child(body)
	var label := Label.new()
	label.text = tr((WaterworksStory.PUBLIC_CHOICE if kind == "public" else WaterworksStory.TANKER_CHOICE) if session.waterworks.is_empty() else (WaterworksJourney.PUBLIC_CHOICE if kind=="public" else WaterworksJourney.TANKER_CHOICE))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; body.add_child(label)
	var confirm := Button.new(); confirm.name = "ConfirmDelivery"; confirm.text = tr("OPEN COURTYARD TAP" if kind == "public" else "FILL THE TANKER")
	confirm.pressed.connect(confirm_delivery); body.add_child(confirm)
	var cancel := Button.new(); cancel.name = "CancelDelivery"; cancel.text = tr("NOT YET / KEEP BOTH ROUTES UNDECIDED"); cancel.pressed.connect(_close_choice); body.add_child(cancel); cancel.grab_focus()

func confirm_delivery() -> bool:
	if not is_instance_valid(choice_layer) or not _near() or not available(session): _close_choice(); return false
	_close_choice()
	if not session.waterworks.is_empty():return get_parent().begin_delivery(kind,actor)
	if not session.record_objective_interaction(objective_id): return false
	session.record_objective_interaction(&"water_delivery")
	get_parent().open_reward(kind)
	get_parent().refresh_waterworks()
	objective_interacted.emit(objective_id)
	actor.interaction_component.information_read.emit(tr(WaterworksStory.PUBLIC_END if kind == "public" else WaterworksStory.TANKER_END))
	SortieRuntime.request_checkpoint()
	return true

func _close_choice() -> void:
	if not is_instance_valid(choice_layer): return
	if is_instance_valid(actor): actor.aim_input_captured = false
	Input.mouse_mode = previous_mouse_mode as Input.MouseMode
	choice_layer.queue_free(); choice_layer = null

func get_interaction_prompt(_player: Node3D, current: SortieSession) -> String:
	if remaining > 0: return tr("PUMP INSTALLATION %.1fs / stay close") % remaining
	if not available(current): return ""
	return ControlBindings.label("interact") + "  " + tr(interaction_prompt)

func refresh() -> void:
	var current := SortieRuntime.get_current_session()
	var enabled := available(current)
	if enabled: add_to_group("interactable")
	else: remove_from_group("interactable")
	var label := get_node_or_null("WorldLabel") as Label3D
	if label: label.text = tr(interaction_prompt); label.modulate = Color("ffce86") if enabled else Color("78867b")
	if kind == "battery" and has_node("Cargo"): get_node("Cargo").visible = not WaterworksStory.done(current, objective_id)
