extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var args := OS.get_cmdline_user_args()
	var mode := args[0] if args.size() > 0 else "menu"
	var output := args[1] if args.size() > 1 else "/tmp/menu.png"
	if args.size() > 2 and args[2] == "scaled":
		root.size = Vector2i(1024, 640)
	var prefs = root.get_node("Preferences")
	prefs.values.language = "es" if mode == "settings" else "en"
	prefs.values.sound = false
	prefs.apply()
	var scene = load("res://scenes/main_menu.tscn" if mode in ["menu", "settings"] else "res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	if mode == "settings":
		scene.get_child(0).show_page("settings")
	elif mode not in ["menu", "settings"]:
		scene.set_process(false)
		scene._new_map(42)
		if mode == "combat":
			scene.gold = 1000
			var placed := 0
			for i in range(3, scene.map_data.route.size() - 3, 6):
				for direction in scene.Mapper.DIRECTIONS:
					var cell: Vector2i = scene.map_data.route[i] + direction
					if cell.x <= 0 or cell.y <= 0 or cell.x >= scene.Mapper.WIDTH - 1 or cell.y >= scene.Mapper.HEIGHT - 1:
						continue
					if scene.map_data.cells[cell.y][cell.x] == scene.Mapper.PAD:
						scene.selected = 3 + placed % 4
						var before: int = scene.towers.size()
						scene._place_tower(cell)
						if scene.towers.size() > before:
							placed += 1
							break
				if placed >= 4:
					break
			scene._start_wave()
			for i in range(10):
				scene._spawn_enemy()
				scene.enemies[-1].progress = 3.0 + i * 1.5
				scene.enemies[-1].hp = 500.0
				scene.enemies[-1].max_hp = 500.0
			scene._tick(0.01)
			scene._refresh_ui()
			scene.renderer.queue_redraw()
		if mode == "upgrade":
			scene.gold = 1000
			for y in range(scene.Mapper.HEIGHT):
				for x in range(scene.Mapper.WIDTH):
					if scene.towers.is_empty() and scene.map_data.cells[y][x] == scene.Mapper.PAD:
						scene._place_tower(Vector2i(x,y))
			scene.selected_tower = scene.towers[0]
			for i in range(3):
				scene._upgrade_selected()
			scene.details.refresh()
			scene.details.show()
		if mode == "shop":
			scene.shop.show_details(3)
	Input.warp_mouse(Vector2(1250, 60))
	await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(output)
	print("UI preview: ", output, " error ", error)
	scene.queue_free()
	await process_frame
	quit(error)
