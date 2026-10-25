class_name BlockadeVan
extends DestructibleWorldObject
## A fixed emplacement: acquires by LOS, then fires at a frozen point, never tracks through cover.
signal objective_interacted(objective_id: StringName)
signal state_changed
signal damage_observed(applied: float, exposed: bool)

enum Phase { IDLE, WARNING, BURST, VENT, WRECK }
const DURATIONS := [1.0, 1.5, 0.22, 2.3, 0.0]
const RANGE := 27.0
const DAMAGE := 14.0
const REAR_CENTER := Vector3(0,1.25,-3.5)
const REAR_HALF := Vector2(1.3,.7)

var phase := Phase.IDLE
var phase_remaining := 1.0
var burst_shots := 0
var aim_point := Vector3.ZERO
var speaker_enabled := true
var speaker_remaining := 2.0
var shots_fired := 0 # Diagnostic only; never an objective or a checkpoint input.
var broadcasts := 0

func _ready() -> void:
	super._ready()
	add_to_group("hostile_emplacements")
	if has_rear_radiator(): _build_rear_radiator()
	GameLanguage.language_changed.connect(refresh)
	refresh()

func _session() -> SortieSession:
	return SortieRuntime.get_current_session()

func _player() -> PlayerController:
	return get_tree().get_first_node_in_group("player") as PlayerController

func muzzle() -> Vector3:
	return global_position + Vector3(0, 2.6, 2.0)

func sees(player: PlayerController) -> bool:
	if not is_instance_valid(player) or player.is_dead or global_position.distance_to(player.global_position) > RANGE: return false
	var query := PhysicsRayQueryParameters3D.create(muzzle(), player.global_position + Vector3.UP * 1.1, 5)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.collider == player

func _physics_process(delta: float) -> void:
	var session := _session()
	if destroyed or not session or session.mission_id != BlockadeStory.MISSION or session.status != SortieSession.Status.ACTIVE: return
	speaker_remaining = maxf(0, speaker_remaining - delta)
	if speaker_enabled and speaker_remaining == 0:
		CombatNoise.emit_at(self, global_position + Vector3.UP * 3.5, 34, &"alarm")
		broadcasts += 1
		speaker_remaining = 7.0
		var sensor := PlayerVisibility.observer(self)
		var gain := sensor.hear(global_position, 34, &"alarm") if sensor else 0.0
		if gain > 0: AudioDirector.play_sfx(&"water_horn", linear_to_db(gain) - 5)
	phase_remaining = maxf(0, phase_remaining - delta)
	if phase_remaining > 0:
		_update_target()
		return
	match phase:
		Phase.IDLE:
			var player := _player()
			if not sees(player): return
			aim_point = player.global_position + Vector3.UP * 1.1
			_enter(Phase.WARNING)
		Phase.WARNING:
			burst_shots = 0
			_enter(Phase.BURST)
		Phase.BURST:
			_fire_locked_shot()
			burst_shots += 1
			if burst_shots == 4: _enter(Phase.VENT)
			else: phase_remaining = DURATIONS[Phase.BURST]
		Phase.VENT: _enter(Phase.IDLE)

func _enter(next: Phase) -> void:
	phase = next
	phase_remaining = DURATIONS[next]
	refresh()
	if next in [Phase.WARNING,Phase.VENT]:
		var sensor := PlayerVisibility.observer(self)
		var gain := sensor.hear(muzzle(), RANGE, &"mechanism") if sensor else 0.0
		if gain > 0: AudioDirector.play_sfx(&"blockade_lock" if next == Phase.WARNING else &"blockade_vent",linear_to_db(gain)-4)

func _fire_locked_shot() -> void:
	var origin := muzzle()
	var direction := origin.direction_to(aim_point)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * RANGE, 7)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	var end := origin + direction * RANGE
	if not hit.is_empty():
		end = hit.position
		if hit.collider.has_method("receive_damage"):
			hit.collider.receive_damage(DamagePacket.new(DAMAGE, 2, 0, self, &"blockade.turret", &"enemy", end, hit.normal, direction * 1.5))
	shots_fired += 1
	CombatEffects.tracer(get_tree().current_scene, origin, end, Color("ff954b"), .06)
	CombatEffects.hit(get_tree().current_scene, end, Color("ff954b"), .6)
	# Gunfire has its ordinary hearing consequence, even after the PA supply is cut.
	CombatNoise.emit_at(self, muzzle(), 26, &"gunshot")
	var sensor := PlayerVisibility.observer(self)
	var gain := sensor.hear(origin, 26, &"gunshot") if sensor else 0.0
	if gain > 0: AudioDirector.play_sfx(&"enemy_fire", linear_to_db(gain))

func has_rear_radiator() -> bool:
	var session := _session()
	return session != null and session.blockade.get("version",0)>=3

func _build_rear_radiator() -> void:
	# Render-only hardware matches the existing chassis's rear collision face.
	# No new hitbox, map signature, activation flag or saved node state.
	VisualFactory.box(self,Vector3(REAR_HALF.x*2,REAR_HALF.y*2,.03),REAR_CENTER+Vector3(0,0,-.015),Color("3f7982"),"RearRadiator")
	for i in 9:
		VisualFactory.box(self,Vector3(2.5,.055,.035),Vector3(0,.65+i*.15,-3.54),Color("83cbd0"),"RearFin%d"%i)
	var label := Label3D.new();label.name="RearLabel";label.position=Vector3(0,2.25,-3.65)
	label.font=load("res://assets/fonts/noto_sans_sc/NotoSansSC.ttf");label.font_size=28;label.pixel_size=.014
	label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.outline_size=4;add_child(label)

