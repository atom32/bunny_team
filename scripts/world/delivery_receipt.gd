extends Node3D
## One fixed receipt for the same batch as the pharmacy's existing record.

func _ready() -> void:
	add_to_group("interactable")
	VisualFactory.box(self,Vector3(.42,.014,.30),Vector3.ZERO,Color("d7cdb5"),"ReceiptPaper")
	for line in 4:
		VisualFactory.box(self,Vector3(.30,.004,.013),Vector3(-.02,.009,-.08+line*.045),Color("6e7461"),"ReceiptLine")
	var label := Label3D.new()
	label.font = UIFactory.FONT
	label.text = "MED-TK-071 / 配送回执"
	label.position.y = .55
	label.font_size = 30
	label.pixel_size = 0.006
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

func interact(actor: Node3D, session: SortieSession) -> Dictionary:
	if not actor is PlayerController or actor.is_dead or not session or actor.global_position.distance_to(global_position) > actor.interaction_component.interaction_radius:
		return {"success": false, "message": "请靠近配送回执。"}
	if not session.record_delivery_receipt(NarrativeSlice.DELIVERY_RECEIPT):
		return {"success": false, "message": "回执已经拿到了，或当前没有这项委托。", "information": NarrativeSlice.RECEIPT_INFORMATION if not session.delivery_receipt.is_empty() else ""}
	SortieRuntime.request_checkpoint()
	return {"success": true, "message": "已取得 MED-TK-071 配送回执；请带回基地。", "information": NarrativeSlice.RECEIPT_INFORMATION}

func get_interaction_prompt(_actor: Node3D, session: SortieSession) -> String:
	if not session or session.status != SortieSession.Status.ACTIVE or not session.q04_active: return ""
	if not session.delivery_receipt.is_empty(): return ControlBindings.label("interact") + "  查看已取得的回执"
	return ControlBindings.label("interact") + "  取得 MED-TK-071 配送回执"
