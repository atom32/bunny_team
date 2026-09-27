extends Node

# Boot enables the full presentation route. Direct Hanger/Result scene entry remains
# available to existing tools and component tests; neither path changes sortie state.
var presentation_enabled := false
var arrival_pending := false
var hideout_section := "Overview"
var _transition: SliceTransition

func begin_mission() -> Error:
	if presentation_enabled:
		return present_scene("res://scenes/presentation/slice/deployment.tscn", "OPERATION ACCEPTED")
	return get_tree().change_scene_to_file("res://scenes/battle/battle.tscn")


func finish_mission() -> Error:
	if presentation_enabled:
		return present_scene("res://scenes/result/result.tscn", "FLIGHT RECORDER / DEBRIEF")
	return get_tree().change_scene_to_file("res://scenes/result/result.tscn")


func return_to_hanger() -> Error:
	if presentation_enabled:
		return present_scene("res://scenes/presentation/slice/hideout.tscn", "BASTION 07 / WELCOME HOME")
	return get_tree().change_scene_to_file("res://scenes/hanger/hanger.tscn")

func open_hideout() -> Error:
	return present_scene("res://scenes/presentation/slice/hideout.tscn", "HOME SIGNAL ACQUIRED")

func open_menu() -> Error:
	return present_scene("res://scenes/presentation/slice/boot.tscn", "BASTION 07 / STANDBY")

func present_scene(path: String, caption: String) -> Error:
	if is_instance_valid(_transition): return ERR_BUSY
	if not ResourceLoader.exists(path): return ERR_FILE_NOT_FOUND
	_transition = SliceTransition.new()
	add_child(_transition)
	_transition.travel(path, caption)
	return OK
