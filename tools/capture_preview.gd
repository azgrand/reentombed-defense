extends SceneTree
## Render a deterministic visual fixture, using a real display (or Xvfb).
## godot --path . --script tools/capture_preview.gd -- 42 /tmp/preview.png
func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var args := OS.get_cmdline_user_args()
	var map_seed := int(args[0]) if args.size() > 0 else 42
	var output := args[1] if args.size() > 1 else "/tmp/reentombed-preview.png"
	var game = load("res://scenes/main.tscn").instantiate()
	game.audio_enabled = false
	root.add_child(game)
	Input.warp_mouse(Vector2(1250, 60))
	game.set_process(false)
	game._new_map(map_seed)
	game.gold = 220
	var placed := 0
	for i in range(5, game.map_data.route.size() - 5, 12):
		for direction in game.Mapper.DIRECTIONS:
			var cell: Vector2i = game.map_data.route[i] + direction
			if cell.x <= 0 or cell.y <= 0 or cell.x >= game.Mapper.WIDTH - 1 or cell.y >= game.Mapper.HEIGHT - 1:
				continue
			if game.map_data.cells[cell.y][cell.x] == game.Mapper.PAD:
				game.selected = placed
				game._place_tower(cell)
				placed += 1
				break
		if placed == 3:
			break
	game._start_wave()
	for i in range(6):
		game._spawn_enemy()
		game.enemies[-1].progress = 2.0 + i * 3.7
	game.animation_time = 0.5
	game._refresh_ui()
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(output)
	print("Preview: %s (error %d)" % [output, error])
	game.sound.stop()
	game.queue_free()
	await process_frame
	quit(error)
