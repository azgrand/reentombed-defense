extends RefCounted
## Higher is better. Targets are preferences, not validity requirements.
static func score(route: Array) -> float:
	var value := 200.0 - absf(float(route.size()) - 85.0) * 0.7
	var previous := Vector2i.ZERO
	var straight := 0
	var turns := 0
	var route_set := {}
	for i in range(route.size()):
		route_set[route[i]] = i
		if i == 0:
			continue
		var direction: Vector2i = route[i] - route[i - 1]
		if previous != Vector2i.ZERO and direction != previous:
			turns += 1
			value -= 3.0 if straight == 1 else 0.5
			straight = 0
		straight += 1
		previous = direction
	for cell in route:
		for offset in [Vector2i(2, 0), Vector2i(0, 2)]:
			if route_set.has(cell + offset) and absi(int(route_set[cell]) - int(route_set[cell + offset])) > 4:
				value -= 0.4
	if route.size() < 45 or route.size() > 120:
		value -= 40.0
	return value - turns * 0.4
