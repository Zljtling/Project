extends SceneTree
## Deterministic review recording using actual simulation/renderer, never production startup.
func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var bridge_review := "--bridge" in OS.get_cmdline_user_args()
	var review_name := "bridge-combat" if bridge_review else "combat-review"
	var game = load("res://scenes/game_run.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.setup.open_loadout()
	game.setup.starter = "needle"
	game.setup.prepare_escape(20261102)
	game.setup.select_spawn(0)
	game.setup.confirm_spawn()
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.arsenal.set_physics_process(false)
	game.presentation.set_process(false)
	game.presentation.effects.set_process(false)
	for enemy in game.enemies:
		enemy.queue_free()
	game.enemies.clear()
	var base: Vector2 = game.layout.resolve(game.layout.villages[0]["position"]+Vector2(450,850))
	if bridge_review:
		base = game.field_center("poison")+Vector2(-11,0)*32
	game.player.position = base
	game.player.contact_grace = 999
	var camera: Camera3D = game.presentation.view_camera
	camera.set_process(false)
	camera.size = 22
	var focus := Vector3(base.x/32,0.8,base.y/32)
	camera.position = focus+Vector3(8,26,18)
	camera.look_at(focus)
	var placements := [["ghoul",Vector2(-190,0)],["charger",Vector2(190,60)],["spitter",Vector2(190,-80)]] if bridge_review else [["ghoul",Vector2(-180,-180)],["charger",Vector2(250,-100)],["spitter",Vector2(250,170)]]
	for entry in placements:
		var enemy = game.spawn_enemy(game.layout.resolve(base+entry[1]))
		enemy.archetype = entry[0]
		enemy.maximum_health = 900
		enemy.health = 900
		enemy.set_physics_process(false)
		enemy.brain.clock = 0.5
	var boss = game.spawn_boss("guardian","fire")
	boss.position = game.layout.resolve(base+(Vector2(350,0) if bridge_review else Vector2(-140,180)))
	boss.home = boss.position
	boss.engaged = true
	boss.attack_clock = 0.6
	boss.set_physics_process(false)
	game.hud.toast.text = ""
	for i in 120:
		var delta := 1.0/30.0
		var direction := Vector2.RIGHT if i < 30 else Vector2.UP if i < 60 else Vector2.LEFT if i < 90 else Vector2.DOWN
		if bridge_review:
			direction = Vector2.RIGHT if i < 60 else Vector2.LEFT
		game.player.position = game.move_actor(game.player.position,direction*70*delta)
		game.player.facing = direction
		game.player.hurt_flash = 0.12 if i in [66,67,68] else 0
		for enemy in game.enemies.duplicate():
			enemy._physics_process(delta)
		game.arsenal._physics_process(delta)
		game.hostile_patterns.update(game,delta)
		for hit in game.hits:
			hit["life"] -= delta
		game.hits = game.hits.filter(func(h: Dictionary): return h["life"] > 0)
		game.presentation._process(delta)
		game.presentation.effects._process(delta)
		await process_frame
		await RenderingServer.frame_post_draw
		if i in [28,55,87]:
			root.get_texture().get_image().save_png("res://outputs/%s-%d.png" % [review_name,i])
	quit()
