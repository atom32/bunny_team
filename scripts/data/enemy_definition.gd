class_name EnemyDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export var scene: PackedScene
@export var humanoid_presentation := false
@export_enum("Patrol", "Guard", "Flanker", "Pressure") var tactical_role: int = EnemyTactics.Role.PATROL
@export_range(1.0, 100000.0, 1.0, "or_greater") var max_health := 60.0
@export_range(0.0, 10000.0, 0.1, "or_greater") var armor := 0.0
@export_range(0.1, 100.0, 0.1, "or_greater") var move_speed := 3.2
@export_range(0.1, 100.0, 0.1, "or_greater") var approach_speed := 1.15
@export_range(0.1, 10000.0, 0.1, "or_greater") var attack_damage := 3.2
@export_range(0.1, 1000.0, 0.1, "or_greater") var attack_range := 15.0
@export_range(0.01, 60.0, 0.01, "or_greater") var attack_cooldown_min := 1.9
@export_range(0.01, 60.0, 0.01, "or_greater") var attack_cooldown_max := 2.6

@export_range(1.0, 100.0) var detection_range := 24.0
@export_range(10.0, 360.0) var view_angle := 110.0
@export_range(0.05, 5.0) var acquire_seconds := 0.35
@export_range(1.0, 60.0) var search_duration := 12.0
@export_range(0.0, 20.0) var patrol_radius := 3.0

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
		and detection_range > 0.0 and view_angle >= 10.0 and view_angle <= 360.0
		and acquire_seconds > 0.0 and search_duration > 0.0 and patrol_radius >= 0.0
		and tactical_role >= EnemyTactics.Role.PATROL and tactical_role <= EnemyTactics.Role.PRESSURE
	)
