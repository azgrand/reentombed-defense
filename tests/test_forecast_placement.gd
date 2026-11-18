extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	for wave in range(10):
		for next_id in range(10):
			game.wave = wave
			game.next_enemy_id = next_id
			var forecast: Dictionary = game.next_wave_forecast()
			var count := 6 + 2 * (wave + 1)
			var actual := 0
			for i in range(count):
				if (next_id + i) % 5 == 4:
					actual += 1
			assert(forecast.number == wave + 1 and forecast.count == count and forecast.heavy == actual)
	game.wave = 10
	assert(game.next_wave_forecast().number == 0)
	game._new_map(42)
	assert(game.tower_buttons.size() == game.balance.towers.size())
	var original: int = game.selected
	game._select(100)
	game._select(-1)
	assert(game.selected == original)
	for y in range(game.Mapper.HEIGHT):
		for x in range(game.Mapper.WIDTH):
			var cell := Vector2i(x, y)
			var gold: int = game.gold
			if game.map_data.cells[y][x] != game.Mapper.PAD:
				assert(game.placement_error(cell) != "")
				game._place_tower(cell)
				assert(game.gold == gold)
	var grid = game.shop.get_child(0)
	assert(grid is GridContainer and grid.columns == 2 and grid.get_child_count() >= 8)
	for card in game.tower_buttons:
		assert(card.size.x > 0 and card.size.y > 0)
	game.shop.show_details(6)
	assert(game.shop.description.text.contains(TranslationServer.translate("shop.support")))
	game.queue_free()
	await process_frame
	print("Forecast/placement/shop: OK")
	quit()
