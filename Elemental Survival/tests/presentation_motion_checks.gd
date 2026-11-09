extends SceneTree
var count := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run_checks")

func check(value: bool, title: String) -> void:
	count += 1
	if value:
		print("PASS  ",title)
	else:
		failures += 1
		push_error("FAIL  "+title)

func run_checks() -> void:
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
	game.presentation._process(0.01)
	var proxy = game.presentation.player_proxy
	check(proxy.sprite.hframes == 8 and proxy.sprite.vframes == 4 and proxy.sprite.texture.get_size() == Vector2(1024,576),"real player uses feet-aligned four-direction gait atlas")
	var start: Vector2 = game.player.position
	game.player.position += Vector2(28,0)
	proxy.sync(0.1,0)
	var moving_frame: Vector2i = proxy.sprite.frame_coords
	check(proxy.motion_state.pose == "walk" and moving_frame.x > 0,"actual displacement drives independent limb frames")
	proxy.sync(0.1,0)
	check(proxy.sprite.frame_coords.x == 0 and proxy.motion_state.pose == "idle","blocked or stationary player stops walking")
	var atlas_directions := {}
	for direction in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
		proxy.motion_state.advance(0.1,20,direction,false,false,false)
		atlas_directions[proxy.motion_state.direction_row] = true
	check(atlas_directions.size() == 4,"front back left right each select a distinct atlas row")
	game.player.hurt_flash = 0.15
	proxy.sync(0.01,0)
	check(proxy.motion_state.pose == "hurt" and proxy.sprite.scale.y < 1,"damage causes compressed reaction without moving collision position")
	game.player.hurt_flash = 0
	game.arsenal.attacked.emit(0,Vector2.RIGHT)
	proxy.sync(0.01,0)
	check(proxy.motion_state.pose == "attack","real arsenal signal drives player attack pose")
	game.player.position += Vector2(30,0)
	proxy.sync(0.01,0)
	check(proxy.motion_state.pose == "attack" and proxy.sprite.frame_coords.x in range(1,7),"automatic attacks preserve gait while moving")
	var enemy = game.spawn_enemy(start+Vector2(200,0))
	enemy.archetype = "charger"
	enemy.set_physics_process(false)
	enemy.brain.clock = 0
	enemy.brain.direction(enemy,Vector2.LEFT,0.01)
	game.presentation._process(0.01)
	var foe = game.presentation.proxies[enemy.get_instance_id()]
	check(foe.motion_state.pose == "windup" and foe.sprite.frame_coords.x == 7,"charger preparation has visible anticipation pose")
	enemy.brain.windup = 0
	enemy.brain.charging = 0.3
	foe.sync(0.01,0)
	check(foe.motion_state.pose == "attack","charging transitions out of anticipation into attack stretch")
	game.arsenal.shots.clear()
	game.arsenal.effects.clear()
	game.hits.clear()
	game.presentation.effects.flashes.clear()
	for mob in game.enemies:
		mob.brain.windup = 0
	game.hostile_patterns.hazards.clear()
	game.hostile_patterns.add(start+Vector2(100,0),17,0,2,8,Vector2.LEFT*155)
	game.presentation.effects._process(0.01)
	check(game.presentation.effects.batch.get_surface_count() == 2,"enemy-only projectile produces solid triangle geometry without player shots")
	check(game.hostile_patterns.hazards[0]["life"] == 2,"presentation does not advance hostile damage simulation")
	for i in 200:
		game.presentation.effects.pulse(start,20,Color.WHITE)
		game.arsenal.attacked.emit(0,Vector2.RIGHT)
	check(game.presentation.effects.pulses.size() <= 64 and game.presentation.effects.flashes.size() <= 12,"cosmetic feedback has bounded pulse and muzzle storage")
	game.presentation.effects._process(1)
	check(game.presentation.effects.pulses.is_empty() and game.presentation.effects.flashes.is_empty(),"expired cosmetic feedback is released")
	game.hud.show_menu("inventory")
	var before: Vector2i = proxy.sprite.frame_coords
	var before_phase: float = proxy.motion_state.phase
	for i in 3:
		await process_frame
	check(paused and proxy.sprite.frame_coords == before and proxy.motion_state.phase == before_phase,"inventory pause freezes live animation alongside combat")
	var grid = game.hud.extras.get_node("InventoryGrid")
	check(grid.get_child(0).get_theme_stylebox("normal").bg_color.get_luminance() > 0.5,"inventory selected slot has legible light forest background")
	var text_luminance: float = game.hud.root.theme.get_color("font_color","Label").srgb_to_linear().get_luminance()
	var paper_luminance: float = Color("ede2bd").srgb_to_linear().get_luminance()
	check((paper_luminance+0.05)/(text_luminance+0.05) >= 7.0,"paper UI body text exceeds seven-to-one luminance contrast")
	game.hud.show_menu("forge")
	var recipe = game.hud.extras.get_node("ForgePanel").find_child("RecipePreview",true,false)
	check(recipe.get_child(0).get_theme_stylebox("panel").bg_color.get_luminance() > 0.5,"forge recipe no longer mixes dark legacy slots with dark text")
	print("RESULT: %d checks, %d failures" % [count,failures])
	quit(1 if failures else 0)
