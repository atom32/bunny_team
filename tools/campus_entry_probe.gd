extends SceneTree
## Explicit continuation tests only. Requires an actual completed preceding save.
func _initialize() -> void: _launch.call_deferred()
func _launch() -> void:
	var args := OS.get_cmdline_user_args()
	var index := args.find("--step")
	var step: String = args[index+1] if index>=0 and index+1<args.size() else ""
	var paths := {"q01":"res://tests/campus_q01_run.gd","q02":"res://tests/campus_q02_run.gd","campus":"res://tests/campus_chapter_run.gd"}
	if not paths.has(step):push_error("Expected --step q01, q02 or campus and an isolated actual preceding save");quit(2);return
	var script = load(paths[step])
	if not script or not script.can_instantiate():quit(2);return
	var test = script.new()
	root.add_child(test)
	current_scene = test
