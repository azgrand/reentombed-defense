extends CanvasLayer
const SettingsPanel = preload("res://scripts/ui/settings_panel.gd")
var game: Node
var page := ""
var screen: Control

func clear() -> void:
	page = ""
	if screen != null:
		remove_child(screen)
		screen.queue_free()
		screen = null

func show_page(next_page: String) -> void:
	clear()
	page = next_page
	screen = Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(screen)
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.05, 0.07, 0.96)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(center)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(460, 0)
	box.add_theme_constant_override("separation", 18)
	center.add_child(box)
	var title := Label.new()
	title.text = "Reentombed Defense" if game == null else tr("menu.pause" if page != "result" else game.hint)
	title.add_theme_font_size_override("font_size", 34)
	box.add_child(title)
	if page == "settings":
		var settings := SettingsPanel.new()
		settings.closed.connect(func(): show_page("menu" if game == null else "pause"))
		box.add_child(settings)
		return
	if game == null:
		var art := TextureRect.new()
		var atlas := AtlasTexture.new()
		atlas.atlas = preload("res://assets/simple_tower_defense/Towers/Castle/spr_castle_green.png")
		atlas.region = Rect2(0, 0, 52, 38)
		art.texture = atlas
		art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.custom_minimum_size.y = 140
		box.add_child(art)
		button(box, "menu.play", func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))
		button(box, "menu.settings", func(): show_page("settings"))
		button(box, "menu.quit", func(): get_tree().quit())
	elif page == "result":
		button(box, "game.retry", func(): game._new_map(game.seed_value); clear())
		button(box, "game.new_map", func(): game._random_map(); clear())
		button(box, "menu.main", _main_menu)
	else:
		button(box, "menu.resume", func(): game._toggle_pause())
		button(box, "menu.settings", func(): show_page("settings"))
		button(box, "menu.main", _confirm_main_menu)

func button(box: Control, key: String, action: Callable) -> Button:
	var item := Button.new()
	item.text = tr(key)
	item.custom_minimum_size.y = 48
	item.pressed.connect(action)
	box.add_child(item)
	return item

func _confirm_main_menu() -> void:
	var confirmation := ConfirmationDialog.new()
	confirmation.dialog_text = tr("menu.confirm")
	confirmation.ok_button_text = tr("menu.accept")
	confirmation.cancel_button_text = tr("menu.cancel")
	confirmation.confirmed.connect(_main_menu)
	confirmation.canceled.connect(confirmation.queue_free)
	screen.add_child(confirmation)
	confirmation.popup_centered()

func _main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready() and page != "":
		call_deferred("show_page", page)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE and page == "settings":
		show_page("menu" if game == null else "pause")
		get_viewport().set_input_as_handled()
