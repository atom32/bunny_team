class_name WaterDeliveryControl
extends Node3D
@export_enum("bypass","loading_gate","handbrake") var kind:="bypass"

func _ready() -> void:
	add_to_group("interactable")
	GameLanguage.language_changed.connect(_label);_label()

func _label() -> void:
	$WorldLabel.text=tr("WATER TRUCK / HANDBRAKE" if kind=="handbrake" else ("WEST BYPASS / RELIEVE PRESSURE" if kind=="bypass" else "RAISE LOADING GATE"))

func available(session: SortieSession) -> bool:
	if kind=="handbrake":return WaterworksJourney.pending(session,"tanker")
	return WaterworksJourney.pending(session,"public" if kind=="bypass" else "tanker") and (kind=="bypass" or not session.waterworks.gate_open)

func get_interaction_prompt(_actor: Node3D,session: SortieSession) -> String:
	if kind=="handbrake":return get_parent().get_interaction_prompt(_actor,session)
	return ControlBindings.label("interact")+"  "+tr("RELIEVE PRESSURE" if kind=="bypass" else "RAISE LOADING GATE") if available(session) else ""

func interact(actor: Node3D,session: SortieSession) -> Dictionary:
	if kind=="handbrake":return get_parent().interact(actor,session)
	if not actor is PlayerController or not available(session):return {"success":false,"message":"This water delivery control is unavailable."}
	if actor.global_position.distance_to(global_position)>actor.interaction_component.interaction_radius:return {"success":false,"message":"Move closer to the delivery control."}
	var query:=PhysicsRayQueryParameters3D.create(actor.global_position+Vector3.UP,global_position+Vector3.UP,4);query.exclude=[actor.get_rid()]
	if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():return {"success":false,"message":"A wall blocks the delivery control."}
	if kind=="bypass":get_parent().complete_delivery("public","bypass")
	else:session.waterworks.gate_open=true;get_parent().refresh_waterworks();SortieRuntime.request_checkpoint()
	return {"success":true,"message":"Pressure relieved. The courtyard gate is open." if kind=="bypass" else "Loading gate raised. Release the truck's handbrake and clear its front."}
