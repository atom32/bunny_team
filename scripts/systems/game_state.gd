extends Node

func begin_mission() -> Error:
	return get_tree().change_scene_to_file("res://scenes/battle/battle.tscn")


func finish_mission() -> Error:
	return get_tree().change_scene_to_file("res://scenes/result/result.tscn")


func return_to_hanger() -> Error:
	return get_tree().change_scene_to_file("res://scenes/hanger/hanger.tscn")
