class_name RecordsTerminal
extends ObjectiveInteractable
## Local copy or urgent noisy uplink. Only this Streets objective uses this flow.
const COPY_SECONDS := 8.0
const UPLINK_SECONDS := 3.0
var remaining := 0.0
var urgent := false
var actor: PlayerController
var session: SortieSession
var observed_health := 0.0

func _build_visual() -> void:
	super._build_visual()
	get_node("WorldLabel").text = "RECORDS"

func bind_actor(player: PlayerController, current: SortieSession) -> void:
	actor = player
	session = current
	observed_health = actor.health
	if not actor.health_changed.is_connected(_health_changed): actor.health_changed.connect(_health_changed)

func _health_changed(health: float, _maximum: float) -> void:
	if remaining > 0 and health < observed_health:
		cancel(tr("RECORDS INTERRUPTED / Hit. Progress lost; retry when safe."))
	observed_health = health

func cancel(reason: String = "") -> void:
	var was_active := remaining > 0
	remaining = 0.0
	urgent = false
	if was_active and not reason.is_empty() and is_instance_valid(actor) and actor.interaction_component:
		actor.interaction_component.interaction_finished.emit(reason,false)
	SortieRuntime.request_checkpoint()

func interact(player: Node3D, current: SortieSession) -> Dictionary:
	if not player is PlayerController or not current or current.status != SortieSession.Status.ACTIVE:
		return {"success":false,"message":"No active sortie"}
	var state := current.get_objective_state(objective_id)
	if not state or state.status == ObjectiveState.Status.COMPLETED or player.is_dead:
		return {"success":false,"message":"Objective Unavailable"}
	if player.global_position.distance_to(global_position) > player.interaction_component.interaction_radius:
		return {"success":false,"message":"Move closer to the records terminal."}
	bind_actor(player,current)
	if remaining > 0:
		if urgent: return {"success":false,"message":"Uplink already active."}
		urgent = true
		remaining = minf(remaining,UPLINK_SECONDS)
		get_node("RecordsAlarm").sound_now(current)
	else:
		remaining = COPY_SECONDS
		urgent = false
	AudioDirector.play_sfx(&"ui_click")
	SortieRuntime.request_checkpoint()
	return {"success":true,"message":"URGENT UPLINK / Local alarm sent now." if urgent else "COPY STARTED / Stay close. Interact again for a noisy fast uplink."}

func _process(delta: float) -> void: tick(delta)

func tick(delta: float) -> void:
	if not is_inside_tree() or get_tree().paused or remaining <= 0: return
	if not is_instance_valid(actor) or not session or session.status != SortieSession.Status.ACTIVE or actor.is_dead:
		cancel()
		return
	if actor.global_position.distance_to(global_position) > actor.interaction_component.interaction_radius:
		cancel(tr("RECORDS INTERRUPTED / Too far away. Return to restart."))
		return
	remaining = maxf(0.0,remaining-delta)
	if remaining == 0:
		urgent = false
		super.interact(actor,session)
		AudioDirector.play_sfx(&"ui_confirm")
		SortieRuntime.request_checkpoint()

func get_interaction_prompt(_player: Node3D, current: SortieSession) -> String:
	var state := current.get_objective_state(objective_id) if current else null
	if not state or current.status != SortieSession.Status.ACTIVE or state.status == ObjectiveState.Status.COMPLETED: return ""
	if urgent: return tr("UPLINK %.1fs / Stay close; damage cancels") % remaining
	if remaining > 0: return tr("COPY %.1fs / %s: FAST UPLINK, ALARM NOW") % [remaining,ControlBindings.label("interact")]
	return tr("%s  COPY RECORDS / 8s / Stay close; damage cancels") % ControlBindings.label("interact")

func snapshot() -> Dictionary:
	return {"remaining":remaining,"urgent":urgent}

static func valid_snapshot(raw: Variant) -> bool:
	if typeof(raw) != TYPE_DICTIONARY: return false
	if raw.is_empty(): return true # Existing saves had an instantaneous terminal.
	if raw.size() != 2 or not SaveService.is_number(raw.get("remaining")) or typeof(raw.get("urgent")) != TYPE_BOOL: return false
	return raw.remaining > 0 and raw.remaining <= UPLINK_SECONDS if raw.urgent else raw.remaining >= 0 and raw.remaining <= COPY_SECONDS

func restore(raw: Dictionary, player: PlayerController, current: SortieSession) -> void:
	bind_actor(player,current)
	remaining = float(raw.get("remaining",0.0))
	urgent = bool(raw.get("urgent",false))
