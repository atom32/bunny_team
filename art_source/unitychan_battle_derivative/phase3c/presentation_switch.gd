extends RefCounted
# Isolated experiment only. Selection is presentation configuration, not save identity.
static func character_scene(legacy: PackedScene) -> PackedScene:
	if OS.get_environment("BUNNY_PRESENTATION") == "unitychan":
		return load("res://assets/characters/unitychan_battle/battle_presentation.glb") as PackedScene
	return legacy

static func create_rig() -> CharacterCombatRig:
	if OS.get_environment("BUNNY_PRESENTATION") == "unitychan":
		return preload("res://spike/presentation_adapter.gd").new()
	return CharacterCombatRig.new()
