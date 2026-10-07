extends Node3D
## Separate nearby interaction. The parent exit retains its extraction behavior.
var exit_point: ExtractionPoint

func _ready() -> void:
	add_to_group("interactable")
	var label := Label3D.new()
	label.font = UIFactory.FONT
	label.text = "出口铭牌 / EXIT CONDITIONS"
	label.position.y = 0.9
	label.font_size = 28
	label.pixel_size = 0.008
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

func interact(actor: Node3D, session: SortieSession) -> Dictionary:
	if not actor is PlayerController or actor.is_dead or not session or not exit_point.available or actor.global_position.distance_to(global_position) > actor.interaction_component.interaction_radius:
		return {"success": false, "message": "Move closer to the exit plaque."}
	if not session.record_exit_observation(String(exit_point.extraction_id), String(exit_point.required_objective_id)):
		return {"success": false, "message": "Exit plaque unavailable or already observed."}
	SortieRuntime.request_checkpoint()
	var condition := "始终可撤离 / RETREAT ALWAYS AVAILABLE" if exit_point.required_objective_id.is_empty() else "取得本局档案后开放 / THIS SORTIE'S RECORDS REQUIRED"
	return {"success": true, "message": String(exit_point.extraction_id) + " / " + condition}

func get_interaction_prompt(_actor: Node3D, session: SortieSession) -> String:
	if not session or session.status != SortieSession.Status.ACTIVE or not exit_point.available: return ""
	if String(exit_point.extraction_id) in session.exit_observations: return "已查看铭牌 / PLAQUE OBSERVED"
	return ControlBindings.label("interact") + "  查看出口铭牌 / INSPECT EXIT CONDITIONS"
