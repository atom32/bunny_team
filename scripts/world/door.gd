class_name Door
extends Node3D

enum State {
	CLOSED,
	OPEN,
}

const CLOSED_ROTATION := 0.0
const OPEN_ROTATION := -PI * 0.5

@export_enum("Closed", "Open") var initial_state: int = State.CLOSED
@export var interaction_prompt := "OPEN DOOR"

var state: int = State.CLOSED

@onready var door_leaf: Node3D = $DoorLeaf
@onready var door_collision: CollisionShape3D = $DoorLeaf/DoorBody/CollisionShape3D


func _ready() -> void:
	add_to_group("interactable")
	state = initial_state
	_apply_state()


func open() -> bool:
	if state == State.OPEN:
		return false
	state = State.OPEN
	_apply_state()
	return true


func close() -> bool:
	if state == State.CLOSED:
		return false
	state = State.CLOSED
	_apply_state()
	return true


func toggle() -> bool:
	return close() if is_open() else open()


func is_open() -> bool:
	return state == State.OPEN


func interact(_actor: Node3D, session: SortieSession) -> Dictionary:
	if not session or session.status != SortieSession.Status.ACTIVE:
		return {"success": false, "message": "Door Unavailable"}
	toggle()
	return {"success": true, "message": "Door Opened" if is_open() else "Door Closed"}


func get_interaction_prompt(_actor: Node3D, session: SortieSession) -> String:
	if not session or session.status != SortieSession.Status.ACTIVE:
		return ""
	return "E  %s" % ("CLOSE DOOR" if is_open() else interaction_prompt.to_upper())


func _apply_state() -> void:
	door_leaf.rotation.y = OPEN_ROTATION if is_open() else CLOSED_ROTATION
	door_collision.disabled = is_open()
