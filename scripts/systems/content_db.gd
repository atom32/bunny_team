extends Node

const DEFAULT_MANIFEST: ContentManifest = preload("res://resources/content/content_manifest.tres")

var _definitions: Dictionary = {}
var _missions: Dictionary = {}
var _loot_tables: Dictionary = {}
var _areas: Dictionary = {}
var _enemies: Dictionary = {}


func _ready() -> void:
	_load_manifest(DEFAULT_MANIFEST)


func get_item(content_id: StringName, report_missing := true) -> ItemDefinition:
	var definition := _definitions.get(content_id) as ItemDefinition
	if not definition and report_missing:
		push_warning("Unknown content ID: %s" % content_id)
	return definition


func get_weapon(content_id: StringName, report_missing := true) -> WeaponDefinition:
	var definition := get_item(content_id, report_missing)
	if definition is WeaponDefinition:
		return definition as WeaponDefinition
	if definition and report_missing:
		push_warning("Content ID is not a weapon: %s" % content_id)
	return null


func get_ammo(content_id: StringName, report_missing := true) -> AmmoDefinition:
	var definition := get_item(content_id, report_missing)
	if definition is AmmoDefinition:
		return definition as AmmoDefinition
	if definition and report_missing:
		push_warning("Content ID is not ammunition: %s" % content_id)
	return null


func get_items() -> Array[ItemDefinition]:
	var result: Array[ItemDefinition] = []
	for definition: ItemDefinition in _definitions.values():
		result.append(definition)
	result.sort_custom(func(a: ItemDefinition, b: ItemDefinition) -> bool: return a.id < b.id)
	return result


func get_mission(mission_id: StringName, report_missing := true) -> MissionDefinition:
	var mission := _missions.get(mission_id) as MissionDefinition
	if not mission and report_missing:
		push_warning("Unknown mission ID: %s" % mission_id)
	return mission


func get_missions() -> Array[MissionDefinition]:
	var result: Array[MissionDefinition] = []
	for mission: MissionDefinition in _missions.values():
		result.append(mission)
	result.sort_custom(func(a: MissionDefinition, b: MissionDefinition) -> bool: return a.mission_id < b.mission_id)
	return result


func get_loot_table(table_id: StringName, report_missing := true) -> LootTableDefinition:
	var table := _loot_tables.get(table_id) as LootTableDefinition
	if not table and report_missing:
		push_warning("Unknown loot table ID: %s" % table_id)
	return table


func get_loot_tables() -> Array[LootTableDefinition]:
	var result: Array[LootTableDefinition] = []
	for table: LootTableDefinition in _loot_tables.values():
		result.append(table)
	result.sort_custom(func(a: LootTableDefinition, b: LootTableDefinition) -> bool: return a.table_id < b.table_id)
	return result


func get_area_definition(area_id: StringName, report_missing := true) -> AreaDefinition:
	var area := _areas.get(area_id) as AreaDefinition
	if not area and report_missing:
		push_warning("Unknown area ID: %s" % area_id)
	return area


func get_area_definitions() -> Array[AreaDefinition]:
	var result: Array[AreaDefinition] = []
	for area: AreaDefinition in _areas.values():
		result.append(area)
	result.sort_custom(func(a: AreaDefinition, b: AreaDefinition) -> bool: return a.id < b.id)
	return result


func get_enemy_definition(enemy_id: StringName, report_missing := true) -> EnemyDefinition:
	var enemy := _enemies.get(enemy_id) as EnemyDefinition
	if not enemy and report_missing:
		push_warning("Unknown enemy ID: %s" % enemy_id)
	return enemy


func get_enemy_definitions() -> Array[EnemyDefinition]:
	var result: Array[EnemyDefinition] = []
	for enemy: EnemyDefinition in _enemies.values():
		result.append(enemy)
	result.sort_custom(func(a: EnemyDefinition, b: EnemyDefinition) -> bool: return a.id < b.id)
	return result


func has_item(content_id: StringName) -> bool:
	return _definitions.has(content_id)


func has_mission(mission_id: StringName) -> bool:
	return _missions.has(mission_id)


func has_loot_table(table_id: StringName) -> bool:
	return _loot_tables.has(table_id)


func has_area(area_id: StringName) -> bool:
	return _areas.has(area_id)


func has_enemy(enemy_id: StringName) -> bool:
	return _enemies.has(enemy_id)


func _load_manifest(manifest: ContentManifest) -> void:
	_definitions.clear()
	_missions.clear()
	_loot_tables.clear()
	_areas.clear()
	_enemies.clear()
	for definition in manifest.definitions:
		if not definition:
			push_error("Content manifest contains an empty definition")
			continue
		if definition.id.is_empty():
			push_error("Content definition is missing a stable ID: %s" % definition.resource_path)
			continue
		if _definitions.has(definition.id):
			push_error("Duplicate content ID: %s" % definition.id)
			continue
		_definitions[definition.id] = definition
	for enemy in manifest.enemies:
		if not enemy or not enemy.validate_definition():
			push_error("Content manifest contains an invalid enemy definition")
			continue
		if _enemies.has(enemy.id) or _definitions.has(enemy.id):
			push_error("Duplicate content ID: %s" % enemy.id)
			continue
		_enemies[enemy.id] = enemy
	for mission in manifest.missions:
		if not mission or not mission.validate_definition():
			push_error("Content manifest contains an invalid mission definition")
			continue
		if _missions.has(mission.mission_id) or _enemies.has(mission.mission_id) or _definitions.has(mission.mission_id):
			push_error("Duplicate content ID: %s" % mission.mission_id)
			continue
		_missions[mission.mission_id] = mission
	for table in manifest.loot_tables:
		if not table or not table.validate_definition():
			push_error("Content manifest contains an invalid loot table definition")
			continue
		if _loot_tables.has(table.table_id) or _missions.has(table.table_id) or _enemies.has(table.table_id) or _definitions.has(table.table_id):
			push_error("Duplicate content ID: %s" % table.table_id)
			continue
		var entries_are_valid := true
		for entry in table.entries:
			if not _definitions.has(entry.definition_id):
				push_error("Loot table %s references unknown item ID: %s" % [table.table_id, entry.definition_id])
				entries_are_valid = false
		if entries_are_valid:
			_loot_tables[table.table_id] = table
	for area in manifest.areas:
		if not area or not area.validate_definition():
			push_error("Content manifest contains an invalid area definition")
			continue
		if _areas.has(area.id) or _loot_tables.has(area.id) or _missions.has(area.id) or _enemies.has(area.id) or _definitions.has(area.id):
			push_error("Duplicate content ID: %s" % area.id)
			continue
		_areas[area.id] = area
