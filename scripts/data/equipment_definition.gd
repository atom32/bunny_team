class_name EquipmentDefinition
extends ItemDefinition

@export var socket_name: StringName
@export var scene: PackedScene
@export var damage_modifier: float = 0.0
@export var movement_modifier: float = 0.0
@export_range(0.0, 100.0, 0.5) var carry_capacity_bonus: float = 0.0
@export_range(0.0, 0.8, 0.01) var damage_reduction: float = 0.0
