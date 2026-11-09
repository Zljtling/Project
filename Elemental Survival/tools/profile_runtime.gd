extends SceneTree
## Headless simulation benchmark; render timings must be measured separately.
func _initialize() -> void:
	call_deferred("run_profile")

func run_profile() -> void:
	var game = load("res://scenes/game_run.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.setup.open_loadout()
	game.setup.prepare_escape(20261102)
	game.setup.select_spawn(0)
	game.setup.confirm_spawn()
	game.player.health.damage_filters.append(func(_amount: float,_source: Node) -> float: return 0)
	game.arsenal.set_physics_process(false)
	game.spawn_clock = 99999
	while game.enemies.size() < 90:
		game.spawn_enemy()
	var samples: Array[float] = []
	for i in 180:
		var begin := Time.get_ticks_usec()
		game._physics_process(1.0/60.0)
		game.player._physics_process(1.0/60.0)
		game.skills._physics_process(1.0/60.0)
		for enemy in game.enemies.duplicate():
			enemy._physics_process(1.0/60.0)
		if i >= 60:
			samples.append((Time.get_ticks_usec()-begin)/1000.0)
	samples.sort()
	var total := 0.0
	for sample in samples:
		total += sample
	print("PROFILE: enemies=%d walls=%d mean_simulation_ms=%.2f p95_simulation_ms=%.2f" % [game.enemies.size(),game.layout.walls.size(),total/samples.size(),samples[int(samples.size()*0.95)]])
	quit()
