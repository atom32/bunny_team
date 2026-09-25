class_name LootRollService
extends RefCounted


static func roll(
	table: LootTableDefinition,
	rng: RandomNumberGenerator,
	roll_count := 1
) -> Array[ItemInstance]:
	var results: Array[ItemInstance] = []
	if not table or not table.validate_definition() or not rng or roll_count <= 0:
		return results
	var total_weight := 0.0
	for entry in table.entries:
		if not ContentDB.has_item(entry.definition_id):
			return []
		total_weight += entry.weight
	if total_weight <= 0.0:
		return results
	for _roll_index in roll_count:
		var entry := _select_entry(table.entries, total_weight, rng)
		if not entry:
			return []
		var quantity := entry.min_quantity
		if entry.max_quantity > entry.min_quantity:
			quantity = rng.randi_range(entry.min_quantity, entry.max_quantity)
		results.append(ItemInstance.new(entry.definition_id, quantity))
	return results


static func _select_entry(
	entries: Array[LootTableEntry],
	total_weight: float,
	rng: RandomNumberGenerator
) -> LootTableEntry:
	var selection := rng.randf() * total_weight
	for entry in entries:
		selection -= entry.weight
		if selection < 0.0:
			return entry
	return entries.back()
