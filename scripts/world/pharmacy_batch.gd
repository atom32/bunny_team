extends Node3D
## Fixed pharmacy record, separate from every random loot container.

func _ready() -> void:
	add_to_group("interactable")
	var label := Label3D.new()
	label.font = UIFactory.FONT
	label.text = "MED-TK-071 / 收货栏"
	label.position.y = 1.6
	label.font_size = 48
	label.pixel_size = 0.012
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

func interact(actor: Node3D, session: SortieSession) -> Dictionary:
	if not actor is PlayerController or actor.is_dead or not session or actor.global_position.distance_to(global_position) > actor.interaction_component.interaction_radius:
		return {"success": false, "message": "请到药房收货栏现场查看。"}
	if not session.record_pharmacy_observation(NarrativeSlice.PHARMACY_BATCH):
		return {"success": false, "message": "指定批次已观察或本局委托未开启。"}
	SortieRuntime.request_checkpoint()
	return {"success": true, "message": "已观察 MED-TK-071；成功撤离后才能带回。"}

func get_interaction_prompt(_actor: Node3D, session: SortieSession) -> String:
	if not session or session.status != SortieSession.Status.ACTIVE or not (session.q02_active or session.q04_active): return ""
	if not session.pharmacy_batch.is_empty(): return "已查看 MED-TK-071 / BATCH OBSERVED"
	return ControlBindings.label("interact") + "  查看药房收货批次 MED-TK-071"
