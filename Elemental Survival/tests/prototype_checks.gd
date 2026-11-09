extends SceneTree

var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("run_checks")

func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS  ", description)
	else:
		failures += 1
		push_error("FAIL  " + description)

func run_checks() -> void:
	var hp := ESHealth.new()
	root.add_child(hp)
	var state := {"charge": true, "deaths": 0}
	hp.died.connect(func(): state["deaths"] += 1)
	hp.lethal_guards.append(func(component: ESHealth):
		if state["charge"]:
			state["charge"] = false
			component.heal(30.0)
	)
	hp.hurt(200)
	check(not hp.is_dead and hp.current == 30.0, "lethal guard can prevent death before settlement")
	check(state["deaths"] == 0, "intercepted lethal hit never emits final death")
	hp.hurt(200)
	hp.hurt(200)
	check(hp.is_dead and state["deaths"] == 1, "spent guard allows exactly one final death notification")
	hp.queue_free()
	var game = load("res://scripts/run/world_simulation.gd").new()
	root.add_child(game)
	current_scene = game
	await process_frame
	check(paused and not game.started, "instructions pause simulation before run starts")
	game.start_run()
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.arsenal.set_physics_process(false)
	check(not paused and game.started, "start resumes the world")
	var player: ESPlayer = game.player
	player.poison_protection = false
	player.update_environment(1.0, true)
	check(player.health.current == 95.0 and player.poison_enchantment > 0.0, "unprotected toxic exposure damages and enchants")
	player.poison_protection = true
	player.update_environment(1.0, true)
	check(player.health.current == 95.0, "whole poison suit prevents environmental poison damage")
	player.armor_owned = false
	player.position = game.ARMOR_PICKUP
	game.interact()
	check(player.armor_owned and player.poison_protection, "world interaction picks up and equips the suit")
	player.position = Vector2(1100, 1000)
	var near: ESEnemy = game.spawn_enemy(player.position + Vector2(80, 0))
	var far: ESEnemy = game.spawn_enemy(player.position + Vector2(160, 0))
	near.set_physics_process(false)
	far.set_physics_process(false)
	game.mark_at(far.position)
	check(game.find_target(player.position, 200.0) == far, "manual mark overrides nearest enemy when in range")
	check(game.find_target(player.position, 100.0) == near, "out-of-range mark does not block a weapon's valid target")
	game.mark_at(Vector2.ZERO)
	check(game.find_target(player.position, 200.0) == near, "empty-space click restores automatic target selection")
	game.mark_at(far.position)
	far.take_hit(100.0, Vector2.ZERO, false)
	check(not is_instance_valid(game.marked), "killed priority target is cleared")
	var toxic_enemy: ESEnemy = game.spawn_enemy(game.TOXIC_CENTER + Vector2(0, 200))
	toxic_enemy.set_physics_process(false)
	toxic_enemy._physics_process(1.01)
	check(toxic_enemy.health < 28.0, "toxic terrain also damages enemies")
	near.take_hit(1.0, Vector2.ZERO, true)
	check(near.poison_left > 0.0, "poisoned weapon applies enemy damage-over-time state")
	var clock: float = game.cycle_left
	var hp_before: float = player.health.current
	game.set_physics_process(true)
	game.player.set_physics_process(true)
	game.arsenal.set_physics_process(true)
	game.hud.show_menu("inventory")
	var paused_position: Vector2 = player.position
	await create_timer(0.08, true, false, true).timeout
	check(game.cycle_left == clock and player.health.current == hp_before and player.position == paused_position, "inventory pauses world clock, damage and movement")
	game.hud.hide_menu()
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.arsenal.set_physics_process(false)
	player.position = game.tower_position
	game._physics_process(0.001)
	check(player.on_tower, "walking into castle automatically establishes region presence")
	var before_interaction := player.position
	game.interact()
	check(player.position == before_interaction, "castle needs no E ascent or exit teleport")
	player.contact_grace = 0.0
	player.contact_hit(20.0)
	check(player.health.current == hp_before - 20, "castle offers no immunity from enemies that can enter")
	var old_tower: Vector2 = game.tower_position
	var old_enemy_count: int = game.enemies.size()
	game.cycle_left = 0.01
	game.advance_world(0.1)
	check(game.cycle_index == 2 and game.sinking_left > 0.0, "cycle boundary starts a gradual castle collapse")
	check(player.on_tower, "collapse preserves presence during the warning window")
	game.advance_world(game.tower_sink_duration)
	check(not player.on_tower and game.tower_position != old_tower, "collapse restores ground and creates the next castle")
	check(player.position.distance_to(old_tower) < 1.0, "player remains on the persistent ground when castle disappears")
	check(game.enemies.size() == old_enemy_count, "world transition preserves existing monsters")
	game.cycle_speed = 6.0
	clock = game.cycle_left
	game.advance_world(1.0)
	check(is_equal_approx(game.cycle_left, clock - 6.0), "test acceleration affects only the world clock")
	# Exercise the real frame loop and projectiles, not just direct mechanic calls.
	player.position = Vector2(1100, 1000)
	player.health.reset()
	game.set_physics_process(true)
	player.set_physics_process(true)
	game.arsenal.set_physics_process(true)
	for enemy in game.enemies:
		enemy.set_physics_process(true)
	var combat_kills: int = game.kills
	var victim: ESEnemy = game.spawn_enemy(player.position + Vector2(90, 0))
	victim.speed = 0.0
	await create_timer(1.2).timeout
	check(game.kills > combat_kills, "three-weapon frame loop kills an enemy without manual firing")
	player.health.hurt(10000.0)
	check(game.run_over and paused and game.hud.menu_kind == "death", "unintercepted player death pauses and opens run settlement")
	paused = false
	game.queue_free()
	await process_frame
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
