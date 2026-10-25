class_name CampusPowerEncounter
extends Node3D
## Fresh v3 power sorties only. No added collision geometry in an old campus save.
enum Phase { IDLE, ACTIVE, CLEARED }
const GROUP:=&"campus_power_charge"
const INTRO:="Su Mi: Wait. That noise is not the relay.\nShen: Away from the console. Now.\nTang Kui: It is wearing a DOOR!\nSu Mi: That is a shield!\nTang Kui: Tell it!"
const CLEAR:="Su Mi: There. Back to the console. L-02B only.\nTang Kui: Shen, your voice cracked.\nShen: Bad radio.\nSu Mi: Mine was very clear."
const CHOICE:="Su Mi: I could rip this whole cabinet out.\nTang Kui: The man by the window is on that wire too.\nSu Mi: ...I know.\nPlayer: Can we cover A first?\nSu Mi: ...Mind her label."
const OPERATION:="Close A's safety cover and unlock B. Both branches stay ON for now.\nIf a charger approaches, leave its orange lane. Defeat it, return here, then pull B OFF."
const COVER_OPEN:=-1.35
const CONFIRM:="CLOSE A COVER / UNLOCK B"
const SHELTER_NOTE:="The man\nby the window"
var phase:=Phase.IDLE

func _ready() -> void:
	add_to_group("campus_power_encounter")
	for entry in [["Ram",Vector3(-37,0,-35),&"campus_rammer"],["Follower0",Vector3(-37,0,-42),&"campus_infected"],["Follower1",Vector3(-47,0,-29),&"campus_infected"]]:
		var point:=EnemySpawnPoint.new();point.name=entry[0];point.position=entry[1];point.rotation.y=PI;point.enemy_definition_id=entry[2];point.initial_spawn=false;point.activation_group_id=GROUP;add_child(point)
	refresh_hardware()

func refresh_hardware(control: CampusAction=null) -> void:
	# Render-only hardware derives from the existing encounter/cut facts. It is
	# absent from v2 controls and adds no collider, work timer or checkpoint field.
	if not control:control=get_parent().get_node_or_null("L02BranchControl") as CampusAction
	if not control:return
	var hardware:=control.get_node_or_null("BranchHardware") as Node3D
	if not hardware:
		hardware=Node3D.new();hardware.name="BranchHardware";control.add_child(hardware)
		for x in [-.35,.35]:VisualFactory.box(hardware,Vector3(.30,.40,.045),Vector3(x,1.2,.81),Color("34474d"),"SwitchMount")
		for entry in [["ShelterCover",-.35,Color("507767")],["ExperimentCover",.35,Color("92664f")]]:
			var cover:=Node3D.new();cover.name=entry[0];cover.position=Vector3(entry[1],1.4,.86);hardware.add_child(cover)
			VisualFactory.box(cover,Vector3(.30,.38,.025),Vector3(0,-.19,0),entry[2],"CoverLeaf")
		var shelter:=hardware.get_node("ShelterCover") as Node3D
		VisualFactory.box(shelter,Vector3(.26,.20,.008),Vector3(0,-.19,.018),Color("ddd0ac"),"NamePaper")
		var note:=Label3D.new();note.name="ShelterNote";note.font=UIFactory.FONT;note.font_size=24;note.pixel_size=.0014;note.outline_size=0;note.modulate=Color("263b39");note.position=Vector3(0,-.19,.025);shelter.add_child(note)
		var lever:=Node3D.new();lever.name="ExperimentLever";lever.position=Vector3(.35,1.2,.89);hardware.add_child(lever)
		VisualFactory.box(lever,Vector3(.035,.17,.035),Vector3(0,.07,0),Color("abb8b7"),"LeverStem")
		VisualFactory.box(lever,Vector3(.15,.055,.06),Vector3(0,.15,0),Color("d5ac64"),"LeverGrip")
	var session:=SortieRuntime.get_current_session()
	var cut: bool=session!=null and not session.campus.is_empty() and session.campus.power_cut
	var guarded:=phase!=Phase.IDLE or cut
	hardware.get_node("ShelterCover").rotation.x=0.0 if guarded else COVER_OPEN
	hardware.get_node("ExperimentCover").rotation.x=COVER_OPEN if guarded else 0.0
	hardware.get_node("ExperimentLever").rotation.z=PI if cut else 0.0
	hardware.get_node("ShelterCover/ShelterNote").text=tr(SHELTER_NOTE)

func rammer() -> CampusRammer:
	var battle:=get_parent().get_parent().get_parent()
	if not battle or not "enemy_container" in battle or not is_instance_valid(battle.enemy_container):return null
	for enemy in battle.enemy_container.get_children():
		if enemy is CampusRammer and not enemy.is_dead:return enemy
	return null

func begin(actor: PlayerController) -> bool:
	var session:=SortieRuntime.get_current_session()
	if phase!=Phase.IDLE or not session or session.campus.is_empty() or session.campus.power_cut:return false
	phase=Phase.ACTIVE
	var battle:=get_parent().get_parent().get_parent()
	battle.spawn_reinforcement_group(GROUP)
	if not rammer():
		# Fail closed: never grant a cut because an encounter could not spawn.
		phase=Phase.IDLE;return false
	actor.interaction_component.interaction_finished.emit(tr("Charge incoming. Step out of the orange lane; L-02B is still on."),true)
	actor.interaction_component.information_read.emit(tr(INTRO));get_parent().refresh_campus_power();battle._sync_objective_hud();SortieRuntime.request_checkpoint()
	return true

func _physics_process(_delta: float) -> void:
	if phase!=Phase.ACTIVE or rammer()!=null:return
	phase=Phase.CLEARED
	get_parent().refresh_campus_power()
	var battle:=get_parent().get_parent().get_parent()
	if is_instance_valid(battle.player):battle.player.interaction_component.information_read.emit(tr(CLEAR))
	battle._sync_objective_hud();SortieRuntime.request_checkpoint()

func valid_checkpoint(entry: Dictionary,session: SortieSession,world: Dictionary) -> bool:
	if not SortieCheckpoint.integer(entry.get("phase"),0,2):return false
	if session.campus.is_empty() or session.campus.version<3 or session.campus.stage!="power":return false
	var prefix:=String(get_parent().get_path_to(self))+"/"
	for name in ["Ram","Follower0","Follower1"]:
		var data: Variant=world.nodes.get(prefix+name)
		if typeof(data)!=TYPE_DICTIONARY or data.get("has_spawned")!=(entry.phase!=Phase.IDLE):return false
	if entry.phase==Phase.CLEARED and world.enemies.has(prefix+"Ram"):return false
	if entry.phase==Phase.ACTIVE and session.campus.power_cut:return false
	if entry.phase==Phase.IDLE and session.campus.power_cut and not ProfileRuntime.get_profile().campus_chapter.branch_disconnected:return false
	return true
