extends SceneTree

const Mapper = preload("res://scripts/core/entombed_mapper.gd")
var failures := 0

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var route_signatures := {}
	var entrance_rows := {}
	var lengths := {}
	for value in range(1000):
		var generated := Mapper.generate(value)
		var route: Array = generated.route
		route_signatures[str(route)] = true
		entrance_rows[route[0].y] = true
		lengths[route.size()] = true
		check(generated == Mapper.generate(value), "Seed is not deterministic: %d" % value)
		check(route[0].x == 0 and route[-1].y == Mapper.HEIGHT - 1, "Missing portals")
		var visited := {}
		var pads := 0
		for i in range(route.size()):
			var cell: Vector2i = route[i]
			check(not visited.has(cell), "Route intersects itself")
			visited[cell] = true
			check(generated.cells[cell.y][cell.x] == Mapper.PATH, "Route overwritten")
			if i > 0:
				var difference: Vector2i = cell - route[i - 1]
				check(absi(difference.x) + absi(difference.y) == 1, "Disconnected route")
		for y in range(Mapper.HEIGHT):
			for x in range(Mapper.WIDTH):
				if generated.cells[y][x] == Mapper.PAD:
					pads += 1
					var adjacent := false
					for direction in Mapper.DIRECTIONS:
						if visited.has(Vector2i(x, y) + direction):
							adjacent = true
					check(adjacent, "Pad without access to route")
		check(generated.generator_version == "0.3", "Missing generator version")
		for decoration in generated.decorations:
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					check(generated.cells[decoration.cell.y + dy][decoration.cell.x + dx] < Mapper.PATH, "Decoration overlaps protected area")
		check(pads <= 44, "Excessive pad density")
		check(pads >= 30, "Insufficient construction space")
	check(route_signatures.size() == 1000, "Repeated route across distinct seeds")
	check(entrance_rows.size() >= 8, "Entrance position lacks variety")
	check(lengths.size() >= 30, "Route lengths lack variety")
	print("Map diversity: %d routes, %d entrances, %d lengths" % [route_signatures.size(), entrance_rows.size(), lengths.size()])
	check(Mapper.generate(1) != Mapper.generate(2), "Different seeds produce same map")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	var recent_seeds := {}
	for i in range(25):
		game._random_map()
		check(not recent_seeds.has(game.seed_value), "New map reused a seed")
		recent_seeds[game.seed_value] = true
	var replay_seed: int = game.seed_value
	var replay_route: Array = game.map_data.route.duplicate()
	game._restart_seed()
	check(game.seed_value == replay_seed and game.map_data.route == replay_route, "Restart changed the requested seed")
	for texture in game.Art.ENEMIES + [game.Art.ARMORED, game.Art.CASTLE, game.Art.ENTRANCE]:
		check(texture.get_width() % 4 == 0, "Invalid animation frame layout")
	game._new_map(42)
	var pad := Vector2i.ZERO
	for y in range(Mapper.HEIGHT):
		for x in range(Mapper.WIDTH):
			if game.map_data.cells[y][x] == Mapper.PAD:
				pad = Vector2i(x, y)
	game._place_tower(game.map_data.route[0])
	check(game.towers.is_empty(), "Construction allowed on route")
	game._place_tower(pad)
	check(game.towers.size() == 1 and game.gold == 130, "Construction transaction incorrect")
	game._place_tower(pad)
	check(game.towers.size() == 1 and game.gold == 130, "Duplicate tower charged")
	game.gold = 0
	game._place_tower(pad + Vector2i.RIGHT)
	check(game.gold == 0 and game.towers.size() == 1, "Invalid purchase charged")
	game._new_map(42)
	game._start_wave()
	game._start_wave()
	check(game.wave == 1 and game.remaining == 8, "Duplicate wave started")
	game._tick(0.01)
	check(game.enemies.size() == 1 and game.remaining == 7, "Enemy not spawned")
	game.remaining = 0
	game.enemies[0].progress = game.map_data.route.size()
	game._tick(0.01)
	check(game.lives == 19 and not game.active, "Leak or wave completion incorrect")
	game._new_map(42)
	game.lives = 1
	game._spawn_enemy()
	game.enemies[0].progress = game.map_data.route.size()
	game._tick(0.01)
	check(game.ended and game.lives == 0, "Defeat not triggered")
	game._new_map(42)
	game.wave = 10
	game.active = true
	game.remaining = 0
	game._tick(0.01)
	check(game.ended and not game.active and game.lives == 20, "Victory not triggered")
	# Exercise each weapon against an enemy placed beside a construction pad.
	for kind in range(game.balance.towers.size()):
		game._new_map(42)
		game.selected = kind
		game._place_tower(pad)
		game.wave = 1
		game._spawn_enemy()
		var route_index := 0
		for i in range(game.map_data.route.size() - 1):
			if Vector2(game.map_data.route[i]).distance_to(Vector2(pad)) <= 1.0:
				route_index = i
				break
		game.enemies[0].progress = float(route_index)
		var health: float = game.enemies[0].hp
		if kind == 1:
			game._spawn_enemy()
			game.enemies[1].progress = float(route_index)
		game._tick(0.001)
		if game.balance.towers[kind].behavior == "aura":
			check(game.enemies[0].hp == health, "Support tower attacked")
		else:
			check(game.enemies[0].hp < health, "Weapon did not hit: %d" % kind)
		if kind == 1:
			check(game.enemies[1].hp < health, "Splash damage missing")
		if kind == 2:
			check(game.enemies[0].slow < 1.0, "Slow effect missing")
	game.sound.stop()
	game.queue_free()
	await process_frame
	print("Tests completed: 1000 seeds + gameplay; failures: %d" % failures)
	quit(0 if failures == 0 else 1)
