extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game._start_wave()
	game._tick(0.01)
	game._toggle_pause()
	assert(game.paused and game.navigation.page == "pause")
	var before: Array = game.enemies.duplicate(true)
	var timer: float = game.spawn_clock
	game._tick(5.0)
	assert(game.enemies == before and game.spawn_clock == timer)
	game.navigation.show_page("settings")
	var prefs = root.get_node("Preferences")
	var old_locale: String = prefs.values.language
	TranslationServer.set_locale("en")
	await process_frame
	await process_frame
	assert(game.paused and game.navigation.page == "settings")
	assert(game.wave_button.text == "Start wave [Space]")
	TranslationServer.set_locale("es")
	await process_frame
	await process_frame
	assert(game.wave_button.text == "Iniciar oleada [Espacio]")
	game.navigation.show_page("pause")
	game._toggle_pause()
	assert(not game.paused and game.navigation.page == "")
	TranslationServer.set_locale(old_locale)
	await process_frame
	game.queue_free()
	await process_frame
	print("Navigation, live locale and pause: OK")
	quit()
