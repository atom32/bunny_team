extends Node3D
func _ready() -> void:add_to_group("interactable")

func interact(actor: Node3D,session: SortieSession) -> Dictionary:
	if not actor is PlayerController or actor.global_position.distance_to(global_position)>actor.interaction_component.interaction_radius:return {"success":false,"message":"Move closer to the steam valve."}
	var query:=PhysicsRayQueryParameters3D.create(actor.global_position+Vector3.UP*1.25,global_position+Vector3.UP*1.25,4);query.exclude=[actor.get_rid()]
	if not actor.get_world_3d().direct_space_state.intersect_ray(query).is_empty():return {"success":false,"message":"The valve is behind cover."}
	var success: bool=get_parent().get_node("Steam").close_valve(actor)
	return {"success":success,"message":"Steam line isolated. Return to Xu Tang if she is waiting." if success else "Steam valve is already closed, or the service bulkhead is still locked."}

func get_interaction_prompt(_actor: Node3D,session: SortieSession) -> String:
	if not session or session.status!=SortieSession.Status.ACTIVE or session.maintenance.is_empty() or session.maintenance.steam_off:return ""
	return ControlBindings.label("interact")+"  "+tr("CLOSE STEAM VALVE / FAR SIDE")
