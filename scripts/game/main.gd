extends Node2D

const Mapper = preload("res://scripts/core/entombed_mapper.gd")
const Art = preload("res://scripts/game/art.gd")
const TILE := 30.0
const ORIGIN := Vector2(28, 112)
var balance: Dictionary
var map_data: Dictionary
var towers: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var beams: Array[Dictionary] = []
var sound := AudioStreamPlayer.new()
var audio_enabled := true
var selected := 0
var gold := 0
var lives := 0
var wave := 0
var remaining := 0
var spawn_clock := 0.0
var active := false
var ended := false
var paused := false
var seed_value := 0
var map_rng := RandomNumberGenerator.new()
var animation_time := 0.0
var panel_style: StyleBoxFlat
var map_info: Label
var next_enemy_id := 0
var stats: Label
var message: Label
var seed_input: LineEdit
var wave_button: Button
var tower_buttons: Array[Button] = []
var hint := "Construye sobre las plataformas marcadas con +."

func _ready() -> void:
	balance = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance.json"))
	add_child(sound)
	panel_style = _panel_style()
	_build_ui()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	map_rng.randomize()
	_random_map()

func _play_sound(path: String) -> void:
	if not audio_enabled or DisplayServer.get_name() == "headless":
		return
	sound.stream = load(path)
	sound.play()

func _button(text_value: String, position_value: Vector2, size_value: Vector2, action: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.position = position_value
	button.size = size_value
	button.pressed.connect(action)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 17)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("1e3340") if state == "normal" else Color("2c4e57")
		if state == "disabled":
			style.bg_color = Color("17242f")
		style.set_border_width_all(1)
		style.border_color = Color("46636c")
		style.set_corner_radius_all(6)
		style.content_margin_left = 12
		style.content_margin_right = 12
		button.add_theme_stylebox_override(state, style)
	add_child(button)
	return button

func _label(text_value: String, position_value: Vector2, size_value: Vector2, font_size: int = 18) -> Label:
	var label := Label.new()
	label.text = text_value
	label.position = position_value
	label.size = size_value
	label.add_theme_font_size_override("font_size", font_size)
	add_child(label)
	return label

func _build_ui() -> void:
	_label("REENTOMBED / DEFENSE", Vector2(28, 18), Vector2(800, 42), 32)
	_label("EL BOSQUE DEL SELLO    /    Cada expedición abre un nuevo laberinto", Vector2(30, 65), Vector2(850, 28), 16)
	_label("ARSENAL", Vector2(928, 110), Vector2(300, 35), 25)
	for i in range(balance.towers.size()):
		var spec: Dictionary = balance.towers[i]
		var text_value := "%d   %s · %d oro
Daño %d / Alcance %.1f" % [i + 1, spec.name, spec.cost, spec.damage, spec.range]
		var button := _button(text_value, Vector2(928, 162 + i * 84), Vector2(320, 72), _select.bind(i))
		button.icon = Art.TOWERS[i]
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 24)
		button.add_theme_constant_override("h_separation", 14)
		tower_buttons.append(button)
	stats = _label("", Vector2(928, 435), Vector2(320, 90), 20)
	wave_button = _button("Iniciar oleada [Espacio]", Vector2(928, 540), Vector2(320, 44), _start_wave)
	_button("Pausa / Continuar [P]", Vector2(928, 594), Vector2(320, 38), _toggle_pause)
	map_info = _label("", Vector2(30, 744), Vector2(850, 24), 14)
	seed_input = LineEdit.new()
	seed_input.position = Vector2(928, 654)
	seed_input.size = Vector2(146, 38)
	seed_input.placeholder_text = "Semilla entera"
	add_child(seed_input)
	_button("Repetir semilla", Vector2(1084, 654), Vector2(164, 38), _restart_seed)
	_button("Nuevo mapa", Vector2(928, 704), Vector2(320, 38), _random_map)
	message = _label("", Vector2(28, 772), Vector2(1220, 36), 17)

