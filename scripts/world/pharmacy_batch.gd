extends Node3D
## Fixed pharmacy record, separate from every random loot container.

func _ready() -> void:
	add_to_group("interactable")
	var label := Label3D.new()
	label.font = UIFactory.FONT
	label.text = "MED-TK-071"
	label.position = Vector3(0,1.01,1.0)
	label.rotation.x = -PI/2
	label.font_size = 24
	label.pixel_size = 0.004
	add_child(label)

func interact(actor: Node3D, session: SortieSession) -> Dictionary:
	if not actor is PlayerController or actor.is_dead or not session or actor.global_position.distance_to(global_position) > actor.interaction_component.interaction_radius:
		return {"success": false, "message": "请靠近药房的收货登记。"}
	if not session.record_pharmacy_observation(NarrativeSlice.PHARMACY_BATCH):
		return {"success": false, "message": "已查看这批货的记录，或当前没有这项委托。", "information": NarrativeSlice.BATCH_INFORMATION if not session.pharmacy_batch.is_empty() else ""}
	SortieRuntime.request_checkpoint()
	return {"success": true, "message": "已查看 MED-TK-071 收货记录；请成功撤离后再回基地交差。", "information": NarrativeSlice.BATCH_INFORMATION}

func get_interaction_prompt(_actor: Node3D, session: SortieSession) -> String:
	if not session or session.status != SortieSession.Status.ACTIVE or not (session.q02_active or session.q04_active): return ""
	if not session.pharmacy_batch.is_empty(): return ControlBindings.label("interact") + "  再次查看 MED-TK-071"
	return ControlBindings.label("interact") + "  查看药房收货批次 MED-TK-071"
