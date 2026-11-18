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
	game._new_map(42)
	var route: Array = game.map_data.route.duplicate()
	var pad := Vector2i.ZERO
	for y in range(game.Mapper.HEIGHT):
		for x in range(game.Mapper.WIDTH):
			if game.map_data.cells[y][x] == game.Mapper.PAD:
				pad = Vector2i(x, y)
	for kind in range(game.balance.towers.size()):
		var base: Dictionary = game.balance.towers[kind]
		game.gold = 10000
		game.selected = kind
		game._place_tower(pad)
		game.selected_tower = game.towers[0]
		var tower: Dictionary = game.selected_tower
		check(tower.level == 1 and tower.total_invested == base.cost, "Initial investment")
		game.gold = 0
		check(not game._upgrade_selected() and tower.level == 1, "Insufficient gold spent")
		game.gold = 10000 - int(base.cost)
		game.active = true
		var invested := int(base.cost)
		for level in range(1, 4):
			var multiplier: float = [0.75, 1.15, 1.60][level - 1]
			var cost := int(ceil(float(base.cost) * multiplier))
			var before: int = game.gold
			check(game._upgrade_selected(), "Upgrade failed")
			invested += cost
			check(tower.level == level + 1 and tower.total_invested == invested and game.gold == before - cost, "Upgrade transaction")
			var computed := System.stats(base, tower, game.balance.progression)
			check(is_equal_approx(computed.damage, base.damage * [1.0, 1.35, 1.75, 2.25][level]), "Damage formula")
			check(is_equal_approx(computed.range, base.range + level * 0.1), "Range formula")
			if base.behavior == "aura":
				check(is_equal_approx(computed.aura_bonus, [0.15, 0.2, 0.25, 0.3][level]), "Aura upgrade")
		check(not game._upgrade_selected(), "Max level upgraded")
		game.paused = true
		check(game._sell_selected() == 0, "Sold while paused")
		game.paused = false
		var expected := int(floor(invested * 0.65))
		check(game._sell_selected() == expected, "Refund formula")
		check(game.gold < 10000, "Arbitrage creates gold")
		game.selected_tower = tower
		check(not game._upgrade_selected() and game._sell_selected() == 0, "Stale tower transaction")
		game.selected_tower = {}
		check(game.map_data.route == route and game.towers.is_empty(), "Upgrade edited route/occupancy")
	game._new_map(42)
	check(game.selected_tower.is_empty() and game.towers.is_empty(), "Reset retains upgrades")
	game.queue_free()
	await process_frame
	print("Upgrade/refund failures: %d" % failures)
	quit(failures)