func _new_map(value: int) -> void:
	animation_time = 0.0
	seed_value = value
	map_data = Mapper.generate(value)
	towers.clear()
	enemies.clear()
	beams.clear()
	gold = int(balance.starting_gold)
	lives = int(balance.starting_lives)
	wave = 0
	remaining = 0
	spawn_clock = 0.0
	active = false
	ended = false
	paused = false
	next_enemy_id = 0
	seed_input.text = str(value)
	hint = "Elige torre (1–3) y pulsa una plataforma +. Clic derecho: vender al 65 %."
	_refresh_ui()
	queue_redraw()

func _random_map() -> void:
	var next_seed := map_rng.randi()
	while next_seed == seed_value:
		next_seed = map_rng.randi()
	_new_map(next_seed)

func _restart_seed() -> void:
	if seed_input.text.is_valid_int():
		_new_map(seed_input.text.to_int())
	else:
		hint = "Introduce una semilla entera válida."

func _select(index: int) -> void:
	selected = index
	_refresh_ui()

func _toggle_pause() -> void:
	if not ended:
		paused = not paused
	_refresh_ui()

func _refresh_ui() -> void:
	map_info.text = "SEMILLA  %d     /     RUTA  %d celdas     /     Rojo: entrada · Azul: castillo" % [seed_value, map_data.route.size()]
	stats.text = "ORO   %d
SELLO   %d vidas
OLEADA   %d / %d" % [gold, lives, wave, balance.waves]
	wave_button.disabled = active or ended
	for i in range(tower_buttons.size()):
		tower_buttons[i].modulate = Color("67e8c4") if i == selected else Color.WHITE
	message.text = "PAUSA · Pulsa P para continuar" if paused else hint

func _start_wave() -> void:
	if active or ended or paused:
		return
	_play_sound("res://assets/audio/wave.wav")
	wave += 1
	remaining = 6 + wave * 2
	spawn_clock = 0.0
	active = true
	hint = "Oleada %d en marcha. Puedes seguir construyendo." % wave
	_refresh_ui()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if seed_input.has_focus():
			return
		match event.keycode:
			KEY_1: _select(0)
			KEY_2: _select(1)
			KEY_3: _select(2)
			KEY_SPACE: _start_wave()
			KEY_P: _toggle_pause()
	if event is InputEventMouseButton and event.pressed:
		if paused or ended:
			return
		var cell := Vector2i(((get_global_mouse_position() - ORIGIN) / TILE).floor())
		if cell.x < 0 or cell.y < 0 or cell.x >= Mapper.WIDTH or cell.y >= Mapper.HEIGHT:
			return
		if event.button_index == MOUSE_BUTTON_RIGHT:
			for i in range(towers.size()):
				if towers[i].cell == cell:
					gold += int(balance.towers[towers[i].kind].cost * 0.65)
					towers.remove_at(i)
					break
		elif event.button_index == MOUSE_BUTTON_LEFT:
			_place_tower(cell)
		_refresh_ui()
		queue_redraw()

func _place_tower(cell: Vector2i) -> void:
	if map_data.cells[cell.y][cell.x] != Mapper.PAD:
		hint = "Solo se puede construir en plataformas +."
		return
	for tower in towers:
		if tower.cell == cell:
			hint = "Esta plataforma ya tiene una torre."
			return
	var spec: Dictionary = balance.towers[selected]
	if gold < int(spec.cost):
		hint = "Oro insuficiente para %s." % spec.name
		return
	_play_sound("res://assets/audio/build.wav")
	gold -= int(spec.cost)
	towers.append({"cell": cell, "kind": selected, "cooldown": 0.0, "aim": Vector2.UP})
	hint = "%s construida. Alcance: %.1f celdas." % [spec.name, spec.range]

func _center(cell: Vector2i) -> Vector2:
	return ORIGIN + Vector2(cell) * TILE + Vector2.ONE * TILE * 0.5

func _enemy_position(enemy: Dictionary) -> Vector2:
	var route: Array = map_data.route
	var index := mini(int(enemy.progress), route.size() - 2)
	return _center(route[index]).lerp(_center(route[index + 1]), fmod(float(enemy.progress), 1.0))

