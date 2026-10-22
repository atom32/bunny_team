class_name MaintenanceAction
extends ObjectiveInteractable
@export var duration:=6.0
var remaining:=0.0
var actor: PlayerController
var observed_health:=0.0
func _ready() -> void:
 super._ready();GameLanguage.language_changed.connect(refresh);refresh()
func available(session: SortieSession) -> bool:
 if not session or session.status!=SortieSession.Status.ACTIVE or session.mission_id!=MaintenanceStory.MISSION:return false
 if objective_id==&"maintenance_radio":return true
 if MaintenanceStory.done(session,objective_id):return false
 if objective_id==&"maintenance_gate" and not session.maintenance.is_empty() and not session.maintenance.steam_off:return false
 var index:=MaintenanceStory.ORDER.find(objective_id)
 return index==0 or (index>0 and MaintenanceStory.done(session,MaintenanceStory.ORDER[index-1]))
func bind_actor(player: PlayerController,_session: SortieSession) -> void:
 actor=player;observed_health=player.health
 if not actor.health_changed.is_connected(_health):actor.health_changed.connect(_health)
func _near() -> bool:
 if not is_instance_valid(actor) or actor.is_dead:return false
 if actor.global_position.distance_to(global_position)>actor.interaction_component.interaction_radius:return false
 var query:=PhysicsRayQueryParameters3D.create(actor.global_position+Vector3.UP*1.25,global_position+Vector3.UP*1.4,4);query.exclude=[actor.get_rid()]
 return actor.get_world_3d().direct_space_state.intersect_ray(query).is_empty()
func interact(player: Node3D,session: SortieSession) -> Dictionary:
 if not player is PlayerController or not available(session):return {"success":false,"message":"Maintenance control is not ready."}
 bind_actor(player,session)
 if not _near():return {"success":false,"message":"Move closer to the maintenance control."}
 if objective_id==&"maintenance_radio":return {"success":true,"message":"Maintenance / radio","information":tr(MaintenanceStory.INTRO)+("\n\n"+tr(MaintenanceJourney.BRIEF) if not session.maintenance.is_empty() else "")}
 if remaining>0:return {"success":false,"message":"Work already in progress."}
 if not session.maintenance.is_empty():
  CombatNoise.emit_at(self,global_position,22,&"repair");AudioDirector.play_sfx(&"blockade_lock",-6)
  return {"success":_complete(session),"message":"Maintenance control operated."}
 observed_health=actor.health
 if not actor.health_changed.is_connected(_health):actor.health_changed.connect(_health)
 remaining=duration;CombatNoise.emit_at(self,global_position,22,&"repair");SortieRuntime.request_checkpoint()
 return {"success":true,"message":"Stay close. Moving away or damage interrupts the work."}
func _health(value: float,_maximum: float) -> void:
 if value<observed_health:_cancel()
 observed_health=value
func _cancel() -> void:
 if remaining<=0:return
 remaining=0;SortieRuntime.request_checkpoint()
 if is_instance_valid(actor):actor.interaction_component.interaction_finished.emit(tr("Work interrupted. The control can be restarted."),false)
func _process(delta: float) -> void:
 if remaining<=0:return
 var session:=SortieRuntime.get_current_session()
 if not available(session):remaining=0;return
 if not _near():_cancel();return
 remaining=maxf(0,remaining-delta)
 if has_node("Handle"):get_node("Handle").rotation.z=(duration-remaining)*TAU
 if remaining>0:return
 _complete(session)
func _complete(session: SortieSession) -> bool:
 if not session.record_objective_interaction(objective_id):return false
 var battle:=get_parent().get_parent().get_parent()
 if objective_id==&"maintenance_release":battle.spawn_reinforcement_group(&"ward_release")
 if objective_id==&"maintenance_gate":battle.spawn_reinforcement_group(&"north_shutter")
 get_parent().refresh_maintenance()
 var message:=MaintenanceJourney.UNLATCH if not session.maintenance.is_empty() else "Service bulkhead open. The south retreat remains open."
 if objective_id==&"maintenance_release":message="Xu Tang is free. Stay within 12m; interact to ask her to wait or follow."
 elif objective_id==&"maintenance_gate":message=MaintenanceJourney.NORTH if not session.maintenance.is_empty() else "North shutter open. Bring Xu Tang through before extracting."
 if objective_id==&"maintenance_release":actor.interaction_component.information_read.emit(tr(MaintenanceStory.RELEASE))
 elif objective_id==&"maintenance_gate":actor.interaction_component.information_read.emit(tr(MaintenanceStory.GATE))
 actor.interaction_component.interaction_finished.emit(tr(message),true)
 objective_interacted.emit(objective_id);SortieRuntime.request_checkpoint();refresh()
 return true
func get_interaction_prompt(_player: Node3D,session: SortieSession) -> String:
 if remaining>0:return tr("WORK %.1fs / stay close")%remaining
 return ControlBindings.label("interact")+"  "+tr(interaction_prompt) if available(session) else ""
func refresh() -> void:
 if available(SortieRuntime.get_current_session()):add_to_group("interactable")
 else:remove_from_group("interactable")
 if has_node("WorldLabel"):get_node("WorldLabel").text=tr(interaction_prompt)
