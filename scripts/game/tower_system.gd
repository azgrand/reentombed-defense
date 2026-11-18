extends RefCounted
## Combat behavior owner; the coordinator retains run state.

static func fire(game: Node, delta: float) -> void:
	for tower in game.towers:
		tower.cooldown -= delta
		if tower.cooldown > 0:
			continue
		var spec: Dictionary = game.balance.towers[tower.kind]
		var origin: Vector2 = game._center(tower.cell)
		var target: Dictionary = {}
		for enemy in game.enemies:
			if enemy.hp <= 0 or enemy.progress >= game.map_data.route.size() - 1:
				continue
			if origin.distance_to(game._enemy_position(enemy)) <= float(spec.range) * game.TILE:
				if target.is_empty() or enemy.progress > target.progress:
					target = enemy
		if target.is_empty():
			continue
		var hit: Vector2 = game._enemy_position(target)
		tower.aim = origin.direction_to(hit)
		game.beams.append({"from": origin, "to": hit, "color": Color(spec.color), "ttl": 0.18, "kind": tower.kind})
		tower.cooldown = float(spec.cooldown)
		for enemy in game.enemies:
			if enemy.hp <= 0:
				continue
			if enemy.id == target.id or (float(spec.splash) > 0 and game._enemy_position(enemy).distance_to(hit) <= float(spec.splash) * game.TILE):
				enemy.hp -= float(spec.damage)
				if float(spec.slow) < 1.0:
					enemy.slow = float(spec.slow)
					enemy.slow_time = 1.6
