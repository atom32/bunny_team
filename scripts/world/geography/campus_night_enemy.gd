extends CharacterBody3D
## Fictional wheeled inspection sentry: authored patrol, LOS acquisition, locked
## telegraph, finite spawns. Shared player damage packets, world collision intact.
signal destroyed(enemy: Node3D)
var operation: Node3D
var room := ""
var id := ""
var role := "patrol"
var health := 60.0
var dead := false
var home:=Vector3.ZERO
var patrol:=PackedVector3Array()
var patrol_index:=0
var alert_left:=0.0
var acquired:=0.0
var cooldown:=1.5
var telegraph:=0.0
var shot_target:=Vector3.ZERO
var last_seen:=Vector3.ZERO
var body: Node3D
var lens: MeshInstance3D
var status: Label3D
var route:=PackedVector2Array()
var route_clock:=0.0
var age:=0.0
var shots:=0

func _ready() -> void:
	collision_layer=2;collision_mask=7;floor_snap_length=.5
	var shape:=CapsuleShape3D.new();shape.radius=.47;shape.height=1.7
	var hitbox:=CollisionShape3D.new();hitbox.shape=shape;hitbox.position.y=.85;add_child(hitbox)
	body=Node3D.new();add_child(body)
	VisualFactory.box(body,Vector3(.9,.55,1.1),Vector3(0,.50,0),Color("35474a"),"ArmoredChassis")
	VisualFactory.box(body,Vector3(.55,.6,.5),Vector3(0,1.07,0),Color("83918c"),"SensorMast")
	VisualFactory.box(body,Vector3(.72,.22,.48),Vector3(0,1.48,0),Color("425457"),"SensorHead")
	for x: float in [-.49,.49]:
		for z: float in [-.34,.34]:
			var wheel:=VisualFactory.cylinder(body,.20,.16,Vector3(x,.24,z),Color("232d30"),"Wheel");wheel.rotation.z=PI*.5
	lens=VisualFactory.box(body,Vector3(.48,.09,.05),Vector3(0,1.5,-.26),Color("eead5b"),"WarningLens")
	lens.material_override=VisualFactory.material(Color("f4b65e"),.3,.4,Color("f4b65e"),1.5)
	status=operation.label(self,"巡检机 / 待命",Vector3(0,2.05,0),Color("ecc278"))

func can_see() -> bool:
	var actor: Node3D=operation.survey.actor
	var delta:=actor.global_position-global_position
	if delta.length()>25:return false
	var flat:=Vector3(delta.x,0,delta.z).normalized()
	if delta.length()>3 and (-global_basis.z).dot(flat)<-.1:return false
	var q:=PhysicsRayQueryParameters3D.create(global_position+Vector3.UP*1.45,actor.global_position+Vector3.UP*1.05,5)
	q.exclude=[get_rid()]
	var hit:=get_world_3d().direct_space_state.intersect_ray(q)
	return not hit.is_empty() and hit.collider==actor

func receive_damage(packet: DamagePacket) -> float:
	if dead or not operation.running() or room!=operation.field.inside or packet.source_faction!=&"player":return 0
	var damage:=minf(health,packet.base_damage);health-=damage
	alert_left=9;last_seen=packet.source_actor.global_position if is_instance_valid(packet.source_actor) else home
	acquired=.7
	CombatEffects.hit(get_tree().current_scene,global_position+Vector3.UP,Color("f5cd87"),.85)
	if health<=0:
		dead=true;collision_layer=0;collision_mask=0
		body.rotation.z=PI*.5;body.position.y=-.25
		status.text="巡检机 / 已停机";status.modulate=Color("8d9d95")
		destroyed.emit(self)
	return damage

func _physics_process(delta: float) -> void:
	if dead or not operation.running() or operation.field.inside!=room:return
	age+=delta
	# Visible bodies are placed with the encounter; a two-second activation
	# grace avoids spawning a shot on entering a floor or loading an encounter.
	if age<2:status.text="巡检机 / 自检";return
	var seen:=can_see()
	acquired=clampf(acquired+(delta if seen else -delta*1.4),0,.7)
	if seen:last_seen=operation.survey.actor.global_position;alert_left=8
	else:alert_left=maxf(0,alert_left-delta)
	var engaged:=acquired>=.65
	cooldown=maxf(0,cooldown-delta)
	if telegraph>0:
		telegraph-=delta;velocity.x=0;velocity.z=0
		status.text="⚠ 锁定射击 / 侧移"
		if telegraph<=0:_shoot()
	elif engaged and cooldown<=0:
		shot_target=operation.survey.actor.global_position+Vector3.UP*1.05
		telegraph=.85;cooldown=2.8 if role=="guard" else 3.4
		CombatEffects.telegraph(get_tree().current_scene,global_position+Vector3.UP*1.45,shot_target,.85)
	else:
		status.text=("警戒 / %.0f"%health) if alert_left>0 else "巡逻 / "+("守卫" if role=="guard" else "机动")
		var goal:=last_seen if alert_left>0 else patrol[patrol_index]
		if alert_left<=0 and global_position.distance_to(goal)<.9:patrol_index=(patrol_index+1)%patrol.size()
		var offset:=goal-global_position;offset.y=0
		var desired:=Vector3.ZERO
		if offset.length()>(10.0 if engaged else .7):
			route_clock-=delta
			if route_clock<=0:
				route=operation.path_between(room,Vector2(global_position.x,global_position.z),Vector2(goal.x,goal.z));route_clock=1.2
			while route.size()>1 and Vector2(global_position.x,global_position.z).distance_to(route[0])<.8:route.remove_at(0)
			if route.size()>0:desired=Vector3(route[0].x-global_position.x,0,route[0].y-global_position.z).normalized()
		velocity.x=desired.x*(2.8 if alert_left>0 else 1.3);velocity.z=desired.z*(2.8 if alert_left>0 else 1.3)
		if offset.length()>.5:rotation.y=lerp_angle(rotation.y,atan2(-offset.x,-offset.z),1-exp(-delta*6))
	velocity.y=-.1 if is_on_floor() else velocity.y-24*delta
	move_and_slide()

func _shoot() -> void:
	if not operation.running() or room!=operation.field.inside:return
	var from:=global_position+Vector3.UP*1.45
	# Fire at the locked point, not the player's updated position. Walls block.
	var to:=from+from.direction_to(shot_target)*32
	var q:=PhysicsRayQueryParameters3D.create(from,to,5);q.exclude=[get_rid()]
	var hit:=get_world_3d().direct_space_state.intersect_ray(q)
	var at: Vector3=hit.position if not hit.is_empty() else to
	CombatEffects.tracer(get_tree().current_scene,from,at,Color("ffa460"),.05)
	CombatEffects.muzzle_flash(get_tree().current_scene,from,from.direction_to(to),Color("ffa460"),.55)
	AudioDirector.play_sfx(&"enemy_fire",-7)
	shots+=1
	if not hit.is_empty() and hit.collider==operation.survey.actor:
		operation.survey.actor.receive_damage(DamagePacket.new(14,0,0,self,&"campus.inspection_sentry",&"enemy",at,hit.normal))
