class_name RecordsAlarm
extends Node3D
## One public, local consequence of accessing records. Never spawns enemies or
## grants them a live player coordinate. The existing hearing/search system owns AI.
const DELAY := 25.0
const RADIUS := 45.0
const ISOLATION_SECONDS := 4.0
const ISOLATION_REPLY := "Su Mi: Wire out?\nYou: Out.\nSu Mi: Press it twice to make sure--\nShen Yanshuang: Do not press it."
enum Phase {IDLE, WARNING, SOUNDED, ISOLATED}
var phase := Phase.IDLE
var remaining := 0.0
var session: SortieSession
var isolation_remaining := 0.0
var actor: PlayerController
var observed_health := 0.0

func isolation_box() -> Node3D: return get_node_or_null("../../RecordsIsolator")

func can_isolate(player: Node3D, current: SortieSession) -> bool:
	if not is_inside_tree() or get_tree().paused: return false
	var box := isolation_box()
	if not is_instance_valid(player) or not player is PlayerController or player.is_dead or not box or not current or current.status != SortieSession.Status.ACTIVE or phase in [Phase.SOUNDED,Phase.ISOLATED]: return false
	if player.global_position.distance_to(box.global_position) > player.interaction_component.interaction_radius: return false
	var ray := PhysicsRayQueryParameters3D.create(player.global_position+Vector3.UP,box.global_position+Vector3.UP*.8,4)
	var hit := player.get_world_3d().direct_space_state.intersect_ray(ray)
	return hit.is_empty() or hit.collider == box

func _bind_actor(player: PlayerController) -> void:
	if is_instance_valid(actor) and actor.health_changed.is_connected(_health_changed): actor.health_changed.disconnect(_health_changed)
	actor = player
	if is_instance_valid(actor):
		observed_health = actor.health
		actor.health_changed.connect(_health_changed)

func begin_isolation(player: Node3D, current: SortieSession) -> bool:
	if isolation_remaining > 0 or not can_isolate(player,current): return false
	_bind_actor(player);session = current
	isolation_remaining = ISOLATION_SECONDS
	CombatNoise.emit_at(self,isolation_box().global_position,12.0,&"repair")
	AudioDirector.play_sfx(&"ui_click")
	SortieRuntime.request_checkpoint()
	return true

func _health_changed(health: float, _maximum: float) -> void:
	if health < observed_health: _cancel_isolation("ISOLATION INTERRUPTED / Hit. Start again when safe.")
	observed_health = health

func _cancel_isolation(message: String) -> void:
	if isolation_remaining <= 0: return
	isolation_remaining = 0.0
	if is_instance_valid(actor) and not actor.is_dead and session and session.status == SortieSession.Status.ACTIVE:
		actor.interaction_component.interaction_finished.emit(TranslationServer.translate(message),false)
	SortieRuntime.request_checkpoint()

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
	if not is_inside_tree() or phase in [Phase.SOUNDED,Phase.ISOLATED] or not current or current.status != SortieSession.Status.ACTIVE: return false
	session = current
	phase = Phase.SOUNDED
	remaining = 0.0
	_cancel_isolation("TOO LATE / The bell rang. Guards keep what they heard.")
	CombatNoise.emit_at(self,global_position,RADIUS,&"alarm")
	AudioDirector.play_sfx(&"ui_confirm")
	SortieRuntime.request_checkpoint()
	return true

func tick(delta: float) -> void:
	if not is_inside_tree() or get_tree().paused or not session or session.status != SortieSession.Status.ACTIVE: return
	if isolation_remaining > 0:
		if not can_isolate(actor,session):
			_cancel_isolation("ISOLATION INTERRUPTED / Left the box, or the bell already rang.")
		elif phase == Phase.WARNING and remaining <= delta and remaining <= isolation_remaining:
			sound_now(session)
			return
		elif isolation_remaining <= delta:
			# At an exact tie the alarm wins. Both clocks consume the same delta.
			phase = Phase.ISOLATED;remaining = 0.0;isolation_remaining = 0.0
			AudioDirector.play_sfx(&"ui_confirm")
			actor.interaction_component.information_read.emit(TranslationServer.translate(ISOLATION_REPLY))
			actor.interaction_component.interaction_finished.emit(TranslationServer.translate("ALARM WIRE ISOLATED / Records and exits retain power."),true)
			SortieRuntime.request_checkpoint()
		else: isolation_remaining = maxf(0.0,isolation_remaining-delta)
	if phase != Phase.WARNING: return
	remaining = maxf(0.0,remaining-delta)
	if remaining > 0: return
	sound_now(session)

func caption() -> String:
	match phase:
		Phase.WARNING: return TranslationServer.translate("RECORDS ALARM IN %ds / Nearby guards will investigate") % ceili(remaining)
		Phase.SOUNDED: return TranslationServer.translate("RECORDS ALARM SENT / Exits remain available")
		Phase.ISOLATED: return TranslationServer.translate("ALARM WIRE ISOLATED / Records and exits retain power.")
	return TranslationServer.translate("Records: copy 8s, alarm 25s later. Fast uplink: 3s, alarm now. Damage cancels work.")

func snapshot() -> Dictionary:
	if not isolation_box(): return {"phase":phase,"remaining":remaining} # Re-saving an old suspended layout must not introduce its new cabinet later.
	return {"phase":phase,"remaining":remaining,"isolation_remaining":isolation_remaining}

static func valid_snapshot(raw: Variant) -> bool:
	if typeof(raw) != TYPE_DICTIONARY: return false
	if raw.is_empty(): return true # Pre-alarm save, without a fabricated pending event.
	if raw.size() not in [2,3] or not SortieCheckpoint.integer(raw.get("phase"),0,3) or not SaveService.is_number(raw.get("remaining")): return false
	if raw.size()==3 and not raw.has("isolation_remaining"): return false
	if raw.phase == Phase.ISOLATED and not raw.has("isolation_remaining"): return false
	var work: Variant = raw.get("isolation_remaining",0.0)
	if not SaveService.is_number(work) or work < 0 or work > ISOLATION_SECONDS or (work > 0 and int(raw.phase) in [Phase.SOUNDED,Phase.ISOLATED]): return false
	return raw.remaining > 0 and raw.remaining <= DELAY if raw.phase == Phase.WARNING else raw.remaining == 0

func restore(raw: Dictionary, current: SortieSession, player: PlayerController=null) -> void:
	session=current
	isolation_remaining=float(raw.get("isolation_remaining",0.0));_bind_actor(player)
	if raw.is_empty():
		var objective:=current.get_objective_state(&"streets_terminal")
		phase=Phase.SOUNDED if objective and objective.status==ObjectiveState.Status.COMPLETED else Phase.IDLE
		remaining=0.0
	else:
		phase=int(raw.phase);remaining=float(raw.remaining)
