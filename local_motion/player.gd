extends "res://scripts/player/player_controller.gd"
## CombatGirls v1.2 runtime adapter; bundled motion provenance: local_motion/NOTICE.md.
const LOCAL_LIBRARY := "res://local_motion/library.tres"
const ROOT_CLIPS := {"Idle":"Idle_Gun","Walk":"Walk","Run":"Run","Dodge":"Dodge","Reload":"Reload","AimIdle":"AimIdle","WalkBack":"WalkBack","WalkRelaxed":"WalkRelaxed","TakeGun":"TakeGun","PutGun":"PutGun","Holstered":"PutGun","WalkFL":"WalkFL","WalkFR":"WalkFR","WalkBL":"WalkBL","WalkBR":"WalkBR"}
const UPPER_BONES := ["Spine","Spine1","Spine2","Neck","Head","LeftShoulder","LeftArm","LeftForeArm","LeftHand","RightShoulder","RightArm","RightForeArm","RightHand"]
var local_motion_usage := {}
var local_motion_events := {"fire":0,"damage":0,"dodge":0,"take":0,"put":0,"interrupt":0}
var _local_library: AnimationLibrary
var _combat12 := false
var _directional16 := false
var _local_states: Array[String]=[]
var _shoot_elapsed := 10.0
var _hit_elapsed := 10.0
var _evade_elapsed := 10.0
var _was_dodging := false
var _switch_clip := ""
var _switch_elapsed := 0.0
var _holstered := false

func _ready() -> void:
	super._ready()
	weapon_fired.connect(func(_strength: float):_shoot_elapsed=0;local_motion_events.fire+=1)
	damage_received.connect(func(_packet: DamagePacket,amount: float):
		if amount>0:_hit_elapsed=0;local_motion_events.damage+=1;_cancel_holster())
	if _combat12 and not InputMap.has_action("local_holster"):
		InputMap.add_action("local_holster")
		var key:=InputEventKey.new();key.physical_keycode=KEY_V
		InputMap.action_add_event("local_holster",key)

func _unhandled_input(event: InputEvent) -> void:
	if _combat12 and not preview_mode and not aim_input_captured and not is_dead and not event.is_echo() and event.is_action_pressed("local_holster"):
		if get_reload_remaining()<=0 and combat_rig.has_weapon():
			_begin_holster("TakeGun" if _holstered or _switch_clip=="PutGun" else "PutGun")
		get_viewport().set_input_as_handled();return
	super._unhandled_input(event)

func _physics_process(delta: float) -> void:
	# Never let a presentation leave a hidden/behind-the-back firing origin.
	if not aim_input_captured and (_fire_queued or Input.is_action_pressed("fire") or Input.is_action_just_pressed("dodge") or get_reload_remaining()>0):_cancel_holster()
	super._physics_process(delta)

func _try_fire() -> bool:
	_cancel_holster()
	return super._try_fire()

func reload_weapon() -> bool:
	_cancel_holster()
	return super.reload_weapon()

func _activate_weapon_slot(slot: StringName) -> bool:
	var ok:=super._activate_weapon_slot(slot)
	if ok and _combat12:_begin_holster("TakeGun")
	return ok

func _die(impulse: Vector3) -> void:
	_cancel_holster();super._die(impulse)

func _combat_facing_rotation(locomotion_direction: Vector3) -> float:
	# Six authored aim-relative strides require an aim-facing lower body.
	# Leave the original locomotion policy and physical dodge untouched otherwise.
	if _directional16 and Input.is_action_pressed("precision_walk") and _dodge_time<=0 and not _holstered and _switch_clip.is_empty() and combat_rig and combat_rig.has_weapon():
		return atan2(-aim_direction.x,-aim_direction.z)
	return super._combat_facing_rotation(locomotion_direction)

func _aim_stride() -> String:
	var forward:=Vector3(aim_direction.x,0,aim_direction.z).normalized()
	var motion:=Vector3(velocity.x,0,velocity.z).normalized()
	var along:=motion.dot(forward)
	var side:=motion.dot(forward.cross(Vector3.UP))
	if absf(side)<.4:return "WalkBack" if along<0 else "Walk"
	return ("WalkB" if along<0 else "WalkF")+("L" if side<0 else "R")

func _begin_holster(clip: String) -> void:
	_switch_clip=clip;_switch_elapsed=0
	local_motion_events["take" if clip=="TakeGun" else "put"]+=1
	if clip=="TakeGun":_holstered=true

func _cancel_holster() -> void:
	if _switch_clip.is_empty() and not _holstered:return
	_switch_clip="";_holstered=false;local_motion_events.interrupt+=1
	if is_instance_valid(equipped_weapon_visual):equipped_weapon_visual.show()
	if is_instance_valid(combat_rig):combat_rig.reset_presentation_pose()

