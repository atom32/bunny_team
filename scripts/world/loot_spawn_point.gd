class_name LootSpawnPoint
extends Node3D

const LOOT_PICKUP_SCENE := preload("res://scenes/world/loot_pickup.tscn")

@export var loot_table_id: StringName
@export_range(1, 32, 1, "or_greater") var roll_count := 1

@export var enabled := true
@export var bonus_loot_table_id: StringName
@export_range(0.0, 1.0) var bonus_chance := 0.0
var has_rolled := false


func setup(p_loot_table_id: StringName, p_roll_count := 1) -> void:
	loot_table_id = p_loot_table_id
	roll_count = maxi(p_roll_count, 1)


func spawn(rng: RandomNumberGenerator) -> Array[LootPickup]:
	var pickups: Array[LootPickup] = []
	if not enabled or has_rolled or not rng:
		return pickups
	var table := ContentDB.get_loot_table(loot_table_id, false)
	if not table:
		return pickups
	var items := LootRollService.roll(table, rng, roll_count)
	if items.is_empty():
		return pickups
	# Separate RNG stream: the optional find never displaces the core or changes
	# the quantities/content of later ordinary supplies. Restore uses saved items.
	if not bonus_loot_table_id.is_empty() and bonus_chance > 0.0 and SortieRuntime.resumed_world.is_empty():
		var bonus_rng := RandomNumberGenerator.new()
		bonus_rng.state = rng.state
		var bonus_roll:=bonus_rng.randf()
		if bonus_chance >= 1.0 or bonus_roll < bonus_chance:
			items.append_array(LootRollService.roll(ContentDB.get_loot_table(bonus_loot_table_id, false), bonus_rng))
	has_rolled = true
	for item in items:
		var pickup := LOOT_PICKUP_SCENE.instantiate() as LootPickup
		pickup.setup(item)
		add_child(pickup)
		pickups.append(pickup)
	return pickups