func _spawn_enemy() -> void:
	var armored := next_enemy_id % 5 == 4
	var health := (32.0 + wave * 13.0) * (2.2 if armored else 1.0)
	enemies.append({"id": next_enemy_id, "hp": health, "max_hp": health, "progress": 0.0,
		"speed": (2.0 + wave * 0.09) * (0.7 if armored else 1.0), "slow": 1.0,
		"slow_time": 0.0, "armored": armored})
	next_enemy_id += 1

func _process(delta: float) -> void:
	if map_data.is_empty():
		return
	if not paused and not ended:
		animation_time += delta
		_tick(delta)
	_refresh_ui()
	queue_redraw()

func _tick(delta: float) -> void:
	for i in range(beams.size() - 1, -1, -1):
		beams[i].ttl -= delta
		if beams[i].ttl <= 0:
			beams.remove_at(i)
	if active and remaining > 0:
		spawn_clock -= delta
		if spawn_clock <= 0:
			_spawn_enemy()
			remaining -= 1
			spawn_clock += maxf(0.3, 0.95 - wave * 0.04)
	for enemy in enemies:
		enemy.slow_time = maxf(0.0, enemy.slow_time - delta)
		if enemy.slow_time <= 0:
			enemy.slow = 1.0
		enemy.progress += delta * enemy.speed * enemy.slow
	for tower in towers:
		tower.cooldown -= delta
		if tower.cooldown > 0:
			continue
		var spec: Dictionary = balance.towers[tower.kind]
		var origin := _center(tower.cell)
		var target: Dictionary = {}
		for enemy in enemies:
			if enemy.hp <= 0 or enemy.progress >= map_data.route.size() - 1:
				continue
			if origin.distance_to(_enemy_position(enemy)) <= float(spec.range) * TILE:
				if target.is_empty() or enemy.progress > target.progress:
					target = enemy
		if target.is_empty():
			continue
		var hit := _enemy_position(target)
		tower.aim = origin.direction_to(hit)
		beams.append({"from": origin, "to": hit, "color": Color(spec.color), "ttl": 0.18, "kind": tower.kind})
		tower.cooldown = float(spec.cooldown)
		for enemy in enemies:
			if enemy.hp <= 0:
				continue
			if enemy.id == target.id or (float(spec.splash) > 0 and _enemy_position(enemy).distance_to(hit) <= float(spec.splash) * TILE):
				enemy.hp -= float(spec.damage)
				if float(spec.slow) < 1.0:
					enemy.slow = float(spec.slow)
					enemy.slow_time = 1.6
	for i in range(enemies.size() - 1, -1, -1):
		if enemies[i].hp <= 0:
			gold += 12 if enemies[i].armored else 7
			enemies.remove_at(i)
		elif enemies[i].progress >= map_data.route.size() - 1:
			lives = maxi(0, lives - 1)
			enemies.remove_at(i)
	if lives <= 0:
		ended = true
		active = false
		hint = "El sello ha caído. Reinicia la semilla para volver a intentarlo."
	elif active and remaining == 0 and enemies.is_empty():
		active = false
		gold += int(balance.wave_bonus)
		ended = wave >= int(balance.waves)
		hint = "¡Victoria! La cripta está a salvo." if ended else "Oleada superada. +%d oro. Prepara tus defensas." % balance.wave_bonus

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
				_sprite(Art.TOWERS[selected], _center(hover) + Vector2(0, 10), 42, 0, 1, Color(1, 1, 1, 0.5))
	for tower in towers:
		var center := _center(tower.cell)
		draw_circle(center + Vector2(0, 6), 10, Color(0, 0, 0, 0.22))
		_sprite(Art.TOWERS[tower.kind], center + Vector2(0, 10), 42)
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
		_sprite(Art.PROJECTILES[beam.kind], position_value, 10)
		draw_arc(beam.to, 4 + progress * 9, 0, TAU, 16, Color(beam.color, 1.0 - progress), 2)

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("101f2a")
	style.set_border_width_all(1)
	style.border_color = Color("304651")
	style.set_corner_radius_all(10)
	return style
