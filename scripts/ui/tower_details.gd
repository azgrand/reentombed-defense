extends PanelContainer
var game: Node
var title: Label
var current: Label
var next: Label
var upgrade: Button
var sell: Button

func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.09, 0.12, 0.98)
	style.set_border_width_all(1)
	style.border_color = Color("67a5a0")
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		style.set_content_margin(side, 12)
	add_theme_stylebox_override("panel", style)
	position = Vector2(550, 410)
	size = Vector2(346, 300)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	title = Label.new()
	current = Label.new()
	next = Label.new()
	for label in [title, current, next]:
		label.custom_minimum_size.x = 310
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(label)
	upgrade = Button.new()
	upgrade.pressed.connect(game._upgrade_selected)
	box.add_child(upgrade)
	sell = Button.new()
	sell.pressed.connect(game._sell_selected)
	box.add_child(sell)
	var close := Button.new()
	close.text = tr("upgrade.close")
	close.pressed.connect(func(): game.selected_tower = {}; hide())
	box.add_child(close)
	hide()

func refresh() -> void:
	if game.selected_tower.is_empty() or not game.towers.has(game.selected_tower):
		hide()
		return
	var tower: Dictionary = game.selected_tower
	var spec: Dictionary = game.TowerSystem.computed_stats(game, tower)
	title.text = tr(spec.name_key) + " · " + tr("upgrade.level").format({"level": tower.level})
	current.text = tr("upgrade.current").format({"dps": snappedf(spec.damage / maxf(0.01, spec.cooldown), 0.1), "damage": snappedf(spec.damage, 0.1), "range": snappedf(spec.range, 0.1), "cooldown": snappedf(spec.cooldown, 0.01), "aura": roundi(float(spec.get("aura_bonus", 0)) * 100)})
	if spec.behavior == "aura":
		current.text = tr("upgrade.support_current").format({"aura": roundi(spec.aura_bonus * 100), "range": snappedf(spec.range, 0.1)})
	var cost: int = game.TowerSystem.upgrade_cost(spec, tower, game.balance.progression)
	upgrade.text = tr("upgrade.max") if tower.level >= 4 else tr("upgrade.action").format({"cost": cost})
	upgrade.disabled = tower.level >= 4 or game.gold < cost or game.paused or game.ended
	sell.text = tr("upgrade.sell").format({"amount": game.TowerSystem.refund(tower, game.balance.progression)})
	sell.disabled = game.paused or game.ended
	if tower.level < 4:
		var future := tower.duplicate()
		future.level += 1
		var future_stats: Dictionary = game.TowerSystem.computed_stats(game, future)
		next.text = tr("upgrade.next").format({"damage": snappedf(future_stats.damage, 0.1), "range": snappedf(future_stats.range, 0.1), "aura": roundi(float(future_stats.get("aura_bonus", 0)) * 100)})
		if spec.behavior == "aura":
			next.text = tr("upgrade.support_next").format({"aura": roundi(future_stats.aura_bonus * 100), "range": snappedf(future_stats.range, 0.1)})
	else:
		next.text = tr("upgrade.max")
