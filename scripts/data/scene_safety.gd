@tool
extends RefCounted
## Shared runtime/editor inspection without instantiating scene scripts.
static func has_scripts(scene: PackedScene) -> bool:
	return _state_has_scripts(scene.get_state())

static func _state_has_scripts(state: SceneState) -> bool:
	var base := state.get_base_scene_state()
	if base and _state_has_scripts(base): return true
	for index in state.get_node_count():
		var nested := state.get_node_instance(index)
		if nested and has_scripts(nested): return true
		for property in state.get_node_property_count(index):
			if state.get_node_property_name(index, property) == &"script" and state.get_node_property_value(index, property): return true
	return false
