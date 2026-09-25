class_name ThreatEvent
extends Area3D

signal activated(event: ThreatEvent, reinforcement_group_id: StringName)

@export var reinforcement_group_id: StringName = &"prototype_local_alert"
@export var trigger_on_body_entered := true

var triggered := false
var reinforcement_spawned := false
var _session: SortieSession


func setup(session: SortieSession) -> void:
	_session = session


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	if trigger_on_body_entered:
		_build_visual()


func try_trigger(body: Node) -> bool:
	if not body or not body.is_in_group("player"):
		return false
	return trigger()


func trigger() -> bool:
	if triggered or not _session or reinforcement_group_id.is_empty() or not _session.raise_threat():
		return false
	triggered = true
	activated.emit(self, reinforcement_group_id)
	return true


func mark_reinforcement_spawned() -> bool:
	if not triggered or reinforcement_spawned:
		return false
	reinforcement_spawned = true
	return true


func _on_body_entered(body: Node) -> void:
	if trigger_on_body_entered:
		try_trigger(body)


func _build_visual() -> void:
	var marker := VisualFactory.cylinder(self, 2.8, 0.04, Vector3(0.0, 0.03, 0.0), Color("713842"), "AlertZoneMarker")
	marker.material_override = VisualFactory.material(Color("4a2029"), 0.35, 0.35, Color("ff536d"), 1.6)
	var label := Label3D.new()
	label.text = "LOCAL ALERT ZONE"
	label.position = Vector3(0.0, 0.72, 0.0)
	label.font_size = 25
	label.outline_size = 8
	label.modulate = Color("ff9aaa")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
