extends "res://scripts/presentation/slice/seat_moment.gd"
## Optional water-return callback. Props and choices never change recovered cargo.
const PUBLIC_LINES=[
	"Tang Kui: I said save a bucket. Not bring the whole bucket upstairs.\nShen: I asked her to.",
	"Tang Kui: Oh. Is that your name on it too?\nSu Mi: Three times. The first one did not fit.",
	"Shen: The second one was too small.\nTang Kui: And the third?\nShen: ...She traced it.",
	"Su Mi: Who drew the flower?\n[The radio goes very quiet.]",
]
const TANKER_LINES=[
	"Tang Kui: The truck went north. The empty bucket came back with you.\nShen: I said I would come back. I did not say in what.",
	"Su Mi: She waited by the stairs. Then carried the empty bucket up herself.\nShen: It was in the way.",
	"Tang Kui: You traced the name again? Afraid the bucket would run off?\nShen: Afraid you would wash your feet in it.",
	"Tang Kui: ...I will use a different one.\nSu Mi: The flower is a nice touch.\n[The radio goes very quiet.]",
]
const DOOR_LINES=[
	"Shen: Come back.\nTang Kui: Use her name!",
	"Shen: ...Come back. Keep the bucket. Just stay here.",
	"Su Mi: Oh.\nTang Kui: Ohhh.\nShen: Both of you. Off the radio.",
]
const LAST_LINES=[
	"Tang Kui: You put that down gently. You were not so gentle with the gate.\nSu Mi: She did not want to scratch the name.",
	"Shen: The bucket is yours. The name can... never mind.",
	"Tang Kui: Who is fetching the water next time?\nShen: Next time I will come to meet you.",
	"Tang Kui: With the bucket?\nShen: I meant her.",
	"Su Mi: Right. I will find a smaller bucket.\n[The biggest one stays beside the bench.]",
]
var water_branch:=""
var held:=true
var grip_weight:=1.0
var bucket_home:=Vector3(2.5,.86,1.52)
var bucket_goals:={}
var place_start:=Vector3.ZERO

static func unlocked(profile: ProfileState) -> bool:
	return profile!=null and profile.first_mission_completed and profile.waterworks_memory in ["water_public","water_tanker"]

func _build_props() -> void:
	var top:=BoxMesh.new();top.size=Vector3(.5,.05,.5)
	_mesh(self,top,Color("8a6e50"),bucket_home-Vector3.UP*.195)
	for x in [-.20,.20]:
		for z in [-.20,.20]:
			var leg:=BoxMesh.new();leg.size=Vector3(.035,.64,.035)
			_mesh(self,leg,Color("444c50"),Vector3(bucket_home.x+x,.32,bucket_home.z+z))
	cup=Node3D.new();cup.name="TheBiggestBucket";add_child(cup)
	var shell:=CylinderMesh.new();shell.top_radius=.19;shell.bottom_radius=.14;shell.height=.34;shell.cap_top=false
	_mesh(cup,shell,Color("a9b8b2"),Vector3.ZERO)
	var rim:=TorusMesh.new();rim.inner_radius=.18;rim.outer_radius=.20
	_mesh(cup,rim,Color("49585d"),Vector3(0,.17,0))
	for x in [-.215,.215]:
		var handle:=BoxMesh.new();handle.size=Vector3(.045,.04,.13)
		_mesh(cup,handle,Color("49585d"),Vector3(x,.12,0))
	var water:=CylinderMesh.new();water.top_radius=.17;water.bottom_radius=.17;water.height=.008
	var surface:=_mesh(cup,water,Color("5d9dba"),Vector3(0,.11,0));surface.name="WaterSurface"
	var nameplate:=Label3D.new();nameplate.name="BucketName";nameplate.font=UIFactory.FONT;nameplate.position=Vector3(0,.0,.192);nameplate.font_size=28;nameplate.pixel_size=.0018;nameplate.outline_size=2;nameplate.text="Shen";cup.add_child(nameplate)
	for i in 5:
		var petal:=SphereMesh.new();petal.radius=.012;petal.height=.024
		var angle:=TAU*i/5
		_mesh(cup,petal,Color("e2a270"),Vector3(.09+cos(angle)*.018,-.08+sin(angle)*.018,.19))

func replay() -> void:
	if leaving:return
	var profile:=ProfileRuntime.get_profile();eligible=unlocked(profile);water_branch=profile.waterworks_memory
	branch="";held=true;grip_weight=1;bucket_goals.clear();cup_held=false
	cup.get_node("WaterSurface").visible=water_branch=="water_public"
	actor.position=Vector3(3.7,0,2.8);actor.body_visual.rotation.y=PI
	motion.height_offset=0;motion.speed=0;motion.seated=false;motion.station="";motion.pending_station="";motion.destination_section=""
	motion.route.assign([Vector3(3.7,0,1.25),Vector3(2.5,0,1.25)]);motion._begin_walk()
	if not eligible:motion.route.clear();motion.phase="idle";motion._change_clip("Idle");held=false;cup.position=bucket_home
	_enter("approach" if eligible else "locked");_camera(0)

func _build_ui() -> void:
	super._build_ui()
	screen.find_child("SkipSeatMoment",true,false).name="SkipBucketMoment"
	next_button.name="NextBucketLine"
	choices.get_child(0).name="ChoiceRest";choices.get_child(1).name="ChoiceDoor"
	exits.get_child(0).name="BucketReturn";exits.get_child(1).name="ReplayBucket"

