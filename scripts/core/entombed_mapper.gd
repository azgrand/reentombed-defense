class_name EntombedMapper
extends RefCounted
## Five-neighbour, row-wise Entombed adaptation; not a ROM reproduction.
## A contextual terrain pass biases a randomized maze; enemies use its reserved route.
const WALL := 0
const FLOOR := 1
const PATH := 2
const PAD := 3
const WIDTH := 29
const HEIGHT := 21
const DIRECTIONS := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
# -1 = random. Original project-specific lookup table, indexed by abcde.
const RULES := [1, 1, 1, -1, 0, 0, -1, 0, 1, 1, 1, 1, -1, 0, 0, 0,
	1, 1, 1, -1, 0, 0, 0, 0, -1, 0, 1, -1, -1, 0, 0, 0]

static func generate(map_seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = map_seed
	var cells: Array = []
	for y in range(HEIGHT):
		var row: Array = []
		row.resize(WIDTH)
		row.fill(WALL)
		cells.append(row)
	# Generate half of each row and mirror it, as in Entombed.
	for y in range(1, HEIGHT - 1):
		for x in range(1, (WIDTH + 1) / 2):
			var a: int = cells[y][maxi(0, x - 2)]
			var b: int = cells[y][x - 1]
			var c: int = cells[y - 1][x - 1]
			var d: int = cells[y - 1][x]
			var e: int = cells[y - 1][x + 1]
			var rule: int = RULES[(a << 4) | (b << 3) | (c << 2) | (d << 1) | e]
			var value: int = rng.randi_range(0, 1) if rule == -1 else rule
			cells[y][x] = value
			cells[y][WIDTH - 1 - x] = value
	# Use the contextual terrain to bias a randomized depth-first maze on a
	# coarse grid. Every cell is visited once: finite, connected and no loops.
	var coarse_size := Vector2i((WIDTH - 1) / 2, (HEIGHT - 1) / 2)
	var start := Vector2i(0, rng.randi_range(0, coarse_size.y - 1))
	var stack: Array[Vector2i] = [start]
	var parents := {start: start}
	var depths := {start: 0}
	var passages: Array[Vector2i] = []
	var exit_cell := start
	var exit_depth := -1
	while not stack.is_empty():
		var current: Vector2i = stack[-1]
		if current.y == coarse_size.y - 1 and int(depths[current]) > exit_depth:
			exit_cell = current
			exit_depth = int(depths[current])
		var candidates: Array[Vector2i] = []
		var weights: Array[float] = []
		var total_weight := 0.0
		for direction in DIRECTIONS:
			var neighbor: Vector2i = current + direction
			if neighbor.x < 0 or neighbor.y < 0 or neighbor.x >= coarse_size.x or neighbor.y >= coarse_size.y or parents.has(neighbor):
				continue
			var terrain: int = cells[neighbor.y * 2 + 1][neighbor.x * 2 + 1]
			var weight := 1.0 + float(terrain) * 0.75
			candidates.append(neighbor)
			weights.append(weight)
			total_weight += weight
		if candidates.is_empty():
			stack.pop_back()
			continue
		var pick := rng.randf() * total_weight
		var next: Vector2i = candidates[-1]
		for i in range(candidates.size()):
			pick -= weights[i]
			if pick <= 0:
				next = candidates[i]
				break
		parents[next] = current
		depths[next] = int(depths[current]) + 1
		passages.append(current * 2 + Vector2i.ONE)
		passages.append(current + next + Vector2i.ONE)
		passages.append(next * 2 + Vector2i.ONE)
		stack.append(next)
	# Reconstruct the unique path to the deepest bottom-border destination.
	var coarse_route: Array[Vector2i] = [exit_cell]
	while coarse_route[-1] != start:
		coarse_route.append(parents[coarse_route[-1]])
	coarse_route.reverse()
	for row in cells:
		row.fill(WALL)
	for passage in passages:
		cells[passage.y][passage.x] = FLOOR
	var route: Array[Vector2i] = [Vector2i(0, start.y * 2 + 1)]
	for i in range(coarse_route.size()):
		var cell: Vector2i = coarse_route[i] * 2 + Vector2i.ONE
		if i > 0:
			route.append(coarse_route[i - 1] + coarse_route[i] + Vector2i.ONE)
		route.append(cell)
	route.append(Vector2i(exit_cell.x * 2 + 1, HEIGHT - 1))
	for cell in route:
		cells[cell.y][cell.x] = PATH
	for cell in route:
		for direction in DIRECTIONS:
			var neighbor: Vector2i = cell + direction
			if neighbor.x > 0 and neighbor.x < WIDTH - 1 and neighbor.y > 0 and neighbor.y < HEIGHT - 1:
				if cells[neighbor.y][neighbor.x] != PATH:
					cells[neighbor.y][neighbor.x] = PAD
	return {"seed": map_seed, "cells": cells, "route": route}
