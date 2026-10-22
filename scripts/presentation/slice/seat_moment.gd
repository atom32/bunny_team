extends Node3D
## Optional Q01 homecoming. All choices are presentation; no rewards/save writes.
const MOTION=preload("res://scripts/presentation/slice/training_motion.gd")
const CONTACT=preload("res://scripts/presentation/bunny_master/rifle_contact.gd")
const INTRO=[
 "Tang Kui, on the radio: Sit down first. The treadmill can wait.",
 "Su Mi: Somebody wiped that bench three times. You had better sit before she starts again.",
 "Shen: The floor is wet. Stay there until it dries.\nTang Kui: It dried yesterday.",
 "Shen: ...You have been very talkative today.",
]
const HESITATE=[
 "Shen: Wait.\nSu Mi: Oh?",
 "Shen: ...The floor.\nTang Kui: Still dry. I checked.",
 "Shen: I said wait. Not forever. Just... a little longer.",
]
const ENDING=[
 "Tang Kui: Warm enough? She changed the water twice.\nShen: The kettle was in my way.",
 "Su Mi: Next time you come back, knock twice.\nShen: The door is not broken.",
 "Tang Kui: Nobody said it was.\nSu Mi: Then why did you go downstairs three times?",
 "Shen: ...Tomorrow, you two clean the bench.",
 "Tang Kui: Fine. You can keep the seat warm.\nShen: ...There is room for you too.",
]
var actor: PlayerController
var motion: Node
var camera: Camera3D
var screen: Control
var dialogue: Label
var next_button: Button
var choices: HBoxContainer
var exits: HBoxContainer
var cup: Node3D
var cup_home:=Vector3.ZERO
var right_side:=1.0
var phase:="approach"
var phase_elapsed:=0.0
var line_index:=0
var branch:=""
var eligible:=false
var leaving:=false
var cup_held:=false
var reach_weight:=0.0
var right_goal:=Vector3.ZERO
var left_goal:=Vector3.ZERO

static func available(profile: ProfileState) -> bool:
 return profile.first_mission_completed and bool(profile.narrative_slice.settled.Q01)

func _ready() -> void:
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 AudioDirector.set_music_context(&"hideout")
 eligible=available(ProfileRuntime.get_profile())
 actor=preload("res://scenes/player/player.tscn").instantiate();actor.preview_mode=true;add_child(actor)
 motion=MOTION.new();add_child(motion);motion.initialize(actor);motion.set_process(false)
 var sk:=actor.character_skeleton
 right_side=signf(sk.to_global(sk.get_bone_global_rest(sk.find_bone("Character1_RightArm")).origin).x-actor.position.x)
 cup_home=Vector3(2.5+right_side*.34,.83,.14)
 _build_props();_build_ui()
 camera=$Camera3D
 replay()
 GameLanguage.language_changed.connect(_refresh_language)

func _mesh(parent: Node3D,shape: Mesh,color: Color,at: Vector3) -> MeshInstance3D:
 var node:=MeshInstance3D.new();node.mesh=shape;node.position=at
 var material:=StandardMaterial3D.new();material.albedo_color=color;material.roughness=.7
 node.material_override=material;parent.add_child(node);return node

func _build_props() -> void:
 var table:=BoxMesh.new();table.size=Vector3(.34,.04,.35)
 _mesh(self,table,Color("8a6e50"),Vector3(cup_home.x,.75,cup_home.z))
 for x in [-.12,.12]:
  for z in [-.12,.12]:
   var leg:=BoxMesh.new();leg.size=Vector3(.035,.73,.035)
   _mesh(self,leg,Color("444c50"),Vector3(cup_home.x+x,.365,cup_home.z+z))
 cup=Node3D.new();cup.name="WarmCup";add_child(cup)
 var body:=CylinderMesh.new();body.top_radius=.049;body.bottom_radius=.043;body.height=.12
 _mesh(cup,body,Color("b1c7bd"),Vector3.ZERO)
 var water:=CylinderMesh.new();water.top_radius=.043;water.bottom_radius=.043;water.height=.003
 _mesh(cup,water,Color("79502f"),Vector3(0,.054,0))
 var rim:=TorusMesh.new();rim.inner_radius=.043;rim.outer_radius=.049
 _mesh(cup,rim,Color("d8e1d8"),Vector3(0,.06,0))
 cup.position=cup_home

