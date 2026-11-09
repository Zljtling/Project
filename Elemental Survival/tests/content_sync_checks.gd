extends SceneTree

var checks := 0
var failures := 0
var game: Node2D

func _initialize() -> void:
	call_deferred("run_checks")

func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS  ", description)
	else:
		failures += 1
		push_error("FAIL  " + description)

func enemy_at(point: Vector2, hp := 200.0) -> ESEnemy:
	var enemy: ESEnemy = game.spawn_enemy(point)
	enemy.set_physics_process(false)
	enemy.maximum_health = hp
	enemy.health = hp
	return enemy

func equip_skill(id: String, used := 0) -> void:
	game.skills.selected[0] = id
	game.skills.uses[id] = used
	game.skills.cooldowns[0] = 0.0

func clear_enemies() -> void:
	for enemy in game.enemies.duplicate():
		enemy.queue_free()
	game.enemies.clear()
	game.marked = null

func run_checks() -> void:
	game = load("res://scenes/validation/planar_run.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.start_run()
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.arsenal.set_physics_process(false)
	game.skills.set_physics_process(false)
	clear_enemies()
	game.player.position = Vector2(2700, 700)
	check(game.domains.keys().size() == 2 and game.progression.inventory.size() == 3, "scope remains two element regions and three existing weapon types")
	check(not game.skills.DEFINITIONS.has("mine") and not game.skills.DEFINITIONS.has("flare") and not game.skills.DEFINITIONS.has("spark") and not game.skills.DEFINITIONS.has("feint"), "removed workbook skills are no longer selectable")
	for id in ["berserk", "execute", "weaken", "fake_death"]:
		check(game.skills.DEFINITIONS.has(id) and ResourceLoader.exists("res://assets/ui/icons/%s.svg" % id), "updated skill has definition and icon: " + id)
	var origin: Vector2 = game.player.position
	equip_skill("turret", 3)
	game.skills.cast(0)
	check(game.skills.devices.size() == 1, "fourth turret use deploys one turret")
	game.skills.cooldowns[0] = 0
	game.skills.cast(0)
	check(game.skills.devices.size() == 2 and game.skills.mastered("turret"), "fifth turret use immediately deploys two turrets")
	var turret_target := enemy_at(game.skills.devices[0]["position"] + Vector2(0, 65))
	game.skills._physics_process(0.01)
	check(is_equal_approx(game.skills.devices[0]["clock"], 0.25) and turret_target.health < 200, "mastered turrets fire at 0.25-second intervals")
	game.skills.cooldowns[0] = 0
	game.skills.cast(0)
	check(game.skills.devices.size() == 2, "repeated deployment keeps a maximum of two turrets")
	game.skills.devices.clear()
	clear_enemies()
	equip_skill("wave", 9)
	var stunned := enemy_at(origin + Vector2(60, 0))
	game.skills.cast(0)
	check(stunned.health == 145 and stunned.stun_left == 1.0, "tenth wave damages and stuns for one second")
	var position_before := stunned.position
	stunned._physics_process(0.25)
	check(stunned.position == position_before and stunned.stun_left > 0, "stunned enemy cannot move or contact attack")
	clear_enemies()
	game.player.health.current = 20
	equip_skill("berserk")
	game.skills.cast(0)
	check(game.skills.berserk_left == 8 and game.skills.attack_speed_multiplier() == 2.0 and is_equal_approx(game.attack_interval_multiplier(), 0.5), "berserk grants eight seconds of doubled weapon attack speed")
	check(is_equal_approx(game.skills.movement_multiplier(), 1.2), "berserk grants 20 percent movement speed")
	var victim := enemy_at(origin + Vector2(70, 0), 10)
	game.deal_player_damage(victim, 10000)
	check(is_equal_approx(game.player.health.current, 21.5), "lifesteal uses actual health removed and never overkill damage")
	equip_skill("berserk", 4)
	game.skills.cast(0)
	check(game.skills.attack_speed_multiplier() == 3 and is_equal_approx(game.skills.movement_multiplier(), 1.4), "fifth berserk use doubles bonuses to 200 percent attack and 40 percent movement")
	victim = enemy_at(origin + Vector2(75, 0))
	game.deal_player_damage(victim, 20)
	check(is_equal_approx(game.player.health.current, 27.5), "mastered berserk grants 30 percent lifesteal")
	game.skills._physics_process(8.01)
	check(game.skills.berserk_left == 0 and game.skills.attack_speed_multiplier() == 1.0, "berserk duration expires without permanent attack-speed gain")
	clear_enemies()
	equip_skill("execute")
	var tank := enemy_at(origin + Vector2(70, 0), 1000)
	tank.health = 600
	game.skills.cast(0)
	check(tank.health == 400, "execute deals 20 percent maximum health rather than current health")
	clear_enemies()
	equip_skill("execute", 6)
	for i in 5:
		var small := enemy_at(origin + Vector2.from_angle(i * TAU / 5) * 60, 100)
		small.health = 10
	game.skills.cast(0)
	check(game.skills.cooldowns[0] == 50, "exactly five small kills do not satisfy greater-than-five reset")
	equip_skill("execute", 7)
	for i in 6:
		var small := enemy_at(origin + Vector2.from_angle(i * TAU / 6) * 70, 100)
		small.health = 10
	game.skills.cast(0)
	check(game.skills.cooldowns[0] == 0, "six small kills with mastery immediately reset execute")
	clear_enemies()
	equip_skill("execute", 8)
	for i in 6:
		var elite := enemy_at(origin + Vector2.from_angle(i * TAU / 6) * 70, 100)
		elite.set_meta("castle_elite", true)
		elite.health = 10
	game.skills.cast(0)
	check(game.skills.cooldowns[0] > 0, "elite kills do not count as small-monster execute resets")
	clear_enemies()
	equip_skill("haste", 9)
	game.skills.cast(0)
	check(game.skills.movement_multiplier() == 2.0, "tenth haste use grants 100 percent movement bonus")
	game.skills.haste_left = 0
	game.skills.passive_haste = 0
	equip_skill("step", 11)
	game.skills.step_charges = 1
	game.player.facing = Vector2.RIGHT
	game.skills.cast(0)
	check(game.player.position.distance_to(origin + Vector2(190, 0)) < 1 and game.skills.step_capacity() == 2 and game.skills.step_charges == 1, "twelfth step follows facing and unlocks one extra stored charge")
	check(game.skills.cast(0) and game.skills.step_charges == 0, "second stored step can be used before cooldown expires")
	check(not game.skills.cast(0), "empty step charges cannot be spammed")
	game.skills._physics_process(8.01)
	check(game.skills.step_charges == 1 and game.skills.cooldowns[0] > 0, "step restores one charge at a time")
	game.skills._physics_process(8.01)
	check(game.skills.step_charges == 2, "step eventually restores both charges")
	game.player.position = origin
	game.player.contact_grace = 0
	equip_skill("weaken")
	var weakened := enemy_at(origin + Vector2(50, 0))
	game.skills.cast(0)
	game.player.health.reset()
	game.player.health.hurt(10)
	check(is_equal_approx(game.player.health.current, 94), "weaken reduces environmental damage by 40 percent")
	game.player.health.reset()
	game.player.health.hurt(10, weakened)
	check(is_equal_approx(game.player.health.current, 95.8), "weakened source adds a multiplicative 30 percent reduction")
	equip_skill("weaken", 5)
	game.skills.cast(0)
	game.player.health.reset()
	game.player.health.hurt(10, weakened)
	check(is_equal_approx(game.player.health.current, 99.2), "sixth weaken use doubles each reduction without exceeding immunity")
	game.skills.weaken_left = 0
	clear_enemies()
	# Environmental damage clocks and the single protection slot.
	var center: Vector2 = game.domains["poison"]
	check(game.field_radius("poison") == 1000 and game.field_radius("fire") == 1000, "workbook radius of one thousand is applied to both regions")
	check(not game.is_toxic(center) and not game.is_toxic(center + Vector2(0, 1080)) and game.is_toxic(center + Vector2(0, 150)), "bridge and two-metre shore are safe while the basin is hazardous")
	game.player.health.reset()
	game.player.poison_protection = false
	game.player.toxin_clock = 0
	game.player.update_environment(0.99, true)
	check(game.player.health.current == 100, "poison waits one full second before damaging")
	game.player.update_environment(0.01, true)
	check(game.player.health.current == 95, "poison deals five damage each second")
	var acid_enemy := enemy_at(center + Vector2(0, 150))
	game.update_enemy_environment(acid_enemy, 0.99)
	check(acid_enemy.health == 200, "acid damage on monsters uses a one-second cadence")
	game.update_enemy_environment(acid_enemy, 0.01)
	check(acid_enemy.health == 196, "acid applies a single environmental tick to monsters")
	var bridge_enemy := enemy_at(center)
	game.update_enemy_environment(bridge_enemy, 2)
	check(bridge_enemy.health == 200, "monster standing on bridge avoids acid exposure")
	game.player.position = game.domains["fire"]
	game.player.health.reset()
	game.player.fire_protection = false
	game.fire_tick = 0
	game._physics_process(0.49)
	check(game.player.health.current == 100, "fire waits half a second before damaging")
	game._physics_process(0.01)
	check(game.player.health.current == 98, "fire deals two damage each half second")
	var fire_enemy := enemy_at(game.domains["fire"] + Vector2(0, 100))
	game.update_enemy_environment(fire_enemy, 0.5)
	check(fire_enemy.health == 198, "lava damages monsters on the same half-second cadence")
	game.player.position = game.FIRE_SUIT_PICKUP
	game.interact()
	check(game.player.fire_armor_owned and game.player.fire_protection and not game.player.poison_protection, "firefighter pickup equips one fire-immune protection suit")
	game.player.position = game.domains["fire"]
	game._physics_process(0.5)
	check(game.player.health.current == 98, "firefighter suit prevents lava damage")
	game.player.armor_owned = true
	game.player.equip_suit("poison")
	check(game.player.poison_protection and not game.player.fire_protection, "biochemical suit replaces firefighter rather than stacking immunities")
	game.player.equip_suit("fire")
	check(game.player.fire_protection and not game.player.poison_protection, "switching back preserves single-slot exclusivity")
	clear_enemies()
	game.player.position = origin
	game.player.equip_suit("")
	game.skills.selected[1] = "wave"
	game.skills.selected[2] = "haste"
	equip_skill("fake_death")
	check(not game.skills.cast(0) and not game.skills.fake_death_used, "fake death cannot be consumed by manual casting")
	game.player.health.reset()
	game.player.health.hurt(10000)
	check(not game.run_over and not game.player.health.is_dead and game.player.health.current == 50, "selected fake death intercepts lethal settlement and restores fifty percent health")
	check(game.skills.fake_death_used and game.skills.invisible_left == 8 and not game.player_visible_to_enemies(), "fake death activates eight-second invisibility and consumes its one run charge")
	check(game.skills.movement_multiplier() == 2, "fake death provides 100 percent movement speed")
	var chaser := enemy_at(origin + Vector2(80, 0))
	check(game.enemy_destination(chaser) == chaser.position, "normal enemies lose tracking of invisible player")
	game.hud._process(0)
	check(game.hud.slots[0].blocked and game.hud.slots[0].blocked_label == "已用", "HUD displays consumed automatic skill")
	game.skills._physics_process(8.01)
	check(game.player_visible_to_enemies() and game.skills.movement_multiplier() == 1, "invisibility and its speed expire together")
	game.skills.offer_reward()
	var no_bad_reward := true
	for choice in game.skills.reward_choices:
		if choice["skill"] == "fake_death":
			no_bad_reward = false
	check(game.skills.reward_choices.size() == 3 and no_bad_reward, "spent passive is excluded while reward still offers three useful choices")
	game.skills.take_reward(0)
	var p: ESRunProgression = game.progression
	p.coins = 500
	p.reset_stock()
	check(p.PRICES["chip"] == 90 and p.stock["chip"] == 1, "chip price and cycle stock match edited workbook")
	check(p.buy("chip") and p.coins == 410 and not p.buy("chip"), "one ninety-coin chip is purchasable per cycle")
	var refresh_before := p.free_refreshes
	check(p.buy("refresh") and p.free_refreshes - refresh_before >= 1 and p.free_refreshes - refresh_before <= 3, "refresh purchase yields between one and three free rolls")
	game.hud.show_menu("shop")
	game.hud.hide_menu()
	game.hud.show_menu("inventory")
	game.hud.hide_menu()
	check(not paused, "updated shop and protection menus open and close safely")
	game.player.health.hurt(10000)
	check(game.run_over and paused and game.hud.menu_kind == "death", "second lethal hit ends the run after fake death is spent")
	paused = false
	game.queue_free()
	await process_frame
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