func _refresh_language() -> void:
	if not is_instance_valid(screen):return
	screen.find_child("SeatTitle",true,false).text=tr("THE BIGGEST BUCKET / BACK AT HOME")
	choices.visible=phase=="choice";exits.visible=phase=="done";next_button.visible=phase in ["intro","hesitate","ending"]
	var text:="Complete a water delivery and return safely to see this moment."
	if phase=="approach":text="Tang Kui: Upstairs. Bucket and all. She has been waiting."
	elif phase=="intro":text=(PUBLIC_LINES if water_branch=="water_public" else TANKER_LINES)[line_index]
	elif phase=="choice":text="There is a name on the bucket. And a very small flower."
	elif phase=="door":text="Tang Kui: Where are you taking her bucket?"
	elif phase=="hesitate":text=DOOR_LINES[line_index]
	elif phase=="back":text="Su Mi: There. I knew she would turn around."
	elif phase=="place":text="Shen: The stool is dry. Put it there."
	elif phase=="sit":text="Tang Kui: The bucket can stand. You sit."
	elif phase in ["ending","done"]:text=LAST_LINES[line_index]
	dialogue.text=tr(text)
	var labels:={"SkipBucketMoment":"RETURN TO QUARTERS","NextBucketLine":"NEXT LINE","ChoiceRest":"PUT IT DOWN / TAKE THE SEAT","ChoiceDoor":"CARRY IT TOWARD THE DOOR","BucketReturn":"RETURN TO QUARTERS","ReplayBucket":"REPLAY THIS MOMENT"}
	for button in screen.find_children("*","Button",true,false):
		if labels.has(String(button.name)):button.text=tr(labels[String(button.name)])
	if is_instance_valid(cup):cup.get_node("BucketName").text=tr("Shen")

func _enter(value: String) -> void:
	phase=value;phase_elapsed=0;line_index=LAST_LINES.size()-1 if value=="done" else 0;_refresh_language()
	if phase=="choice":choices.get_child(0).grab_focus()
	elif phase=="done":exits.get_child(0).grab_focus()
	elif next_button.visible:next_button.grab_focus()

func choose(value: String) -> void:
	# Base UI callbacks are reused, but the visible choices have their own actions.
	if phase!="choice" or leaving or value not in ["stay","rise"]:return
	branch="rest" if value=="stay" else "door"
	if branch=="rest":place_start=cup.position;_enter("place")
	else:
		motion.route.assign([Vector3(3.7,0,1.25),Vector3(3.7,0,2.8)]);motion._begin_walk();_enter("door")

func advance_line() -> void:
	if phase not in ["intro","hesitate","ending"] or leaving:return
	var lines: Array=(PUBLIC_LINES if water_branch=="water_public" else TANKER_LINES) if phase=="intro" else (DOOR_LINES if phase=="hesitate" else LAST_LINES)
	if line_index+1<lines.size():line_index+=1;_refresh_language();return
	if phase=="intro":_enter("choice")
	elif phase=="hesitate":
		motion.route.assign([Vector3(3.7,0,1.25),Vector3(2.5,0,1.25)]);motion._begin_walk();_enter("back")
	else:_enter("done")

func _process(delta: float) -> void:
	if not is_instance_valid(motion) or leaving:return
	motion._process(delta);phase_elapsed+=delta
	if phase=="approach" and motion.phase=="idle":_enter("intro")
	elif phase=="door" and motion.phase=="idle":_enter("hesitate")
	elif phase=="back" and motion.phase=="idle":place_start=cup.position;_enter("place")
	elif phase=="sit" and motion.seated and motion.phase=="idle":_enter("ending")
	if held:
		var desired:=_carry_position()
		if phase=="place":
			desired=place_start.lerp(bucket_home,smoothstep(0,1.4,phase_elapsed))
			grip_weight=1-smoothstep(1.5,2.0,phase_elapsed)
		cup.position=desired;_grip_bucket()
		if phase=="place" and phase_elapsed>=2:
			held=false;grip_weight=0;cup.position=bucket_home
			motion.route.assign([Vector3(2.5,0,0)]);motion.pending_station="rest";motion._begin_walk();_enter("sit")
	_camera(delta)

func _carry_position() -> Vector3:
	var forward:=Vector3.FORWARD.rotated(Vector3.UP,actor.body_visual.rotation.y)
	return actor.position+forward*.27+Vector3.UP*.94

func _grip_bucket() -> void:
	# Goals are on actual side handles. Only rotations change on the skeleton.
	var yaw:=actor.body_visual.rotation.y
	cup.rotation.y=yaw-PI
	for side in ["Right","Left"]:
		var local:=Vector3(right_side*.215*(1 if side=="Right" else -1),.12,0)
		var goal:=cup.to_global(local)
		bucket_goals[side]=goal;_palm(side,goal,grip_weight)

func _camera(delta: float) -> void:
	var focus:=Vector3(2.8,.95,1.1)
	var at:=Vector3(5.4,1.8,4.9)
	if phase in ["door","hesitate"]:focus=Vector3(3.4,1,2.1);at=Vector3(5.8,1.8,5.5)
	camera.position=camera.position.lerp(at,1-exp(-delta*3)) if delta>0 else at
	camera.fov=52;camera.look_at(focus)
