extends SceneTree
## Deterministic purchasing policy; an observation tool, not a human-play test.
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	for value in [0, 42, 2026]:
		var game = load("res://scenes/main.tscn").instantiate()
		game.audio_enabled = false
		root.add_child(game)
		game.set_process(false)
		game._new_map(value)
		var purchase := 0
		for tick in range(40000):
			if game.ended:
				break
			game.selected = purchase % game.balance.towers.size()
			if game.gold >= int(game.balance.towers[game.selected].cost):
				var best := Vector2i(-1, -1)
				var best_score := -INF
				for y in range(game.Mapper.HEIGHT):
					for x in range(game.Mapper.WIDTH):
						var cell := Vector2i(x, y)
						if game.placement_error(cell) != "":
							continue
						var coverage := 0.0
						for index in range(game.map_data.route.size()):
							if Vector2(cell).distance_to(Vector2(game.map_data.route[index])) <= float(game.balance.towers[game.selected].range):
								coverage += 1.0 + (1.0 - float(index) / game.map_data.route.size()) * 0.1
						if coverage > best_score:
							best_score = coverage
							best = cell
				if best.x >= 0:
					game._place_tower(best)
					purchase += 1
			if not game.active:
				game._start_wave()
			game._tick(0.15)
		print("Balance policy seed=%d route=%d wave=%d lives=%d towers=%d gold=%d ended=%s" % [value, game.map_data.route.size(), game.wave, game.lives, game.towers.size(), game.gold, game.ended])
		game.queue_free()
		await process_frame
	quit()
