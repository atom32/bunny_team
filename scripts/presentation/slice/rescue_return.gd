extends "res://scripts/presentation/slice/seat_moment.gd"
## Optional earned rescue callback. No rewards, seen flags or profile writes.
const GUEST_PROFILE=preload("res://resources/presentation/subjects_female/campus_subject_profile.tres")
const FIRST=[
	"Xu Tang: Wait.\n[She stops outside the doorway.]",
	"Xu Tang: I know. It is stupid.\nTang Kui: The door is stupid. Stay there.",
]
const INSIDE=["Xu Tang: ...You can let go now.\nTang Kui: She heard you. The door has not."]
const LAST=[
	"Xu Tang: Is it staying open?\nSu Mi: Yes.",
	"Tang Kui: We will have to close it eventually.\nXu Tang: ...\nTang Kui: In spring! I meant in spring.",
	"Tang Kui: She has been holding the outside handle half the night.\nShen: Tang Kui.\nTang Kui: Fine. I am hanging up.",
	"Xu Tang: Do not hang up.\nTang Kui: ...All right.\n[The door stays open.]",
]
var guest: Node3D
var guest_animation: AnimationPlayer
var door: Node3D
var latch: Node3D
var latched:=false
var grip:=0.0
var hand_side:="Right"
var hand_goal:=Vector3.ZERO
var guest_walked:=0.0
var catch_sounded:=false

static func unlocked(profile: ProfileState) -> bool:return profile!=null and profile.maintenance_rescued

func _build_props() -> void:
	VisualFactory.add_world_environment(self,Color("b2bdb6"))
	var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-48,-35,0);light.light_color=Color("ffe0b5");light.light_energy=.85;light.shadow_enabled=true;add_child(light)
	_shape("Floor",Vector3(6,.12,6),Vector3(2,-.06,1.5),Color("6b7a78"))
	_shape("BackWall",Vector3(6,2.6,.16),Vector3(2,1.3,-.7),Color("a1ada2"))
	_shape("DoorLeft",Vector3(1.5,.55,.16),Vector3(.45,.275,1.4),Color("a1ada2"))
	_shape("DoorRight",Vector3(2.4,.55,.16),Vector3(3.8,.275,1.4),Color("a1ada2"))
	for x in [1.16,2.64]:_shape("DoorPost",Vector3(.08,2.5,.22),Vector3(x,1.25,1.4),Color("394c4e"))
	_shape("Lintel",Vector3(1.5,.35,.25),Vector3(1.95,2.5,1.4),Color("394c4e"))
	_shape("Threshold",Vector3(1.4,.018,.24),Vector3(1.9,.009,1.4),Color("b5a36a"))
	door=Node3D.new();door.name="HeldDoor";door.position=Vector3(1.2,0,1.4);add_child(door)
	_shape("DoorLeaf",Vector3(1.4,2.3,.075),Vector3(.7,1.15,0),Color("486968"),door)
	_shape("DoorWindow",Vector3(.55,.45,.015),Vector3(.85,1.65,.046),Color("91aaa5"),door)
	_shape("Handle",Vector3(.20,.04,.08),Vector3(1.18,1.03,.08),Color("c9bd8a"),door)
	latch=Node3D.new();latch.name="HoldOpenCatch";latch.position=Vector3(1.16,1.32,1.55);add_child(latch)
	_shape("Catch",Vector3(.18,.04,.05),Vector3(-.06,0,0),Color("d0af68"),latch)
	_shape("Bench",Vector3(1.6,.12,.5),Vector3(3.4,.47,-.1),Color("7d6650"))
	for x in [2.8,4.0]:_shape("BenchLeg",Vector3(.07,.4,.38),Vector3(x,.2,-.1),Color("34494b"))
	guest=Node3D.new();guest.name="XuTangAtTheDoor";add_child(guest)
	var model: Node3D=GUEST_PROFILE.model.instantiate();model.rotation.y=GUEST_PROFILE.forward_yaw;model.scale=Vector3.ONE*GUEST_PROFILE.model_scale;guest.add_child(model)
	for player: AnimationPlayer in model.find_children("*","AnimationPlayer",true,false):player.autoplay="";player.stop();player.active=false
	guest_animation=AnimationPlayer.new();model.add_child(guest_animation);guest_animation.add_animation_library(&"",GUEST_PROFILE.animation_library)

func _shape(name: String,size: Vector3,at: Vector3,color: Color,parent: Node3D=null) -> void:
	var shape:=BoxMesh.new();shape.size=size
	var node:=_mesh(self if not parent else parent,shape,color,at);node.name=name

