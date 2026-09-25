class_name LootSpawnPoint
extends Node3D

const LOOT_PICKUP_SCENE := preload("res://scenes/world/loot_pickup.tscn")

@export var loot_table_id: StringName
@export_range(1, 32, 1, "or_greater") var roll_count := 1

var has_rolled := false


func setup(p_loot_table_id: StringName, p_roll_count := 1) -> void:
	loot_table_id = p_loot_table_id
	roll_count = maxi(p_roll_count, 1)


func spawn(rng: RandomNumberGenerator) -> Array[LootPickup]:
	var pickups: Array[LootPickup] = []
	if has_rolled or not rng:
		return pickups
	var table := ContentDB.get_loot_table(loot_table_id, false)
	if not table:
		return pickups
	var items := LootRollService.roll(table, rng, roll_count)
	if items.is_empty():
		return pickups
	has_rolled = true
	for item in items:
		var pickup := LOOT_PICKUP_SCENE.instantiate() as LootPickup
		pickup.setup(item)
		add_child(pickup)
		pickups.append(pickup)
	return pickups
