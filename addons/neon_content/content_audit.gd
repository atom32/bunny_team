@tool
extends RefCounted
## Read-only definition/reference audit. No instances, gameplay sessions or profile calls.
const FOLDERS := ["items", "weapons", "equipment", "ammo", "enemies", "missions", "loot", "areas"]

static func issue(report: Dictionary, severity: String, code: String, path: String, message: String) -> void:
	report[severity].append({"code": code, "path": path, "message": message})

static func item_errors(item: ItemDefinition) -> Array[String]:
	var errors: Array[String] = []
	if item.id.is_empty(): errors.append("Missing stable ID")
	if item.display_name.strip_edges().is_empty(): errors.append("Missing display name")
	if not is_finite(item.weight) or item.weight < 0: errors.append("Weight must be finite and nonnegative")
	if item.base_value < 0: errors.append("Value must be nonnegative")
	if item.stash_size.x < 1 or item.stash_size.y < 1: errors.append("Stash footprint must be positive")
	if item.max_stack < 1 or (not item.stackable and item.max_stack != 1): errors.append("Invalid stack limit")
	if item is EquipmentDefinition:
		if item.stackable: errors.append("Owned equipment cannot be stackable")
		if item.scene == null: errors.append("Equipment requires a wrapped scene")
		if item.socket_name.is_empty(): errors.append("Equipment requires a socket")
	if item is WeaponDefinition:
		if item.compatible_ammo_ids.is_empty(): errors.append("Weapon requires compatible ammunition")
		for field in ["damage", "fire_rate", "weapon_range", "reload_seconds"]:
			var value: float = item.get(field)
			if not is_finite(value) or value <= 0: errors.append("Weapon " + field + " must be positive")
		if item.magazine_capacity < 1: errors.append("Weapon magazine must be positive")
		if item.action_type not in [&"hitscan", &"projectile"]: errors.append("Unsupported weapon action_type")
	if item is MedicalDefinition:
		if not is_finite(item.healing) or item.healing <= 0 or not is_finite(item.use_seconds) or item.use_seconds <= 0:
			errors.append("Medical healing and duration must be positive")
	return errors

static func definition_valid(resource: Resource) -> bool:
	# Gameplay Resources are deliberately not @tool. Inspect their exported data
	# without invoking methods on Godot's editor placeholder instances.
	if resource is AreaDefinition:
		return not resource.id.is_empty() and not resource.display_name.is_empty() and resource.scene != null
	if resource is EnemyDefinition:
		if resource.id.is_empty() or resource.display_name.is_empty() or resource.scene == null: return false
		if resource.presentation_profile and not resource.presentation_profile.validate_profile(): return false
		for field in ["max_health", "move_speed", "approach_speed", "attack_damage", "attack_range", "attack_cooldown_min", "detection_range", "acquire_seconds", "search_duration"]:
			var value: float = resource.get(field)
			if not is_finite(value) or value <= 0: return false
		return is_finite(resource.armor) and resource.armor >= 0 and resource.attack_cooldown_max >= resource.attack_cooldown_min and is_finite(resource.attack_cooldown_max) and resource.view_angle >= 10 and resource.view_angle <= 360 and resource.patrol_radius >= 0 and is_finite(resource.patrol_radius) and resource.tactical_role >= 0 and resource.tactical_role <= 3
	if resource is LootTableDefinition:
		if resource.table_id.is_empty() or resource.entries.is_empty(): return false
		for entry in resource.entries:
			if not entry or entry.definition_id.is_empty() or not is_finite(entry.weight) or entry.weight <= 0 or entry.min_quantity < 1 or entry.max_quantity < entry.min_quantity: return false
		return true
	if resource is MissionDefinition:
		if resource.mission_id.is_empty() or resource.display_name.is_empty() or resource.objective_definitions.is_empty(): return false
		var ids := {}; var required := false
		for objective in resource.objective_definitions:
			if not objective or objective.objective_id.is_empty() or objective.display_name.is_empty() or ids.has(objective.objective_id) or objective.target < 1 or objective.objective_type not in [0, 1, 2]: return false
			if objective.objective_type != 0 and objective.target_id.is_empty(): return false
			ids[objective.objective_id] = true; required = required or objective.required
		return required
	return false

