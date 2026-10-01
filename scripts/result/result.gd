extends Node3D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const UI_SCENE := preload("res://scenes/ui/result_ui.tscn")

var _pending_outcome: SortieOutcome
var finalize_save_path := SaveService.DEFAULT_SAVE_PATH
var result_ui: ResultUI


func _ready() -> void:
	var session := SortieRuntime.get_current_session()
	if not session:
		FlowMenu.show_error("No debrief is available. Return to base to start a new sortie.", true)
		return
	_pending_outcome = SortieRuntime.get_outcome()
	if not _pending_outcome:
		FlowMenu.show_error("The sortie could not be recovered. Return to base to continue.", true)
		return
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioDirector.set_music_context(&"result")
	VisualFactory.add_world_environment(self, Color("09111c"))
	VisualFactory.box(self, Vector3(24.0, 0.2, 16.0), Vector3(0.0, -0.1, 0.0), Color("1e2934"), "Floor")
	var preview := PLAYER_SCENE.instantiate() as PlayerController
	preview.preview_mode = true
	preview.position = Vector3(-4.2, 0.0, 0.0)
	preview.rotation.y = PI - 0.35
	preview.configure_loadout(session.inventory, session.loadout)
	add_child(preview)
	var camera := Camera3D.new()
	camera.position = Vector3(-4.0, 2.5, 6.8)
	camera.fov = 42.0
	camera.current = true
	add_child(camera)
	camera.look_at(Vector3(-3.2, 1.2, 0.0), Vector3.UP)
	result_ui = UI_SCENE.instantiate() as ResultUI
	result_ui.configure(_pending_outcome)
	add_child(result_ui)
	result_ui.return_requested.connect(_return_to_hanger)


func _return_to_hanger() -> void:
	if result_ui:
		result_ui.set_return_pending(true)
	var finalize_error := finalize_sortie(finalize_save_path)
	if finalize_error != OK:
		if result_ui:
			result_ui.show_return_error(tr("Save failed: %s. Retry, or press Esc for recovery options.") % error_string(finalize_error))
		return
	if _pending_outcome.mission_id == &"first_mission" and ProfileRuntime.get_profile().first_mission_completed:
		GameState.hideout_section = "Workshop"
	var scene_error := GameState.return_to_hanger()
	if scene_error != OK and result_ui:
		result_ui.show_return_error(tr("Could not open Hanger: %s") % error_string(scene_error))


func finalize_sortie(save_path: String = SaveService.DEFAULT_SAVE_PATH) -> Error:
	return SortieRuntime.finalize_sortie(save_path)
