extends SceneTree
const System = preload("res://scripts/game/tower_system.gd")
var failures := 0
func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		push_error(label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	var route_index := 0
	var pad := Vector2i.ZERO
	for i in range(2, game.map_data.route.size() - 2):
		for direction in game.Mapper.DIRECTIONS:
			var cell: Vector2i = game.map_data.route[i] + direction
			if cell.x > 0 and cell.y > 0 and cell.x < game.Mapper.WIDTH - 1 and cell.y < game.Mapper.HEIGHT - 1 and game.map_data.cells[cell.y][cell.x] == game.Mapper.PAD:
				route_index = i
				pad = cell
		if pad != Vector2i.ZERO:
			break
	for kind in range(game.balance.towers.size()):
		var spec: Dictionary = game.balance.towers[kind]
		check(game.Art.TOWERS.has(spec.id), "Missing tower art")
		if spec.behavior == "aura":
			continue
		check(game.Art.PROJECTILES.has(spec.id), "Missing projectile")
		game.towers.clear()
		game.enemies.clear()
		game.gold = 1000
		game.selected = kind
		game._place_tower(pad)
		for i in range(6):
			game._spawn_enemy()
			game.enemies[-1].hp = 1000.0
			game.enemies[-1].progress = float(route_index)
			game.enemies[-1].speed = 0.0
		System.fire(game, 0.001)
		var damaged := 0
		for enemy in game.enemies:
			if enemy.hp < 1000:
				damaged += 1
		if spec.behavior == "chain":
			check(damaged == 4, "Chain max jumps or repeated hits")
			var damage_values: Array = []
			for enemy in game.enemies:
				if enemy.hp < 1000:
					damage_values.append(1000 - enemy.hp)
			damage_values.sort()
			check(is_equal_approx(damage_values[0], 18.0 * pow(0.7, 3)), "Chain falloff")
		if spec.behavior == "pierce":
			check(damaged == 3, "Pierce max unique hits")
		if spec.behavior == "poison":
			var target: Dictionary = game.enemies[0]
			System.hit(target, spec, 0)
			System.hit(target, spec, 0)
			check(target.poison_dps == 9 and target.poison_time == 3, "Poison stacks")
			game.towers.clear()
			var hp: float = target.hp
			game._tick(1.0)
			check(is_equal_approx(target.hp, hp - 9), "DOT timing")
			System.hit(target, spec, 0)
			check(target.poison_time == 3, "Poison refresh")
			game.paused = true
			game._tick(10.0)
			check(target.poison_time == 3, "Poison advances while paused")
			game.paused = false
			game._tick(5.0)
			check(target.poison_time == 0 and is_equal_approx(target.hp, hp - 36), "Poison expiry over large delta")
			game.enemies.clear()
			game.enemies.append(target)
			target.hp = 1
			System.hit(target, spec, 0)
			var gold: int = game.gold
			game._tick(1.0)
			game._tick(1.0)
			check(game.gold == gold + 7, "Duplicate DOT reward")
	var banner_kind := -1
	for i in range(game.balance.towers.size()):
		if game.balance.towers[i].behavior == "aura":
			banner_kind = i
	game.towers.clear()
	game.towers.append({"cell": Vector2i(5, 5), "kind": 0, "level": 1})
	game.towers.append({"cell": Vector2i(6, 5), "kind": banner_kind, "level": 1})
	game.towers.append({"cell": Vector2i(5, 6), "kind": banner_kind, "level": 1})
	check(is_equal_approx(System.aura_bonus(game, game.towers[0]), 0.15), "Aura stacked")
	game.towers[1].level = 4
	game.towers[2].level = 2
	check(is_equal_approx(System.aura_bonus(game, game.towers[0]), 0.30), "Upgraded aura not applied dynamically")
	game.towers.remove_at(1)
	check(is_equal_approx(System.aura_bonus(game, game.towers[0]), 0.20), "Sold strongest aura remains cached")
	game.towers.remove_at(1)
	game.towers.clear()
	game.towers.append({"cell": Vector2i(6, 5), "kind": banner_kind, "level": 4})
	check(System.aura_bonus(game, game.towers[0]) == 0, "Aura buffs itself")
	game.queue_free()
	await process_frame
	print("Tower behavior failures: %d" % failures)
	quit(failures)
