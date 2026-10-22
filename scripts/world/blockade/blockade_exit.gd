extends ExtractionPoint

func interact(actor: Node3D, session: SortieSession) -> Dictionary:
	if not can_extract(session):return {"success":false,"message":"Disable the van, then release the east-booth counterweight. South retreat stays open." if session and not session.blockade.is_empty() else "Disable the blockade van first, or retreat south."}
	return super.interact(actor,session)

func get_interaction_prompt(_actor: Node3D, session: SortieSession) -> String:
	return tr("%s  EXTRACT") % ControlBindings.label("interact") if can_extract(session) else tr("LOCKED / VAN AND NORTH COUNTERWEIGHT" if session and not session.blockade.is_empty() else "LOCKED / DISABLE THE VAN FIRST")
