class_name MaintenanceAlarmCarrier
extends "res://scripts/enemies/infected_controller.gd"
## A carried alarm, not a summoner or a broadcast of the player's hidden position.
enum CallPhase { READY, WINDUP, COOLDOWN }
const WARNING_SECONDS := 1.0
const COOLDOWN_SECONDS := 7.0
const CALL_RADIUS := 32.0
var call_phase := CallPhase.READY
var call_remaining := 0.0
var calls_emitted := 0 # Diagnostics only, never progression or checkpoint input.
var call_interrupts := 0
var beacon: MeshInstance3D

func _build_visual() -> void:
	super._build_visual()
	VisualFactory.box(body_visual,Vector3(.3,.38,.18),Vector3(.28,1.2,.25),Color("394956"),"AlarmPack")
	VisualFactory.box(body_visual,Vector3(.025,.45,.025),Vector3(.28,1.59,.25),Color("82969d"),"AlarmAntenna")
	beacon = VisualFactory.box(body_visual,Vector3(.18,.08,.19),Vector3(.28,1.43,.25),Color("d29a45"),"AlarmBeacon")
	beacon.material_override = beacon.material_override.duplicate()

func _movement_goal(delta: float) -> Vector3:
	return global_position if call_phase == CallPhase.WINDUP else super._movement_goal(delta)

func _telegraph_shot() -> void:
	if call_phase != CallPhase.WINDUP: super._telegraph_shot()

func _physics_process(delta: float) -> void:
	if is_dead: return
	var session := SortieRuntime.get_current_session()
	if not session or session.status != SortieSession.Status.ACTIVE:
		if call_phase == CallPhase.WINDUP: call_phase = CallPhase.READY; call_remaining = 0.0
		_refresh_call(); return
	if call_phase != CallPhase.READY:
		call_remaining = maxf(0.0,call_remaining-delta)
		if call_remaining == 0.0:
			if call_phase == CallPhase.WINDUP:
				call_phase = CallPhase.COOLDOWN; call_remaining = COOLDOWN_SECONDS
				calls_emitted += 1
				CombatNoise.emit_at(self,global_position,CALL_RADIUS,&"alarm")
				_call_sound(&"water_horn",-6.0)
			else: call_phase = CallPhase.READY
			SortieRuntime.request_checkpoint()
	super._physics_process(delta)
	if call_phase == CallPhase.READY and awareness.state == EnemyAwareness.State.COMBAT and awareness.target_visible and not _is_telegraphing:
		call_phase = CallPhase.WINDUP; call_remaining = WARNING_SECONDS
		_call_sound(&"blockade_lock",-7.0)
		SortieRuntime.request_checkpoint()
	_refresh_call()

func receive_damage(packet: DamagePacket) -> float:
	var applied := super.receive_damage(packet)
	if applied > 0.0 and not is_dead and call_phase == CallPhase.WINDUP:
		call_phase = CallPhase.COOLDOWN; call_remaining = 2.5
		call_interrupts += 1
		_refresh_call(); SortieRuntime.request_checkpoint()
	return applied

func _call_sound(cue: StringName, offset: float) -> void:
	var observer := PlayerVisibility.observer(self)
	var gain: float = observer.hear(global_position,CALL_RADIUS,&"alarm") if observer else 0.0
	if gain > 0.0: AudioDirector.play_sfx(cue,offset+linear_to_db(gain))

func _update_awareness_indicator() -> void:
	super._update_awareness_indicator()
	if call_phase == CallPhase.WINDUP:
		awareness_indicator.text = tr("CALLING!")
		awareness_indicator.modulate = Color("ffc66d")
		awareness_indicator.font_size = 40
		awareness_indicator.pixel_size = .014
		awareness_indicator.outline_size = 4
	else:
		awareness_indicator.font_size = 48
		awareness_indicator.pixel_size = .008
		awareness_indicator.outline_size = 12

func _refresh_call() -> void:
	if not is_instance_valid(beacon): return
	var color := Color("db4c39") if call_phase == CallPhase.COOLDOWN and call_remaining > 6.6 else Color("d29a45")
	if call_phase == CallPhase.WINDUP:
		color = Color("ffd275") if int(call_remaining*10)%2 == 0 else Color("e36f38")
	var material := beacon.material_override as StandardMaterial3D
	material.albedo_color = color
	material.emission_enabled = call_phase == CallPhase.WINDUP
	material.emission = color
	_update_awareness_indicator()

func call_snapshot() -> Dictionary:
	return {"phase":call_phase,"remaining":call_remaining}

static func valid_call(data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY or data.size() != 2 or not SortieCheckpoint.integer(data.get("phase"),0,2) or not SaveService.is_number(data.get("remaining")): return false
	if data.phase == CallPhase.READY: return data.remaining == 0.0
	return data.remaining >= 0.0 and data.remaining <= (WARNING_SECONDS if data.phase == CallPhase.WINDUP else COOLDOWN_SECONDS)

func restore_call(data: Dictionary) -> void:
	call_phase = int(data.phase); call_remaining = data.remaining
	_refresh_call()