func _build_ui() -> void:
	super._build_ui()
	screen.find_child("SkipSeatMoment",true,false).name="SkipRescueMoment"
	next_button.name="NextRescueLine";exits.get_child(0).name="RescueReturn";exits.get_child(1).name="ReplayRescue"

func replay() -> void:
	if leaving:return
	eligible=unlocked(ProfileRuntime.get_profile());guest.visible=eligible;latched=false;grip=0;guest_walked=0;catch_sounded=false
	door.rotation.y=-1.2;latch.rotation.y=0
	actor.position=Vector3(2.85,0,1.1);actor.body_visual.rotation.y=0
	motion.height_offset=0;motion.speed=0;motion.seated=false;motion.station="";motion.pending_station="";motion.destination_section=""
	motion.route.assign([Vector3(2.85,0,.6)]);motion._begin_walk()
	guest.position=Vector3(2.25,0,3.9);guest.rotation.y=0
	if not eligible:motion.route.clear();motion.phase="idle";motion._change_clip("Idle")
	_enter("arrival" if eligible else "locked");_camera(0)

func _enter(value: String) -> void:
	phase=value;phase_elapsed=0;line_index=LAST.size()-1 if value=="done" else 0;_refresh_language()
	if phase=="done":exits.get_child(0).grab_focus()
	elif next_button.visible:next_button.grab_focus()

func _refresh_language() -> void:
	if not is_instance_valid(screen):return
	screen.find_child("SeatTitle",true,false).text=tr("THE DOOR CAN WAIT / BACK AT HOME")
	choices.visible=false;exits.visible=phase=="done";next_button.visible=phase in ["intro","inside","ending"]
	var text:="Rescue Xu Tang and return safely to see this moment."
	if phase=="arrival":text="Tang Kui: Come in. The soup is not getting any warmer."
	elif phase=="intro":text=FIRST[line_index]
	elif phase=="back":text="[She turns back before the door can close.]"
	elif phase=="opening":text="Xu Tang: ...Do not let go yet."
	elif phase=="crossing":text="[She keeps her hand on the door until Xu Tang is through.]"
	elif phase=="inside":text=INSIDE[line_index]
	elif phase=="catch":text="[The little brass catch clicks into place.]"
	elif phase in ["returning","settling"]:text="Xu Tang: You came back again."
	elif phase in ["settling","ending","done"]:text=LAST[line_index]
	dialogue.text=tr(text)
	var keys:={"SkipRescueMoment":"RETURN TO QUARTERS","NextRescueLine":"NEXT LINE","RescueReturn":"RETURN TO QUARTERS","ReplayRescue":"REPLAY THIS MOMENT"}
	for button in screen.find_children("*","Button",true,false):
		if keys.has(String(button.name)):button.text=tr(keys[String(button.name)])

func advance_line() -> void:
	if phase not in ["intro","inside","ending"] or leaving:return
	var lines: Array=FIRST if phase=="intro" else (INSIDE if phase=="inside" else LAST)
	if line_index+1<lines.size():line_index+=1;_refresh_language();return
	if phase=="intro":
		motion.route.assign([Vector3(2.35,0,.6),Vector3(2.35,0,2.85),Vector3(1.1,0,2.85),Vector3(1.1,0,2.05)]);motion._begin_walk();_enter("back")
	elif phase=="inside":_enter("catch")
	else:_enter("done")

func _guest_step(goal: Vector3,delta: float) -> bool:
	var gap:=goal-guest.position;var moving:=gap.length()>.025
	if moving:
		var before:=guest.position;guest.position=guest.position.move_toward(goal,.85*delta);guest_walked+=before.distance_to(guest.position)
		guest.rotation.y=lerp_angle(guest.rotation.y,atan2(-gap.x,-gap.z),1-exp(-6*delta))
	var clip: StringName=GUEST_PROFILE.semantic_clips[&"walk" if moving else &"idle"]
	if guest_animation.current_animation!=String(clip):guest_animation.play(clip,.15)
	return not moving

func _palm(side: String,goal: Vector3,weight: float) -> void:
	var sk:=actor.character_skeleton
	var hand:=sk.find_bone("Character1_"+side+"Hand")
	var rest:=sk.get_bone_global_rest(hand)
	var middle:=sk.get_bone_global_rest(sk.find_bone("Character1_"+side+"HandMiddle1")).origin
	var palm_local:=rest.affine_inverse()*rest.origin.lerp(middle,.55)
	var pose:=sk.get_bone_global_pose(hand)
	# Flat fingers run up the leaf. Keep the original lengths: rotate, never stretch.
	var normal: Vector3=door.global_basis.z*(1 if side=="Left" else -1) # Left anatomical frame has the opposite handed palm normal.
	var frame:=sk.global_basis.orthonormalized().inverse()*CONTACT.frame(Vector3.UP,normal)
	var target:=frame*CONTACT.hand_frame(sk,side).inverse()*pose.basis
	var basis:=Basis(pose.basis.get_rotation_quaternion().slerp(target.orthonormalized().get_rotation_quaternion(),weight))
	var wrist:=CONTACT.palm(sk,side).lerp(sk.to_local(goal),weight)-basis*palm_local
	_reach_arm(sk,side,wrist);_set_basis(sk,hand,basis)
	for finger in ["Index","Middle","Ring","Pinky"]:
		for joint in range(1,4):
			var index:=sk.find_bone("Character1_"+side+"Hand"+finger+str(joint))
			sk.set_bone_pose_rotation(index,sk.get_bone_pose_rotation(index).slerp(Quaternion.IDENTITY,weight))

