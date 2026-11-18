extends VBoxContainer
const Art = preload("res://scripts/game/art.gd")
const System = preload("res://scripts/game/tower_system.gd")
var game: Node
var buttons: Array[Button] = []
var inspected := -1
var info: PanelContainer
var description: Label

func _ready() -> void:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	add_child(grid)
	for i in range(game.balance.towers.size()):
		var spec: Dictionary = game.balance.towers[i]
		var card := Button.new()
		card.text = "%d %s" % [i + 1, tr(spec.name_key)]
		card.custom_minimum_size = Vector2(156, 54)
		var atlas := AtlasTexture.new()
		atlas.atlas = Art.tower_texture(spec.id)
		atlas.region = Rect2(0, 0, atlas.atlas.get_width() / Art.tower_frames(spec.id), atlas.atlas.get_height())
		card.icon = atlas
		card.expand_icon = true
		card.add_theme_constant_override("icon_max_width", 20)
		card.pressed.connect(game._select.bind(i))
		card.mouse_entered.connect(show_details.bind(i))
		card.focus_entered.connect(show_details.bind(i))
		card.mouse_exited.connect(hide_details)
		card.focus_exited.connect(hide_details)
		grid.add_child(card)
		buttons.append(card)
	var empty := Control.new()
	empty.custom_minimum_size = Vector2(156, 54)
	grid.add_child(empty)
	info = PanelContainer.new()
	info.position = Vector2(-354, 0)
	info.size = Vector2(340, 220)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(info)
	# Top level prevents VBox layout from positioning the floating details.
	info.set_as_top_level(true)
	info.position = Vector2(572, 156)
	description = Label.new()
	description.custom_minimum_size.x = 320
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(description)
	info.hide()

func show_details(index: int) -> void:
	inspected = index
	var spec: Dictionary = game.balance.towers[index]
	var dps := tr("shop.support") if spec.behavior == "aura" else tr("shop.dps").format({"value": snappedf(float(spec.damage) / float(spec.cooldown), 0.1)})
	description.text = tr("shop.details").format({"name": tr(spec.name_key), "cost": int(spec.cost), "damage": spec.damage, "range": spec.range, "cooldown": spec.cooldown, "dps": dps, "description": tr(spec.description_key)})
	info.show()

func hide_details() -> void:
	if info != null:
		info.hide()
