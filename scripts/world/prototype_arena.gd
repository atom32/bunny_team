class_name PrototypeArena
extends Node3D

const TERMINAL_OBJECTIVE_ID := &"interact_prototype_terminal"


func _ready() -> void:
	VisualFactory.add_world_environment(self, Color("24211f"))
	var terminal := find_child("PrototypeTerminal", true, false) as ObjectiveInteractable
	if terminal and not terminal.objective_interacted.is_connected(_on_terminal_interacted):
		terminal.objective_interacted.connect(_on_terminal_interacted)


func _on_terminal_interacted(objective_id: StringName) -> void:
	if objective_id != TERMINAL_OBJECTIVE_ID:
		return
	var threat_event := find_child("LocalAlertEvent", true, false) as ThreatEvent
	if threat_event:
		threat_event.trigger()
