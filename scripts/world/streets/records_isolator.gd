class_name RecordsIsolator
extends Node3D
## Solid cabinet. Work/deadline state belongs to the connected RecordsAlarm.
var alarm: RecordsAlarm

func _ready() -> void:
	add_to_group("interactable")
	alarm = get_node("../StreetTerminal/RecordsAlarm")
	get_node("Lamp").material_override = get_node("Lamp").material_override.duplicate()
	GameLanguage.language_changed.connect(_refresh_visual)
	_refresh_visual()

func _process(_delta: float) -> void: _refresh_visual()

func _refresh_visual() -> void:
	if not is_instance_valid(alarm): return
	var isolated := alarm.phase == RecordsAlarm.Phase.ISOLATED
	get_node("Lamp").material_override.albedo_color = status_color()
	get_node("Lever").rotation_degrees.z = -55.0 if isolated else 0.0
	get_node("WorldLabel").text = tr(status_label())

func status_label() -> String:
	if alarm.phase == RecordsAlarm.Phase.ISOLATED: return "BELL WIRE / ISOLATED"
	return "BELL ALREADY RANG" if alarm.phase == RecordsAlarm.Phase.SOUNDED else "BELL JUNCTION / 4s"

func status_color() -> Color:
	if alarm.phase == RecordsAlarm.Phase.ISOLATED: return Color("86d2b0")
	return Color("bb5144") if alarm.phase == RecordsAlarm.Phase.SOUNDED else Color("e8b058")

func interact(player: Node3D, current: SortieSession) -> Dictionary:
	return {"success":true,"message":"ISOLATING BELL / 4s nearby. Local tool noise; damage cancels."} if alarm.begin_isolation(player,current) else {"success":false,"message":"Bell box unavailable. Move close before it rings."}

func get_interaction_prompt(player: Node3D, current: SortieSession) -> String:
	if not current or current.status != SortieSession.Status.ACTIVE: return ""
	if alarm.phase == RecordsAlarm.Phase.ISOLATED: return tr("BELL WIRE / ISOLATED")
	if alarm.phase == RecordsAlarm.Phase.SOUNDED: return tr("BELL ALREADY RANG")
	if not alarm.can_isolate(player,current): return ""
	if alarm.isolation_remaining > 0: return tr("ISOLATING %.1fs / Stay close; damage cancels") % alarm.isolation_remaining
	return tr("%s  ISOLATE BELL / 4s / Local tool noise") % ControlBindings.label("interact")
