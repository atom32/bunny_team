extends ObjectiveInteractable

func interact(actor: Node3D, session: SortieSession) -> Dictionary:
	if not actor is PlayerController or not session or session.mission_id != BlockadeStory.MISSION or session.status != SortieSession.Status.ACTIVE: return {"success":false,"message":"Interaction Unavailable"}
	if actor.global_position.distance_to(global_position) > actor.interaction_component.interaction_radius: return {"success":false,"message":"Move closer"}
	if objective_id == &"blockade_brief": return {"success":true,"message":"CHECKPOINT / RADIO","information":tr(BlockadeStory.INTRO if session.blockade.is_empty() else BlockadeJourney.INTRO)}
	if not get_parent().get_node("Van").cut_speaker(): return {"success":false,"message":"PA SUPPLY ALREADY OFF"}
	objective_interacted.emit(objective_id)
	return {"success":true,"message":"PA SUPPLY OFF / GUN STILL ACTIVE","information":tr(BlockadeStory.CUT)}

func get_interaction_prompt(_actor: Node3D, session: SortieSession) -> String:
	if not session or session.status != SortieSession.Status.ACTIVE: return ""
	if objective_id != &"blockade_brief" and not get_parent().get_node("Van").speaker_enabled: return ""
	return ControlBindings.label("interact") + "  " + tr(interaction_prompt)
