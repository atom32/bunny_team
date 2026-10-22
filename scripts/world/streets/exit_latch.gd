extends Node3D

func _ready() -> void:add_to_group("interactable")

func interact(actor: Node3D,current: SortieSession) -> Dictionary:
	var gate:=get_parent() as CampusExitGate
	if not actor is PlayerController or actor.is_dead or not gate.available(current) or gate.is_open():return {"success":false,"message":"The north gate does not need another pull."}
	if actor.global_position.distance_to(global_position)>actor.interaction_component.interaction_radius or gate.to_local(actor.global_position).z<.7:return {"success":false,"message":"Go round the end of the wall. The bolt is on the outside."}
	var ray:=PhysicsRayQueryParameters3D.create(actor.global_position+Vector3.UP*1.2,global_position+Vector3.UP*1.2,4);ray.exclude=[actor.get_rid()]
	if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty():return {"success":false,"message":"The wall blocks the outside latch."}
	return {"success":gate.open_gate(1,actor),"message":"Outside bolt released."}

func get_interaction_prompt(actor: Node3D,current: SortieSession) -> String:
	var gate:=get_parent() as CampusExitGate
	if not gate.available(current) or gate.is_open():return ""
	if gate.to_local(actor.global_position).z<.7:return tr("Go round the end of the wall. The bolt is on the outside.")
	return ControlBindings.label("interact")+"  "+tr("RELEASE OUTSIDE BOLT / QUIET")
