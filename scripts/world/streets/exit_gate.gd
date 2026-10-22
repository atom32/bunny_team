class_name CampusExitGate
extends Node3D
## First-campus field action: an outside bolt OR a shot chain. No work timer,
## extra reward, permanent flag, healing or ammunition grant.
const GROUP:=&"campus_exit_chain"
const INTRO:="Tang Kui: Good news. The gate is not broken.\nShen: Bad news?\nTang Kui: The bolt is on the other side.\nSu Mi: Whoever locked it was very thoughtful.\nShen: Not yet. Follow the wall round before you shoot.\nTang Kui: ...I was already aiming."
const QUIET:="[The bolt comes free.]\nTang Kui: Leave it open.\nShen: It will not shut by itself.\nTang Kui: I know. ...Leave it open anyway.\nSu Mi: All right. Open it stays."
const LOUD:="[The chain snaps. Two voices answer beyond the gate.]\nTang Kui: ...Did it have to be that loud?\nSu Mi: The chain, or you?\nShen: Behind the wall. Both of you."
var mode:=0 # 0 bolted, 1 outside lever, 2 shot chain with finite response.
var introduced:=false

func _ready() -> void:
	# Render-only shutter rails/housing. Authored wall/door colliders stay intact.
	for x in [-2.45,2.45]:VisualFactory.box(self,Vector3(.16,2.9,.5),Vector3(x,1.45,0),Color("344845"),"ShutterRail")
	VisualFactory.box(self,Vector3(5.4,.3,.6),Vector3(0,2.8,0),Color("344845"),"ShutterHousing")
	for y in [.5,1.05,1.6,2.15]:VisualFactory.box($GateBody,Vector3(4.8,.035,.02),Vector3(0,y,-.19),Color("8caaa0"),"ShutterRib")
	# The real latch is on the outside. Its top-edge handle remains visible from
	# the normal overhead camera, rather than being buried behind the shutter.
	VisualFactory.box($GateBody,Vector3(.9,.1,.12),Vector3(0,2.65,.55),Color("e4bd63"),"OutsideBolt")
	VisualFactory.box($GateBody,Vector3(.12,.4,.16),Vector3(.25,2.85,.55),Color("e4bd63"),"BoltHandle")
	for x in [-.3,.3]:VisualFactory.box($GateBody,Vector3(.08,.23,.4),Vector3(x,2.65,.36),Color("627d76"),"BoltBracket")
	for entry in [["Guard0",Vector3(-1.2,0,5.3),1],["Guard1",Vector3(1.2,0,6.6),2]]:
		var point:=EnemySpawnPoint.new();point.name=entry[0];point.position=entry[1]
		point.initial_spawn=false;point.activation_group_id=GROUP;point.enemy_definition_id=&"prototype_basic_enemy";point.tactical_role=entry[2]
		add_child(point)
	GameLanguage.language_changed.connect(apply_progress)
	apply_progress()
	# Battle creates nearby plaque interactions after the area's _ready returns.
	# Apply the v8-only marker policy once those children actually exist.
	apply_progress.call_deferred()

func battle() -> Node3D:return get_parent().get_parent().get_parent()
func is_open() -> bool:return mode!=0
func closed_message() -> String:return tr("North gate bolted. Go round the end of the wall to the outside latch, or shoot the red chain. The other assigned retreat stays open.")

func available(current: SortieSession) -> bool:
	return current and current.status==SortieSession.Status.ACTIVE and current.area_id==&"street_district" and not current.slice_context.is_empty() and current.slice_context.get("quest_id")=="Q01"

func open_gate(kind: int,actor: PlayerController) -> bool:
	if mode!=0 or kind not in [1,2] or not is_instance_valid(actor) or actor.is_dead or not available(SortieRuntime.get_current_session()):return false
	if kind==2 and battle().spawn_reinforcement_group(GROUP)!=2:
		FlowMenu.show_error("Gate response could not spawn. Return to base to retry.",true);return false
	mode=kind;introduced=true;apply_progress()
	actor.interaction_component.interaction_finished.emit(tr("North gate open. The plaque still shows this sortie's records condition."),true)
	actor.interaction_component.information_read.emit(tr(QUIET if mode==1 else LOUD))
	if mode==2:CombatNoise.emit_at(self,global_position,52,&"gate_chain")
	AudioDirector.play_sfx(&"blockade_lock",-7)
	SortieRuntime.request_checkpoint()
	return true

