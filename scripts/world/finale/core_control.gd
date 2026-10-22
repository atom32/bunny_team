class_name FinaleControl
extends ObjectiveInteractable

func _ready() -> void:
	super._ready();GameLanguage.language_changed.connect(refresh);refresh()

func _near(player: PlayerController) -> bool:
	if player.is_dead or player.global_position.distance_to(global_position)>player.interaction_component.interaction_radius:return false
	var query:=PhysicsRayQueryParameters3D.create(player.global_position+Vector3.UP*1.25,global_position+Vector3.UP*1.4,4);query.exclude=[player.get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func reason(session: SortieSession) -> String:
	if not session or session.status!=SortieSession.Status.ACTIVE or session.mission_id!=FinaleStory.MISSION:return "No active backup-power operation."
	if objective_id==&"core_radio":return ""
	if FinaleStory.done(session,objective_id):return "This circuit is already isolated."
	if objective_id==FinaleStory.BRIDGE:return ""
	if not FinaleStory.done(session,FinaleStory.BRIDGE):return "Keep shelter power first. Use the bridge at the south entrance."
	if objective_id==FinaleStory.STOP and not (FinaleStory.done(session,FinaleStory.LEFT) and FinaleStory.done(session,FinaleStory.RIGHT)):return "Isolate both side feeds before using the master stop."
	if get_parent().get_node("Sweep").phase!=FinaleSweep.Phase.COOLING:return "Wait for the blue cooling window. Do not touch a live feed."
	return ""

func interact(actor: Node3D,session: SortieSession) -> Dictionary:
	if not actor is PlayerController or not _near(actor):return {"success":false,"message":"Move closer to this control, on the same side of the wall."}
	var why:=reason(session)
	if not why.is_empty():return {"success":false,"message":why}
	if objective_id==&"core_radio":return {"success":true,"message":"Backup power / radio","information":tr(FinaleStory.INTRO)}
	var first_feed:=not FinaleStory.done(session,FinaleStory.LEFT) and not FinaleStory.done(session,FinaleStory.RIGHT)
	if not session.record_objective_interaction(objective_id):return {"success":false,"message":"Control could not be operated."}
	var battle:=get_parent().get_parent().get_parent()
	var line:=FinaleStory.BRIDGE_LINE
	if objective_id in [FinaleStory.LEFT,FinaleStory.RIGHT]:
		if first_feed:battle.spawn_reinforcement_group(&"core_response")
		line=FinaleStory.BOTH_FEEDS if FinaleStory.done(session,FinaleStory.LEFT) and FinaleStory.done(session,FinaleStory.RIGHT) else FinaleStory.FIRST_FEED
	elif objective_id==FinaleStory.STOP:
		line=FinaleStory.STOP_LINE;battle.spawn_reinforcement_group(&"core_final")
	get_parent().refresh_core()
	objective_interacted.emit(objective_id);SortieRuntime.request_checkpoint()
	return {"success":true,"message":"Circuit changed / L-02A shelter supply remains on.","information":tr(line)}

func get_interaction_prompt(_actor: Node3D,session: SortieSession) -> String:
	var why:=reason(session)
	return ControlBindings.label("interact")+"  "+tr(interaction_prompt) if why.is_empty() else tr(why)

func refresh() -> void:
	if has_node("WorldLabel"):get_node("WorldLabel").text=tr(interaction_prompt)
