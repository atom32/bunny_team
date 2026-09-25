class_name ExtractionPoint
extends Node3D

signal extracted(session: SortieSession, extraction_id: StringName)

@export var extraction_id: StringName = &"prototype_extract_south"


func _ready() -> void:
	add_to_group("interactable")
	_build_visual()


func can_extract(session: SortieSession) -> bool:
	return session != null and session.status == SortieSession.Status.ACTIVE


func extract(session: SortieSession) -> bool:
	if not can_extract(session) or not session.complete_extraction():
		return false
	extracted.emit(session, extraction_id)
	return true


func interact(_actor: Node3D, session: SortieSession) -> Dictionary:
	if extract(session):
		return {"success": true, "message": "Extraction Successful"}
	return {"success": false, "message": "Extraction Unavailable"}


func get_interaction_prompt(_actor: Node3D, session: SortieSession) -> String:
	return "E  EXTRACT" if can_extract(session) else ""


func _build_visual() -> void:
	var pad := VisualFactory.cylinder(self, 2.1, 0.12, Vector3(0.0, 0.06, 0.0), Color("263846"), "ExtractionPad")
	pad.material_override = VisualFactory.material(Color("263846"), 0.65, 0.3, Color("4bc7ff"), 1.2)
	for angle_index in range(8):
		var angle := TAU * float(angle_index) / 8.0
		var marker_position := Vector3(cos(angle) * 1.65, 0.17, sin(angle) * 1.65)
		var marker := VisualFactory.box(self, Vector3(0.42, 0.08, 0.16), marker_position, Color("72ddff"), "ExtractionMarker")
		marker.rotation.y = -angle
		marker.material_override = VisualFactory.material(Color("27768d"), 0.35, 0.3, Color("72ddff"), 3.0)
	var label := Label3D.new()
	label.text = "EXTRACTION"
	label.position = Vector3(0.0, 1.0, 0.0)
	label.font_size = 34
	label.outline_size = 10
	label.modulate = Color("a9efff")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
