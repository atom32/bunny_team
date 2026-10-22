class_name WaterTanker
extends AnimatableBody3D
## A short drivable straight loading lane, not an escort-health or traffic system.
const START:=Vector3(34,0,-25)
const DISTANCE:=14.0
const GATE_STOP:=4.5
var progress:=0.0
var moving:=false
var blocked:=false
var noise_remaining:=0.0

func _ready() -> void:
	GameLanguage.language_changed.connect(_label);_label()

func _label() -> void:$WorldLabel.text=tr("WATER TRUCK / HANDBRAKE")

func get_interaction_prompt(_actor: Node3D,session: SortieSession) -> String:
	if not WaterworksJourney.pending(session,"tanker"):return ""
	return ControlBindings.label("interact")+"  "+tr("SET HANDBRAKE" if moving else "RELEASE HANDBRAKE")

func interact(actor: Node3D,session: SortieSession) -> Dictionary:
	if not actor is PlayerController or not WaterworksJourney.pending(session,"tanker"):return {"success":false,"message":"Choose the north water delivery first."}
	if actor.global_position.distance_to(global_position+Vector3.LEFT*1.8)>actor.interaction_component.interaction_radius:return {"success":false,"message":"Move beside the truck's handbrake."}
	if progress>=GATE_STOP and not session.waterworks.gate_open:return {"success":false,"message":"Raise the loading gate before moving the truck."}
	moving=not moving;SortieRuntime.request_checkpoint()
	return {"success":true,"message":"Truck moving. Keep its front clear." if moving else "Handbrake set. Truck stopped."}

func apply_progress() -> void:position=START+Vector3.FORWARD*progress

func _front_occupied() -> bool:
	var shape:=BoxShape3D.new();shape.size=Vector3(3.6,2.2,1.0)
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.transform=Transform3D(Basis.IDENTITY,global_position+Vector3(0,1.1,-4.6));query.collision_mask=3;query.exclude=[get_rid()]
	return not get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()

func _physics_process(delta: float) -> void:
	var session:=SortieRuntime.get_current_session()
	if not WaterworksJourney.pending(session,"tanker") or not moving:return
	blocked=_front_occupied()
	if blocked:return
	var limit:=DISTANCE if session.waterworks.gate_open else GATE_STOP
	var traveled:=minf(2*delta,maxf(0,limit-progress));progress+=traveled;apply_progress()
	for wheel in $Wheels.get_children():wheel.rotation.x-=traveled/.65
	noise_remaining-=delta
	if noise_remaining<=0:CombatNoise.emit_at(self,global_position,24,&"engine");noise_remaining=2
	if progress>=limit:
		moving=false
		if limit==DISTANCE:get_parent().complete_delivery("tanker")
		else:
			get_parent().get_parent().get_parent().player.interaction_component.interaction_finished.emit(tr("Truck stopped at the closed loading gate. Raise it from the west lever."),false)
			SortieRuntime.request_checkpoint()

func valid_checkpoint(entry: Dictionary,session: SortieSession) -> bool:
	if entry.progress<0 or entry.progress>DISTANCE:return false
	if session.waterworks.branch!="tanker":return entry.progress==0 and not entry.moving
	if not session.waterworks.gate_open and entry.progress>GATE_STOP:return false
	if session.waterworks.delivered:return entry.progress==DISTANCE and not entry.moving
	return entry.progress<DISTANCE and (entry.progress<GATE_STOP or session.waterworks.gate_open or not entry.moving)
