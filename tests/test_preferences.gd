extends SceneTree
const Store = preload("res://scripts/services/settings_store.gd")
var failures := 0
func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		push_error(label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var prefs = root.get_node("Preferences")
	var original: Dictionary = prefs.values.duplicate()
	prefs.settings_path = "user://test-preferences.cfg"
	prefs.set_preference("language", "en")
	check(TranslationServer.translate("menu.play") == "Play", "English not applied")
	prefs.set_preference("language", "es")
	check(TranslationServer.translate("menu.play") == "Jugar", "Spanish not applied")
	prefs.set_preference("sound", false)
	var saved := Store.read_settings(prefs.settings_path)
	check(saved.language == "es" and not saved.sound, "Preferences did not persist")
	prefs.set_preference("language", "xx")
	check(prefs.values.language == "es", "Unsupported locale accepted")
	var file := FileAccess.open(prefs.settings_path, FileAccess.WRITE)
	file.store_string("this is corrupt [[[!")
	file.close()
	var fallback := Store.read_settings(prefs.settings_path)
	check(fallback.sound and not fallback.fullscreen and fallback.language in ["en", "es"], "Corrupt settings defaults")
	DirAccess.remove_absolute(prefs.settings_path)
	prefs.values = original
	prefs.settings_path = Store.PATH
	prefs.apply()
	var menu = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	check(menu.get_child_count() == 1, "Menu missing")
	menu.queue_free()
	await process_frame
	print("Preferences/menu failures: %d" % failures)
	quit(failures)
