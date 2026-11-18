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
	# Atlas is a 3x3 ring (48px), with 8px corner/edge quadrants.
	# Connected sides retain the solid dirt base, so no transparent center
	# sample can cut a hole across a narrow road or disconnected pad.
	for corner in range(4):
		var right_half := corner % 2 == 1
		var bottom_half := corner >= 2
		var open_x := not right if right_half else not left
		var open_y := not bottom if bottom_half else not top
		if not open_x and not open_y:
			continue
		var source_x := (40 if right_half else 0) if open_x else 16
		var source_y := (40 if bottom_half else 0) if open_y else 16
		var target := Rect2(rect.position + Vector2(15 if right_half else 0, 15 if bottom_half else 0), Vector2(15, 15))
		draw_texture_rect_region(texture, target, Rect2(source_x, source_y, 8, 8))

func _draw() -> void:
	# Framing and grass form a continuous surface rather than a debug grid.
	draw_rect(Rect2(ORIGIN - Vector2(4, 4), Vector2(Mapper.WIDTH, Mapper.HEIGHT) * TILE + Vector2(8, 8)), Color("51604b"), false, 2)
	for y in range(Mapper.HEIGHT):
		for x in range(Mapper.WIDTH):
			var cell := Vector2i(x, y)
			var rect := Rect2(ORIGIN + Vector2(cell) * TILE, Vector2.ONE * TILE)
			draw_texture_rect(Art.GRASS, rect, false, [Color("9caf9c"), Color("afaaa0"), Color("7d9d91")][map_data.theme])
			var value: int = map_data.cells[y][x]
			if value == Mapper.PATH:
				_path_tile(cell, Art.GROUND, Mapper.PATH, Color("b87048"))
			elif value == Mapper.PAD:
				_path_tile(cell, Art.STONE, Mapper.PAD, Color("777b79"))
				var center := _center(cell)
				draw_line(center - Vector2(3, 0), center + Vector2(3, 0), Color("ccd7c4"), 1)
				draw_line(center - Vector2(0, 3), center + Vector2(0, 3), Color("ccd7c4"), 1)
	for decoration in map_data.decorations:
		var texture: Texture2D = Art.DECORATIONS[decoration.kind]
		_sprite(texture, _center(decoration.cell) + Vector2(0, 11), texture.get_height() * 2.0)
