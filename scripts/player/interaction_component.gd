class_name InteractionComponent
extends Node

signal prompt_changed(text: String)
signal interaction_finished(message: String, success: bool)

@export var interaction_radius := 2.6

var actor: Node3D
var session: SortieSession
var _current_target: Node3D
var _last_prompt := ""
var _enabled := true


func setup(p_actor: Node3D, p_session: SortieSession) -> void:
	actor = p_actor
	session = p_session


func _physics_process(_delta: float) -> void:
	if not _enabled or not is_instance_valid(actor) or not session or session.status != SortieSession.Status.ACTIVE:
		_set_prompt("")
		return
	_current_target = _find_nearest_interactable()
	if _current_target and _current_target.has_method("get_interaction_prompt"):
		_set_prompt(str(_current_target.get_interaction_prompt(actor, session)))
	else:
		_set_prompt("")


func _unhandled_input(event: InputEvent) -> void:
	if _enabled and session and session.status == SortieSession.Status.ACTIVE and event.is_action_pressed("interact"):
		interact_with_current()
		get_viewport().set_input_as_handled()


func interact_with_current() -> Dictionary:
	if not session or session.status != SortieSession.Status.ACTIVE:
		return {"success": false, "message": "No active sortie"}
	if not is_instance_valid(_current_target):
		_current_target = _find_nearest_interactable()
	if not _current_target or not _current_target.has_method("interact"):
		return {"success": false, "message": "Nothing to interact with"}
	var response: Variant = _current_target.interact(actor, session)
	if typeof(response) != TYPE_DICTIONARY:
		response = {"success": false, "message": "Interaction failed"}
	interaction_finished.emit(str(response.get("message", "")), bool(response.get("success", false)))
	return response


func set_enabled(value: bool) -> void:
	_enabled = value
	set_physics_process(value)
	set_process_unhandled_input(value)
	if not value:
		_current_target = null
		_set_prompt("")


func _find_nearest_interactable() -> Node3D:
	var nearest: Node3D
	var nearest_distance_squared := interaction_radius * interaction_radius
	for candidate_node in get_tree().get_nodes_in_group("interactable"):
		var candidate := candidate_node as Node3D
		if not candidate or not candidate.has_method("interact"):
			continue
		var distance_squared := actor.global_position.distance_squared_to(candidate.global_position)
		if distance_squared <= nearest_distance_squared:
			nearest = candidate
			nearest_distance_squared = distance_squared
	return nearest


func _set_prompt(text: String) -> void:
	if text == _last_prompt:
		return
	_last_prompt = text
	prompt_changed.emit(text)
