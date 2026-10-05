class_name RelayStation
extends ObjectiveInteractable
## Timed field work, owned by existing objective/result semantics.
const DURATION := 12.0
var remaining := 0.0
var start_damage := 0.0
var actor: PlayerController
var session: SortieSession
var observed_health := 0.0

func bind_actor(p_actor: PlayerController, current: SortieSession) -> void:
	actor = p_actor
	session = current
	observed_health = actor.health
	if not actor.health_changed.is_connected(_on_health_changed): actor.health_changed.connect(_on_health_changed)

func _on_health_changed(current: float, _maximum: float) -> void:
	# The mission's damage counter rounds to integers. Listen to actual health so
	# even sub-one-point hits cancel work, including between simulation ticks.
	if remaining > 0 and current < observed_health:
		remaining = 0.0
		SortieRuntime.request_checkpoint()
	observed_health = current

func _build_visual() -> void:
	super._build_visual()
	for label in find_children("*","Label3D",true,false): label.text = "RELAY / 12s"

func interact(p_actor: Node3D, current: SortieSession) -> Dictionary:
	if not p_actor is PlayerController or not current or current.status != SortieSession.Status.ACTIVE:
		return {"success":false,"message":"No active sortie"}
	var state := current.get_objective_state(objective_id)
	if not state or state.status == ObjectiveState.Status.COMPLETED or remaining > 0:
		return {"success":false,"message":"Relay unavailable or already active."}
	if p_actor.is_dead or p_actor.global_position.distance_to(global_position) > p_actor.interaction_component.interaction_radius:
		return {"success":false,"message":"Move closer to the relay."}
	bind_actor(p_actor,current)
	remaining = DURATION
	start_damage = session.damage_taken
	CombatNoise.emit_at(self,global_position,18.0,&"repair")
	AudioDirector.play_sfx(&"ui_click")
	SortieRuntime.request_checkpoint()
	return {"success":true,"message":"REPAIR STARTED / Stay nearby for 12s. Damage cancels work."}

func _process(delta: float) -> void: tick(delta)

func tick(delta: float) -> void:
	if not is_inside_tree() or get_tree().paused or remaining <= 0: return
	if not is_instance_valid(actor) or not session or session.status != SortieSession.Status.ACTIVE or actor.is_dead or session.damage_taken > start_damage or actor.global_position.distance_to(global_position) > actor.interaction_component.interaction_radius:
		remaining = 0.0
		SortieRuntime.request_checkpoint()
		return
	remaining = maxf(0.0,remaining-delta)
	if remaining == 0:
		super.interact(actor,session)
		AudioDirector.play_sfx(&"ui_confirm")
		SortieRuntime.request_checkpoint()

func get_interaction_prompt(_actor: Node3D, current: SortieSession) -> String:
	var state := current.get_objective_state(objective_id) if current else null
	if not state or current.status != SortieSession.Status.ACTIVE: return ""
	if state.status == ObjectiveState.Status.COMPLETED: return tr("RELAY ONLINE")
	if remaining > 0: return tr("REPAIRING %.1fs / Stay nearby; avoid damage") % remaining
	return tr("%s  REPAIR RELAY / 12s / Local noise") % ControlBindings.label("interact")
