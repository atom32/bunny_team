class_name ObjectiveInteractable
extends Node3D

signal objective_interacted(objective_id: StringName)

@export var objective_id: StringName
@export var interaction_prompt := "ACCESS TERMINAL"


func _ready() -> void:
	add_to_group("interactable")
	_build_visual()


func interact(_actor: Node3D, session: SortieSession) -> Dictionary:
	if session and session.record_objective_interaction(objective_id):
		objective_interacted.emit(objective_id)
		return {"success": true, "message": "Objective Updated"}
	return {"success": false, "message": "Objective Unavailable"}


func get_interaction_prompt(_actor: Node3D, session: SortieSession) -> String:
	if not session or session.status != SortieSession.Status.ACTIVE:
		return ""
	var state := session.get_objective_state(objective_id)
	if not state or state.objective_type != ObjectiveDefinition.Type.INTERACT or state.status == ObjectiveState.Status.COMPLETED:
		return ""
	return "E  %s" % interaction_prompt.to_upper()


func _build_visual() -> void:
	var pedestal := VisualFactory.box(self, Vector3(0.9, 1.1, 0.55), Vector3(0.0, 0.55, 0.0), Color("24323c"), "TerminalPedestal")
	pedestal.material_override = VisualFactory.material(Color("24323c"), 0.65, 0.35)
	var screen := VisualFactory.box(self, Vector3(0.68, 0.42, 0.06), Vector3(0.0, 0.82, -0.3), Color("3fd9ca"), "TerminalScreen")
	screen.material_override = VisualFactory.material(Color("164a4e"), 0.25, 0.2, Color("54f4df"), 3.0)
	var label := Label3D.new()
	label.text = "FIELD TERMINAL"
	label.position = Vector3(0.0, 1.45, 0.0)
	label.font_size = 26
	label.outline_size = 8
	label.modulate = Color("bffdf6")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
