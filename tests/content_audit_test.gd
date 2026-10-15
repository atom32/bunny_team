extends Node
const AUDIT := preload("res://addons/neon_content/content_audit.gd")
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message); push_error(message)
func has_code(report: Dictionary, code: String) -> bool:
	for error in report.errors: if error.code == code: return true
	return false
func _ready() -> void:
	var source: ContentManifest = load("res://resources/content/content_manifest.tres")
	var before := FileAccess.get_sha256(source.resource_path)
	var count_before := source.definitions.size()
	var profile := JSON.stringify(ProfileRuntime.get_profile().to_dict())
	var recipes := SupplyService.RECIPES.duplicate(); recipes.merge(SupplyService.FACILITY_RECIPES)
	var report: Dictionary = AUDIT.audit(source, true, recipes)
	for collection in [source.enemies, source.areas, source.missions, source.loot_tables]:
		for resource: Resource in collection:
			check(AUDIT.definition_valid(resource) == resource.validate_definition(), "Editor-safe schema agrees with runtime validation")
	check(report.pass and report.counts.items == source.definitions.size(), "Production definitions and references audit without errors")
	var channels_found := false
	for row in report.items:
		if row.id == "material.fabric": channels_found = row.channels.size() > 0 and not row.name_zh.is_empty()
	check(channels_found, "Report contains real acquisition channels and Chinese text")
	var broken := source.duplicate() as ContentManifest
	broken.definitions = source.definitions.duplicate()
	broken.definitions.append(source.definitions[0])
	check(has_code(AUDIT.audit(broken, false), "id.conflict"), "Duplicate IDs are rejected")
	broken = source.duplicate() as ContentManifest
	broken.definitions = source.definitions.duplicate()
	var weapon := ContentDB.get_weapon(&"weapon.assault_rifle_01").duplicate() as WeaponDefinition
	weapon.id = &"weapon.audit_invalid"; weapon.compatible_ammo_ids = PackedStringArray(["material.fabric"])
	broken.definitions.append(weapon)
	check(has_code(AUDIT.audit(broken, false), "weapon.ammo"), "A material cannot masquerade as ammunition")
	weapon.weight = -1
	check(has_code(AUDIT.audit(broken, false), "item.invalid"), "Invalid item weight is rejected")
	var foreign := {"invalid": {"inputs": {&"item.missing": 1}, "output": &"item.missing"}}
	check(has_code(AUDIT.audit(source, false, foreign), "recipe.missing_item"), "Missing recipe references are reported")
	var manifest := ContentManifest.new()
	var loot := LootTableDefinition.new(); loot.table_id = &"loot.audit"
	var entry := LootTableEntry.new(); entry.definition_id = &"item.missing"; loot.entries.append(entry)
	manifest.loot_tables.append(loot)
	check(has_code(AUDIT.audit(manifest, false), "loot.missing_item"), "Missing loot references are reported")
	var folder := "user://audit_files"
	DirAccess.make_dir_recursive_absolute(folder + "/items")
	var fixture := '[gd_resource type="Resource" format=3 uid="uid://br2kgipcnmtan"]\n[ext_resource type="Texture2D" path="res://missing_icon.png" id="1"]\n[resource]\nid = &"item.conflict"\n'
	for filename in ["a.tres", "b.tres"]:
		var file := FileAccess.open(folder + "/items/" + filename, FileAccess.WRITE); file.store_string(fixture); file.close()
	var files_report := {"errors": [], "warnings": []}
	AUDIT._scan_files(files_report, {}, folder)
	check(has_code(files_report, "file.reference") and has_code(files_report, "file.uid_conflict") and has_code(files_report, "file.id_conflict"), "File scanner aggregates missing paths, copied UIDs and duplicate IDs")
	for filename in ["a.tres", "b.tres"]: DirAccess.remove_absolute(folder + "/items/" + filename)
	check(source.definitions.size() == count_before and FileAccess.get_sha256(source.resource_path) == before and JSON.stringify(ProfileRuntime.get_profile().to_dict()) == profile, "Audit leaves manifest memory, file and profile untouched")
	AudioDirector.shutdown_for_test()
	print("CONTENT_AUDIT_TEST: ", "PASS" if failures.is_empty() else "FAIL")
	get_tree().quit(0 if failures.is_empty() else 1)