static func audit(manifest: ContentManifest, scan_files := true, recipes: Dictionary = {}) -> Dictionary:
	var report := {"pass": false, "errors": [], "warnings": [], "items": [], "counts": {}}
	if not manifest:
		issue(report, "errors", "manifest.missing", "", "Content manifest could not be loaded")
		return report
	var ids := {}
	var items := {}
	var registered := {}
	var groups := {"items": manifest.definitions, "enemies": manifest.enemies, "missions": manifest.missions, "loot": manifest.loot_tables, "areas": manifest.areas}
	for category: String in groups:
		report.counts[category] = groups[category].size()
		for resource: Resource in groups[category]:
			if not resource:
				issue(report, "errors", "manifest.empty", category, "Empty registered resource")
				continue
			var field := "mission_id" if category == "missions" else ("table_id" if category == "loot" else "id")
			var id: StringName = resource.get(field)
			if id.is_empty() or ids.has(id): issue(report, "errors", "id.conflict", resource.resource_path, "Missing or duplicate cross-type ID: " + String(id))
			ids[id] = resource
			registered[resource.resource_path] = id
			if not resource.resource_path.is_empty() and not FileAccess.file_exists(resource.resource_path):
				issue(report, "errors", "definition.path", resource.resource_path, "Registered definition file is missing")
			if category == "items": items[id] = resource
			elif not definition_valid(resource): issue(report, "errors", "definition.invalid", resource.resource_path, "Invalid " + category + " definition: " + String(id))
	var channels := {}
	for id in items: channels[id] = []
	for table in manifest.loot_tables:
		if not table: continue
		for entry in table.entries:
			if not entry: continue
			if not items.has(entry.definition_id): issue(report, "errors", "loot.missing_item", table.resource_path, "Unknown loot ID: " + String(entry.definition_id))
			else: channels[entry.definition_id].append("loot:" + String(table.table_id))
	for key in recipes:
		var recipe: Dictionary = recipes[key]
		var references: Array = recipe.get("inputs", {}).keys()
		references.append(recipe.get("output", &""))
		for id in references:
			if not items.has(id): issue(report, "errors", "recipe.missing_item", String(key), "Unknown recipe ID: " + String(id))
			else: channels[id].append("recipe:" + String(key))
	var chinese := load("res://localization/zh_CN.tres") as Translation
	for item: ItemDefinition in manifest.definitions:
		if not item: continue
		for message in item_errors(item): issue(report, "errors", "item.invalid", item.resource_path, message)
		if item is WeaponDefinition:
			for ammo_id in item.compatible_ammo_ids:
				if not items.get(StringName(ammo_id)) is AmmoDefinition: issue(report, "errors", "weapon.ammo", item.resource_path, "Ammo ID is missing or not AmmoDefinition: " + ammo_id)
			if item.uses_combat_rig and item.scene:
				var names := PackedStringArray()
				var state: SceneState = item.scene.get_state()
				for index in state.get_node_count(): names.append(String(state.get_node_name(index)))
				for marker in ["Muzzle", "PrimaryGrip", "SupportGrip", "ReloadGrip"]:
					if not names.has(marker): issue(report, "errors", "weapon.marker", item.resource_path, "Missing saved weapon mount: " + marker)
		if item.item_tags.has("weapon") or item.item_tags.has("armor") or item.item_tags.has("backpack") or item.item_tags.has("ammo") or item.item_tags.has("fitting_kit") or item is MedicalDefinition:
			channels[item.id].append("shop:SupplyService (progression gates apply)")
		if not item.icon: issue(report, "warnings", "item.icon", item.resource_path, "No inventory icon")
		var zh := String(chinese.get_message(item.display_name)) if chinese else ""
		if zh.is_empty(): issue(report, "warnings", "text.zh_missing", item.resource_path, "Missing Chinese display-name translation")
		var source := String(item.get_meta("authoring_source", ""))
		var license_ref := String(item.get_meta("license_ref", ""))
		if source.is_empty() or license_ref.is_empty(): issue(report, "warnings", "provenance.review", item.resource_path, "Legacy asset provenance needs manual SOURCE/THIRD_PARTY_ASSETS review")
		report.items.append({"id": String(item.id), "type": String(item.get_script().get_global_name()), "path": item.resource_path, "name_en": item.display_name, "name_zh": zh, "icon": item.icon.resource_path if item.icon else "", "weight": item.weight, "channels": channels[item.id], "authoring_source": source, "license_ref": license_ref})
	if scan_files: _scan_files(report, registered)
	report.pass = report.errors.is_empty()
	return report

static func _scan_files(report: Dictionary, registered: Dictionary, root := "res://resources") -> void:
	var known_ids := {}
	var known_uids := {}
	var id_pattern := RegEx.new()
	id_pattern.compile('(?m)^(?:id|mission_id|table_id) = &?"([^"]+)"')
	var reference_pattern := RegEx.new()
	reference_pattern.compile('(?m)^\\[ext_resource[^\\n]* path="([^"]+)"')
	var uid_pattern := RegEx.new()
	uid_pattern.compile('uid="([^"]+)"')
	for folder: String in FOLDERS:
		if not DirAccess.dir_exists_absolute(root + "/" + folder):
			issue(report, "warnings", "scan.directory", root + "/" + folder, "Directory unavailable; not scanned")
			continue
		for filename in DirAccess.get_files_at(root + "/" + folder):
			if not filename.ends_with(".tres"): continue
			var path := root + "/" + folder + "/" + filename
			var source := FileAccess.get_file_as_string(path)
			var match_id := id_pattern.search(source)
			if match_id:
				var id := match_id.get_string(1)
				if known_ids.has(id): issue(report, "errors", "file.id_conflict", path, "Duplicate file ID; also in " + known_ids[id])
				known_ids[id] = path
			else: issue(report, "errors", "file.id_missing", path, "No exported stable ID")
			var uid := uid_pattern.search(source.get_slice("\n", 0))
			if uid:
				var value := uid.get_string(1)
				if known_uids.has(value): issue(report, "errors", "file.uid_conflict", path, "Copied resource UID; also in " + known_uids[value])
				known_uids[value] = path
			for reference in reference_pattern.search_all(source):
				var target := reference.get_string(1)
				if not FileAccess.file_exists(target): issue(report, "errors", "file.reference", path, "Missing external resource: " + target)
			if not registered.has(path): issue(report, "warnings", "file.unregistered", path, "Definition is not registered in the manifest")
