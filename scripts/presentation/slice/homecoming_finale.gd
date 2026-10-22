extends "res://scripts/presentation/slice/seat_moment.gd"
## The ending reuses the chair the player was promised, not the old conversation.
## No rewards, seen flags or save mutations; safe skip and free-play return.
const GUEST_PROFILE=preload("res://resources/presentation/subjects_female/campus_subject_profile.tres")
const HOME_INTRO=[
	"Tang Kui, on the radio: Two knocks. I said two.\nSu Mi: She knocked three times.\nShen: One was you kicking the door.",
	"Xu Tang: I thought I would never hear anyone complain about a door again.",
	"Tang Kui: Then sit down. There is plenty more where that came from.\nShen: The chair is still here.",
	"Su Mi: She has counted them twice.\nShen: I counted the people.",
]
const HOME_WAIT=[
	"Xu Tang: Do not get up. I can stand for a bit.\nShen: There is another chair.",
	"Tang Kui: There WAS another chair. Somebody left a rifle on it.\nShen: ...I will move it.",
	"Xu Tang: I am not leaving.\nSu Mi: Neither is anyone else tonight.",
]
const HOME_END=[
	"Tang Kui: Warm water first. The soup is in the pot.\nSu Mi: She saved the soup three times.",
	"Tang Kui: Two. I ate the first bowl.\nXu Tang: Then I will have the second.",
	"Shen: I should have come sooner.\nXu Tang: You came back. That is the part I was waiting for.",
	"[For once, nobody reaches for the radio.]",
	"Tang Kui: Who is washing up?\nSu Mi: The one who kicked the door.\nTang Kui: I am going to turn this thing off.",
	"Shen: Leave it.\nXu Tang: Let them argue. It is nice.\n[There is room at the table. The soup is still warm.]",
]
var guest: Node3D
var guest_animation: AnimationPlayer
var end_card: Panel

func _ready() -> void:
	super._ready()
	eligible=ProfileRuntime.get_profile().maintenance_closed
	guest.visible=eligible
	replay()

func _build_props() -> void:
	var table:=BoxMesh.new();table.size=Vector3(1.0,.045,.4)
	var center:=Vector3(cup_home.x-right_side*.25,.75,cup_home.z)
	_mesh(self,table,Color("8a6e50"),center)
	for x in [-.43,.43]:
		for z in [-.15,.15]:
			var leg:=BoxMesh.new();leg.size=Vector3(.035,.73,.035)
			_mesh(self,leg,Color("444c50"),Vector3(center.x+x,.365,center.z+z))
	cup=Node3D.new();cup.name="HomeWater";add_child(cup);cup.position=cup_home
	var body:=CylinderMesh.new();body.top_radius=.049;body.bottom_radius=.043;body.height=.12
	_mesh(cup,body,Color("b1c7bd"),Vector3.ZERO)
	var water:=CylinderMesh.new();water.top_radius=.043;water.bottom_radius=.043;water.height=.003
	_mesh(cup,water,Color("997e54"),Vector3(0,.054,0))
	var rim:=TorusMesh.new();rim.inner_radius=.043;rim.outer_radius=.049
	_mesh(cup,rim,Color("d8e1d8"),Vector3(0,.06,0))
	var pot:=CylinderMesh.new();pot.top_radius=.13;pot.bottom_radius=.11;pot.height=.14
	var pot_at:=Vector3(cup_home.x-right_side*.45,.845,cup_home.z)
	_mesh(self,pot,Color("556065"),pot_at)
	var soup:=CylinderMesh.new();soup.top_radius=.12;soup.bottom_radius=.12;soup.height=.003
	_mesh(self,soup,Color("b38b49"),pot_at+Vector3.UP*.067)
	guest=Node3D.new();guest.name="XuTangAtHome";add_child(guest)
	var model: Node3D=GUEST_PROFILE.model.instantiate();model.rotation.y=GUEST_PROFILE.forward_yaw;model.scale=Vector3.ONE*GUEST_PROFILE.model_scale
	for player: AnimationPlayer in model.find_children("*","AnimationPlayer",true,false):player.autoplay="";player.stop();player.active=false
	guest.add_child(model)
	guest_animation=AnimationPlayer.new();model.add_child(guest_animation);guest_animation.add_animation_library(&"",GUEST_PROFILE.animation_library)
	var nameplate:=Label3D.new();nameplate.font=UIFactory.FONT;nameplate.text="Xu Tang";nameplate.position.y=1.9;nameplate.font_size=24;nameplate.pixel_size=.006;nameplate.billboard=BaseMaterial3D.BILLBOARD_ENABLED;guest.add_child(nameplate)

