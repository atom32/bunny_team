class_name WaterResident
extends CharacterBody3D
## Anonymous adult CC0 visual placeholders. Walk to the tap, no escort objective.
@export var destination:=Vector3.ZERO
@export var male:=false
var arrived:=false
var home:=Vector3.ZERO
var agent: NavigationAgent3D
var animation: AnimationPlayer
var profile: PresentationProfile
var started:=false

func _ready() -> void:
	collision_layer=0;collision_mask=4;home=position
	profile=load("res://resources/presentation/subjects/campus_subject_profile.tres" if male else "res://resources/presentation/subjects_female/campus_subject_profile.tres")
	var model: Node3D=profile.model.instantiate();model.rotation.y=profile.forward_yaw;model.scale=Vector3.ONE*profile.model_scale;add_child(model)
	for player: AnimationPlayer in model.find_children("*","AnimationPlayer",true,false):player.autoplay="";player.stop();player.active=false
	animation=AnimationPlayer.new();model.add_child(animation);animation.add_animation_library(&"",profile.animation_library)
	agent=NavigationAgent3D.new();agent.path_desired_distance=.15;agent.target_desired_distance=.2;add_child(agent)

func _physics_process(delta: float) -> void:
	var session:=SortieRuntime.get_current_session();var walking:=false
	if WaterworksStory.done(session,&"water_public") and not arrived and NavigationServer3D.map_get_iteration_id(agent.get_navigation_map())>0:
		if not started:agent.target_position=destination;started=true
		if global_position.distance_to(destination)<.3:arrived=true;SortieRuntime.request_checkpoint()
		elif not agent.is_navigation_finished():
			var direction:=global_position.direction_to(agent.get_next_path_position());direction.y=0
			if direction.length_squared()>.001:
				velocity.x=direction.normalized().x*1.3;velocity.z=direction.normalized().z*1.3;walking=true;rotation.y=lerp_angle(rotation.y,atan2(-direction.x,-direction.z),1-exp(-7*delta))
	if not walking:velocity.x=0;velocity.z=0
	velocity.y-=20*delta;move_and_slide()
	var clip: StringName=profile.semantic_clips[&"walk" if walking else &"idle"]
	if animation.current_animation!=String(clip):animation.play(clip,.15)

func valid_checkpoint(entry: Dictionary,session: SortieSession) -> bool:
	var at:=Vector3(entry.position[0],entry.position[1],entry.position[2]);var speed:=Vector3(entry.velocity[0],entry.velocity[1],entry.velocity[2])
	if at.x< -45 or at.x> -32 or at.z< -26 or at.z> -11 or at.y< -.3 or at.y>1:return false
	if absf(entry.rotation[0])>.001 or absf(entry.rotation[2])>.001 or Vector2(speed.x,speed.z).length()>1.31 or absf(speed.y)>20:return false
	if not WaterworksStory.done(session,&"water_public"):return not entry.arrived and Vector2(at.x-home.x,at.z-home.z).length()<.01
	return not entry.arrived or at.distance_to(destination)<.31
