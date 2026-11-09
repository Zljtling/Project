extends SceneTree
## Real runtime presentation, deterministic poses for tower review.
func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var game = load("res://scenes/game_run.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.setup.open_loadout()
	game.setup.prepare_escape(20261102)
	game.setup.select_spawn(0)
	game.setup.confirm_spawn()
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.skills.set_physics_process(false)
	game.arsenal.set_physics_process(false)
	game.presentation.set_process(false)
	for enemy in game.enemies:
		enemy.set_physics_process(false)
	game.hud.toast.text = ""
	var camera: Camera3D = game.presentation.view_camera
	camera.set_process(false)
	var origin: Vector2 = game.tower_position
	for shot in ["overview","court","treasury","gallery","sink"]:
		game.player.position = origin + (Vector2(220,260) if shot == "treasury" else Vector2(0,160))
		if shot == "gallery":
			game.player.position = origin+Vector2(-244,-118)
		game.sinking_left = 2.0 if shot == "sink" else 0.0
		game.presentation._process(0.0)
		var focus := Vector3(origin.x/32,3.0,origin.y/32)
		camera.size = 45.0
		if shot in ["court","treasury","gallery"]:
			focus = game.presentation.player_proxy.position+Vector3(0,1.0,0)
			camera.size = 22.0
		camera.position = focus+Vector3(0.25,0.8,0.5454).normalized()*65
		camera.look_at(focus)
		for i in 5:
			await process_frame
			await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://outputs/tower-%s.png" % shot)
		print("CAPTURE tower-",shot)
	quit()
