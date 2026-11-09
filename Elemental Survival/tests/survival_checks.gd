extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run_checks")

func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS  ", description)
	else:
		failures += 1
		push_error("FAIL  " + description)

func freeze_actors(game: Node2D) -> void:
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.arsenal.set_physics_process(false)
	game.skills.set_physics_process(false)
	for enemy in game.enemies:
		enemy.set_physics_process(false)

func run_checks() -> void:
	var game = load("res://scenes/validation/planar_run.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	check(paused and game.hud.menu_kind == "main", "complete run begins at paused main menu")
	check(not game.hud.minimap.is_visible_in_tree(), "persistent minimap is removed from gameplay HUD")
	check(game.hud.slots.size() == 4 and game.hud.slots[3].texture != null, "three skill icons and separate dash icon are available")
	check(InputMap.has_action("map"), "M map action is registered")
	var logical_map := InputEventKey.new()
	logical_map.keycode = KEY_M
	logical_map.pressed = true
	check(logical_map.is_action_pressed("map"), "logical M events work without a physical scan code")
	var logical_skill := InputEventKey.new()
	logical_skill.keycode = KEY_1
	logical_skill.pressed = true
	check(logical_skill.is_action_pressed("skill_1"), "logical number-key events trigger skill bindings")
	game.start_run()
	freeze_actors(game)
	game.hud.show_menu("map")
	check(paused and game.hud.menu_kind == "map", "opening map pauses the run")
	var old_clock: float = game.cycle_left
	game.set_physics_process(true)
	await create_timer(0.08, true, false, true).timeout
	check(game.cycle_left == old_clock, "map pauses world clock rather than only covering the screen")
	game.set_physics_process(false)
	game.hud.hide_menu()
	check(not paused, "closing map resumes gameplay")
	game.hud._input(logical_map)
	check(paused and game.hud.menu_kind == "map", "M key event actually opens the paused map menu")
	game.hud._input(logical_map)
	check(not paused, "second M key event closes map and resumes")
	check(not game.enter_dungeon(), "locked dungeon rejects entry without three parts")
	var initial_max: float = game.player.health.maximum
	game.player.position = game.objectives.prism_position()
	game.player.hurt_flash = 0.0
	check(game.objectives.begin_extraction(), "dangerous-domain part starts with deliberate interaction")
	game.objectives.update(1.0, true)
	check(not game.objectives.found["prism"], "part is not granted before extraction finishes")
	game.player.position += Vector2(30, 0)
	game.objectives.update(0.1, true)
	check(not game.objectives.extracting and game.objectives.extraction_progress == 0.0, "moving away interrupts extraction without granting a part")
	game.player.position = game.objectives.prism_position()
	game.player.hurt_flash = 0.0
	game.objectives.begin_extraction()
	game.objectives.update(3.6, true)
	check(game.objectives.found["prism"] and game.objectives.count() == 1, "exploration source grants one distinct component")
	check(game.player.health.maximum > initial_max, "component immediately improves player attributes")
	var once_max: float = game.player.health.maximum
	check(not game.objectives.acquire("prism") and game.player.health.maximum == once_max, "duplicate component cannot stack progress or attributes")
	var p: ESRunProgression = game.progression
	p.parts = 75
	p.materials["poison"] = 8
	p.materials["fire"] = 8
	game.player.position = Vector2(2300, 1700)
	check(not game.objectives.craft_gear() and p.parts == 75, "crafting component requires being at forge and consumes nothing remotely")
	game.player.position = game.facilities.filter(func(f: Dictionary): return f["kind"] == "forge")[0]["position"]
	check(game.objectives.craft_gear() and p.parts == 0 and p.materials["poison"] == 0 and p.materials["fire"] == 0, "forge source consumes displayed recipe and grants gear")
	check(game.objectives.count() == 2 and not game.enter_dungeon(), "two components do not unlock final dungeon")
	game.cycle_index = 6
	game.cycle_left = game.cycle_duration
	game.objectives.update(0.1, false)
	var bounty: ESEnemy = game.objectives.bounty
	check(is_instance_valid(bounty) and bounty.get_meta("key_part", "") == "core", "time guarantee marks an actual living boss with the missing part")
	check(game.objectives.count() == 2, "guarantee creates a challenge rather than handing out the part")
	bounty.set_physics_process(false)
	bounty.take_hit(100000.0, Vector2.ZERO, false)
	check(game.objectives.count() == 3 and game.objectives.found["core"], "defeating marked boss guarantees the missing component")
	check(game.player.health.maximum == initial_max + 60.0, "three distinct components apply exactly three growth bonuses")
	check(game.weapon_damage(0, 10.0) > 10.0 and game.skill_cooldown_multiplier() < 1.0 and game.attack_interval_multiplier() < 1.0, "growth improves weapon damage, attack cadence and active-skill cooldown")
	while game.skills.pending_rewards > 0:
		game.skills.take_reward(0)
	game.hud.hide_menu()
	game.player.position = Vector2(1800, 1600)
	check(not game.enter_dungeon(), "unlocked dungeon still requires reaching the fixed entrance")
	var survivor: ESEnemy = game.spawn_enemy(Vector2(1100, 1200))
	survivor.set_physics_process(false)
	var survivor_hp := survivor.health
	game.player.position = game.ENTRANCE
	game.bike_position = game.ENTRANCE
	game.toggle_mount()
	var max_before_entry: float = game.player.health.maximum
	check(game.enter_dungeon(), "three components and entrance interaction begin dungeon")
	freeze_actors(game)
	check(game.in_dungeon and not game.riding and not game.player.on_tower, "dungeon entry clears vehicle and tower states")
	check(game.objectives.count() == 3 and game.player.health.maximum == max_before_entry, "opening entrance retains all components and growth")
	check(survivor.is_queued_for_deletion() and survivor not in game.enemies, "one-way dungeon transition releases surface monsters")
	old_clock = game.cycle_left
	game._physics_process(0.2)
	check(game.cycle_left == old_clock and game.dungeon_time > 0.0, "dungeon clock advances while world migration stays stopped")
	check(game.dungeon_room == 0 and game.enemies.size() == 12 and not game.room_cleared, "first stable room contains a finite encounter")
	game.player.position = game.dungeon_door()
	game.interact()
	check(game.dungeon_room == 0, "locked room door cannot skip living enemies")
	game.player.position = game.dungeon_rect().position+Vector2(250,340)
	game.player.dash_left = 0
	game.dungeon_time = 1.21
	var hp_before: float = game.player.health.current
	game._physics_process(0.02)
	check(game.player.health.current == hp_before, "former trap location no longer deals timed damage")
	game._physics_process(4.5)
	check(game.player.health.current == hp_before, "no trap damage returns on the former cycle")
	for room in 3:
		for enemy in game.enemies.duplicate():
			enemy.take_hit(100000, Vector2.ZERO, false)
		check(game.room_cleared and not game.run_over, "clearing room requires reaching exit rather than auto-winning: %d" % room)
		game.player.position = game.dungeon_door()
		game.interact()
		if room < 2:
			freeze_actors(game)
			check(game.dungeon_room == room + 1 and not game.room_cleared, "door advances to next populated room: %d" % room)
			if room == 1:
				var final_found := false
				for enemy in game.enemies:
					if enemy.get_meta("display_name", "") == "出口守卫":
						final_found = true
				check(final_found, "final room contains a distinct exit guardian")
	check(game.won and game.run_over and paused and game.hud.menu_kind == "victory", "complete collect-to-extract path ends in victory settlement")
	check(game.hud.primary_button.text == "重新开局", "victory offers a fresh run")
	var fx: Dictionary = game.fx_library.load_effect("melee/sword-slash")
	check(not fx.is_empty() and fx["frames"].get_frame_count("default") > 1, "downloaded PixelFX atlas loads as native animation frames")
	check(game.fx_library.play_effect("pickups/collect-burst", game.player.position), "real PixelFX pickup effect can play")
	check(not game.fx_library.play_effect("missing/not-a-real-effect", Vector2.ZERO), "missing optional effect fails safely")
	paused = false
	game.fx_library.clear_effects()
	game.fx_library.play_effect("impacts/hit-flash", game.player.position)
	await create_timer(1.1).timeout
	check(game.fx_library.play_effect("impacts/hit-flash", game.player.position), "effects can be replayed after finished sprite nodes are freed")
	game.fx_library.clear_effects()
	for i in 60:
		game.fx_library.play_effect("impacts/hit-flash", game.player.position)
	check(game.fx_library.active.size() == 48, "effect pool stays bounded under many simultaneous hits")
	var catalog = JSON.parse_string(FileAccess.get_file_as_string("res://assets/pixelfx/catalog.json"))
	var all_native := true
	for entry in catalog["effects"]:
		var frames = load(entry["resource"])
		if not frames is SpriteFrames or frames.get_frame_count("default") != int(entry["frames"]):
			all_native = false
	check(catalog["effects"].size() == 244 and all_native, "all 244 PixelFX native SpriteFrames resources load with expected frame counts")
	paused = false
	game.queue_free()
	await process_frame
	game = load("res://scenes/validation/planar_run.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.start_run()
	freeze_actors(game)
	check(game.objectives.count() == 0 and not game.in_dungeon and not game.won, "new run resets component and dungeon state")
	game.player.health.hurt(100000.0)
	check(game.run_over and not game.won and game.hud.menu_kind == "death", "ordinary lethal hit still ends the run in failure")
	paused = false
	game.queue_free()
	await process_frame
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