func _build_ui() -> void:
	super._build_ui()
	var credits:=SliceUI.button(exits,"END CARD / CREDITS",Vector2.ZERO,Vector2(300,52),func():_enter("credits" if phase!="credits" else "done"));credits.custom_minimum_size=Vector2(300,52);credits.name="HomeCredits"
	end_card=SliceUI.panel(screen,Vector2(260,125),Vector2(760,320));end_card.name="FinaleEndCard";end_card.add_theme_stylebox_override("panel",FieldManualStyle.panel())
	var title:=SliceUI.label(end_card,"",Vector2(30,30),30,FieldManualStyle.ACCENT);title.name="FinaleEndTitle";title.size=Vector2(700,80);title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var credits_text:=SliceUI.label(end_card,"",Vector2(30,120),18,FieldManualStyle.INK);credits_text.name="FinaleCredits";credits_text.size=Vector2(700,170);credits_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART

func replay() -> void:
	super.replay()
	if is_instance_valid(guest):guest.position=Vector3(.7,0,1.8);guest.rotation.y=0

func _enter(value: String) -> void:
	phase=value;phase_elapsed=0;line_index=HOME_END.size()-1 if value=="done" else 0;_refresh_language()
	if phase=="choice":choices.get_child(0).grab_focus()
	elif phase in ["done","credits"]:exits.get_child(0).grab_focus()
	elif next_button.visible:next_button.grab_focus()

func _refresh_language() -> void:
	if not is_instance_valid(screen):return
	screen.find_child("SeatTitle",true,false).text=tr("EVERYONE IS HOME / THE END")
	choices.visible=phase=="choice";exits.visible=phase in ["done","credits"];next_button.visible=phase in ["intro","hesitate","ending"]
	var text:="Finish the backup-core operation and return safely to see this ending."
	if phase=="approach":text="Tang Kui: Shoes by the door. Sit before I eat your share."
	elif phase=="intro":text=HOME_INTRO[line_index]
	elif phase=="choice":text="Xu Tang stops beside the table. The chair is still yours."
	elif phase=="rise":text="Xu Tang: You do not have to move."
	elif phase=="hesitate":text=HOME_WAIT[line_index]
	elif phase=="resit":text="Shen: Sit. I moved the rifle.\nTang Kui: Only because she was looking at you."
	elif phase=="reach":text="Su Mi: Both hands on the cup. The rest can wait."
	elif phase in ["ending","done"]:text=HOME_END[line_index]
	elif phase=="credits":text="Tonight, nobody is waiting outside. Return to the table, or head back to base."
	dialogue.text=tr(text)
	var keys:={"SkipSeatMoment":"RETURN TO QUARTERS","NextSeatLine":"NEXT LINE","ChoiceStay":"KEEP THE SEAT","ChoiceRise":"MAKE ROOM FOR HER","SeatReturn":"FREE PLAY / BACK TO BASE","ReplaySeat":"REPLAY THIS ENDING","HomeCredits":"BACK TO THE TABLE" if phase=="credits" else "END CARD / CREDITS"}
	for button in screen.find_children("*","Button",true,false):
		if keys.has(String(button.name)):button.text=tr(keys[String(button.name)])
	if is_instance_valid(end_card):
		end_card.visible=phase=="credits"
		end_card.get_node("FinaleEndTitle").text=tr("THE END / EVERYONE IS HOME")
		end_card.get_node("FinaleCredits").text=tr("Neon Bastion / Local prototype\nGodot Engine\nThird-party asset credits: bundled notices\n\nThank you for bringing everyone home.")
	if is_instance_valid(guest) and guest.get_child_count()>0:
		var labels:=guest.find_children("*","Label3D",true,false)
		if not labels.is_empty():labels[0].text=tr("Xu Tang")

func advance_line() -> void:
	if phase not in ["intro","hesitate","ending"] or leaving:return
	var lines: Array=HOME_INTRO if phase=="intro" else (HOME_WAIT if phase=="hesitate" else HOME_END)
	if line_index+1<lines.size():line_index+=1;_refresh_language();return
	if phase=="intro":_enter("choice")
	elif phase=="hesitate":motion.pending_station="rest";motion._start_station();_enter("resit")
	else:_enter("done")

func _process(delta: float) -> void:
	super._process(delta)
	if not is_instance_valid(guest) or not eligible or leaving:return
	var goal:=Vector3(1.15,0,.35)
	var gap:=goal-guest.position
	var moving:=gap.length()>.035
	if moving:
		guest.position=guest.position.move_toward(goal,1.2*delta)
		guest.rotation.y=lerp_angle(guest.rotation.y,atan2(-gap.x,-gap.z),1-exp(-6*delta))
	else:guest.rotation.y=lerp_angle(guest.rotation.y,-PI/2,1-exp(-3*delta))
	var clip: StringName=GUEST_PROFILE.semantic_clips[&"walk" if moving else &"idle"]
	if guest_animation.current_animation!=String(clip):guest_animation.play(clip,.15)

func _camera(delta: float) -> void:
	var destination:=Vector3(4.8,1.8,3.5)
	camera.position=camera.position.lerp(destination,1-exp(-3*delta)) if delta>0 else destination
	camera.fov=57;camera.look_at(Vector3(2.05,.95,.25))
