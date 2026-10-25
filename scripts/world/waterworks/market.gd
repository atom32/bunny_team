class_name WaterMarket
extends Node3D
## Optional south-market depot. Physical shutters and loot, not quest credit.
var isolated := false
var mode := 0 # 0 closed, 1 quiet opening, 2 alarm opening.
var progress := 0.0
var back_open := false

const INTRO := "Tang Kui: The repair shop. The little shutter.\nShen: We came for a pump battery.\nTang Kui: I know. I am looking with my mouth.\nSu Mi: The bell wire runs to the west stalls. Cut it there, or let the whole street hear you opening up.\n\nOptional depot: a 6kg salvage core and repair supplies. Leave 8kg for the pump battery. The main water route does not require this depot."
const QUIET := "[The shutter climbs. No bell.]\nTang Kui: See? I can be quiet.\nSu Mi: You are on the radio.\nTang Kui: ...Right."
const LOUD := "[The shutter rattles. A bell answers from the north street.]\nShen: Two coming down the loading lane.\nTang Kui: Put it down if you have to. Not you. The thing in your bag!"
const FRAME_NOTICE := "Tang Kui: Wait. On that workbench. The old carrier straps.\nSu Mi: Do not climb back in for a buckle.\nTang Kui: I said straps!\n\nInside the depot: one 3kg carrier frame. Bring it home to Su Mi for a light fast pack OR a heavy cargo frame. No extra materials needed; choose at base. Leave room for the pump battery."
const PORTABLE_ALARM := &"tool.portable_alarm"
const ALARM_NOTICE := "Su Mi: A spare bell box. Battery still in. Leave the wall bell alone.\nTang Kui: You told me to be quiet. Now she gets a portable bell?\nSu Mi: Hers waits three seconds.\n\nRecovered field tool / 1kg. Press %s to place the alarm box on clear ground. It rings three times after a 3-second delay, then stops. Placement consumes the box. Use it today, or bring it home to pack one next time."

func _ready() -> void:
	get_parent().refresh_waterworks_labels()

func carrier_hint() -> String:
	var cache:=get_parent().get_node("DepotParts") as LootSpawnPoint
	var has_frame:=not cache.has_rolled
	var has_alarm:=false
	for child in cache.get_children():
		if not child is LootPickup or child.consumed or child.is_queued_for_deletion():continue
		if child.item_instance.definition_id==RecoveredCarrier.FRAME:has_frame=true
		if child.item_instance.definition_id==PORTABLE_ALARM:has_alarm=true
	var current:=SortieRuntime.get_current_session()
	if current:
		for item in current.inventory.get_items():
			if item.definition_id==RecoveredCarrier.FRAME:has_frame=true
			if item.definition_id==PORTABLE_ALARM:has_alarm=true
	var notices:PackedStringArray=[]
	if has_frame:notices.append(tr(FRAME_NOTICE))
	if has_alarm:notices.append(tr(ALARM_NOTICE)%ControlBindings.label("place_alarm"))
	return "\n\n".join(notices) # Old opened depots only promise cargo that really exists.

func _physics_process(delta: float) -> void:
	if mode>0 and progress<1:
		progress=minf(1,progress+delta/2.2)
		apply_progress()
		if progress==1:SortieRuntime.request_checkpoint()

func available(actor: Node3D,current: SortieSession,point: Node3D) -> bool:
	return actor is PlayerController and not actor.is_dead and current!=null and current.status==SortieSession.Status.ACTIVE and current.waterworks.get("version",0)==3 and actor.global_position.distance_to(point.global_position)<=actor.interaction_component.interaction_radius

func operate(kind: String,actor: Node3D,current: SortieSession,point: Node3D) -> Dictionary:
	if not available(actor,current,point):return {"success":false,"message":"Move closer to the market equipment."}
	var message:=""
	if kind=="breaker":
		if isolated or mode!=0:return {"success":false,"message":"The depot bell circuit cannot be changed now."}
		isolated=true;message="Depot bell disconnected. The shutter can now open quietly."
	elif kind=="shutter":
		if mode!=0:return {"success":false,"message":"The depot shutter is already open or moving."}
		mode=1 if isolated else 2
		if mode==2:
			var battle:=get_parent().get_parent().get_parent()
			battle.spawn_reinforcement_group(&"water_market_alarm")
			CombatNoise.emit_at(self,$FrontGate.global_position,58,&"alarm")
			var sensor:=PlayerVisibility.observer(self)
			var gain:=sensor.hear($FrontGate.global_position,58,&"alarm") if sensor else 1.0
			if gain>0:AudioDirector.play_sfx(&"water_horn",linear_to_db(gain))
		message="Depot shutter rising / keep the opening clear."
	elif kind=="back_bar":
		if progress!=1 or back_open or actor.global_position.x<24 or actor.global_position.z<54:return {"success":false,"message":"The north bar releases only from inside the open depot."}
		back_open=true;message="Depot north exit unbarred. The loading lane is open."
	else:return {"success":false,"message":"Unknown market equipment."}
	apply_progress();SortieRuntime.request_checkpoint()
	var result:={"success":true,"message":message}
	if kind=="shutter":result["information"]=tr(QUIET if mode==1 else LOUD)
	return result

func apply_progress() -> void:
	$FrontGate.position.y=progress*3.3
	$NorthGate.position.y=3.3 if back_open else 0.0
	$FrontLink.enabled=progress==1
	$NorthLink.enabled=back_open
	$BellLight.visible=mode==2
	$BreakerHandle.rotation_degrees.z=-60 if isolated else 0
	for name in ["DepotCore","DepotParts"]:
		var cache:=get_parent().get_node(name) as LootSpawnPoint
		cache.enabled=progress==1
		if cache.enabled and not cache.has_rolled:
			var rng:=RandomNumberGenerator.new();rng.seed=4603 if name=="DepotCore" else 4604
			cache.spawn(rng)
			# Append only to a newly successful roll, never to an opened/restored box.
			# No RNG call: repair supplies, the carrier frame and core stay unchanged.
			if name=="DepotParts" and cache.has_rolled:
				var alarm:=LootSpawnPoint.LOOT_PICKUP_SCENE.instantiate() as LootPickup
				alarm.setup(ItemInstance.new(PORTABLE_ALARM))
				cache.add_child(alarm)
	get_parent().refresh_waterworks_labels()

func valid_checkpoint(entry: Dictionary,current: SortieSession,world: Dictionary) -> bool:
	if current.waterworks.get("version",0)!=3 or not SortieCheckpoint.integer(entry.mode,0,2) or entry.progress<0 or entry.progress>1:return false
	if entry.mode==0 and (entry.progress!=0 or entry.back_open):return false
	if entry.mode==1 and not entry.isolated:return false
	if entry.mode==2 and entry.isolated:return false
	if entry.back_open and entry.progress!=1:return false
	for name in ["MarketResponse0","MarketResponse1"]:
		if world.nodes.get(name,{}).get("has_spawned")!=(entry.mode==2):return false
	for name in ["DepotCore","DepotParts"]:
		var cache:Dictionary=world.nodes.get(name,{})
		if cache.get("enabled")!=(entry.progress==1) or cache.get("has_rolled")!=(entry.progress==1):return false
	return true
