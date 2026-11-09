extends SceneTree

func _initialize() -> void:
	call_deferred("measure")

func measure() -> void:
	var game = load("res://scenes/validation/planar_run.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.start_run()
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.arsenal.set_physics_process(false)
	game.skills.set_physics_process(false)
	game.player.health.maximum = 1000000
	game.player.health.current = 1000000
	game.player.position = Vector2(1500, 1500)
	for i in 89:
		var point: Vector2 = game.player.position + Vector2.from_angle(i * 2.4) * (250 + i * 4)
		game.spawn_enemy(point).set_physics_process(false)
	var samples: Array[float] = []
	for i in 180:
		var start := Time.get_ticks_usec()
		for enemy in game.enemies.duplicate():
			if enemy.alive:
				enemy._physics_process(1.0 / 60)
		game.arsenal._physics_process(1.0 / 60)
		samples.append((Time.get_ticks_usec() - start) / 1000.0)
	var total := 0.0
	for sample in samples:
		total += sample
	samples.sort()
	print("PERFORMANCE: 90 enemies + walls + navigation + arsenal; mean %.2f ms / p95 %.2f ms / max %.2f ms (CPU simulation only)" % [total / samples.size(), samples[int(samples.size() * 0.95)], samples.back()])
	game.queue_free()
	await process_frame
	quit()
