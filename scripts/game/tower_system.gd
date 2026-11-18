extends RefCounted
## Shared targeting/stats. Never mutates definitions or credits rewards.
static func stats(definition: Dictionary, _tower: Dictionary) -> Dictionary:
	return definition.duplicate(true)

static func aura_bonus(game: Node, tower: Dictionary) -> float:
	var strongest := 0.0
	for ally in game.towers:
		if ally == tower:
			continue
		var definition: Dictionary = game.balance.towers[ally.kind]
		if definition.behavior != "aura":
			continue
		var computed := stats(definition, ally)
		if Vector2(ally.cell).distance_to(Vector2(tower.cell)) <= float(computed.range):
			strongest = maxf(strongest, computed.aura_bonus)
	return strongest

static func eligible(game: Node, enemy: Dictionary) -> bool:
	return enemy.hp > 0 and enemy.progress < game.map_data.route.size() - 1

static func hit(enemy: Dictionary, spec: Dictionary, damage: float) -> void:
	if enemy.hp <= 0:
		return
	enemy.hp -= damage
	if spec.behavior == "slow":
		enemy.slow = spec.slow
		enemy.slow_time = 1.6
	if spec.behavior == "poison":
		enemy.poison_dps = spec.poison_dps
		enemy.poison_time = spec.poison_duration

static func fire(game: Node, delta: float) -> void:
	for tower in game.towers:
		var spec := stats(game.balance.towers[tower.kind], tower)
		if spec.behavior == "aura":
			continue
		tower.cooldown -= delta
		if tower.cooldown > 0:
			continue
		var origin: Vector2 = game._center(tower.cell)
		var target: Dictionary = {}
		for enemy in game.enemies:
			if not eligible(game, enemy):
				continue
			if origin.distance_to(game._enemy_position(enemy)) <= float(spec.range) * game.TILE:
				if target.is_empty() or enemy.progress > target.progress or (enemy.progress == target.progress and enemy.id < target.id):
					target = enemy
		if target.is_empty():
			continue
		var position_value: Vector2 = game._enemy_position(target)
		tower.aim = origin.direction_to(position_value)
		tower.cooldown = float(spec.cooldown) / (1.0 + aura_bonus(game, tower))
		game.beams.append({"from": origin, "to": position_value, "color": Color(spec.color), "ttl": 0.18, "kind": tower.kind})
		match spec.behavior:
			"chain":
				var visited := {}
				var damage := float(spec.damage)
				var current: Dictionary = target
				for jump in range(int(spec.chain_jumps) + 1):
					visited[current.id] = true
					hit(current, spec, damage)
					var from: Vector2 = game._enemy_position(current)
					var next: Dictionary = {}
					var distance: float = float(spec.chain_radius) * game.TILE + 0.001
					for enemy in game.enemies:
						if not eligible(game, enemy) or visited.has(enemy.id):
							continue
						var candidate_distance: float = from.distance_to(game._enemy_position(enemy))
						if candidate_distance < distance or (is_equal_approx(candidate_distance, distance) and not next.is_empty() and enemy.id < next.id):
							next = enemy
							distance = candidate_distance
					if next.is_empty() or jump == int(spec.chain_jumps):
						break
					game.beams.append({"from": from, "to": game._enemy_position(next), "color": Color(spec.color), "ttl": 0.18, "kind": tower.kind})
					current = next
					damage *= float(spec.chain_decay)
			"pierce":
				var direction := origin.direction_to(position_value)
				var hits: Array[Dictionary] = []
				for enemy in game.enemies:
					if not eligible(game, enemy):
						continue
					var offset: Vector2 = game._enemy_position(enemy) - origin
					var along := offset.dot(direction)
					if along >= 0 and along <= float(spec.range) * game.TILE and absf(offset.cross(direction)) <= float(spec.pierce_tolerance) * game.TILE:
						hits.append({"enemy": enemy, "along": along})
				hits.sort_custom(func(a, b): return a.along < b.along if a.along != b.along else a.enemy.id < b.enemy.id)
				for index in range(mini(int(spec.pierce_hits), hits.size())):
					hit(hits[index].enemy, spec, spec.damage)
			"splash":
				for enemy in game.enemies:
					if eligible(game, enemy) and game._enemy_position(enemy).distance_to(position_value) <= float(spec.splash) * game.TILE:
						hit(enemy, spec, spec.damage)
			_:
				hit(target, spec, spec.damage)
