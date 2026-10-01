extends Node
signal language_changed
const PATH := "user://language.cfg"
const CHINESE := preload("res://localization/zh_CN.tres")
var has_saved_language := false

func _ready() -> void:
	TranslationServer.add_translation(CHINESE)
	TranslationServer.set_locale("en")
	var preferences := ConfigFile.new()
	if preferences.load(PATH) == OK:
		var locale: Variant = preferences.get_value("language", "locale", "en")
		if locale is String and locale in ["en", "zh_CN"]:
			has_saved_language = true
			TranslationServer.set_locale(locale)

func initialize_game_language() -> void:
	# New games default to Chinese; direct component/test scenes keep their locale.
	if not has_saved_language: set_language("zh_CN", false)

func set_language(locale: String, persist := true, path := PATH) -> Error:
	if locale not in ["en", "zh_CN"]: return ERR_INVALID_PARAMETER
	TranslationServer.set_locale(locale)
	language_changed.emit()
	if not persist: return OK
	var preferences := ConfigFile.new()
	preferences.set_value("language", "locale", locale)
	var error := preferences.save(path)
	if error == OK: has_saved_language = true
	return error

func item_name(value: String) -> String:
	for suffix in [" [+10% DMG]", " +10% DMG"]:
		if value.ends_with(suffix):
			return tr(value.trim_suffix(suffix)) + tr(" +10% DMG")
	return tr(value)
