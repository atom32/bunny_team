class_name DamagePacket
extends RefCounted

var base_damage: float
var armor_penetration: float
var structure_damage: float
var source_actor: Node
var source_weapon: StringName
var source_faction: StringName
var hit_position: Vector3
var hit_normal: Vector3
var knockback_impulse: Vector3


func _init(
	base_damage_value := 0.0,
	armor_penetration_value := 0.0,
	structure_damage_value := 0.0,
	source_actor_value: Node = null,
	source_weapon_value: StringName = &"",
	source_faction_value: StringName = &"",
	hit_position_value := Vector3.ZERO,
	hit_normal_value := Vector3.ZERO,
	knockback_impulse_value := Vector3.ZERO
) -> void:
	base_damage = maxf(base_damage_value, 0.0)
	armor_penetration = maxf(armor_penetration_value, 0.0)
	structure_damage = maxf(structure_damage_value, 0.0)
	source_actor = source_actor_value
	source_weapon = source_weapon_value
	source_faction = source_faction_value
	hit_position = hit_position_value
	hit_normal = hit_normal_value
	knockback_impulse = knockback_impulse_value
