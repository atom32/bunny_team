extends ExtractionPoint

var extraction_remaining := 0.0
var actor: Node3D
var active_session: SortieSession

func can_extract(session: SortieSession) -> bool:
	var director := get_tree().get_first_node_in_group("first_mission_director")
	return super.can_extract(session) and director != null and director.stage >= director.Stage.CHOICE

func interact(p_actor: Node3D, session: SortieSession) -> Dictionary:
	if not can_extract(session) or extraction_remaining > 0:
		return {"success": false, "message": "Extraction is not ready."}
	actor = p_actor
	active_session = session
	extraction_remaining = 8.0
	return {"success": true, "message": "Return link opening. Defend the beacon for 8 seconds."}

func _process(delta: float) -> void:
	if extraction_remaining <= 0: return
	if not is_instance_valid(actor) or actor.is_dead or not can_extract(active_session) or actor.global_position.distance_to(global_position) > actor.interaction_component.interaction_radius:
		extraction_remaining = 0.0
		return
	extraction_remaining = maxf(0.0, extraction_remaining - delta)
	if extraction_remaining == 0: extract(active_session)

func get_interaction_prompt(_actor: Node3D, session: SortieSession) -> String:
	if extraction_remaining > 0: return tr("EXTRACTING  %.1fs / DEFEND THE BEACON") % extraction_remaining
	return tr("%s  EXTRACT / DEFEND FOR 8s") % ControlBindings.label("interact") if can_extract(session) else "LINK LOCKED / INVESTIGATE THE TERMINAL"