func _build_ui() -> void:
 var layer:=CanvasLayer.new();add_child(layer);screen=SliceUI.root(layer);screen.theme=FieldManualStyle.theme()
 var top:=SliceUI.panel(screen,Vector2(24,16),Vector2(1232,72));top.add_theme_stylebox_override("panel",FieldManualStyle.panel())
 var title:=SliceUI.label(top,tr("SAVED YOU A SEAT / BACK AT HOME"),Vector2(20,20),23,FieldManualStyle.INK);title.name="SeatTitle"
 SliceUI.button(top,"RETURN TO QUARTERS",Vector2(952,12),Vector2(260,48),return_to_base).name="SkipSeatMoment"
 var bottom:=SliceUI.panel(screen,Vector2(24,548),Vector2(1232,156));bottom.add_theme_stylebox_override("panel",FieldManualStyle.panel())
 dialogue=SliceUI.label(bottom,"",Vector2(20,14),20,FieldManualStyle.INK);dialogue.size=Vector2(930,126);dialogue.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 next_button=SliceUI.button(bottom,"NEXT LINE",Vector2(972,94),Vector2(240,44),advance_line);next_button.name="NextSeatLine"
 choices=HBoxContainer.new();choices.name="SeatChoice";choices.position=Vector2(24,478);choices.add_theme_constant_override("separation",12);screen.add_child(choices)
 for id in ["stay","rise"]:
  var b:=SliceUI.button(choices,"STAY FOR A MOMENT" if id=="stay" else "GET UP TO HELP",Vector2.ZERO,Vector2(350,52),func():choose(id));b.name="Choice"+id.capitalize();b.custom_minimum_size=Vector2(350,52)
 exits=HBoxContainer.new();exits.name="AfterSeatMoment";exits.position=Vector2(24,478);exits.add_theme_constant_override("separation",12);screen.add_child(exits)
 SliceUI.button(exits,"RETURN TO QUARTERS",Vector2.ZERO,Vector2(300,52),return_to_base).name="SeatReturn"
 SliceUI.button(exits,"REPLAY THIS MOMENT",Vector2.ZERO,Vector2(300,52),replay).name="ReplaySeat"
 for b in exits.get_children():b.custom_minimum_size=Vector2(300,52)

func _refresh_language() -> void:
 screen.find_child("SeatTitle",true,false).text=tr("SAVED YOU A SEAT / BACK AT HOME")
 choices.visible=phase=="choice";exits.visible=phase=="done";next_button.visible=phase in ["intro","hesitate","ending"]
 var text:=""
 if phase=="locked":text="Finish the campus exit survey and return safely. This moment gives no supplies or bonuses."
 elif phase=="approach":text="Tang Kui, on the radio: The bench. Not the treadmill."
 elif phase=="intro":text=INTRO[line_index]
 elif phase=="choice":text="The cup beside the bench is still warm."
 elif phase=="rise":text="Shen: Wait."
 elif phase=="hesitate":text=HESITATE[line_index]
 elif phase=="resit":text="Tang Kui: Sit. I will tell them you are busy.\nSu Mi: Terribly busy. Both hands occupied."
 elif phase=="reach":text="Su Mi: There. Now she cannot run away.\nShen: Do not make her spill it."
 elif phase in ["ending","done"]:text=ENDING[line_index]
 dialogue.text=tr(text)
 for b in screen.find_children("*","Button",true,false):
  var key: String={"SkipSeatMoment":"RETURN TO QUARTERS","NextSeatLine":"NEXT LINE","ChoiceStay":"STAY FOR A MOMENT","ChoiceRise":"GET UP TO HELP","SeatReturn":"RETURN TO QUARTERS","ReplaySeat":"REPLAY THIS MOMENT"}.get(b.name,"")
  if not key.is_empty():b.text=tr(key)

func _enter(value: String) -> void:
 phase=value;phase_elapsed=0;line_index=ENDING.size()-1 if value=="done" else 0;_refresh_language()
 if phase=="choice":choices.get_child(0).grab_focus()
 elif phase=="done":exits.get_child(0).grab_focus()
 elif next_button.visible:next_button.grab_focus()

func replay() -> void:
 if leaving:return
 cup.position=cup_home;cup_held=false;reach_weight=0;branch=""
 actor.position=Vector3(3.7,0,1.25);actor.body_visual.rotation.y=PI/2
 motion.height_offset=0;motion.speed=0
 motion.station="";motion.pending_station="rest";motion.seated=false;motion.destination_section=""
 motion.route.assign([Vector3(2.5,0,1.25),Vector3(2.5,0,0)]);motion._begin_walk()
 if not eligible:
  motion.route.clear();motion.phase="idle";_enter("locked")
 else:_enter("approach")
 _camera(0)

func advance_line() -> void:
 if phase not in ["intro","hesitate","ending"] or leaving:return
 var lines: Array=INTRO if phase=="intro" else (HESITATE if phase=="hesitate" else ENDING)
 if line_index+1<lines.size():line_index+=1;_refresh_language();return
 if phase=="intro":_enter("choice")
 elif phase=="hesitate":
  motion.pending_station="rest";motion._start_station();_enter("resit")
 else:_enter("done")

func choose(value: String) -> void:
 if phase!="choice" or value not in ["stay","rise"] or leaving:return
 branch=value
 if value=="stay":_enter("reach")
 else:
  motion.station="idle";motion.phase="rise";motion.seated=false;motion._change_clip("Sitting_Exit");_enter("rise")

func return_to_base() -> void:
 if leaving:return
 GameState.hideout_section="Rest"
 leaving=GameState.present_scene("res://scenes/presentation/slice/hideout.tscn","PERSONAL QUARTERS")==OK

