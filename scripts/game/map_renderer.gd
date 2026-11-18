extends Node2D
const Mapper = preload("res://scripts/core/entombed_mapper.gd")
const Art = preload("res://scripts/game/art.gd")
const TILE := 30.0
const ORIGIN := Vector2(28, 112)
var wave: int:
	get: return game.wave
const MapLayer = preload("res://scripts/game/map_layer.gd")
var layer: Node2D

func prepare_map() -> void:
	if layer == null:
		layer = MapLayer.new()
		layer.game = game
		layer.show_behind_parent = true
		add_child(layer)
	layer.queue_redraw()

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
	draw_style_box(panel_style, Rect2(912, 100, 352, 652))
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
		var valid: bool = game.placement_error(hover) == ""
		var tint := Color("67e8a0") if valid else Color("f16f6f")
		var radius: float = float(balance.towers[selected].range) * TILE
		draw_circle(_center(hover), radius, Color(tint, 0.10))
		draw_arc(_center(hover), radius, 0, TAU, 64, Color(tint, 0.65), 1)
		_sprite(Art.tower_texture(balance.towers[selected].id), _center(hover) + Vector2(0, 10), 42, 0, Art.tower_frames(balance.towers[selected].id), Color(tint, 0.5))
	for tower in towers:
		var center := _center(tower.cell)
		draw_circle(center + Vector2(0, 6), 10, Color(0, 0, 0, 0.22))
		_sprite(Art.tower_texture(balance.towers[tower.kind].id), center + Vector2(0, 10), 42, frame if balance.towers[tower.kind].id == "banner" else 0, Art.tower_frames(balance.towers[tower.kind].id))
		for pip in range(int(tower.level)):
			draw_circle(center + Vector2(-9 + pip * 6, 12), 2, Color("f4db70") if tower.level == 4 else Color("d1e4cb"))
		var bonus: float = game.TowerSystem.aura_bonus(game, tower)
		if bonus > 0:
			draw_arc(center, 13, 0, TAU, 20, Color(0.5, 0.9, 0.6, 0.55), 1)
	for enemy in enemies:
		var center := _enemy_position(enemy)
		var texture: Texture2D = Art.ARMORED if enemy.armored else Art.ENEMIES[(wave - 1) % Art.ENEMIES.size()]
		var tint := Color("8ab4ff") if enemy.slow < 1 else (Color("a9e96d") if enemy.get("poison_time", 0.0) > 0 else Color.WHITE)
		draw_circle(center + Vector2(0, 6), 8, Color(0, 0, 0, 0.25))
		_sprite(texture, center + Vector2(0, 8), 25 if enemy.armored else 19, (int(animation_time * 8) + int(enemy.id)) % 4, 4, tint)
		draw_rect(Rect2(center + Vector2(-10, -20), Vector2(20, 3)), Color("1a1f2a"))
		draw_rect(Rect2(center + Vector2(-10, -20), Vector2(20 * maxf(0, enemy.hp / enemy.max_hp), 3)), Color("a5ed86"))
	for beam in beams:
		var progress := clampf(1.0 - float(beam.ttl) / 0.18, 0.0, 1.0)
		var position_value: Vector2 = beam.from.lerp(beam.to, progress)
		if balance.towers[beam.kind].behavior == "chain":
			draw_line(beam.from, beam.to, beam.color, 3)
		else:
			_sprite(Art.PROJECTILES[balance.towers[beam.kind].id], position_value, 10)
		draw_arc(beam.to, 4 + progress * 9, 0, TAU, 16, Color(beam.color, 1.0 - progress), 2)

