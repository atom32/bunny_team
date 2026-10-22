extends ExtractionPoint
func interact(actor: Node3D,session: SortieSession) -> Dictionary:
	if not actor is PlayerController or actor.global_position.distance_to(global_position)>actor.interaction_component.interaction_radius:return {"success":false,"message":"Move closer to this exit."}
	if not can_extract(session):return {"success":false,"message":"Stop the backup core before using the north exit. South retreat remains open."}
	return super.interact(actor,session)
func get_interaction_prompt(_actor: Node3D,session: SortieSession) -> String:
	return tr("%s  EXTRACT")%ControlBindings.label("interact") if can_extract(session) else tr("NORTH CLOSED / STOP THE BACKUP CORE")
