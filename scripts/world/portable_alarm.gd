class_name PortableAlarm
extends Node3D
## A consumed, finite field sound source. It never spawns enemies, supplies a
## player target, clears visual contact, or becomes recoverable after placement.
const ITEM_ID := &"tool.portable_alarm"
const MAX_LIVE := 8
const PLACE_DISTANCE := 1.2
const RADIUS := 24.0
const DURATION := 9.0
const PULSE_TIMES := [3.0,5.0,7.0]
const FIRST_RING := "Tang Kui: It gets to shout three times?\nSu Mi: It does not argue back.\nTang Kui: ..."
var instance_id := ""
var elapsed := 0.0
var pulses := 0
var label: Label3D
var beacon: MeshInstance3D
var _session_id := ""

static func carried(session: SortieSession) -> ItemInstance:
	if not session or not session.inventory:return null
	for item in session.inventory.get_items():
		if item.definition_id==ITEM_ID and item.quantity==1:return item
	return null

static func live(battle: Node3D) -> Array[PortableAlarm]:
	var result:Array[PortableAlarm]=[]
	if not is_instance_valid(battle):return result
	for child in battle.get_children():
		if child is PortableAlarm and not child.is_queued_for_deletion() and child.elapsed<DURATION:result.append(child)
	return result

static func place_for(actor: PlayerController) -> Dictionary:
	return place(actor,actor.get_parent() as Node3D) if is_instance_valid(actor) else {"success":false,"message":"Cannot place an alarm now."}

static func place(actor: PlayerController,battle: Node3D) -> Dictionary:
	if not _available(actor,battle) or actor.get_tree().paused:
		return {"success":false,"message":"Cannot place an alarm now."}
	if actor.aim_input_captured:
		return {"success":false,"message":"Close the interaction panel before placing an alarm."}
	if _placing_busy(actor):
		return {"success":false,"message":"Stand still and finish your current action before placing an alarm."}
	var session:SortieSession=battle.session
	var item:=carried(session)
	if not item:return {"success":false,"message":"No portable alarm box is packed."}
	var active:=live(battle)
	if active.size()>=MAX_LIVE:return {"success":false,"message":"Too many active alarm boxes."}
	var direction:=Vector3(actor.aim_direction.x,0,actor.aim_direction.z)
	if not direction.is_finite() or direction.length_squared()<.001:
		return {"success":false,"message":"Place the alarm on clear, nearby ground."}
	var target:=actor.global_position+direction.normalized()*PLACE_DISTANCE
	var space:=actor.get_world_3d().direct_space_state
	var standing:=_floor_at(space,actor.global_position)
	var floor_hit:=_floor_at(space,target)
	if standing.is_empty() or floor_hit.is_empty() or absf(floor_hit.position.y-standing.position.y)>.35:
		return {"success":false,"message":"Place the alarm on clear, nearby ground."}
	var point:Vector3=floor_hit.position
	var sight:=PhysicsRayQueryParameters3D.create(actor.global_position+Vector3.UP*.7,point+Vector3.UP*.25,4)
	sight.exclude=[actor.get_rid()];sight.hit_from_inside=true
	if not space.intersect_ray(sight).is_empty():
		return {"success":false,"message":"Place the alarm on clear, nearby ground."}
	var shape:=BoxShape3D.new();shape.size=Vector3(.6,.5,.52)
	var query:=PhysicsShapeQueryParameters3D.new()
	query.shape=shape;query.transform=Transform3D(Basis.IDENTITY,point+Vector3.UP*.29)
	query.collision_mask=7;query.exclude=[actor.get_rid()]
	if not space.intersect_shape(query,1).is_empty():
		return {"success":false,"message":"Place the alarm on clear, nearby ground."}
	for other in active:
		if other.global_position.distance_to(point)<.7:
			return {"success":false,"message":"Place the alarm on clear, nearby ground."}
	# All spatial and ownership checks precede the one exact-ID consumption.
	var id:=item.instance_id
	if id.is_empty() or id.length()>128 or not session.inventory.consume_item(id,1):
		return {"success":false,"message":"No portable alarm box is packed."}
	var alarm:=PortableAlarm.new();alarm.instance_id=id
	alarm.position=battle.to_local(point);battle.add_child(alarm)
	SortieRuntime.request_checkpoint()
	return {"success":true,"message":"Alarm placed / 3-second delay. Enemies who see you still pursue you.","alarm":alarm,"instance_id":id}

static func _available(actor: PlayerController,battle: Node3D) -> bool:
	if not is_instance_valid(actor) or not actor.is_inside_tree() or actor.preview_mode or actor.is_dead or actor.health<=0:return false
	if not is_instance_valid(battle) or not battle.is_inside_tree() or actor.get_parent()!=battle or battle.get("player")!=actor:return false
	if actor.get_world_3d()!=battle.get_world_3d():return false
	var session:SortieSession=battle.get("session")
	return session!=null and session==SortieRuntime.get_current_session() and session.status==SortieSession.Status.ACTIVE and not battle.get("ending")

static func _placing_busy(actor: PlayerController) -> bool:
	if actor._dodge_time>0 or Vector2(actor.velocity.x,actor.velocity.z).length()>.2 or actor._fire_queued:return true
	if actor.combat_rig and actor.combat_rig.is_reloading():return true
	if actor.medical and actor.medical.is_active():return true
	for remaining:float in actor._reload_remaining_by_weapon.values():
		if remaining>0:return true
	for action in ["move_left","move_right","move_forward","move_back","fire","dodge","reload","switch_weapon","interact"]:
		if Input.is_action_pressed(action):return true
	return false