func _physics_process(_delta: float) -> void:
	_refresh_markers()
	if introduced or not available(SortieRuntime.get_current_session()):return
	var actor: PlayerController=battle().player
	if is_instance_valid(actor) and actor.global_position.distance_to(global_position)<20:
		introduced=true;actor.interaction_component.information_read.emit(tr(INTRO));SortieRuntime.request_checkpoint()

func apply_progress() -> void:
	# Only the new physical-gate instance owns these markers. Old layouts and
	# every other exit keep their original name/plaque presentation unchanged.
	var exit:=get_parent().get_node_or_null("Exit2")
	if exit:
		for label in exit.find_children("*","Label3D",true,false):label.visible=false
	$GateBody.position.y=3.5 if is_open() else 0.0
	$GateBody.visible=not is_open()
	$GateLink.enabled=is_open()
	$Chain.visible=not is_open()
	$Chain/CollisionShape3D.set_deferred("disabled",is_open() or $Chain.destroyed)
	$OutsideLatch/WorldLabel.text=tr("OUTSIDE BOLT / OPEN" if is_open() else "OUTSIDE BOLT / RELEASE")
	$GateLabel.text=tr("NORTH GATE / OPEN" if is_open() else "NORTH GATE / OUTSIDE BOLT")
	$Chain/WorldLabel.text=tr("RED CHAIN / SHOOT")
	_refresh_markers()

func _refresh_markers() -> void:
	var actor:=get_tree().get_first_node_in_group("player") as PlayerController
	var nearby: bool=is_instance_valid(actor) and actor.global_position.distance_to(global_position)<14
	var outside: bool=is_instance_valid(actor) and to_local(actor.global_position).z>.7
	$OutsideLatch/WorldLabel.visible=nearby and outside and not is_open()
	$Chain/WorldLabel.visible=nearby and not outside and not is_open()
	$GateLabel.visible=nearby and (not outside or is_open())

func carve_navigation(source: NavigationMesh) -> NavigationMesh:
	# Cut the real wall footprint out of a copy of the authored grid. The closed
	# gate cannot be routed through; an ordinary bidirectional link opens with it.
	var blocked:=Rect2();var first:=true
	for path in ["GateBody/CollisionShape3D","WestWing/CollisionShape3D","EastWing/CollisionShape3D"]:
		var collider:=get_node(path) as CollisionShape3D
		var size: Vector3=(collider.shape as BoxShape3D).size
		for x in [-size.x/2,size.x/2]:
			for z in [-size.z/2,size.z/2]:
				var p:=collider.to_global(Vector3(x,0,z));var flat:=Vector2(p.x,p.z)
				if first:blocked=Rect2(flat,Vector2.ZERO);first=false
				else:blocked=blocked.expand(flat)
	blocked=blocked.grow(.55)
	var result:=source.duplicate() as NavigationMesh;result.clear_polygons()
	var vertices:=source.get_vertices()
	for index in source.get_polygon_count():
		var polygon:=source.get_polygon(index);var p:=vertices[polygon[0]];var bounds:=Rect2(Vector2(p.x,p.z),Vector2.ZERO)
		for vertex in polygon:
			p=vertices[vertex];bounds=bounds.expand(Vector2(p.x,p.z))
		if not blocked.intersects(bounds):result.add_polygon(polygon)
	return result

func valid_checkpoint(entry: Dictionary,current: SortieSession,world: Dictionary) -> bool:
	if not available(current) or int(world.map_revision)!=8 or not SortieCheckpoint.integer(entry.get("mode"),0,2) or typeof(entry.get("introduced"))!=TYPE_BOOL:return false
	if entry.mode>0 and not entry.introduced:return false
	var chain: Dictionary=world.nodes.get("CampusExitGate/Chain",{})
	if chain.get("destroyed")!=(entry.mode==2):return false
	for name in ["Guard0","Guard1"]:
		if world.nodes.get("CampusExitGate/"+name,{}).get("has_spawned")!=(entry.mode==2):return false
	return entry.mode!=0 or not "streets_exit_2" in world.exit_observations
