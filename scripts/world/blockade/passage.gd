class_name BlockadePassage
extends Node3D
var service_open:=false
var escape_started:=false
var escape_progress:=0.0

func _battle() -> Node:return get_parent().get_parent().get_parent()
func _session() -> SortieSession:return SortieRuntime.get_current_session()

func message(text: String) -> void:
	var battle:=_battle()
	if is_instance_valid(battle.player):battle.player.interaction_component.information_read.emit(tr(text))

func alarm() -> void:
	var session:=_session()
	if not session or session.status!=SortieSession.Status.ACTIVE or session.blockade.is_empty() or session.blockade.alarm:return
	session.blockade.alarm=true
	_battle().spawn_reinforcement_group(&"blockade_alarm")
	CombatNoise.emit_at(get_parent().get_node("Searchlight"),get_parent().get_node("Searchlight").global_position,35,&"alarm")
	var sensor:=PlayerVisibility.observer(self)
	var gain:=sensor.hear(get_parent().get_node("Searchlight").global_position,35,&"alarm") if sensor else 0.0
	if gain>0:AudioDirector.play_sfx(&"water_horn",linear_to_db(gain)-4)
	get_parent().get_node("Searchlight").refresh_visual()
	message(BlockadeJourney.ALARM);SortieRuntime.request_checkpoint()

func open_service() -> bool:
	if service_open or not _session() or _session().status!=SortieSession.Status.ACTIVE:return false
	service_open=true;refresh_hardware();message(BlockadeJourney.SERVICE)
	AudioDirector.play_sfx(&"blockade_lock",-5);SortieRuntime.request_checkpoint();return true

func van_disabled() -> void:
	var session:=_session()
	session.blockade.van_down=true
	get_parent().get_node("Searchlight").exposure=0
	_battle().spawn_reinforcement_group(&"blockade_escape")
	message(BlockadeJourney.DOWN);refresh_hardware();_battle()._sync_objective_hud()

func start_escape() -> bool:
	var session:=_session()
	if not session or session.status!=SortieSession.Status.ACTIVE or session.blockade.is_empty() or not session.blockade.van_down or escape_started:return false
	escape_started=true;message(BlockadeJourney.OPENING)
	AudioDirector.play_sfx(&"blockade_lock",-4);SortieRuntime.request_checkpoint();return true

func _physics_process(delta: float) -> void:
	if not escape_started or escape_progress>=1 or not _session() or _session().status!=SortieSession.Status.ACTIVE:return
	escape_progress=minf(1,escape_progress+delta*.65);refresh_hardware()
	if escape_progress==1:
		var session:=_session();session.blockade.escape_open=true
		session.record_objective_interaction(&"blockade_van")
		get_parent().get_node("Van").objective_interacted.emit(&"blockade_van")
		message(BlockadeJourney.CLEAR);SortieRuntime.request_checkpoint()

func refresh_hardware() -> void:
	var root:=get_parent()
	root.get_node("ServiceGate").position.y=4 if service_open else 0
	root.get_node("ServiceLink").enabled=service_open
	root.get_node("StreetGate").position.y=4 if root.get_node("StreetChain").destroyed else 0
	root.get_node("StreetLink").enabled=root.get_node("StreetChain").destroyed
	root.get_node("EscapeGate").position.y=5*escape_progress
	root.get_node("EscapeLink").enabled=escape_progress==1
	root.get_node("ServiceLever/Lever").rotation.x=-.8 if service_open else .4
	root.get_node("EscapeLever/Lever").rotation.x=-.8 if escape_started else .4
	root.refresh_route_labels()

func valid_checkpoint(entry: Dictionary,session: SortieSession,world: Dictionary) -> bool:
	if session.blockade.is_empty() or entry.escape_progress<0 or entry.escape_progress>1:return false
	if entry.escape_progress>0 and not entry.escape_started:return false
	if (entry.escape_started or entry.escape_progress>0) and not session.blockade.van_down:return false
	if (entry.escape_progress==1)!=session.blockade.escape_open:return false
	for pair in [["Alarm0",session.blockade.alarm],["Alarm1",session.blockade.alarm],["EscapeRam",session.blockade.van_down],["EscapeFollower",session.blockade.van_down]]:
		var data: Variant=world.nodes.get(pair[0])
		if typeof(data)!=TYPE_DICTIONARY or data.get("has_spawned")!=pair[1]:return false
	return true
