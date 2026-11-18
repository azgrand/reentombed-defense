extends VBoxContainer
signal closed
var language_label: Label
var sound: CheckButton
var fullscreen: CheckButton
var back: Button

func _ready() -> void:
	language_label = Label.new()
	add_child(language_label)
	var language := OptionButton.new()
	language.add_item("English")
	language.add_item("Español")
	language.select(1 if Preferences.values.language == "es" else 0)
	language.item_selected.connect(func(index): Preferences.set_preference("language", "es" if index == 1 else "en"))
	add_child(language)
	sound = CheckButton.new()
	sound.button_pressed = Preferences.values.sound
	sound.toggled.connect(func(value): Preferences.set_preference("sound", value))
	add_child(sound)
	fullscreen = CheckButton.new()
	fullscreen.button_pressed = Preferences.values.fullscreen
	fullscreen.toggled.connect(func(value): Preferences.set_preference("fullscreen", value))
	add_child(fullscreen)
	back = Button.new()
	back.pressed.connect(func(): closed.emit())
	add_child(back)
	_refresh()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_refresh()

func _refresh() -> void:
	language_label.text = tr("settings.language")
	sound.text = tr("settings.sound")
	fullscreen.text = tr("settings.fullscreen")
	back.text = tr("menu.back")
