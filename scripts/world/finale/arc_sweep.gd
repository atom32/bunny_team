class_name FinaleSweep
extends Node3D
## Fixed authored lanes, not an omniscient attack that follows the player.
enum Phase { STARTUP, WARNING, SWEEP, COOLING, OFF }
const DURATIONS := [5.0,1.75,2.5,4.5,0.0]
const LANES := [-8.0,0.0,8.0]
var phase := Phase.STARTUP
var remaining := 5.0
var lane := 0
var cycle := 0
var hit_cooldown := 0.0
var actual_hits := 0 # Diagnostic only, not completion or checkpoint data.

func _ready() -> void:
	GameLanguage.language_changed.connect(refresh)
	refresh()

func enabled_lanes(session: SortieSession) -> Array[int]:
	var lanes: Array[int]=[1]
	if not FinaleStory.done(session,FinaleStory.LEFT):lanes.push_front(0)
	if not FinaleStory.done(session,FinaleStory.RIGHT):lanes.append(2)
	return lanes

func _physics_process(delta: float) -> void:
	var session:=SortieRuntime.get_current_session()
	if not session or session.mission_id!=FinaleStory.MISSION or session.status!=SortieSession.Status.ACTIVE:return
	if FinaleStory.done(session,FinaleStory.STOP):
		if phase!=Phase.OFF:phase=Phase.OFF;remaining=0;hit_cooldown=0;refresh()
		return
	hit_cooldown=maxf(0,hit_cooldown-delta)
	remaining=maxf(0,remaining-delta)
	if remaining==0:
		match phase:
			Phase.STARTUP,Phase.COOLING:
				var lanes:=enabled_lanes(session);lane=lanes[cycle%lanes.size()];phase=Phase.WARNING
			Phase.WARNING:phase=Phase.SWEEP
			Phase.SWEEP:phase=Phase.COOLING;cycle+=1
		remaining=DURATIONS[phase]
		if phase==Phase.WARNING:
			CombatNoise.emit_at(self,Vector3(LANES[lane],0,-9),28,&"mechanism")
			AudioDirector.play_sfx(&"blockade_lock",-12)
		elif phase==Phase.COOLING:AudioDirector.play_sfx(&"blockade_vent",-14)
	refresh()
	if phase==Phase.SWEEP:_apply_arc()

func bar_z() -> float:
	var t:=1-remaining/DURATIONS[Phase.SWEEP]
	return lerpf(6,-24,t) if cycle%2==0 else lerpf(-24,6,t)

func _apply_arc() -> void:
	if phase!=Phase.SWEEP:return
	var battle:=get_parent().get_parent().get_parent()
	var player: PlayerController=battle.player
	if not is_instance_valid(player) or player.is_dead or hit_cooldown>0:return
	var at:=player.global_position
	if absf(at.x-LANES[lane])>2.5 or absf(at.z-bar_z())>1.1 or at.y>1.2:return
	var packet:=DamagePacket.new(12,0,0,self,&"facility.arc",&"environment",at)
	if player.receive_damage(packet)>0:actual_hits+=1
	hit_cooldown=.65

func refresh() -> void:
	if not is_inside_tree():return
	var warning: MeshInstance3D=$WarningLane
	warning.visible=phase==Phase.WARNING
	warning.position=Vector3(LANES[lane],.035,-9)
	$LiveBar.visible=phase==Phase.SWEEP
	$LiveBar.position=Vector3(LANES[lane],.16,bar_z()) if phase==Phase.SWEEP else Vector3.ZERO
	$CoolingLamp.visible=phase==Phase.COOLING
	var names:=["LEFT","MIDDLE","RIGHT"]
	var line:=tr("CORE STARTING / %.1fs")%remaining
	if phase==Phase.WARNING:line=tr("AMBER / %s LANE / MOVE ASIDE")%tr(names[lane])
	elif phase==Phase.SWEEP:line=tr("LIVE ARC / %s LANE")%tr(names[lane])
	elif phase==Phase.COOLING:line=tr("BLUE WINDOW / %.1fs / SIDE FEEDS")%remaining
	elif phase==Phase.OFF:line=tr("NO RESTART / SHELTER POWER ON")
	$WorldLabel.text=tr(line)
	$Rotor.rotation.y=float(cycle)*PI+(1-remaining/maxf(.001,DURATIONS[phase]))*PI if phase!=Phase.OFF else float(cycle)*PI

func valid_checkpoint(raw: Dictionary,session: SortieSession) -> bool:
	if not SortieCheckpoint.integer(raw.phase,0,Phase.OFF) or not SortieCheckpoint.integer(raw.lane,0,2) or not SortieCheckpoint.integer(raw.cycle,0,1000000):return false
	if raw.remaining<0 or raw.remaining>DURATIONS[int(raw.phase)] or raw.hit_cooldown<0 or raw.hit_cooldown>.65:return false
	if (int(raw.phase)==Phase.OFF)!=FinaleStory.done(session,FinaleStory.STOP):return false
	if int(raw.phase)==Phase.OFF and (raw.remaining!=0 or raw.hit_cooldown!=0):return false
	return int(raw.phase) not in [Phase.WARNING,Phase.SWEEP] or int(raw.lane) in enabled_lanes(session)