func _build_character_animation_player(sk: Skeleton3D) -> AnimationPlayer:
	var player:=super._build_character_animation_player(sk)
	var original:=player.get_animation_library(&"")
	_local_library=load(LOCAL_LIBRARY) as AnimationLibrary
	assert(_local_library and _local_library.get_animation_list().size() in [3,12,16])
	_combat12=_local_library.get_animation_list().size()>=12
	_directional16=_local_library.get_animation_list().size()==16
	for alias in _local_library.get_animation_list():
		local_motion_usage[String(alias)]=0
		var target: StringName=&"Idle_Gun" if alias==&"Idle" else alias
		if original.has_animation(target):original.remove_animation(target)
		original.add_animation(target,_local_library.get_animation(alias).duplicate(true))
	return player

func _build_locomotion_tree() -> void:
	super._build_locomotion_tree()
	var states:=animation_tree.tree_root as AnimationNodeStateMachine
	_local_states.assign(["Idle","Walk","Run","Dodge","Reload"])
	if _combat12:_local_states.append_array(["AimIdle","WalkBack","WalkRelaxed","TakeGun","PutGun","Holstered"])
	if _directional16:_local_states.append_array(["WalkFL","WalkFR","WalkBL","WalkBR"])
	for state in _local_states:
		if state not in ["Idle","Walk","Run","Dodge"]:
			var clip:=AnimationNodeAnimation.new();clip.animation=ROOT_CLIPS[state]
			var tree:=AnimationNodeBlendTree.new();tree.add_node(&"Clip",clip);tree.add_node(&"Cadence",AnimationNodeTimeScale.new())
			tree.connect_node(&"Cadence",0,&"Clip");tree.connect_node(&"output",0,&"Cadence");states.add_node(state,tree)
		var tree:=states.get_node(state) as AnimationNodeBlendTree
		var previous: StringName=&"Cadence"
		tree.disconnect_node(&"output",0)
		if state=="Dodge" and _combat12:
			tree.add_node(&"EvadeSeek",AnimationNodeTimeSeek.new());tree.connect_node(&"EvadeSeek",0,previous);previous=&"EvadeSeek"
		if state=="Holstered":
			tree.add_node(&"Hold",AnimationNodeTimeSeek.new());tree.connect_node(&"Hold",0,previous);previous=&"Hold"
		for layer in ["Reload","Shoot","Hit","Dodge","PutGun"]:
			if not _local_library.has_animation(layer):continue
			var clip:=AnimationNodeAnimation.new();clip.animation=layer
			var blend:=AnimationNodeBlend2.new();blend.filter_enabled=true
			for bone in UPPER_BONES:blend.set_filter_path(NodePath(".:Character1_"+bone),true)
			for side in ["Left","Right"]:
				for finger in ["Thumb","Index","Middle","Ring","Pinky"]:
					for joint in range(1,4):blend.set_filter_path(NodePath(".:Character1_"+side+"Hand"+finger+str(joint)),true)
			tree.add_node(layer+"Clip",clip);tree.add_node(layer+"Seek",AnimationNodeTimeSeek.new());tree.add_node(layer+"Blend",blend)
			tree.connect_node(layer+"Seek",0,layer+"Clip");tree.connect_node(layer+"Blend",0,previous);tree.connect_node(layer+"Blend",1,layer+"Seek");previous=StringName(layer+"Blend")
		tree.connect_node(&"output",0,previous)
	for from in _local_states:
		for to in _local_states:
			if from==to or (from in ["Idle","Walk","Run","Dodge"] and to in ["Idle","Walk","Run","Dodge"]):continue
			var transition:=AnimationNodeStateMachineTransition.new();transition.xfade_time=.1
			states.add_transition(from,to,transition)

func _count(alias: String) -> void:
	if not local_motion_usage.has(alias):return
	if local_motion_usage[alias]==0:print("LOCAL_RIFLE_ACTUAL_STATE ",alias)
	local_motion_usage[alias]+=1

func _layer(state: String,alias: String,weight: float,time: float) -> void:
	if not _local_library.has_animation(alias):return
	animation_tree.set("parameters/%s/%sBlend/blend_amount"%[state,alias],weight)
	if weight>0:animation_tree.set("parameters/%s/%sSeek/seek_request"%[state,alias],time)

