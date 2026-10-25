extends Node
var failures: Array[String] = []
var checks := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message)

func _ready() -> void:
	var digest := "0123456789abcdef".repeat(4)
	var valid := {"format":1,"id":"nb-"+digest.left(16),"source_sha256":digest,"packaged":true}
	var decoded := BuildIdentity.decode(valid)
	check(decoded.id == valid.id and decoded.source_sha256 == digest and decoded.packaged and not decoded.engine.is_empty(),"bounded source identity decodes with actual runtime engine")
	for raw in [null,{},[],{"format":1,"id":"development","source_sha256":"","packaged":false}]:
		check(not BuildIdentity.decode(raw).packaged and BuildIdentity.decode(raw).id=="development","missing or development metadata does not invent a packaged version")
	for change in [{"format":2},{"format":true},{"id":"nb-wrong"},{"source_sha256":"a".repeat(63)},{"source_sha256":"A".repeat(64)},{"source_sha256":"g".repeat(64)},{"packaged":"true"},{"extra":"hidden"}]:
		var raw := valid.duplicate();raw.merge(change,true)
		check(not BuildIdentity.decode(raw).packaged,"malformed identity cannot become a release label")
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(BuildIdentity.PATH))
	check(BuildIdentity.current()==BuildIdentity.decode(raw),"runtime identity is read from actual packaged/stub bytes, not HEAD or save data")
	if raw is Dictionary and raw.get("packaged")==true:
		check(BuildIdentity.current().source_sha256==raw.source_sha256,"actual generated package digest is visible at runtime")
	for failure in failures:push_error(failure)
	print("BUILD_IDENTITY_TEST: %s (%d checks)"%["PASS" if failures.is_empty() else "FAIL",checks])
	get_tree().quit(0 if failures.is_empty() else 1)
