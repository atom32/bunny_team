extends Node3D

func _ready() -> void:
	VisualFactory.add_world_environment(self, Color("24211f"))
