class_name CampusSupplyHandoff
extends Node3D
## A field handoff, not another inventory charge or a defend-for-N-seconds task.
enum Phase { WAITING, MOVING, RECEIVED }
var phase := Phase.WAITING
var progress := 0.0
var introduced := false # Presentation only; hearing a radio line never changes progress.
const GUARDS := ["WestGuard", "EastGuard"]
const INTRO := "Tang Kui: They still will not leave the dormitory.\nShen: I know.\nTang Kui: Then why are we giving them guns?\nShen: Because I cannot carry everyone home.\n[Her radio clicks off. Then on.]\nShen: Get this lot through the south window first."
const RECEIVED := "[The crate scrapes across the sill. Someone catches the far end.]\nVoice inside: This vest is a bit big.\nShen: Can you lift your arms?\nVoice inside: Yes.\nShen: Try running.\nVoice inside: You told us not to go outside.\nShen: ...Inside. Run inside.\nTang Kui: Watch the soup!"

func _ready() -> void:
	add_to_group("interactable")
	if SortieRuntime.get_current_session().campus.version>=5:
		var link:=NavigationLink3D.new()
		link.name="HandoffDoorLink";link.start_position=Vector3(0,.03,-5.2);link.end_position=Vector3(0,.03,.4);link.enabled=false
		add_child(link)
	for entry in [["WestGuard",Vector3(-8,0,3),&"prototype_basic_enemy",1],["EastGuard",Vector3(7,0,4),&"prototype_basic_enemy",2],["WestInfected",Vector3(-13,0,-11),&"campus_infected",3]]:
		var point := EnemySpawnPoint.new()
		point.name=entry[0];point.position=entry[1];point.enemy_definition_id=entry[2];point.tactical_role=entry[3]
		point.rotation.y=PI;add_child(point)
	var profile: PresentationProfile=load("res://resources/presentation/subjects_female/campus_subject_profile.tres")
	var model: Node3D=profile.model.instantiate()
	model.name="Resident";model.position=Vector3(.6,0,-3.0);model.rotation.y=profile.forward_yaw+PI;model.scale=Vector3.ONE*profile.model_scale
	add_child(model)
	for player: AnimationPlayer in model.find_children("*","AnimationPlayer",true,false):player.autoplay="";player.stop();player.active=false
	var animation:=AnimationPlayer.new();model.add_child(animation);animation.add_animation_library(&"",profile.animation_library);animation.play(profile.semantic_clips[&"idle"])
	refresh_visual()

func _battle() -> Node3D:
	return get_parent().get_parent().get_parent()

func threats_remaining() -> int:
	var battle:=_battle()
	if not "enemy_container" in battle or not is_instance_valid(battle.enemy_container):return GUARDS.size()
	var remaining:=0
	for name in GUARDS:
		var point:=get_node(name) as EnemySpawnPoint
		if not point.has_spawned:remaining+=1;continue
		var key:=String(get_parent().get_path_to(point))
		for enemy in battle.enemy_container.get_children():
			if enemy is EnemyController and not enemy.is_dead and enemy.get_meta("spawn_key","")==key:remaining+=1;break
	return remaining

func interact(actor: Node3D,current: SortieSession) -> Dictionary:
	if not actor is PlayerController or actor.is_dead or not current or current.status!=SortieSession.Status.ACTIVE or current.campus.get("version",0)<4 or current.campus.get("stage")!="supply":return {"success":false,"message":"Campus handoff unavailable."}
	if actor.global_position.distance_to(global_position)>actor.interaction_component.interaction_radius:return {"success":false,"message":"Move closer to the dormitory handoff window."}
	if not current.campus.gear_ready:return {"success":false,"message":"Pack the spare armor and 60 standard rounds at base first."}
	if phase!=Phase.WAITING:return {"success":false,"message":"The supplies are already moving or received."}
	if threats_remaining()>0:return {"success":false,"message":"Two gunmen cover the window. Flank them; the rest of campus need not be cleared.","information":tr(INTRO)}
	phase=Phase.MOVING;refresh_visual();SortieRuntime.request_checkpoint()
	return {"success":true,"message":"Window open. The packed equipment is moving inside; no second payment."}

func _physics_process(delta: float) -> void:
	var current:=SortieRuntime.get_current_session()
	if not current or current.status!=SortieSession.Status.ACTIVE:return
	var battle:=_battle()
	if phase==Phase.WAITING and current.campus.gear_ready and not introduced and is_instance_valid(battle.player) and battle.player.global_position.distance_to(global_position)<20:
		introduced=true;battle.player.interaction_component.information_read.emit(tr(INTRO))
	if phase!=Phase.MOVING:return
	# One short physical transfer. The player may move and fight throughout it.
	progress=minf(1,progress+delta/2.4);refresh_visual()
	if progress<1:return
	phase=Phase.RECEIVED;current.campus.supply_received=true;refresh_visual()
	if is_instance_valid(battle.player):battle.player.interaction_component.information_read.emit(tr(RECEIVED))
	battle._sync_objective_hud();SortieRuntime.request_checkpoint()

func refresh_visual() -> void:
	var current:=SortieRuntime.get_current_session()
	$Cargo.visible=current!=null and current.campus.get("gear_ready",false)
	$Shutter.position.y=1.35+minf(progress*3,1)*2.3
	var link:=get_node_or_null("HandoffDoorLink") as NavigationLink3D
	if link:link.enabled=progress>=1.0/3.0
	$Cargo.position.z=lerpf(-.6,-4.0,maxf(0,(progress-.3)/.7))
	$Handle.rotation_degrees.z=-65 if phase!=Phase.WAITING else 0
	$WorldLabel.text=tr("DORMITORY / SUPPLIES RECEIVED" if phase==Phase.RECEIVED else "DORMITORY SOUTH / HANDOFF WINDOW")

func get_interaction_prompt(_actor: Node3D,current: SortieSession) -> String:
	if not current or current.status!=SortieSession.Status.ACTIVE:return ""
	if phase==Phase.RECEIVED:return tr("Supplies received / extract safely")
	if phase==Phase.MOVING:return tr("The crate is moving inside / you can move and fight")
	if not current.campus.gear_ready:return tr("Pack the spare armor and 60 standard rounds at base first.")
	return ControlBindings.label("interact")+"  "+tr("CLEAR THE TWO WINDOW GUNMEN" if threats_remaining()>0 else "OPEN HANDOFF WINDOW / SEND PACKED EQUIPMENT")

func valid_checkpoint(entry: Dictionary,current: SortieSession,world: Dictionary) -> bool:
	if current.campus.get("version",0)<4 or current.campus.get("stage")!="supply" or not SortieCheckpoint.integer(entry.phase,0,2) or entry.progress<0 or entry.progress>1:return false
	if (entry.phase==Phase.WAITING and entry.progress!=0) or (entry.phase==Phase.MOVING and entry.progress>=1) or (entry.phase==Phase.RECEIVED and entry.progress!=1):return false
	if current.campus.supply_received!=(entry.phase==Phase.RECEIVED):return false
	if entry.phase!=Phase.WAITING and not current.campus.gear_ready:return false
	var prefix:=String(get_parent().get_path_to(self))+"/"
	for name in ["WestGuard","EastGuard","WestInfected"]:
		if world.nodes.get(prefix+name,{}).get("has_spawned")!=true:return false
	for name in GUARDS:
		if entry.phase!=Phase.WAITING and world.enemies.has(prefix+name):return false
	return true
