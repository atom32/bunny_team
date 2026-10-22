class_name MaintenanceSurvivor
extends CharacterBody3D
## Noncombat adult CC0 placeholder, never a replacement for the player's model.
## Route/spacing pressure, not a shootable escort-health system.
const PROFILE=preload("res://resources/presentation/subjects_female/campus_subject_profile.tres")
var waiting:=false
var steam_blocked:=false
var model: Node3D
var animation: AnimationPlayer
var agent: NavigationAgent3D
var actor: PlayerController
var repath:=0.0
var traversing_link:=false
var link_goal:=Vector3.ZERO
func _ready() -> void:
 collision_layer=0;collision_mask=4
 model=PROFILE.model.instantiate();model.name="CC0SurvivorPlaceholder";model.rotation.y=PROFILE.forward_yaw;model.scale=Vector3.ONE*PROFILE.model_scale;add_child(model)
 animation=AnimationPlayer.new();model.add_child(animation);animation.add_animation_library(&"",PROFILE.animation_library);animation.play(PROFILE.semantic_clips[&"idle"])
 agent=NavigationAgent3D.new();agent.path_desired_distance=.35;agent.target_desired_distance=1.8;agent.radius=.35;add_child(agent)
 agent.link_reached.connect(_link_reached)
 add_to_group("interactable")
 GameLanguage.language_changed.connect(_refresh_label);_refresh_label()
func _refresh_label() -> void:
 if has_node("WorldLabel"):get_node("WorldLabel").text=tr("XU TANG / STEAM AHEAD" if steam_blocked and not waiting else "XU TANG / SURVIVOR")
func _link_reached(details: Dictionary) -> void:
 var link: NavigationLink3D=details.get("owner")
 if not link or link.get_parent()!=get_parent() or not link.enabled:return
 traversing_link=true;link_goal=details.link_exit_position
func interact(player: Node3D,session: SortieSession) -> Dictionary:
 if not player is PlayerController or not MaintenanceStory.done(session,&"maintenance_release"):return {"success":false,"message":"Open the ward door first."}
 if player.global_position.distance_to(global_position)>player.interaction_component.interaction_radius:return {"success":false,"message":"Move closer to Xu Tang."}
 if MaintenanceStory.done(session,&"maintenance_rescue"):return {"success":true,"message":"Xu Tang is safe. You still need to extract."}
 waiting=not waiting;SortieRuntime.request_checkpoint()
 return {"success":true,"message":"Xu Tang will wait here." if waiting else "Xu Tang will follow. Stay within 12m."}
func get_interaction_prompt(_player: Node3D,session: SortieSession) -> String:
 if not MaintenanceStory.done(session,&"maintenance_release"):return ""
 return ControlBindings.label("interact")+"  "+tr("FOLLOW ME" if waiting else "WAIT HERE")
func _physics_process(delta: float) -> void:
 var session:=SortieRuntime.get_current_session();var battle:=get_parent().get_parent().get_parent()
 if not is_instance_valid(actor) and battle and "player" in battle:actor=battle.player
 var moving:=false
 steam_blocked=false
 var active:=session and session.status==SortieSession.Status.ACTIVE and is_instance_valid(actor) and not actor.is_dead
 if active and MaintenanceStory.done(session,&"maintenance_release") and not MaintenanceStory.done(session,&"maintenance_rescue"):
  var distance:=global_position.distance_to(actor.global_position)
  repath-=delta
  if not waiting and distance<12 and (distance>2.2 or traversing_link) and NavigationServer3D.map_get_iteration_id(agent.get_navigation_map())>0:
   # Retargeting halfway across a link snaps the new path back to its entry.
   # Walk its actual exit first, including after a suspended mid-doorway save.
   if traversing_link and global_position.distance_to(link_goal)<.9:
    traversing_link=false;link_goal=Vector3.ZERO;repath=0
   if not traversing_link and repath<=0:
    # Reassigning an unchanged target also rewinds funnel corner progress.
    if agent.target_position.distance_to(actor.global_position)>.8:agent.target_position=actor.global_position
    repath=.25
   if traversing_link or not agent.is_navigation_finished():
    var next:=link_goal if traversing_link else agent.get_next_path_position();var direction:=global_position.direction_to(next);direction.y=0
    if direction.length_squared()>.001 and _step_allowed(global_position+direction.normalized()*2.8*delta,session):velocity.x=direction.normalized().x*2.8;velocity.z=direction.normalized().z*2.8;moving=true;rotation.y=lerp_angle(rotation.y,atan2(-direction.x,-direction.z),1-exp(-7*delta))
  if MaintenanceStory.done(session,&"maintenance_gate") and global_position.distance_to(MaintenanceStory.SAFE)<2 and distance<4.5:
   if session.record_objective_interaction(&"maintenance_rescue"):
    moving=false
    battle._sync_objective_hud();actor.interaction_component.interaction_finished.emit(tr("Xu Tang is at the north exit. Extract safely to bring her home."),true);SortieRuntime.request_checkpoint()
 if not moving:velocity.x=0;velocity.z=0
 velocity.y-=20*delta;move_and_slide()
 var clip: StringName=PROFILE.semantic_clips[&"walk" if moving else &"idle"]
 if animation.current_animation!=String(clip):animation.play(clip,.15)
 _refresh_label()

func _step_allowed(at: Vector3,session: SortieSession) -> bool:
 if session.maintenance.is_empty():return true
 var inside:=MaintenanceJourney.ZONE.grow(.4).has_point(Vector2(at.x,at.z))
 var steam:=get_parent().get_node("Steam") as MaintenanceSteam
 if not session.maintenance.steam_off and inside:
  steam_blocked=true;steam.warn_blocked(actor);return false
 if session.maintenance.steam_off and inside:steam.notify_follow(actor)
 return true

func valid_checkpoint(entry: Dictionary,session: SortieSession) -> bool:
 var at:=Vector3(entry.position[0],entry.position[1],entry.position[2])
 var speed:=Vector3(entry.velocity[0],entry.velocity[1],entry.velocity[2])
 if absf(at.x)>25.5 or at.z < -41.5 or at.z>27.5 or at.y < -.3 or at.y>1:return false
 if Vector2(speed.x,speed.z).length()>2.81 or absf(speed.y)>20:return false
 if not session.maintenance.is_empty() and not session.maintenance.steam_off and MaintenanceJourney.ZONE.grow(.35).has_point(Vector2(at.x,at.z)):return false
 if absf(entry.rotation[0])>.001 or absf(entry.rotation[2])>.001:return false
 var goal:=Vector3(entry.link_goal[0],entry.link_goal[1],entry.link_goal[2])
 if not entry.traversing_link and goal!=Vector3.ZERO:return false
 if entry.traversing_link:
  var valid_link:=false
  for name in get_parent().GATES:
   var link: NavigationLink3D=get_parent().get_node(name+"Link")
   if not MaintenanceStory.done(session,get_parent().GATES[name]):continue
   var start:=link.to_global(link.start_position);var end:=link.to_global(link.end_position)
   if (goal.is_equal_approx(start) or goal.is_equal_approx(end)) and at.distance_to(Geometry3D.get_closest_point_to_segment(at,start,end))<.6:valid_link=true
  if not valid_link:return false
 if not MaintenanceStory.done(session,&"maintenance_release"):
  return not entry.waiting and not entry.traversing_link and Vector2(at.x-15,at.z+11).length()<.01
 if not MaintenanceStory.done(session,&"maintenance_gate") and at.z < -27.5:return false
 if MaintenanceStory.done(session,&"maintenance_rescue") and at.distance_to(MaintenanceStory.SAFE)>2.01:return false
 return true
