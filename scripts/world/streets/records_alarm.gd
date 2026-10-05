class_name RecordsAlarm
extends Node3D
## One public, local consequence of accessing records. Never spawns enemies or
## grants them a live player coordinate. The existing hearing/search system owns AI.
const DELAY := 25.0
const RADIUS := 45.0
enum Phase {IDLE, WARNING, SOUNDED}
var phase := Phase.IDLE
var remaining := 0.0
var session: SortieSession

func arm(current: SortieSession) -> bool:
	if phase != Phase.IDLE or not current or current.status != SortieSession.Status.ACTIVE: return false
	var objective := current.get_objective_state(&"streets_terminal")
	if not objective or objective.status != ObjectiveState.Status.COMPLETED: return false
	session = current
	phase = Phase.WARNING
	remaining = DELAY
	AudioDirector.play_sfx(&"ui_click") # Existing radio/UI chirp placeholder.
	SortieRuntime.request_checkpoint()
	return true

func _process(delta: float) -> void: tick(delta)

func sound_now(current: SortieSession) -> bool:
	if not is_inside_tree() or phase == Phase.SOUNDED or not current or current.status != SortieSession.Status.ACTIVE: return false
	session = current
	phase = Phase.SOUNDED
	remaining = 0.0
	CombatNoise.emit_at(self,global_position,RADIUS,&"alarm")
	AudioDirector.play_sfx(&"ui_confirm")
	SortieRuntime.request_checkpoint()
	return true

func tick(delta: float) -> void:
	if not is_inside_tree() or get_tree().paused or phase != Phase.WARNING or not session or session.status != SortieSession.Status.ACTIVE: return
	remaining = maxf(0.0,remaining-delta)
	if remaining > 0: return
	sound_now(session)

func caption() -> String:
	match phase:
		Phase.WARNING: return TranslationServer.translate("RECORDS ALARM IN %ds / Nearby guards will investigate") % ceili(remaining)
		Phase.SOUNDED: return TranslationServer.translate("RECORDS ALARM SENT / Exits remain available")
	return TranslationServer.translate("Records: copy 8s, alarm 25s later. Fast uplink: 3s, alarm now. Damage cancels work.")

func snapshot() -> Dictionary: return {"phase":phase,"remaining":remaining}

static func valid_snapshot(raw: Variant) -> bool:
	if typeof(raw) != TYPE_DICTIONARY: return false
	if raw.is_empty(): return true # Pre-alarm save, without a fabricated pending event.
	if raw.size()!=2 or not SortieCheckpoint.integer(raw.get("phase"),0,2) or not SaveService.is_number(raw.get("remaining")): return false
	return raw.remaining > 0 and raw.remaining <= DELAY if raw.phase == Phase.WARNING else raw.remaining == 0

func restore(raw: Dictionary, current: SortieSession) -> void:
	session=current
	if raw.is_empty():
		var objective:=current.get_objective_state(&"streets_terminal")
		phase=Phase.SOUNDED if objective and objective.status==ObjectiveState.Status.COMPLETED else Phase.IDLE
		remaining=0.0
	else:
		phase=int(raw.phase);remaining=float(raw.remaining)
