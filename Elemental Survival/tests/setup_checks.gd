extends SceneTree
const SpawnPolicy = preload("res://scripts/world/spawn_locations.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run_checks")

func check(value: bool, description: String) -> void:
	checks += 1
	if value:
		print("PASS  ", description)
	else:
		failures += 1
		push_error("FAIL  " + description)

func run_checks() -> void:
	var game = load("res://scenes/validation/planar_run.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var flow = game.setup
	check(paused and not game.started and game.hud.menu_kind == "main", "startup shows main menu without running simulation")
	check(not game.player.visible, "player stays hidden until spawning")
	check(not flow.confirm_spawn(), "cannot bypass loadout and spawn selection")
	game.hud.primary_button.pressed.emit()
	check(flow.stage == flow.Stage.LOADOUT and game.hud.menu_kind == "loadout", "start game enters loadout rather than gameplay")
	var weapon_picker: OptionButton = game.hud.extras.get_node("StarterWeapon")
	weapon_picker.item_selected.emit(1)
	check(flow.starter == "needle", "starter weapon UI stores chosen weapon")
	game.skills.choose(0, "seeker")
	check(flow.prepare_escape(1024), "start escape creates a seeded map and enters spawn selection")
	check(paused and not game.started and game.hud.menu_kind == "spawn" and game.hud.primary_button.disabled, "spawn screen remains paused and requires a choice")
	check(game.layout.generation_seed == 1024 and game.layout.villages.size() == 6 and game.layout.houses.size() == 24, "random map retains six settlements and 24 enterable houses")
	var first_layout: Array = game.layout.villages.duplicate(true)
	var first_fields: Dictionary = game.domains.duplicate()
	check(game.layout.roads.size() == 6, "generated ring connects all settlements")
	var safe := true
	for choice in flow.spawn_choices:
		safe = safe and SpawnPolicy.is_safe(game, choice["position"])
	check(safe and not flow.spawn_choices.is_empty(), "all offered spawn points pass terrain, danger and obstacle validation")
	for element in game.domains:
		check(not SpawnPolicy.is_safe(game, game.domains[element]), "danger region is never a valid spawn: " + element)
	check(not SpawnPolicy.is_safe(game, Vector2.INF) and not SpawnPolicy.is_safe(game, Vector2(-1, -1)), "non-finite and outside-map spawn points are rejected")
	var clock: float = game.cycle_left
	var elite_position: Vector2 = game.castle_elite.position
	game.player.dash_cooldown = 2
	game.skills.cooldowns[0] = 3
	for i in 8:
		await process_frame
	check(game.run_time == 0 and game.cycle_left == clock and game.castle_elite.position == elite_position and game.skills.cooldowns[0] == 3 and game.player.dash_cooldown == 2, "enemies, survival time, world clock and cooldowns stay frozen before spawn")
	game.hud.hide_menu()
	check(game.hud.modal.visible and paused, "closing modal cannot bypass required spawn screen")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	game.hud._input(escape)
	check(game.hud.menu_kind == "loadout" and paused and not game.started, "Escape returns to loadout without unpausing")
	flow.prepare_escape(1024)
	check(game.layout.villages == first_layout and game.domains == first_fields, "same seed reproduces settlement arrangement and initial danger fields")
	flow.open_loadout()
	flow.prepare_escape(2048)
	check(game.layout.villages != first_layout, "different seed rearranges settlements")
	check(not flow.select_spawn(-1) and not flow.select_spawn(9999), "invalid spawn choices are rejected")
	# Revalidate at confirmation, not merely when generating the marker list.
	flow.select_spawn(0)
	var original_point: Vector2 = flow.spawn_choices[0]["position"]
	flow.spawn_choices[0]["position"] = game.domains["fire"]
	check(not flow.confirm_spawn() and paused and not game.started, "confirmation rejects a point that became dangerous")
	flow.spawn_choices[0]["position"] = original_point
	var map_view = game.hud.extras.get_node("SpawnMap")
	map_view.spawn_selected.emit(0)
	check(flow.selected_spawn == 0 and not game.hud.primary_button.disabled, "map selection highlights a target and enables confirmation")
	var chosen: Vector2 = flow.spawn_choices[0]["position"]
	if "--capture-setup" in OS.get_cmdline_user_args():
		for i in 6:
			await process_frame
		# Exercise actual GUI hit testing after the map has been rendered.
		map_view = game.hud.extras.get_node("SpawnMap")
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		click.position = map_view.point_to_map(chosen)
		map_view._gui_input(click)
		for i in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://outputs/spawn-selection.png")
		flow.open_loadout()
		for i in 6:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://outputs/loadout-preview.png")
		quit()
		return
	game.player.dash_cooldown = 0
	game.skills.cooldowns[0] = 0
	game.hud.primary_button.pressed.emit()
	check(game.started and not paused and game.player.visible and game.player.position == chosen, "confirm spawn places player then starts simulation")
	check(game.progression.inventory.size() == 1 and game.progression.equipped[0].spec == load("res://data/weapons/needle.tres") and game.progression.equipped[1] == null and game.progression.equipped[2] == null, "run starts with exactly the selected starter and two empty slots")
	check(game.skills.selected[0] == "seeker" and game.arsenal.specs[1] == null, "chosen skills survive setup and spare weapon slots do not attack")
	check(not flow.confirm_spawn(), "spawn confirmation is one-time")
	var layout_before: Array = game.layout.villages.duplicate(true)
	var roads_before: Array = game.layout.roads.duplicate(true)
	game.cycle_left = 0.01
	game._physics_process(0.02)
	check(game.cycle_index == 2 and game.layout.villages == layout_before, "cycle migrates dynamic content without rearranging settlements")
	check(game.layout.roads == roads_before, "roads keep their exact positions across world migration")
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