static func _floor_at(space: PhysicsDirectSpaceState3D,point: Vector3) -> Dictionary:
	var query:=PhysicsRayQueryParameters3D.create(point+Vector3.UP*.45,point+Vector3.DOWN*.45,4)
	var hit:=space.intersect_ray(query)
	if hit.is_empty() or not hit.collider is StaticBody3D or hit.normal.dot(Vector3.UP)<.95 or absf(hit.position.y-point.y)>.35:return {}
	return hit

func _ready() -> void:
	var battle:=get_parent() as Node3D
	var session:SortieSession=battle.get("session") if is_instance_valid(battle) else null
	_session_id=session.session_id if session else ""
	add_to_group("sight_sensitive");set_meta("sight_height",.25)
	VisualFactory.box(self,Vector3(.4,.22,.3),Vector3(0,.13,0),Color("55646a"),"AlarmBox")
	VisualFactory.box(self,Vector3(.42,.035,.32),Vector3(0,.255,0),Color("859192"),"BoxLid")
	for x in [-.14,-.07,0,.07,.14]:
		VisualFactory.box(self,Vector3(.022,.12,.012),Vector3(x,.14,-.155),Color("222e33"),"SpeakerGrille")
	VisualFactory.box(self,Vector3(.22,.025,.035),Vector3(0,.34,0),Color("27373c"),"CarryHandle")
	for x in [-.095,.095]:
		VisualFactory.box(self,Vector3(.025,.07,.035),Vector3(x,.305,0),Color("27373c"),"HandleMount")
	beacon=VisualFactory.box(self,Vector3(.075,.035,.06),Vector3(.125,.29,-.06),Color("e2af54"),"AlarmLamp")
	label=Label3D.new();label.name="AlarmLabel";label.font=UIFactory.FONT
	label.position=Vector3(0,.65,0);label.font_size=24;label.pixel_size=.009;label.outline_size=4
	label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;add_child(label)
	GameLanguage.language_changed.connect(_refresh_visual)
	_refresh_visual() # Construction and restoration are deliberately silent.

func _physics_process(delta: float) -> void:
	if not is_inside_tree() or get_tree().paused:return
	var battle:=get_parent() as Node3D
	if not is_instance_valid(battle) or not _available(battle.get("player") as PlayerController,battle):
		queue_free();return
	if _session_id!=battle.session.session_id:
		queue_free();return
	if not is_finite(delta) or delta<=0:return
	elapsed=minf(DURATION,elapsed+delta)
	while pulses<PULSE_TIMES.size() and elapsed>=PULSE_TIMES[pulses]:
		pulses+=1
		_emit_pulse(battle)
		SortieRuntime.request_checkpoint()
	if elapsed>=DURATION:
		queue_free();SortieRuntime.request_checkpoint();return
	_refresh_visual()

func _emit_pulse(battle: Node3D) -> void:
	CombatNoise.emit_at(self,global_position,RADIUS,&"alarm")
	var observer:=PlayerVisibility.observer(self)
	if observer and observer.actor==battle.player:
		var gain:=observer.hear(global_position,RADIUS,&"alarm")
		if gain>0:
			AudioDirector.play_sfx(&"water_horn",linear_to_db(gain)-7.0)
			if pulses==1 and battle.player.interaction_component:
				battle.player.interaction_component.information_read.emit(tr(FIRST_RING))

func _refresh_visual() -> void:
	if not is_instance_valid(label) or not is_instance_valid(beacon):return
	label.text=tr("ALARM / ARMING" if pulses==0 else "ALARM / RINGING")
	var color:=Color("e2af54") if pulses==0 else Color("df6949")
	var material:=beacon.material_override as StandardMaterial3D
	material.albedo_color=color;material.emission=color;material.emission_enabled=int(elapsed*8)%2==0
	var battle:=get_parent() as Node3D
	var actor:=battle.get("player") as PlayerController if is_instance_valid(battle) else null
	label.visible=is_instance_valid(actor) and actor.global_position.distance_to(global_position)<=10.0 and PlayerVisibility.point_visible(self,global_position+Vector3.UP*.4)

func snapshot() -> Dictionary:
	return {"id":instance_id,"position":[global_position.x,global_position.y,global_position.z],"elapsed":elapsed,"pulses":pulses}

static func valid_snapshot(raw: Variant,battle: Node3D) -> bool:
	if typeof(raw)!=TYPE_DICTIONARY or raw.size()!=4:return false
	if typeof(raw.get("id"))!=TYPE_STRING or raw.id.is_empty() or raw.id.length()>128:return false
	if typeof(raw.get("position"))!=TYPE_ARRAY or raw.position.size()!=3:return false
	for coordinate in raw.position:
		if not SaveService.is_number(coordinate) or absf(coordinate)>1000000:return false
	if not SaveService.is_number(raw.get("elapsed")) or raw.elapsed<0 or raw.elapsed>=DURATION:return false
	if not SortieCheckpoint.integer(raw.get("pulses"),0,3):return false
	var expected:=0
	for time in PULSE_TIMES:
		if raw.elapsed>=time:expected+=1
	if raw.pulses!=expected or not is_instance_valid(battle):return false
	var session:SortieSession=battle.get("session")
	return session!=null and session.inventory!=null and session.status==SortieSession.Status.ACTIVE and not session.inventory.contains(raw.id)

static func restore_node(raw: Dictionary,battle: Node3D) -> PortableAlarm:
	if not valid_snapshot(raw,battle):return null
	var alarm:=PortableAlarm.new()
	alarm.instance_id=raw.id;alarm.elapsed=raw.elapsed;alarm.pulses=int(raw.pulses)
	alarm.position=battle.to_local(Vector3(raw.position[0],raw.position[1],raw.position[2]))
	battle.add_child(alarm)
	return alarm
