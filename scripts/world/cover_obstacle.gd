class_name CoverObstacle
extends StaticBody3D

const WORLD_COLLISION_LAYER := 1 << 2


func _ready() -> void:
	collision_layer = WORLD_COLLISION_LAYER
	collision_mask = 0
