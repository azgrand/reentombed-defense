extends Node2D

const Mapper = preload("res://scripts/core/entombed_mapper.gd")
const Art = preload("res://scripts/game/art.gd")
const TowerSystem = preload("res://scripts/game/tower_system.gd")
const MapRenderer = preload("res://scripts/game/map_renderer.gd")
var renderer: Node2D
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
	renderer = MapRenderer.new()
	renderer.game = self
	add_child(renderer)
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
		button.icon = Art.TOWERS[spec.id]
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
	renderer.queue_redraw()

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
	if index < 0 or index >= balance.towers.size():
		return
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
		if event.keycode >= KEY_1 and event.keycode < KEY_1 + balance.towers.size():
			_select(event.keycode - KEY_1)
		match event.keycode:
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
		renderer.queue_redraw()

func _place_tower(cell: Vector2i) -> void:
	if cell.x < 0 or cell.y < 0 or cell.x >= Mapper.WIDTH or cell.y >= Mapper.HEIGHT:
		return
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
	renderer.queue_redraw()

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
	TowerSystem.fire(self, delta)
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

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("101f2a")
	style.set_border_width_all(1)
	style.border_color = Color("304651")
	style.set_corner_radius_all(10)
	return style
