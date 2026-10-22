extends ExtractionPoint

func interact(actor: Node3D, session: SortieSession) -> Dictionary:
	if not can_extract(session): return {"success":false,"message":"This route is closed. Confirm its water delivery, or use the south retreat."}
	return super.interact(actor,session)

func get_interaction_prompt(_actor: Node3D, session: SortieSession) -> String:
	return tr("%s  EXTRACT") % ControlBindings.label("interact") if can_extract(session) else tr("CLOSED / CHOOSE THIS WATER DELIVERY FIRST")
