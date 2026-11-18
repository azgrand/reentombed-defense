extends Node
signal changed
var values := {}
const PATH := "user://settings.cfg"
var settings_path := PATH

static func read_settings(path: String) -> Dictionary:
	var defaults := {"language": "es" if OS.get_locale_language() == "es" else "en", "sound": true, "fullscreen": false}
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return defaults
	for key in defaults:
		var value = config.get_value("preferences", key, defaults[key])
		if typeof(value) == typeof(defaults[key]):
			defaults[key] = value
	if defaults.language not in ["es", "en"]:
		defaults.language = "en"
	return defaults

func _ready() -> void:
	values = read_settings(settings_path)
	apply()

func set_preference(key: String, value: Variant) -> void:
	if not values.has(key) or typeof(values[key]) != typeof(value):
		return
	if key == "language" and value not in ["es", "en"]:
		return
	values[key] = value
	apply()
	var config := ConfigFile.new()
	for item in values:
		config.set_value("preferences", item, values[item])
	config.save(settings_path)
	changed.emit()

func apply() -> void:
	TranslationServer.set_locale(values.language)
	AudioServer.set_bus_mute(0, not values.sound)
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if values.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
