extends Node3D
## A palette override for imported decorative GLBs; never creates collision.
@export var palette_material: Material
@export var floor_material: Material

func _ready() -> void:
	for node in find_children("*", "MeshInstance3D", true, false):
		if not node.has_meta("keep_material"):
			var is_floor := node.get_parent().name.begins_with("Floor")
			(node as MeshInstance3D).material_override = floor_material if floor_material and is_floor else palette_material
