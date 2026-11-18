extends Control
const Navigation = preload("res://scripts/ui/navigation.gd")
func _ready() -> void:
	var navigation := Navigation.new()
	add_child(navigation)
	navigation.show_page("menu")
