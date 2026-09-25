class_name EnemyDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export var scene: PackedScene
@export_range(1.0, 100000.0, 1.0, "or_greater") var max_health := 60.0
@export_range(0.0, 10000.0, 0.1, "or_greater") var armor := 0.0
@export_range(0.1, 100.0, 0.1, "or_greater") var move_speed := 3.2
@export_range(0.1, 100.0, 0.1, "or_greater") var approach_speed := 1.15
@export_range(0.1, 10000.0, 0.1, "or_greater") var attack_damage := 3.2
@export_range(0.1, 1000.0, 0.1, "or_greater") var attack_range := 15.0
@export_range(0.01, 60.0, 0.01, "or_greater") var attack_cooldown_min := 1.9
@export_range(0.01, 60.0, 0.01, "or_greater") var attack_cooldown_max := 2.6


func validate_definition() -> bool:
	return (
		not id.is_empty()
		and not display_name.is_empty()
		and scene != null
		and max_health > 0.0
		and armor >= 0.0
		and move_speed > 0.0
		and approach_speed > 0.0
		and attack_damage > 0.0
		and attack_range > 0.0
		and attack_cooldown_min > 0.0
		and attack_cooldown_max >= attack_cooldown_min
	)
