class_name BuildIdentity
extends RefCounted
## A source-snapshot identity, not a save/person ID or an assertion of release rights.
const PATH := "res://resources/runtime_build.json"

static func current() -> Dictionary:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH)) if FileAccess.file_exists(PATH) else null
	return decode(raw)

static func decode(raw: Variant) -> Dictionary:
	var result := {"id":"development","source_sha256":"","packaged":false,"engine":Engine.get_version_info().string}
	if not raw is Dictionary or raw.size() != 4 or typeof(raw.get("format")) not in [TYPE_INT,TYPE_FLOAT] or raw.format != 1 or typeof(raw.get("packaged")) != TYPE_BOOL: return result
	if typeof(raw.get("id")) != TYPE_STRING or typeof(raw.get("source_sha256")) != TYPE_STRING: return result
	if not raw.packaged: return result
	var digest: String = raw.source_sha256
	if digest.length() != 64 or raw.id != "nb-" + digest.left(16): return result
	for character in digest:
		if character not in "0123456789abcdef": return result
	result.id = raw.id
	result.source_sha256 = digest
	result.packaged = true
	return result