func _process(delta: float) -> void:
	if not is_instance_valid(motion) or leaving:return
	motion._process(delta);phase_elapsed+=delta
	if phase=="arrival":
		door.rotation.y=lerpf(-1.2,-.9,smoothstep(0,1.6,phase_elapsed))
		var arrived:=_guest_step(Vector3(2.25,0,3.4),delta)
		if arrived and phase_elapsed>=1.7 and motion.phase=="idle":_enter("intro")
	elif phase=="back" and motion.phase=="idle":
		var sk:=actor.character_skeleton;var goal:=door.to_global(Vector3(.4,1.22,.045))
		var r:=sk.to_global(sk.get_bone_global_pose(sk.find_bone("Character1_RightArm")).origin)
		var l:=sk.to_global(sk.get_bone_global_pose(sk.find_bone("Character1_LeftArm")).origin)
		hand_side="Right" if r.distance_to(goal)<l.distance_to(goal) else "Left";_enter("opening")
	elif phase=="opening":
		grip=smoothstep(0,.7,phase_elapsed);door.rotation.y=lerpf(-.9,-1.2,smoothstep(.8,2.0,phase_elapsed))
		if phase_elapsed>=2.4:_enter("crossing")
	elif phase=="crossing":
		if _guest_step(Vector3(1.8,0,.6),delta):_enter("inside")
	elif phase=="catch":
		latch.rotation.y=lerpf(0,PI/2,smoothstep(.7,1.3,phase_elapsed))
		if not catch_sounded and phase_elapsed>=1.3:catch_sounded=true;AudioDirector.play_sfx(&"blockade_lock",-14)
		grip=1-smoothstep(1.6,2.1,phase_elapsed)
		if phase_elapsed>=2.3:
			latched=true;grip=0
			motion.route.assign([Vector3(1.1,0,3.1),Vector3(2.35,0,3.1),Vector3(2.35,0,.95),Vector3(2.9,0,.6)]);motion._begin_walk();_enter("returning")
	elif phase=="returning" and motion.phase=="idle":_enter("settling")
	elif phase=="settling" and phase_elapsed>=.9:_enter("ending")
	if phase not in ["arrival","crossing"]:_guest_step(guest.position,delta)
	if grip>0:
		var contact:=door.to_global(Vector3(.4,1.22,.045))
		hand_goal=contact.lerp(latch.global_position,smoothstep(0,.6,phase_elapsed)) if phase=="catch" else contact
		var direction:=hand_goal-actor.position;direction.y=0
		motion.target_yaw=atan2(-direction.x,-direction.z)
		actor.body_visual.rotation.y=lerp_angle(actor.body_visual.rotation.y,motion.target_yaw,1-exp(-6*delta))
		_palm(hand_side,hand_goal,grip)
	elif phase in ["settling","ending","done"]:
		var gap:=guest.position-actor.position
		motion.target_yaw=atan2(-gap.x,-gap.z)
		actor.body_visual.rotation.y=lerp_angle(actor.body_visual.rotation.y,motion.target_yaw,1-exp(-4*delta))
		guest.rotation.y=lerp_angle(guest.rotation.y,atan2(gap.x,gap.z),1-exp(-4*delta))
	_camera(delta)

func _camera(delta: float) -> void:
	var at:=Vector3(0,1.85,4.7);var focus:=Vector3(1.8,1.05,1.9)
	if phase in ["opening","inside","catch"]:at=Vector3(-.45,1.75,-.1);focus=Vector3(1.15,1.15,2)
	if phase=="crossing":at=Vector3(4.8,1.85,4.7);focus=Vector3(2.1,1.0,1.8)
	if phase in ["settling","ending","done"]:at=Vector3(4.7,1.7,1.1);focus=Vector3(2.6,1.05,.6)
	camera.position=camera.position.lerp(at,1-exp(-3*delta)) if delta>0 else at
	camera.fov=65 if phase in ["opening","inside","catch"] else 55;camera.look_at(focus)
