class_name StashLayout
extends RefCounted
## A warehouse layout, not a second inventory. All transfers keep instance identity.
const COLUMNS := 12
const MAX_ROW := 10000
var profile: ProfileState

func _init(value: ProfileState) -> void:
	profile = value

func footprint(instance_id: String, rotated := false) -> Vector2i:
	var item := profile.inventory.get_item(instance_id)
	var definition := ContentDB.get_item(item.definition_id, false) if item else null
	var result := definition.stash_size if definition else Vector2i.ONE
	result = Vector2i(clampi(result.x, 1, COLUMNS), clampi(result.y, 1, COLUMNS))
	return Vector2i(result.y, result.x) if rotated else result

func reconcile() -> void:
	var old := profile.stash_layout.duplicate(true)
	profile.stash_layout.clear()
	for item in profile.inventory.get_items():
		if profile.loadout.is_equipped(item.instance_id): continue
		var entry: Variant = old.get(item.instance_id)
		if not _valid_entry(entry): continue
		var cell := Vector2i(int(entry[0]), int(entry[1]))
		if can_place(item.instance_id, cell, entry[2]):
			profile.stash_layout[item.instance_id] = [cell.x, cell.y, entry[2]]
	for item in profile.inventory.get_items():
		if profile.loadout.is_equipped(item.instance_id) or profile.stash_layout.has(item.instance_id): continue
		var cell := find_space(item.instance_id)
		profile.stash_layout[item.instance_id] = [cell.x, cell.y, false]

func _valid_entry(entry: Variant) -> bool:
	return typeof(entry) == TYPE_ARRAY and entry.size() == 3 and SaveService.is_number(entry[0]) and SaveService.is_number(entry[1]) and floor(entry[0]) == entry[0] and floor(entry[1]) == entry[1] and typeof(entry[2]) == TYPE_BOOL and entry[0] >= 0 and entry[0] < COLUMNS and entry[1] >= 0 and entry[1] < MAX_ROW

func rect_for(instance_id: String) -> Rect2i:
	var entry: Array = profile.stash_layout[instance_id]
	return Rect2i(Vector2i(entry[0], entry[1]), footprint(instance_id, entry[2]))

func can_place(instance_id: String, cell: Vector2i, rotated := false) -> bool:
	if not profile.inventory.contains(instance_id): return false
	var rect := Rect2i(cell, footprint(instance_id, rotated))
	if cell.x < 0 or cell.y < 0 or rect.end.x > COLUMNS or rect.end.y > MAX_ROW: return false
	for other_id in profile.stash_layout:
		if other_id == instance_id: continue
		if rect.intersects(rect_for(other_id)): return false
	return true

func find_space(instance_id: String, rotated := false) -> Vector2i:
	for y in range(row_count() + COLUMNS):
		for x in COLUMNS:
			if can_place(instance_id, Vector2i(x, y), rotated): return Vector2i(x, y)
	return Vector2i(-1, -1)

func move_item(instance_id: String, cell: Vector2i, rotated := false) -> bool:
	if not can_place(instance_id, cell, rotated): return false
	for slot in LoadoutState.SLOT_IDS:
		if profile.loadout.get_equipped_instance_id(slot) == instance_id:
			profile.loadout.unequip(slot)
	profile.stash_layout[instance_id] = [cell.x, cell.y, rotated]
	return true

func can_equip(instance_id: String, slot: StringName) -> bool:
	var item := profile.inventory.get_item(instance_id)
	return item != null and slot in LoadoutState.SLOT_IDS and profile.loadout._is_compatible(slot, item)

func equip_item(instance_id: String, slot: StringName) -> bool:
	if not can_equip(instance_id, slot): return false
	# Build the complete replacement first, so a rejected swap never partially unequips.
	var candidate := LoadoutState.from_dict(profile.loadout.to_dict())
	var source := &""
	for key in LoadoutState.SLOT_IDS:
		if candidate.get_equipped_instance_id(key) == instance_id: source = key
	if source == slot: return true
	var displaced := candidate.get_equipped_instance_id(slot)
	if not source.is_empty(): candidate.unequip(source)
	candidate.unequip(slot)
	if not candidate.equip(slot, instance_id, profile.inventory): return false
	if not source.is_empty() and not displaced.is_empty():
		if not candidate.equip(source, displaced, profile.inventory): return false
	if not candidate.validate(profile.inventory): return false
	profile.loadout._slots = candidate._slots.duplicate()
	reconcile()
	return true

func rotate_item(instance_id: String) -> bool:
	if not profile.stash_layout.has(instance_id): return false
	var entry: Array = profile.stash_layout[instance_id]
	return move_item(instance_id, Vector2i(entry[0], entry[1]), not entry[2])

func sort_items() -> void:
	profile.stash_layout.clear()
	var items := profile.inventory.get_items()
	items.sort_custom(func(a: ItemInstance, b: ItemInstance) -> bool:
		var sa := footprint(a.instance_id)
		var sb := footprint(b.instance_id)
		return sa.x * sa.y > sb.x * sb.y if sa != sb else String(a.definition_id) < String(b.definition_id)
	)
	for item in items:
		if profile.loadout.is_equipped(item.instance_id): continue
		var cell := find_space(item.instance_id)
		profile.stash_layout[item.instance_id] = [cell.x, cell.y, false]

func row_count() -> int:
	var rows := 8
	for instance_id in profile.stash_layout:
		rows = maxi(rows, rect_for(instance_id).end.y + 1)
	return rows
