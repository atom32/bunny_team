class_name CampusRammer
extends "res://scripts/enemies/infected_controller.gd"
## One committed straight charge, not a homing attack or a larger health sponge.
enum Phase { HUNT, WINDUP, CHARGE, RECOVER, STUN }
const WINDUP:=.95
const SPEED:=15.0
const DISTANCE:=12.0
const SHIELD_PENETRATION:=16.0
var ram_phase:=Phase.HUNT
var ram_remaining:=0.0
var ram_direction:=Vector3.ZERO
var ram_traveled:=0.0
var wall_impacts:=0
var player_impacts:=0
var shield: MeshInstance3D
var lane: MeshInstance3D

func _build_visual() -> void:
	super._build_visual()
	shield=MeshInstance3D.new();shield.name="FrontShield"
	var plate:=BoxMesh.new();plate.size=Vector3(.75,1.0,.12);shield.mesh=plate
	shield.position=Vector3(0,.95,-.39);shield.material_override=VisualFactory.material(Color("627c86"),.6,.5)
	body_visual.add_child(shield)
	lane=MeshInstance3D.new();lane.name="CommittedChargeLane";lane.mesh=ImmediateMesh.new()
	var material:=StandardMaterial3D.new();material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;material.cull_mode=BaseMaterial3D.CULL_DISABLED;material.albedo_color=Color(1,.48,.1,.55)
	lane.material_override=material;lane.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(lane);lane.top_level=true;lane.hide()

func _movement_goal(_delta: float) -> Vector3:
	return awareness.destination(patrol_radius) if awareness.state!=EnemyAwareness.State.COMBAT else awareness.last_known

func _telegraph_shot() -> void:
	if ram_phase!=Phase.HUNT or is_dead or not is_instance_valid(target):return
	# Called only after the ordinary perception/range test. Never track after commit.
	ram_direction=global_position.direction_to(awareness.last_known);ram_direction.y=0;ram_direction=ram_direction.normalized()
	if ram_direction.length_squared()<.9:return
	ram_phase=Phase.WINDUP;ram_remaining=WINDUP;ram_traveled=0;_shot_cooldown=4
	CombatNoise.emit_at(self,global_position,18,&"impact");SortieRuntime.request_checkpoint()

func _on_safe_velocity(safe_velocity: Vector3) -> void:
	if ram_phase==Phase.HUNT:super._on_safe_velocity(safe_velocity)

func _physics_process(delta: float) -> void:
	if is_dead:
		if is_instance_valid(lane):lane.hide()
		if is_instance_valid(shield):shield.hide()
		return
	if ram_phase==Phase.HUNT:
		super._physics_process(delta);_refresh_ram();return
	velocity.x=0;velocity.z=0
	velocity.y=-.1 if is_on_floor() else velocity.y-24*delta
	ram_remaining=maxf(0,ram_remaining-delta)
	if ram_phase==Phase.WINDUP:
		_face_direction(ram_direction,delta)
		move_and_slide()
		if ram_remaining<=0:ram_phase=Phase.CHARGE;ram_remaining=DISTANCE/SPEED
	elif ram_phase==Phase.CHARGE:
		var before:=global_position
		velocity.x=ram_direction.x*SPEED;velocity.z=ram_direction.z*SPEED
		move_and_slide();ram_traveled+=Vector2(global_position.x-before.x,global_position.z-before.z).length()
		for index in get_slide_collision_count():
			var collision:=get_slide_collision(index)
			if absf(collision.get_normal().y)>.65:continue
			var hit:=collision.get_collider()
			if hit is PlayerController:
				hit.receive_damage(DamagePacket.new(attack_damage,0,0,self,&"enemy.campus_ram",&"enemy",hit.global_position,collision.get_normal(),ram_direction*1.8));player_impacts+=1;_recover(false)
			else:
				if hit is DestructibleWorldObject:hit.receive_damage(DamagePacket.new(0,0,24,self,&"enemy.campus_ram",&"enemy",collision.get_position(),collision.get_normal()))
				_recover(true)
			break
		if ram_phase==Phase.CHARGE and (ram_remaining<=0 or ram_traveled>=DISTANCE):_recover(false)
	else:
		move_and_slide()
		if ram_remaining<=0:
			ram_phase=Phase.HUNT;ram_remaining=0;ram_direction=Vector3.ZERO;ram_traveled=0;_shot_cooldown=1.3;SortieRuntime.request_checkpoint()
	_movement_direction=ram_direction if ram_phase==Phase.CHARGE else Vector3.ZERO
	_update_presentation(delta,global_position+ram_direction*8, SPEED if ram_phase==Phase.CHARGE else 0)
	_update_awareness_indicator();_refresh_ram()

