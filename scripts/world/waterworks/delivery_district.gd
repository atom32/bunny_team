extends "res://scripts/world/waterworks/waterworks_district.gd"
## Version-two geometry is kept separate so original live checkpoints still fit.
var geometry_ready:=false
var jet_cooldown:=0.0

func _ready() -> void:
	super._ready()
	geometry_ready=true # Do not move colliders before Battle signs the authored map.

func refresh_waterworks() -> void:
	super.refresh_waterworks()
	# The legacy fill stream must not float over the empty loading bay after departure.
	$TankerWater.visible=false
	if not geometry_ready:return
	var session:=SortieRuntime.get_current_session()
	if not session or session.waterworks.is_empty():return
	var facts:=session.waterworks
	$PublicGate.position.y=4 if facts.delivered and facts.branch=="public" else 0
	$PublicLink.enabled=facts.delivered and facts.branch=="public"
	$LoadingGate.position.y=5 if facts.gate_open else 0
	$LoadingLink.enabled=facts.gate_open
	$PressureJet.visible=WaterworksJourney.pending(session,"public")
	$Tanker.apply_progress()

func begin_delivery(branch: String,actor: PlayerController) -> bool:
	var session:=SortieRuntime.get_current_session()
	if branch not in ["public","tanker"] or not session or session.waterworks.is_empty() or not session.waterworks.branch.is_empty() or not WaterworksStory.done(session,&"water_pump"):return false
	session.waterworks.branch=branch
	get_parent().get_parent().spawn_reinforcement_group(&"water_choice")
	get_parent().get_parent()._sync_objective_hud()
	refresh_waterworks()
	actor.interaction_component.information_read.emit(tr(WaterworksJourney.JAM if branch=="public" else "Shen: The key is in. You have the handbrake.\nTang Kui: Do not stand in front of it. I am not catching that thing."))
	SortieRuntime.request_checkpoint()
	return true

func complete_delivery(branch: String,fix:="") -> bool:
	var session:=SortieRuntime.get_current_session()
	if not WaterworksJourney.pending(session,branch):return false
	if branch=="public" and fix not in ["bypass","shot"]:return false
	if branch=="tanker" and (not session.waterworks.gate_open or $Tanker.progress<$Tanker.DISTANCE):return false
	session.waterworks.public_fix=fix;session.waterworks.delivered=true
	session.record_objective_interaction(StringName("water_"+branch));session.record_objective_interaction(&"water_delivery")
	open_reward(branch);refresh_waterworks()
	var battle:=get_parent().get_parent()
	battle._sync_objective_hud()
	battle.player.interaction_component.information_read.emit(tr(WaterworksStory.PUBLIC_END if branch=="public" else WaterworksStory.TANKER_END))
	SortieRuntime.request_checkpoint()
	return true

func _physics_process(delta: float) -> void:
	jet_cooldown=maxf(0,jet_cooldown-delta)
	if not WaterworksJourney.pending(SortieRuntime.get_current_session(),"public"):return
	var actor: PlayerController=get_parent().get_parent().player
	if not actor or actor.is_dead:return
	var at:=actor.global_position
	if jet_cooldown<=0 and at.x>-29 and at.x< -22 and at.z> -19 and at.z< -17:
		actor.receive_damage(DamagePacket.new(3,0,0,self,&"water_pressure",&"world",at));jet_cooldown=.75