func _animate_stride(delta: float) -> void:
	if not locomotion_playback:return
	_shoot_elapsed+=delta;_hit_elapsed+=delta;_evade_elapsed+=delta
	var dodging:=_dodge_time>0
	if dodging and not _was_dodging:_evade_elapsed=0;local_motion_events.dodge+=1
	_was_dodging=dodging
	var speed:=Vector2(velocity.x,velocity.z).length()
	var moving:=speed>.4
	var reloading:=combat_rig and combat_rig.is_reloading()
	if not _switch_clip.is_empty():
		_switch_elapsed+=delta
		if _switch_clip=="PutGun" and _switch_elapsed>=.49282077:_holstered=true
		if _switch_clip=="TakeGun" and _switch_elapsed>=.086127274:_holstered=false
		if _switch_elapsed>=_local_library.get_animation(_switch_clip).length:_switch_clip=""
	if is_instance_valid(equipped_weapon_visual) and _combat12:equipped_weapon_visual.visible=not _holstered
	var state: String="Idle"
	if dodging:state="Dodge"
	elif not _switch_clip.is_empty():state=_switch_clip
	elif _holstered:state=("Run" if speed>=2.6 else "WalkRelaxed") if moving else "Holstered"
	elif reloading and not moving:state="Reload"
	elif moving:
		if Input.is_action_pressed("precision_walk"):
			state=_aim_stride() if _directional16 else ("WalkBack" if _combat12 and velocity.dot(aim_direction)<-.2 else "Walk")
		else:state="WalkRelaxed" if _combat12 and speed<2.6 else "Run"
	elif _combat12 and (Input.is_action_pressed("precision_walk") or _shoot_elapsed<.3):state="AimIdle"
	if locomotion_playback.get_current_node()!=StringName(state):locomotion_playback.travel(state)
	if state=="Reload":animation_tree.set("parameters/Reload/Cadence/scale",animation_player.get_animation(&"Reload").length/combat_rig.reload_duration)
	if state=="Holstered":
		animation_tree.set("parameters/Holstered/Cadence/scale",0.0);animation_tree.set("parameters/Holstered/Hold/seek_request",_local_library.get_animation(&"PutGun").length)
	var evade_source:=minf(_evade_elapsed/.16,1.0)*.2 if _evade_elapsed<.16 else lerpf(.2,animation_player.get_animation(&"Dodge").length,smoothstep(.16,.48,_evade_elapsed))
	if dodging:
		if _combat12:
			animation_tree.set("parameters/Dodge/Cadence/scale",0.0)
			animation_tree.set("parameters/Dodge/EvadeSeek/seek_request",evade_source)
	for candidate in _local_states:
		_layer(candidate,"Reload",1.0 if reloading and moving and not dodging else 0.0,clampf(combat_rig._reload_elapsed/combat_rig.reload_duration,0,1)*animation_player.get_animation(&"Reload").length if reloading else 0.0)
		_layer(candidate,"Shoot",maxf(0,1-_shoot_elapsed/.28) if not reloading else 0.0,minf(_shoot_elapsed/.28,1)*(_local_library.get_animation(&"Shoot").length if _combat12 else 0))
		_layer(candidate,"Hit",.65*sin(clampf(_hit_elapsed/.55,0,1)*PI) if _hit_elapsed<.55 else 0.0,minf(_hit_elapsed/.55,1)*(_local_library.get_animation(&"Hit").length if _combat12 else 0))
		_layer(candidate,"PutGun",1.0 if _holstered and _switch_clip.is_empty() else 0.0,_local_library.get_animation(&"PutGun").length if _combat12 else 0.0)
		_layer(candidate,"Dodge",.5*(1-smoothstep(.16,.48,_evade_elapsed)) if not dodging and _evade_elapsed<.48 else 0.0,evade_source)
	for walk in ["Walk","WalkBack","WalkRelaxed","Run","WalkFL","WalkFR","WalkBL","WalkBR"]:
		if not _local_states.has(walk):continue
		var clip:=animation_player.get_animation(walk)
		if not clip.has_meta("driver_nominal_speed"):continue
		var driver_leg:=animation_source_skeleton.get_bone_global_rest(animation_source_skeleton.find_bone("Character1_Hips")).origin.distance_to(animation_source_skeleton.get_bone_global_rest(animation_source_skeleton.find_bone("Character1_LeftFoot")).origin)
		var target_leg:=character_skeleton.get_bone_global_rest(character_skeleton.find_bone("Character1_Hips")).origin.distance_to(character_skeleton.get_bone_global_rest(character_skeleton.find_bone("Character1_LeftFoot")).origin)
		var cadence:=speed/maxf(float(clip.get_meta("driver_nominal_speed"))*target_leg/driver_leg,.01)
		var path:="parameters/%s/Cadence/scale"%walk;animation_tree.set(path,lerpf(float(animation_tree.get(path)),maxf(cadence,.1),1-exp(-10*delta)))
	combat_rig.motion_mode=_switch_clip if not _switch_clip.is_empty() else ("Holstered" if _holstered else ("Dodge" if dodging else ""))
	combat_rig.stride_mode=state
	combat_rig.motion_time=_switch_elapsed
	_count("Idle" if state=="Idle" else ("PutGun" if state=="Holstered" else state))
	if reloading and moving:_count("Reload")
	if _combat12 and _shoot_elapsed<.28:_count("Shoot")
	if _combat12 and _hit_elapsed<.55:_count("Hit")
