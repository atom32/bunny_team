class_name WeaponDefinition
extends EquipmentDefinition

@export var weapon_type: StringName
@export var compatible_ammo_ids := PackedStringArray()
@export_range(0, 10000, 1, "or_greater") var magazine_capacity: int = 0
@export var fire_mode: StringName
@export var action_type: StringName = &"hitscan"
@export var uses_combat_rig := false

@export var damage: float = 10.0
@export_range(0.0, 10000.0, 0.1, "or_greater") var armor_penetration := 0.0
@export_range(0.0, 10000.0, 0.1, "or_greater") var structure_damage := 0.0
@export var fire_rate: float = 5.0
@export var weapon_range: float = 25.0
@export var projectile_speed: float = 20.0
@export var blast_radius: float = 0.0
@export var knockback: float = 2.0
@export var tracer_color: Color = Color.WHITE
@export var tracer_width: float = 0.045
@export var muzzle_scale: float = 1.0
@export var recoil_strength: float = 0.08
@export var impact_scale: float = 1.0


func get_runtime_ammo_definition_id() -> StringName:
	return StringName(compatible_ammo_ids[0]) if not compatible_ammo_ids.is_empty() else &""
