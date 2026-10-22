class_name SharedMaintenanceSurvivor
extends MaintenanceSurvivor
## v3-only optional physical task. No teleport, invulnerability, command or reward flag.
var helping_cache: Node3D
var finish_remaining:=0.0
var handle_reach: HandleReach

func _ready() -> void:
	super._ready()
	handle_reach=HandleReach.new();handle_reach.helper=self
	var skeleton:=model.get_node(PROFILE.skeleton_path) as Skeleton3D
	for side in ["Left","Right"]:
		var bones: Array[int]=[]
		for part in ["UpperArm","LowerArm","Hand","MiddleProximal"]:
			bones.append(skeleton.find_bone(PROFILE.bone_map.get_skeleton_bone_name(side+part)))
		handle_reach.arms.append(bones)
	skeleton.add_child(handle_reach)
	handle_reach.modification_processed.connect(handle_reach.sample_contact)

func request_help(cache: Node3D, player: PlayerController) -> void:
	helping_cache=cache;actor=player;repath=0

func is_bracing(cache: Node3D) -> bool:
	return helping_cache==cache and global_position.distance_to(cache.helper_position())<=.10 and animation.current_animation==String(PROFILE.semantic_clips[&"interact"]) and handle_reach.contact_ready

func finish_unlatch() -> void:
	finish_remaining=.65

func interact(player: Node3D, session: SortieSession) -> Dictionary:
	if player is PlayerController and player.global_position.distance_to(global_position)<=player.interaction_component.interaction_radius:
		helping_cache=null;agent.target_desired_distance=1.8;handle_reach.contact_ready=false
	return super.interact(player,session)

func _physics_process(delta: float) -> void:
	var session:=SortieRuntime.get_current_session()
	if finish_remaining>0:
		var safe:=is_instance_valid(helping_cache) and is_instance_valid(actor) and not actor.is_dead and session and session.status==SortieSession.Status.ACTIVE and actor.global_position.distance_to(helping_cache.global_position)<=actor.interaction_component.interaction_radius
		if safe:
			finish_remaining=maxf(0,finish_remaining-delta)
			velocity.x=0;velocity.z=0;velocity.y-=20*delta;move_and_slide()
			if animation.current_animation!=String(PROFILE.semantic_clips[&"interact"]):animation.play(PROFILE.semantic_clips[&"interact"],.1)
			if finish_remaining==0:helping_cache=null;agent.target_desired_distance=1.8
			_refresh_label();return
		finish_remaining=0

	if not is_instance_valid(helping_cache) or not helping_cache.help_request_active(actor,session):
		helping_cache=null;agent.target_desired_distance=1.8;handle_reach.contact_ready=false
		super._physics_process(delta);return
	var target: Vector3=helping_cache.helper_position()
	var moving:=false
	agent.target_desired_distance=.025;repath-=delta
	if global_position.distance_to(target)>.06 and NavigationServer3D.map_get_iteration_id(agent.get_navigation_map())>0:
		if traversing_link and global_position.distance_to(link_goal)<.9:
			traversing_link=false;link_goal=Vector3.ZERO;repath=0
		if not traversing_link and repath<=0:
			if agent.target_position.distance_to(target)>.1:agent.target_position=target
			repath=.25
		if traversing_link or not agent.is_navigation_finished():
			var next: Vector3=link_goal if traversing_link else agent.get_next_path_position()
			var direction:=global_position.direction_to(next);direction.y=0
			if direction.length_squared()>.001 and _step_allowed(global_position+direction.normalized()*2.8*delta,session):
				velocity.x=direction.normalized().x*2.8;velocity.z=direction.normalized().z*2.8;moving=true
				rotation.y=lerp_angle(rotation.y,atan2(-direction.x,-direction.z),1-exp(-7*delta))
	if not moving:
		velocity.x=0;velocity.z=0
		var toward: Vector3=helping_cache.helper_grip(0)-global_position
		rotation.y=lerp_angle(rotation.y,atan2(-toward.x,-toward.z),1-exp(-7*delta))
	velocity.y-=20*delta;move_and_slide()
	var clip: StringName=PROFILE.semantic_clips[&"walk" if moving else &"interact"]
	if animation.current_animation!=String(clip):animation.play(clip,.15)
	_refresh_label()

