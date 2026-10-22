extends Node3D
@export var escape:=false
func _ready() -> void:add_to_group("interactable")

func interact(actor: Node3D,session: SortieSession) -> Dictionary:
	if not actor is PlayerController or not session or session.status!=SortieSession.Status.ACTIVE or session.blockade.is_empty():return {"success":false,"message":"Interaction Unavailable"}
	if actor.global_position.distance_to(global_position)>actor.interaction_component.interaction_radius:return {"success":false,"message":"Move closer"}
	var route: BlockadePassage=get_parent().get_node("Passage")
	var success:=route.start_escape() if escape else route.open_service()
	return {"success":success,"message":("Counterweight released. The gate moves while you fight." if escape else "Service shutter open. Stay out of the searchlight.") if success else "The north counterweight needs the van disabled first, or this lever is already open."}

func get_interaction_prompt(_actor: Node3D,session: SortieSession) -> String:
	if not session or session.status!=SortieSession.Status.ACTIVE or session.blockade.is_empty():return ""
	var route: BlockadePassage=get_parent().get_node("Passage")
	if (escape and route.escape_started) or (not escape and route.service_open):return ""
	return ControlBindings.label("interact")+"  "+tr("RELEASE COUNTERWEIGHT / NORTH GATE" if escape else "OPEN SERVICE SHUTTER / QUIET ENTRY")
