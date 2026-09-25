class_name DestructibleWorldObject
extends StaticBody3D

const WORLD_COLLISION_LAYER := 1 << 2

@export_range(1.0, 100000.0, 1.0, "or_greater") var max_structure_health := 20.0

var current_structure_health := 0.0
var destroyed := false
var collision_shape: CollisionShape3D
var visual: MeshInstance3D


func _ready() -> void:
	collision_layer = WORLD_COLLISION_LAYER
	collision_mask = 0
	current_structure_health = max_structure_health
	collision_shape = get_node("CollisionShape3D") as CollisionShape3D
	visual = get_node("BarrierMesh") as MeshInstance3D


func receive_damage(packet: DamagePacket) -> float:
	if destroyed or packet.structure_damage <= 0.0:
		return 0.0
	var applied_damage := minf(packet.structure_damage, current_structure_health)
	current_structure_health = maxf(current_structure_health - applied_damage, 0.0)
	if current_structure_health <= 0.0:
		_destroy()
	return applied_damage


func _destroy() -> void:
	destroyed = true
	visual.visible = false
	collision_shape.set_deferred("disabled", true)
