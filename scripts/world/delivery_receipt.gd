extends Node3D
## One fixed receipt for the same batch as the pharmacy's existing record.

func _ready() -> void:
	add_to_group("interactable")
	var label := Label3D.new()
	label.font = UIFactory.FONT
	label.text = "MED-TK-071 / 配送回执"
	label.position.y = 1.6
	label.font_size = 48
	label.pixel_size = 0.012
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

func interact(actor: Node3D, session: SortieSession) -> Dictionary:
	if not actor is PlayerController or actor.is_dead or not session or actor.global_position.distance_to(global_position) > actor.interaction_component.interaction_radius:
		return {"success": false, "message": "请靠近配送回执。"}
	if not session.record_delivery_receipt(NarrativeSlice.DELIVERY_RECEIPT):
		return {"success": false, "message": "配送回执已取得或本局委托未开启。"}
	SortieRuntime.request_checkpoint()
	return {"success": true, "message": "已取得 MED-TK-071 配送回执；成功撤离后才能带回。"}

func get_interaction_prompt(_actor: Node3D, session: SortieSession) -> String:
	if not session or session.status != SortieSession.Status.ACTIVE or not session.q04_active: return ""
	if not session.delivery_receipt.is_empty(): return "配送回执已取得 / RECEIPT COLLECTED"
	return ControlBindings.label("interact") + "  取得 MED-TK-071 配送回执"