func _process(delta: float) -> void:
 if not is_instance_valid(motion) or leaving:return
 motion._process(delta)
 phase_elapsed+=delta
 if phase=="approach" and motion.seated and motion.phase=="idle":_enter("intro")
 elif phase=="rise" and not motion.seated and motion.phase=="idle":_enter("hesitate")
 elif phase=="resit" and motion.seated and motion.phase=="idle":_enter("reach")
 if phase=="reach":
  reach_weight=smoothstep(0,.85,phase_elapsed)
  if phase_elapsed>=1:cup_held=true
  if phase_elapsed>=3.2:_enter("ending")
 if cup_held or phase=="reach":_pose_cup()
 _camera(delta)

func _pose_cup() -> void:
 var lift:=smoothstep(1,2.7,phase_elapsed) if phase=="reach" else 1.0
 var held:=Vector3(2.5+right_side*.04,.93,.32)
 var desired:=cup_home.lerp(held,lift)
 right_goal=desired+Vector3(right_side*.05,0,0)
 left_goal=desired-Vector3(right_side*.05,0,0)
 _palm("Right",right_goal,reach_weight)
 _palm("Left",left_goal,smoothstep(.25,.85,lift)*reach_weight)
 if cup_held:cup.position=desired

func _palm(side: String,goal: Vector3,weight: float) -> void:
 if weight<=0:return
 var sk:=actor.character_skeleton
 var hand:=sk.find_bone("Character1_"+side+"Hand")
 var rest:=sk.get_bone_global_rest(hand)
 var middle:=sk.get_bone_global_rest(sk.find_bone("Character1_"+side+"HandMiddle1")).origin
 var palm_local:=rest.affine_inverse()*rest.origin.lerp(middle,.55)
 var pose:=sk.get_bone_global_pose(hand)
 var desired:=sk.to_local(goal)
 var current:=CONTACT.palm(sk,side)
 var wrist:=current.lerp(desired,weight)-pose.basis*palm_local
 _reach_arm(sk,side,wrist)
 _set_basis(sk,hand,pose.basis)
 for finger in ["Thumb","Index","Middle","Ring","Pinky"]:
  for joint in range(1,4):
   var bone:=sk.find_bone("Character1_"+side+"Hand"+finger+str(joint))
   var rotation:=sk.get_bone_pose_rotation(bone)
   var bend:=deg_to_rad(([12,25,18] if finger=="Thumb" else [18,35,25])[joint-1])*weight
   sk.set_bone_pose_rotation(bone,rotation*Quaternion(Vector3.RIGHT,bend if side=="Right" else -bend))

func _reach_arm(sk: Skeleton3D,side: String,goal: Vector3) -> void:
 # Rotation-only analytic reach. Never assign global pose origins: the imported
 # hand lengths must remain the model's, even when a target is out of reach.
 var upper:=sk.find_bone("Character1_"+side+"Arm")
 var elbow:=sk.find_bone("Character1_"+side+"ForeArm")
 var hand:=sk.find_bone("Character1_"+side+"Hand")
 var root:=sk.get_bone_global_pose(upper).origin
 var middle:=sk.get_bone_global_pose(elbow).origin
 var tip:=sk.get_bone_global_pose(hand).origin
 var direction:=root.direction_to(goal)
 var a:=root.distance_to(middle);var b:=middle.distance_to(tip)
 var d:=clampf(root.distance_to(goal),absf(a-b)+.0001,a+b-.0001)
 var along:=(a*a+d*d-b*b)/(2*d)
 var pole:=sk.global_basis.inverse()*Vector3.DOWN
 var outward:=(pole-direction*pole.dot(direction)).normalized()
 var joint:=root+direction*along+outward*sqrt(maxf(0,a*a-along*along))
 _set_basis(sk,upper,Basis(Quaternion((middle-root).normalized(),(joint-root).normalized()))*sk.get_bone_global_pose(upper).basis)
 middle=sk.get_bone_global_pose(elbow).origin;tip=sk.get_bone_global_pose(hand).origin
 _set_basis(sk,elbow,Basis(Quaternion((tip-middle).normalized(),(goal-middle).normalized()))*sk.get_bone_global_pose(elbow).basis)

func _set_basis(sk: Skeleton3D,index: int,desired: Basis) -> void:
 var parent:=sk.get_bone_parent(index)
 var local: Basis=sk.get_bone_global_pose(parent).basis.inverse()*desired if parent>=0 else desired
 sk.set_bone_pose_rotation(index,local.orthonormalized().get_rotation_quaternion())

func _camera(delta: float) -> void:
 var close:=phase not in ["approach","locked","rise"]
 var destination:=Vector3(4.45,1.55,2.65) if close else Vector3(4.8,1.7,3.2)
 camera.position=camera.position.lerp(destination,1-exp(-delta*3)) if delta>0 else destination
 camera.fov=53
 camera.look_at(Vector3(2.5,.95,.15))
