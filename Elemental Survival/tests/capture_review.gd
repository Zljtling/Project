# Graphical review harness. Does not drive Windows input or change game saves.
extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func snapshot(name: String) -> void:
	var pending: Array[Node] = [root]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node.get_script() == preload("res://scripts/presentation/actor_visual.gd"):
			node._process(0.0)
		if node is CanvasItem:
			node.queue_redraw()
		pending.append_array(node.get_children())
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var result := image.save_png("res://logs/" + name + ".png")
	if result != OK:
		push_error("Screenshot failed: " + name)
	print("SNAPSHOT ", name, " ", image.get_size())

func capture() -> void:
	var game = load("res://scenes/validation/planar_run.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.start_run()
	paused = true
	game.skills.cooldowns[0] = 5.0
	game.player.dash_cooldown = 0.8
	await snapshot("review_gameplay")
	game.bike_position = game.player.position
	game.toggle_mount()
	await snapshot("review_riding")
	game.toggle_mount()
	game.player.position = Vector2(1500, 1500)
	game.camera.reset_smoothing()
	game.camera.force_update_scroll()
	await snapshot("review_village")
	game.player.position = game.layout.houses[0].get_center()
	game.camera.reset_smoothing()
	game.camera.force_update_scroll()
	await snapshot("review_house")
	game.player.position = game.tower_position + Vector2(0, 170)
	game.camera.reset_smoothing()
	game.camera.force_update_scroll()
	game.spawn_enemy(game.tower_position + Vector2(-75, 200)).set_physics_process(false)
	await snapshot("review_castle")
	game.player.position = game.domains["poison"] - Vector2(500, 0)
	game.camera.reset_smoothing()
	game.camera.force_update_scroll()
	await snapshot("review_domain")
	game.player.position = game.domains["fire"] - Vector2(600, 0)
	game.camera.reset_smoothing()
	game.camera.force_update_scroll()
	await snapshot("review_lava")
	game.skills.selected[0] = "seeker"
	game.skills.uses["seeker"] = 4
	game.skills.cooldowns[0] = 0
	paused = false
	game.skills.cast(0)
	paused = true
	print("COOLDOWN ", game.skills.cooldowns[0], " DISPLAY ", game.hud.slots[0].remaining)
	game.hud.show_menu("map")
	await snapshot("review_map")
	game.hud.hide_menu()
	game.player.position = Vector2(2700, 700)
	game.skills.selected[0] = "berserk"
	game.skills.selected[1] = "step"
	game.skills.selected[2] = "fake_death"
	game.skills.uses["berserk"] = 4
	game.skills.uses["step"] = 11
	game.skills.cooldowns[0] = 0
	game.skills.cooldowns[1] = 0
	game.skills.cast(0)
	game.skills.cast(1)
	game.player.health.hurt(1000)
	paused = true
	game.camera.reset_smoothing()
	game.camera.force_update_scroll()
	await snapshot("review_updated_skills")
	game.hud.show_menu("intro")
	await snapshot("review_skill_selection")
	game.hud.hide_menu()
	game.skills.selected[0] = "seeker"
	game.skills.selected[1] = "wave"
	game.skills.selected[2] = "haste"
	game.skills.invisible_left = 0
	game.skills.berserk_left = 0
	game.player.health.reset()
	game.player.armor_owned = true
	game.player.fire_armor_owned = true
	game.hud.show_menu("inventory")
	await snapshot("review_suits")
	game.hud.show_menu("shop")
	await snapshot("review_shop")
	game.hud.hide_menu()
	game.objectives.acquire("core")
	game.objectives.acquire("prism")
	game.objectives.acquire("gear")
	game.player.position = game.ENTRANCE
	game.enter_dungeon()
	paused = true
	game.dungeon_time = 0.8
	await snapshot("review_dungeon")
	paused = false
	game.skills.cooldowns[0] = 0.0
	for i in 3:
		game.skills.cast(i)
	await create_timer(3.0).timeout
	await snapshot("review_live_combat")
	paused = true
	for room in 2:
		for enemy in game.enemies.duplicate():
			enemy.take_hit(100000, Vector2.ZERO, false)
		game.player.position = game.dungeon_door()
		game.interact()
	await snapshot("review_final_guardian")
	paused = false
	game.queue_free()
	await process_frame
	quit()
