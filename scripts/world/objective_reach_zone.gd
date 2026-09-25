class_name ObjectiveReachZone
extends Area3D

signal objective_reached(objective_id: StringName)

@export var objective_id: StringName

var _session: SortieSession


func setup(session: SortieSession) -> void:
	_session = session


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	_build_visual()


func try_reach(body: Node) -> bool:
	if (
		not body
		or not body.is_in_group("player")
		or not _session
		or not _session.record_objective_reached(objective_id)
	):
		return false
	objective_reached.emit(objective_id)
	return true


func _on_body_entered(body: Node) -> void:
	try_reach(body)


func _build_visual() -> void:
	var marker := VisualFactory.cylinder(self, 2.4, 0.04, Vector3(0.0, 0.03, 0.0), Color("485e8c"), "ReachZoneMarker")
	marker.material_override = VisualFactory.material(Color("25365c"), 0.4, 0.25, Color("74a8ff"), 1.8)
	var label := Label3D.new()
	label.text = "SURVEY ZONE"
	label.position = Vector3(0.0, 0.65, 0.0)
	label.font_size = 26
	label.outline_size = 8
	label.modulate = Color("b9d4ff")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
