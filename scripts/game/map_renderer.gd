extends Node2D
const Mapper = preload("res://scripts/core/entombed_mapper.gd")
const Art = preload("res://scripts/game/art.gd")
const TILE := 30.0
const ORIGIN := Vector2(28, 112)
var wave: int:
	get: return game.wave
var game: Node
var map_data: Dictionary:
	get: return game.map_data
var seed_value: int:
	get: return game.seed_value
var panel_style: StyleBoxFlat:
	get: return game.panel_style
var animation_time: float:
	get: return game.animation_time
var towers: Array[Dictionary]:
	get: return game.towers
var enemies: Array[Dictionary]:
	get: return game.enemies
var beams: Array[Dictionary]:
	get: return game.beams
var selected: int:
	get: return game.selected
var ended: bool:
	get: return game.ended
var balance: Dictionary:
	get: return game.balance

func _center(cell: Vector2i) -> Vector2:
	return game._center(cell)

func _enemy_position(enemy: Dictionary) -> Vector2:
	return game._enemy_position(enemy)

# All source sheets have four horizontal frames; each frame is kept intact.
func _sprite(texture: Texture2D, feet: Vector2, height: float, frame: int = 0, frames: int = 1, tint: Color = Color.WHITE) -> void:
	var source := Rect2(float(texture.get_width()) / frames * frame, 0, float(texture.get_width()) / frames, texture.get_height())
	var size_value := Vector2(source.size.x / source.size.y * height, height)
	draw_texture_rect_region(texture, Rect2(feet - Vector2(size_value.x * 0.5, size_value.y), size_value), source, tint)

func _path_tile(cell: Vector2i, texture: Texture2D, kind: int, base: Color) -> void:
	var rect := Rect2(ORIGIN + Vector2(cell) * TILE, Vector2.ONE * TILE)
	draw_rect(rect, base)
	var left := cell.x > 0 and int(map_data.cells[cell.y][cell.x - 1]) == kind
	var right := cell.x < Mapper.WIDTH - 1 and int(map_data.cells[cell.y][cell.x + 1]) == kind
	var top := cell.y > 0 and int(map_data.cells[cell.y - 1][cell.x]) == kind
	var bottom := cell.y < Mapper.HEIGHT - 1 and int(map_data.cells[cell.y + 1][cell.x]) == kind
	var atlas_x := 0 if not left else (32 if not right else 16)
	var atlas_y := 0 if not top else (32 if not bottom else 16)
	draw_texture_rect_region(texture, rect, Rect2(atlas_x, atlas_y, 16, 16))

func _draw() -> void:
	if map_data.is_empty():
		return
	# Framing and grass form a continuous surface rather than a debug grid.
	draw_style_box(panel_style, Rect2(912, 100, 352, 652))
	draw_rect(Rect2(ORIGIN - Vector2(4, 4), Vector2(Mapper.WIDTH, Mapper.HEIGHT) * TILE + Vector2(8, 8)), Color("51604b"), false, 2)
	for y in range(Mapper.HEIGHT):
		for x in range(Mapper.WIDTH):
			var cell := Vector2i(x, y)
			var rect := Rect2(ORIGIN + Vector2(cell) * TILE, Vector2.ONE * TILE)
			draw_texture_rect(Art.GRASS, rect, false, Color("9caf9c"))
			var value: int = map_data.cells[y][x]
			if value == Mapper.PATH:
				_path_tile(cell, Art.GROUND, Mapper.PATH, Color("b87048"))
			elif value == Mapper.PAD:
				_path_tile(cell, Art.STONE, Mapper.PAD, Color("777b79"))
				var center := _center(cell)
				draw_line(center - Vector2(3, 0), center + Vector2(3, 0), Color("ccd7c4"), 1)
				draw_line(center - Vector2(0, 3), center + Vector2(0, 3), Color("ccd7c4"), 1)
			elif value == Mapper.WALL:
				# Stable per-cell variety without consuming the gameplay RNG.
				var variation := absi(hash(Vector3i(x, y, seed_value)))
				if variation % 4 == 0:
					var decoration: Texture2D = Art.DECORATIONS[int(variation / 4) % Art.DECORATIONS.size()]
					_sprite(decoration, _center(cell) + Vector2(0, 11), decoration.get_height() * 1.75)
	var route: Array = map_data.route
	var frame := int(animation_time * 6) % 4
	_sprite(Art.ENTRANCE, _center(route[0]) + Vector2(0, 14), 44, frame, 4)
	_sprite(Art.CASTLE, _center(route[-1]) + Vector2(0, 14), 48, frame, 4)
	# Discrete directional marks help distinguish the enemy lane from scenery.
	for i in range(3, route.size() - 2, 7):
		var center := _center(route[i])
		var direction := Vector2(route[i + 1] - route[i])
		var side := Vector2(-direction.y, direction.x)
		draw_line(center - direction * 3 + side * 3, center + direction * 2, Color(1, 0.88, 0.66, 0.5), 1)
		draw_line(center - direction * 3 - side * 3, center + direction * 2, Color(1, 0.88, 0.66, 0.5), 1)
	var hover := Vector2i(((get_global_mouse_position() - ORIGIN) / TILE).floor())
	if hover.x >= 0 and hover.y >= 0 and hover.x < Mapper.WIDTH and hover.y < Mapper.HEIGHT:
		if map_data.cells[hover.y][hover.x] == Mapper.PAD:
			var radius: float = float(balance.towers[selected].range) * TILE
			draw_circle(_center(hover), radius, Color(0.6, 0.95, 0.8, 0.10))
			draw_arc(_center(hover), radius, 0, TAU, 64, Color(0.6, 0.95, 0.8, 0.6), 1)
			var occupied := false
			for tower in towers:
				if tower.cell == hover:
					occupied = true
			if not occupied and not ended:
				_sprite(Art.TOWERS[balance.towers[selected].id], _center(hover) + Vector2(0, 10), 42, 0, 1, Color(1, 1, 1, 0.5))
	for tower in towers:
		var center := _center(tower.cell)
		draw_circle(center + Vector2(0, 6), 10, Color(0, 0, 0, 0.22))
		_sprite(Art.TOWERS[balance.towers[tower.kind].id], center + Vector2(0, 10), 42)
	for enemy in enemies:
		var center := _enemy_position(enemy)
		var texture: Texture2D = Art.ARMORED if enemy.armored else Art.ENEMIES[(wave - 1) % Art.ENEMIES.size()]
		var tint := Color("8ab4ff") if enemy.slow < 1 else Color.WHITE
		draw_circle(center + Vector2(0, 6), 8, Color(0, 0, 0, 0.25))
		_sprite(texture, center + Vector2(0, 8), 25 if enemy.armored else 19, (int(animation_time * 8) + int(enemy.id)) % 4, 4, tint)
		draw_rect(Rect2(center + Vector2(-10, -20), Vector2(20, 3)), Color("1a1f2a"))
		draw_rect(Rect2(center + Vector2(-10, -20), Vector2(20 * maxf(0, enemy.hp / enemy.max_hp), 3)), Color("a5ed86"))
	for beam in beams:
		var progress := clampf(1.0 - float(beam.ttl) / 0.18, 0.0, 1.0)
		var position_value: Vector2 = beam.from.lerp(beam.to, progress)
		_sprite(Art.PROJECTILES[balance.towers[beam.kind].id], position_value, 10)
		draw_arc(beam.to, 4 + progress * 9, 0, TAU, 16, Color(beam.color, 1.0 - progress), 2)

