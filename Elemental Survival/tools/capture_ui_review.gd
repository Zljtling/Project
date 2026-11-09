extends SceneTree
## Captures real controls through the real pre-run flow, then inventory/forge.
func _initialize() -> void:
	call_deferred("capture")

func save_screen(id: String) -> void:
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://outputs/ui-%s.png" % id)

func capture() -> void:
	var game = load("res://scenes/game_run.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await save_screen("main")
	game.setup.open_loadout()
	await save_screen("loadout")
	game.setup.prepare_escape(20261102)
	game.setup.select_spawn(0)
	game.hud.show_menu("spawn")
	await save_screen("spawn")
	game.setup.confirm_spawn()
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.arsenal.set_physics_process(false)
	for i in 12:
		game.progression.random_weapon()
	game.hud.show_menu("inventory")
	await save_screen("inventory")
	game.hud.show_menu("forge")
	await save_screen("forge")
	quit()
