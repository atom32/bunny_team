extends Node3D
## Separate nearby interaction. The parent exit retains its extraction behavior.
var exit_point: ExtractionPoint
const FIRST_REPLY := "Shen Yanshuang: Your chair is still yours. Do not leave me arguing with an empty seat all night."
const SECOND_REPLY := "Tang Kui: She has wiped that chair down three times.\nShen Yanshuang: Nobody asked you to count."

func _ready() -> void:
	add_to_group("interactable")
	var label := Label3D.new()
	label.font = UIFactory.FONT
	label.text = tr("EXIT PLAQUE\nREAD CONDITIONS")
	label.position.y = 0.9
	label.font_size = 30
	label.pixel_size = 0.012
	label.outline_size = 2
	label.modulate = Color("f0e5c9")
	label.no_depth_test = true
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
	GameLanguage.language_changed.connect(func(): label.text = tr("EXIT PLAQUE\nREAD CONDITIONS"))

func interact(actor: Node3D, session: SortieSession) -> Dictionary:
	if not actor is PlayerController or actor.is_dead or not session or session.status != SortieSession.Status.ACTIVE or not is_instance_valid(exit_point) or not exit_point.available or actor.global_position.distance_to(global_position) > actor.interaction_component.interaction_radius:
		return {"success": false, "message": "Move closer to the exit plaque."}
	var information := conditions_text(session)
	var gate:=exit_point.physical_gate()
	if gate and not gate.is_open():return {"success":false,"message":gate.closed_message(),"information":information}
	if not session.record_exit_observation(String(exit_point.extraction_id), String(exit_point.required_objective_id)):
		return {"success": false, "message": "Exit plaque unavailable or already observed.", "information": information if String(exit_point.extraction_id) in session.exit_observations else ""}
	SortieRuntime.request_checkpoint()
	# Only freshly earned, provisional observations speak. Re-reading keeps the
	# gate conditions available without replaying the exchange or granting facts.
	information += "\n\n" + tr(FIRST_REPLY if session.exit_observations.size() == 1 else SECOND_REPLY)
	return {"success": true, "message": "已查看出口铭牌", "information": information}

func conditions_text(session: SortieSession) -> String:
	var title := tr("ASSIGNED EXIT")
	# Read the actual parent gate's name, not a second, drifting list of names.
	for child in exit_point.get_children():
		if child is Label3D and not child.text.is_empty():
			title = tr(child.text)
			break
	var condition := "OPEN NOW / NO RECORDS REQUIRED"
	var gate:=exit_point.physical_gate()
	if not exit_point.required_objective_id.is_empty():
		var state := session.get_objective_state(exit_point.required_objective_id)
		condition = "OPEN NOW / RECORDS RECOVERED" if state and state.status == ObjectiveState.Status.COMPLETED else "LOCKED / RECOVER THIS SORTIE'S RECORDS"
	return title + "\n" + (gate.closed_message()+"\n" if gate and not gate.is_open() else "") + tr(condition)

func get_interaction_prompt(_actor: Node3D, session: SortieSession) -> String:
	if not session or session.status != SortieSession.Status.ACTIVE or not exit_point.available: return ""
	if String(exit_point.extraction_id) in session.exit_observations: return ControlBindings.label("interact") + "  再次查看出口铭牌"
	return ControlBindings.label("interact") + "  查看出口铭牌"