func rear_hit(packet: DamagePacket) -> bool:
	if not has_rear_radiator():return false
	var at := to_local(packet.hit_position)
	var normal := global_basis.inverse()*packet.hit_normal
	return normal.z<-.95 and absf(at.z-REAR_CENTER.z)<.035 and absf(at.x)<=REAR_HALF.x and absf(at.y-REAR_CENTER.y)<=REAR_HALF.y

func receive_damage(packet: DamagePacket) -> float:
	if destroyed or packet.source_faction != &"player": return 0.0
	# Armor is not invulnerability; spending ammunition blindly is possible but costly.
	var damage := maxf(packet.base_damage, packet.structure_damage)
	var exposed := phase == Phase.VENT or rear_hit(packet)
	if not exposed: damage *= .18
	if damage <= 0: return 0.0
	var applied := minf(current_structure_health, damage)
	current_structure_health = maxf(0, current_structure_health - applied)
	damage_observed.emit(applied,exposed)
	if current_structure_health == 0: _destroy()
	refresh()
	return applied

func cut_speaker() -> bool:
	var session := _session()
	if destroyed or not speaker_enabled or not session or session.status != SortieSession.Status.ACTIVE: return false
	speaker_enabled = false
	speaker_remaining = 0
	session.record_objective_interaction(&"blockade_speaker")
	refresh()
	SortieRuntime.request_checkpoint()
	return true

func _destroy() -> void:
	destroyed = true
	phase = Phase.WRECK
	phase_remaining = 0
	speaker_enabled = false
	speaker_remaining = 0
	var session := _session()
	if session and not session.blockade.is_empty():get_parent().van_disabled()
	else:
		if session:session.record_objective_interaction(&"blockade_van")
		objective_interacted.emit(&"blockade_van")
	refresh()
	var player := _player()
	if player and player.interaction_component and session and session.blockade.is_empty():player.interaction_component.information_read.emit(tr(BlockadeStory.END))
	SortieRuntime.request_checkpoint()

func refresh() -> void:
	if not is_node_ready(): return
	if has_node("RearLabel"):
		get_node("RearLabel").text=tr("REAR RADIATOR")
		get_node("RearLabel").visible=not destroyed
	# The disabled vehicle remains physical cover. No disappearing chassis or new kill credit.
	visual.visible = true
	collision_shape.set_deferred("disabled", false)
	get_node("WreckSmoke").visible = destroyed
	get_node("SpeakerLight").visible = speaker_enabled and not destroyed
	get_node("VentLight").visible = phase == Phase.VENT and not destroyed
	get_node("ShutterLeft").rotation.z = .8 if phase == Phase.VENT else 0.0
	get_node("ShutterRight").rotation.z = -.8 if phase == Phase.VENT else 0.0
	var beam := get_node("WarningLine") as MeshInstance3D
	beam.visible = phase in [Phase.WARNING, Phase.BURST] and not destroyed
	if beam.visible:
		var from := global_position + Vector3(0,.08,2)
		var to := Vector3(aim_point.x,.08,aim_point.z)
		beam.global_position = (from + to) * .5
		beam.global_basis = Basis.IDENTITY
		beam.rotation.y = atan2(to.x-from.x, to.z-from.z)
		beam.scale = Vector3(1,1,maxf(.01,from.distance_to(to)))

	_update_target()
	state_changed.emit()

func _update_target() -> void:
	var target := get_node("WarningTarget") as Node3D
	target.visible = phase in [Phase.WARNING,Phase.BURST] and not destroyed
	target.global_position = Vector3(aim_point.x,.065,aim_point.z)
	target.scale = Vector3.ONE * (1.0 + .12 * sin(phase_remaining*10.0))

func observed() -> bool:
	var sensor := PlayerVisibility.observer(self)
	if not sensor or not sensor.in_view(global_position): return false
	var camera := get_viewport().get_camera_3d()
	if not camera or camera.is_position_behind(muzzle()) or not get_viewport().get_visible_rect().has_point(camera.unproject_position(muzzle())): return false
	var query := PhysicsRayQueryParameters3D.create(sensor.actor.global_position+Vector3.UP*1.55,muzzle(),4)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.collider == self

func valid_checkpoint(entry: Dictionary, session: SortieSession) -> bool:
	if session.mission_id != BlockadeStory.MISSION or session.area_id != BlockadeStory.AREA: return false
	if entry.phase < 0 or entry.phase > Phase.WRECK or entry.burst_shots < 0 or entry.burst_shots > 4: return false
	if entry.phase_remaining < 0 or entry.phase_remaining > DURATIONS[entry.phase]: return false
	if entry.speaker_remaining < 0 or entry.speaker_remaining > 7: return false
	if Vector3(entry.aim_point[0], entry.aim_point[1], entry.aim_point[2]).distance_to(global_position) > RANGE + 2: return false
	if entry.destroyed != (session.blockade.van_down if not session.blockade.is_empty() else BlockadeStory.done(session,&"blockade_van")):return false
	if entry.destroyed != (entry.phase == Phase.WRECK): return false
	if entry.destroyed and (entry.speaker_enabled or entry.speaker_remaining != 0): return false
	if not entry.destroyed and entry.speaker_enabled == BlockadeStory.done(session, &"blockade_speaker"): return false
	if not entry.speaker_enabled and entry.speaker_remaining != 0: return false
	if entry.phase == Phase.BURST and entry.burst_shots >= 4: return false
	return true
