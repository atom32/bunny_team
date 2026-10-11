extends Node3D
## Separate nearby interaction. The parent exit retains its extraction behavior.
var exit_point: ExtractionPoint

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
	if not actor is PlayerController or actor.is_dead or not session or not exit_point.available or actor.global_position.distance_to(global_position) > actor.interaction_component.interaction_radius:
		return {"success": false, "message": "Move closer to the exit plaque."}
	var condition := "始终可撤离" if exit_point.required_objective_id.is_empty() else "取得本局档案后开放"
	var information := String(exit_point.extraction_id) + " / " + condition
	if not session.record_exit_observation(String(exit_point.extraction_id), String(exit_point.required_objective_id)):
		return {"success": false, "message": "Exit plaque unavailable or already observed.", "information": information if String(exit_point.extraction_id) in session.exit_observations else ""}
	SortieRuntime.request_checkpoint()
	return {"success": true, "message": "已查看出口铭牌", "information": information}

func get_interaction_prompt(_actor: Node3D, session: SortieSession) -> String:
	if not session or session.status != SortieSession.Status.ACTIVE or not exit_point.available: return ""
	if String(exit_point.extraction_id) in session.exit_observations: return ControlBindings.label("interact") + "  再次查看出口铭牌"
	return ControlBindings.label("interact") + "  查看出口铭牌"
