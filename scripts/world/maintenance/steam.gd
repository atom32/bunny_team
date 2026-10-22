class_name MaintenanceSteam
extends Node3D
const PERIOD:=4.8
var cycle_time:=0.0
var hit_cooldown:=0.0
var warned:=false
var followed:=false

func isolated() -> bool:
	var session:=SortieRuntime.get_current_session()
	return session and not session.maintenance.is_empty() and session.maintenance.steam_off

func phase() -> int:
	if isolated() or cycle_time<2.4:return 0
	return 1 if cycle_time<3.2 else 2

func _ready() -> void:add_to_group("maintenance_steam")

func _physics_process(delta: float) -> void:
	var session:=SortieRuntime.get_current_session()
	if not session or session.status!=SortieSession.Status.ACTIVE:return
	if isolated():hit_cooldown=0;refresh();return
	var previous_phase:=phase()
	cycle_time=fmod(cycle_time+delta,PERIOD);hit_cooldown=maxf(0,hit_cooldown-delta)
	if phase()==2 and previous_phase!=2:
		var sensor:=PlayerVisibility.observer(self)
		var gain:=sensor.hear(Vector3(0,1,-13),18,&"steam") if sensor else 0.0
		if gain>0:AudioDirector.play_sfx(&"blockade_vent",linear_to_db(gain)-8)
	var actor:=get_tree().get_first_node_in_group("player") as PlayerController
	if actor and not actor.is_dead and phase()==2 and hit_cooldown==0 and MaintenanceJourney.ZONE.has_point(Vector2(actor.global_position.x,actor.global_position.z)):
		actor.receive_damage(DamagePacket.new(6,0,0,self,&"maintenance_steam",&"world",actor.global_position));hit_cooldown=.5
	refresh()

func close_valve(actor: PlayerController) -> bool:
	var session:=SortieRuntime.get_current_session()
	if not session or session.status!=SortieSession.Status.ACTIVE or session.maintenance.is_empty() or isolated() or not MaintenanceStory.done(session,&"maintenance_bypass"):return false
	session.maintenance.steam_off=true;hit_cooldown=0
	get_parent().refresh_maintenance();actor.interaction_component.information_read.emit(tr(MaintenanceJourney.CLOSED))
	AudioDirector.play_sfx(&"blockade_vent",-5);SortieRuntime.request_checkpoint();return true

func warn_blocked(actor: PlayerController) -> void:
	if warned or isolated():return
	warned=true;actor.interaction_component.information_read.emit(tr(MaintenanceJourney.WARNING));SortieRuntime.request_checkpoint()

func notify_follow(actor: PlayerController) -> void:
	if not warned or followed or not isolated():return
	followed=true;actor.interaction_component.information_read.emit(tr(MaintenanceJourney.FOLLOW));SortieRuntime.request_checkpoint()

func refresh() -> void:
	$Jets.visible=phase()==2
	$Warning.visible=phase()==1
	$Safe.visible=phase()==0
	$Lamp.light_color=[Color("75bcaa"),Color("e0ab50"),Color("df6041")][phase()]
	$WorldLabel.text=tr("STEAM ISOLATED / BRING HER THROUGH" if isolated() else ["CLEAR WINDOW / CROSS NOW","PRESSURE RISING / WAIT","HOT STEAM / KEEP OUT"][phase()])
	$WorldLabel.font_size=26;$WorldLabel.pixel_size=.011
	get_parent().get_node("SteamValve/Handle").rotation.z=-PI/2 if isolated() else 0
	var look:=get_parent().get_node_or_null("MaintenanceLook") as MaintenancePresentation
	if look:look.update_steam(phase(),cycle_time,isolated())

func valid_checkpoint(entry: Dictionary,session: SortieSession) -> bool:
	if session.maintenance.is_empty() or entry.cycle_time<0 or entry.cycle_time>=PERIOD or entry.hit_cooldown<0 or entry.hit_cooldown>.5:return false
	if session.maintenance.steam_off and entry.hit_cooldown!=0:return false
	if (entry.warned or entry.followed) and not MaintenanceStory.done(session,&"maintenance_release"):return false
	return not entry.followed or (entry.warned and session.maintenance.steam_off)
