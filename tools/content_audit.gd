extends Node
const AUDIT := preload("res://addons/neon_content/content_audit.gd")
func _ready() -> void:
	var recipes := SupplyService.RECIPES.duplicate()
	recipes.merge(SupplyService.FACILITY_RECIPES)
	var report := AUDIT.audit(load("res://resources/content/content_manifest.tres"), true, recipes)
	var path := OS.get_environment("NEON_CONTENT_AUDIT_REPORT")
	if not path.is_empty():
		var file := FileAccess.open(path, FileAccess.WRITE)
		if not file: report.pass = false
		else: file.store_string(JSON.stringify(report, "\t")); file.close()
	print("CONTENT_AUDIT: ", "PASS" if report.pass else "FAIL", " errors=", report.errors.size(), " warnings=", report.warnings.size())
	AudioDirector.shutdown_for_test()
	get_tree().quit(0 if report.pass else 1)