class HandleReach extends SkeletonModifier3D:
	# Runs after the authored animation. Rotate the existing two arm segments;
	# never translate/scale a bone, move the actor, or make an unreachable grip ready.
	var helper: Node3D
	var arms: Array[Array]=[]
	var contact_ready:=false
	var last_grips: Array[Vector3]=[]
	var applying:=false

	func _process_modification_with_delta(delta: float) -> void:
		applying=false;contact_ready=false;last_grips.clear()
		var cache: Node3D=helper.helping_cache
		if not is_instance_valid(cache) or helper.global_position.distance_to(cache.helper_position())>.10 or helper.animation.current_animation!=String(helper.PROFILE.semantic_clips[&"interact"]):
			influence=0;return
		var session:=SortieRuntime.get_current_session()
		if not (helper.finish_remaining>0 or cache.help_request_active(helper.actor,session)):
			influence=0;return
		influence=move_toward(influence,1,delta*5)
		var sk:=get_skeleton()
		for index in arms.size():
			var bones: Array=arms[index]
			var upper: int=bones[0];var elbow: int=bones[1];var hand: int=bones[2]
			var pose:=sk.get_bone_global_pose(hand)
			var rest:=sk.get_bone_global_rest(hand)
			var palm_local:=rest.affine_inverse()*rest.origin.lerp(sk.get_bone_global_rest(bones[3]).origin,.55)
			var down: Vector3=sk.global_basis.inverse()*Vector3.DOWN
			var desired:=Basis(Quaternion((pose.basis*palm_local).normalized(),down.normalized()))*pose.basis
			var goal:=sk.to_local(cache.helper_grip(index))-desired*palm_local
			var shoulder:=sk.get_bone_global_pose(upper).origin
			var middle:=sk.get_bone_global_pose(elbow).origin
			var tip:=pose.origin
			var a:=shoulder.distance_to(middle);var b:=middle.distance_to(tip)
			var direction:=shoulder.direction_to(goal)
			var distance:=clampf(shoulder.distance_to(goal),absf(a-b)+.0001,a+b-.0001)
			var along:=(a*a+distance*distance-b*b)/(2*distance)
			var pole:=down-direction*down.dot(direction)
			if pole.length_squared()<.00001:pole=Vector3.FORWARD-direction*Vector3.FORWARD.dot(direction)
			var joint:=shoulder+direction*along+pole.normalized()*sqrt(maxf(0,a*a-along*along))
			_set_arm_basis(sk,upper,Basis(Quaternion((middle-shoulder).normalized(),(joint-shoulder).normalized()))*sk.get_bone_global_pose(upper).basis)
			middle=sk.get_bone_global_pose(elbow).origin;tip=sk.get_bone_global_pose(hand).origin
			_set_arm_basis(sk,elbow,Basis(Quaternion((tip-middle).normalized(),(goal-middle).normalized()))*sk.get_bone_global_pose(elbow).basis)
			_set_arm_basis(sk,hand,desired)
		applying=true

	func sample_contact() -> void:
		if not applying or not is_instance_valid(helper.helping_cache):return
		var sk:=get_skeleton()
		contact_ready=influence>=.99
		for index in arms.size():
			var hand: int=arms[index][2]
			var rest:=sk.get_bone_global_rest(hand)
			var palm_local:=rest.affine_inverse()*rest.origin.lerp(sk.get_bone_global_rest(arms[index][3]).origin,.55)
			var actual:=sk.to_global(sk.get_bone_global_pose(hand)*palm_local)
			last_grips.append(actual)
			contact_ready=contact_ready and actual.distance_to(helper.helping_cache.helper_grip(index))<.045

	func _set_arm_basis(sk: Skeleton3D,index: int,desired: Basis) -> void:
		var parent:=sk.get_bone_parent(index)
		var local:=sk.get_bone_global_pose(parent).basis.inverse()*desired if parent>=0 else desired
		sk.set_bone_pose_rotation(index,local.orthonormalized().get_rotation_quaternion())
