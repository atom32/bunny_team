extends "res://local_motion/player.gd"
## Peaceful survey unless the independent night sortie is explicitly accepted.
var night_operation: Node3D
var night_reload:=0.0

func _physics_process(delta: float) -> void:
	if night_reload>0:
		night_reload=maxf(0,night_reload-delta)
		if night_reload<=0 and night_operation and night_operation.state.active:
			var state: RefCounted=night_operation.state
			var amount:=mini(30-state.magazine,state.reserve);state.magazine+=amount;state.reserve-=amount
	super._physics_process(delta)

func _try_fire() -> bool:
	if not night_operation or not night_operation.running() or night_operation.state.magazine<=0 or night_reload>0:return false
	if not super._try_fire():return false
	night_operation.state.magazine-=1;night_operation.cancel_work();return true

func reload_weapon() -> bool:
	if not night_operation or not night_operation.running() or night_reload>0 or night_operation.state.magazine>=30 or night_operation.state.reserve<=0:return false
	night_operation.cancel_work();night_reload=1.6
	if combat_rig:combat_rig.reload_duration=1.6;combat_rig.start_reload()
	AudioDirector.play_sfx(&"reload");return true

func get_reload_remaining() -> float:
	return night_reload

func get_magazine_ammo() -> int:
	return night_operation.state.magazine if night_operation and night_operation.state.active else 0

func get_magazine_capacity() -> int:
	return 30 if night_operation and night_operation.state.active else 0

func get_reserve_ammo() -> int:
	return night_operation.state.reserve if night_operation and night_operation.state.active else 0

func receive_damage(packet: DamagePacket) -> float:
	if not night_operation or not night_operation.running():return 0
	return super.receive_damage(packet)
