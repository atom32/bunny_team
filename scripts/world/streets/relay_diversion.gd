class_name CampusRelayDiversion
extends Node3D
## An optional, finite sound source. Existing enemies hear it normally; no spawns,
## forced destinations, quest credit, extra loot or repair-time multiplier.
enum Phase { READY, PLAYING, SPENT }
const DURATION := 8.0
const PULSE_INTERVAL := 2.0
const INTRO := "Su Mi: That old PA switch still has power.\nTang Kui: You sound much too pleased about that.\nSu Mi: It is a school speaker. How loud can it be?\nShen: ...Take your headphones off."
const START := "[The west-wall speaker shrieks.]\nTang Kui: Su Mi!\nSu Mi: I found the volume knob.\nShen: Do not turn it up!\n[Another shriek.]\nSu Mi: ...Wrong way."
const END := "[The speaker coughs out.]\nTang Kui: I can still hear it.\nSu Mi: That is in your headphones.\nTang Kui: I took them off.\nSu Mi: ...Oh."
var phase := Phase.READY
var remaining := 0.0
var pulse_remaining := 0.0
var introduced := false

func _ready() -> void:
	add_to_group("interactable")
	$WorldLabel.font = UIFactory.FONT
	GameLanguage.language_changed.connect(refresh_visual)
	refresh_visual()

func _battle() -> Node3D: return get_parent().get_parent().get_parent()

func _available(current: SortieSession) -> bool:
	return current != null and current.status == SortieSession.Status.ACTIVE and current.campus.get("stage") == "relay" and int(get_parent().get_meta("map_revision", 0)) == 7

func interact(actor: Node3D, current: SortieSession) -> Dictionary:
	if not actor is PlayerController or actor.is_dead or not _available(current) or phase != Phase.READY:
		return {"success": false, "message": "The old PA cannot be used again."}
	if actor.global_position.distance_to(global_position) > actor.interaction_component.interaction_radius:
		return {"success": false, "message": "Move closer to the PA switch."}
	var query := PhysicsRayQueryParameters3D.create(actor.global_position + Vector3.UP, global_position + Vector3.UP, 4)
	query.exclude = [actor.get_rid()]
	if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():
		return {"success": false, "message": "A wall blocks the PA switch."}
	phase = Phase.PLAYING; remaining = DURATION; introduced = true
	_pulse(); refresh_visual()
	actor.interaction_component.information_read.emit(tr(START))
	SortieRuntime.request_checkpoint()
	return {"success": true, "message": "West speaker active. Enemies who see you still pursue you."}

func _pulse() -> void:
	CombatNoise.emit_at(self, $Speaker.global_position, 80.0, &"campus_pa")
	AudioDirector.play_sfx(&"campus_pa", -6.0)
	pulse_remaining = PULSE_INTERVAL

func _physics_process(delta: float) -> void:
	var battle := _battle()
	if not is_instance_valid(battle.player) or not _available(battle.session): return
	if not introduced and battle.player.global_position.distance_to(global_position) < 22:
		introduced = true
		battle.player.interaction_component.information_read.emit(tr(INTRO))
		SortieRuntime.request_checkpoint()
	if phase != Phase.PLAYING: return
	remaining = maxf(0, remaining - delta)
	pulse_remaining = maxf(0, pulse_remaining - delta)
	if remaining <= 0:
		phase = Phase.SPENT; pulse_remaining = 0
		refresh_visual()
		battle.player.interaction_component.information_read.emit(tr(END))
		SortieRuntime.request_checkpoint()
	elif pulse_remaining <= 0:
		_pulse()

func refresh_visual() -> void:
	$WorldLabel.text = tr("WEST PA / ONE USE" if phase == Phase.READY else ("WEST PA / ACTIVE" if phase == Phase.PLAYING else "WEST PA / SPENT"))
	$Switch.rotation_degrees.z = -55 if phase != Phase.READY else 0
	$Speaker/Lamp.visible = phase == Phase.PLAYING

func get_interaction_prompt(_actor: Node3D, current: SortieSession) -> String:
	if not _available(current): return ""
	return ControlBindings.label("interact") + "  " + tr("TRIGGER WEST PA / OPTIONAL DISTRACTION") if phase == Phase.READY else tr("PA USED / NO MORE POWER")

func valid_checkpoint(entry: Dictionary, current: SortieSession, world: Dictionary) -> bool:
	if current.campus.get("stage") != "relay" or int(world.map_revision) != 7 or not SortieCheckpoint.integer(entry.phase, 0, 2): return false
	if entry.remaining < 0 or entry.remaining > DURATION or entry.pulse_remaining < 0 or entry.pulse_remaining > PULSE_INTERVAL: return false
	if entry.phase != Phase.PLAYING and (entry.remaining != 0 or entry.pulse_remaining != 0): return false
	if entry.phase == Phase.PLAYING and entry.remaining <= 0: return false
	return entry.phase == Phase.READY or entry.introduced
