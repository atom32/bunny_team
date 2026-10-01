extends ObjectiveInteractable

var investigation_remaining := 0.0
var actor: Node3D
var active_session: SortieSession

func interact(p_actor: Node3D, session: SortieSession) -> Dictionary:
	var director := get_tree().get_first_node_in_group("first_mission_director")
	if not director or director.stage != director.Stage.TERMINAL or investigation_remaining > 0:
		return {"success": false, "message": "Finish the current training step first."}
	actor = p_actor
	active_session = session
	investigation_remaining = 8.0
	return {"success": true, "message": "Investigating: stay near the terminal for 8 seconds."}

func _process(delta: float) -> void:
	if investigation_remaining <= 0: return
	if not is_instance_valid(actor) or actor.is_dead or active_session.status != SortieSession.Status.ACTIVE or actor.global_position.distance_to(global_position) > actor.interaction_component.interaction_radius:
		investigation_remaining = 0.0
		return
	investigation_remaining = maxf(0.0, investigation_remaining - delta)
	if investigation_remaining == 0:
		super.interact(actor, active_session)

func get_interaction_prompt(p_actor: Node3D, session: SortieSession) -> String:
	var director := get_tree().get_first_node_in_group("first_mission_director")
	if not director or director.stage != director.Stage.TERMINAL: return ""
	if investigation_remaining > 0: return tr("INVESTIGATING  %.1fs / STAY NEARBY") % investigation_remaining
	return super.get_interaction_prompt(p_actor, session)