func _recover(wall: bool) -> void:
	ram_phase=Phase.STUN if wall else Phase.RECOVER;ram_remaining=2.6 if wall else 1.6
	velocity.x=0;velocity.z=0
	if wall:
		wall_impacts+=1;presentation.play_hit();CombatNoise.emit_at(self,global_position,24,&"impact")
	SortieRuntime.request_checkpoint()

func receive_damage(packet: DamagePacket) -> float:
	var multiplier:=1.5 if ram_phase==Phase.STUN else 1.0
	if ram_phase!=Phase.STUN:
		# Shield response uses the actual impact trajectory, not hidden shooter intel.
		var incoming:=-packet.knockback_impulse;incoming.y=0
		if incoming.length_squared()>.001 and (-global_basis.z).dot(incoming.normalized())>.5 and packet.armor_penetration<SHIELD_PENETRATION:multiplier=.3
	var scaled:=DamagePacket.new(packet.base_damage*multiplier,packet.armor_penetration,packet.structure_damage,packet.source_actor,packet.source_weapon,packet.source_faction,packet.hit_position,packet.hit_normal,packet.knockback_impulse)
	return super.receive_damage(scaled)

func _die(impact: Vector3) -> void:
	shield.hide();lane.hide()
	super._die(impact)

func _refresh_ram() -> void:
	if not is_instance_valid(shield):return
	shield.rotation.x=.7 if ram_phase==Phase.STUN else 0
	var material:=shield.material_override as StandardMaterial3D
	material.albedo_color=Color("68bed0") if ram_phase==Phase.STUN else Color("627c86")
	lane.visible=ram_phase in [Phase.WINDUP,Phase.CHARGE] and not is_dead and PlayerVisibility.enemy_observed(self,self)
	if not lane.visible:return
	lane.global_transform=Transform3D(Basis.IDENTITY,global_position+Vector3.UP*.06)
	var length:=maxf(.05,DISTANCE-ram_traveled)
	var ray:=PhysicsRayQueryParameters3D.create(global_position+Vector3.UP,global_position+Vector3.UP+ram_direction*length,4)
	var hit:=get_world_3d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty():length=minf(length,global_position.distance_to(hit.position))
	var side:=ram_direction.cross(Vector3.UP)*.6
	var vertices:=PackedVector3Array()
	for segment in 24:
		var start:=ram_direction*length*float(segment)/24
		var end:=ram_direction*length*float(segment+1)/24
		var points:=[start-side,start+side,end+side,end-side]
		if not points.all(func(point):return PlayerVisibility.point_visible(self,lane.global_position+point)):continue
		for index in [0,1,2,0,2,3]:vertices.append(points[index])
	var mesh:=lane.mesh as ImmediateMesh;mesh.clear_surfaces()
	if vertices.is_empty():return
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for point in vertices:mesh.surface_add_vertex(point)
	mesh.surface_end()

func ram_snapshot() -> Dictionary:
	return {"phase":ram_phase,"remaining":ram_remaining,"direction":[ram_direction.x,ram_direction.y,ram_direction.z],"traveled":ram_traveled,"wall_impacts":wall_impacts,"player_impacts":player_impacts}

static func valid_ram(data: Variant) -> bool:
	if typeof(data)!=TYPE_DICTIONARY or data.size()!=6:return false
	if not SortieCheckpoint.integer(data.get("phase"),0,4) or not SortieCheckpoint.integer(data.get("wall_impacts"),0,10000) or not SortieCheckpoint.integer(data.get("player_impacts"),0,10000):return false
	if typeof(data.get("direction"))!=TYPE_ARRAY or data.direction.size()!=3 or not SaveService.is_number(data.get("remaining")) or not SaveService.is_number(data.get("traveled")):return false
	for value in data.direction:
		if not SaveService.is_number(value) or absf(value)>1.001:return false
	var direction:=Vector3(data.direction[0],data.direction[1],data.direction[2])
	if absf(direction.y)>.001 or data.traveled<0 or data.traveled>DISTANCE+.3:return false
	if data.phase==Phase.HUNT:return data.remaining==0 and direction==Vector3.ZERO and data.traveled==0
	if absf(direction.length()-1)>.001 or (data.phase==Phase.STUN and data.wall_impacts==0):return false
	var limit: float={Phase.WINDUP:WINDUP,Phase.CHARGE:DISTANCE/SPEED,Phase.RECOVER:1.6,Phase.STUN:2.6}[int(data.phase)]
	return data.remaining>=0 and data.remaining<=limit and (data.phase!=Phase.WINDUP or data.traveled==0)

func restore_ram(data: Dictionary) -> void:
	ram_phase=int(data.phase);ram_remaining=data.remaining;ram_direction=Vector3(data.direction[0],data.direction[1],data.direction[2]);ram_traveled=data.traveled;wall_impacts=int(data.wall_impacts);player_impacts=int(data.player_impacts);_refresh_ram()
