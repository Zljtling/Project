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
	var game = load("res://scripts/run/run_growth.gd").new()
	root.add_child(game)
	current_scene = game
	await process_frame
	check(paused and game.hud.menu_kind == "intro", "growth scene opens paused loadout selection")
	check(game.hud.root.get_child(game.hud.root.get_child_count() - 1) == game.hud.modal, "modal layer stays above skill bar and resource HUD")
	game.skills.choose(0, "decoy")
	game.skills.choose(1, "turret")
	game.skills.choose(2, "seeker")
	check(game.skills.selected == ["decoy", "turret", "seeker"], "all three slots can use the same category")
	game.start_run()
	game.skills.choose(0, "haste")
	check(game.skills.selected[0] == "decoy", "loadout cannot change after the run starts")
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.arsenal.set_physics_process(false)
	game.skills.set_physics_process(false)
	var p: ESRunProgression = game.progression
	var main: ESWeaponInstance = p.equipped[0]
	main.elements = {"poison": 1}
	p.equipped[1].elements = {"fire": 1}
	p.equipped[2].elements = {"poison": 1}
	var fodder := p.ingredients(main)
	check(not p.combine(main, [fodder[0], fodder[0]]), "forge rejects duplicate material references atomically")
	check(main.stars == 1 and p.inventory.size() == 3, "invalid combine consumes no weapon")
	check(p.combine(main, fodder), "different same-star weapon types can combine")
	check(main.stars == 2 and main.elements == {"poison": 2, "fire": 1}, "combine preserves main type and merges duplicate element strength")
	check(p.inventory.size() == 1 and p.equipped[1] == null and p.equipped[2] == null, "consumed equipped materials leave empty weapon slots")
	check(p.equipped[0] == main and main.capacity() == 3, "two-star main remains equipped with three element slots")
	for i in 2:
		var material := p.random_weapon()
		material.stars = 2
		material.elements = {"poison": 1}
	check(p.combine(main, p.ingredients(main)) and main.stars == 3 and main.elements["poison"] == 4, "second combine upgrades to three stars and preserves elemental investment")
	p.miracles = 1
	var old_damage := main.damage(main.spec.damage)
	check(p.breakthrough(main) and main.stars == 4 and p.miracles == 0, "miracle piece is consumed exactly once for four-star evolution")
	check(main.capacity() > 100000 and main.damage(main.spec.damage) > old_damage * 2.0, "four-star weapon has unrestricted element capacity and substantial damage boost")
	var elemental_target: ESEnemy = game.spawn_enemy(Vector2(1100, 1000))
	elemental_target.set_physics_process(false)
	game.apply_elements(elemental_target, game.weapon_elements(0))
	check(elemental_target.poison_damage >= 40 and elemental_target.burn_damage >= 12.5, "four-star multiplier also boosts elemental damage, not only direct damage")
	elemental_target.take_hit(10000, Vector2.ZERO, false)
	p.materials["poison"] = 20
	check(not p.enchant(main, "poison"), "materials alone cannot bypass elemental boss unlock")
	p.unlocked_elements.append("poison")
	check(p.enchant(main, "poison") and main.elements["poison"] == 5 and p.materials["poison"] == 14, "repeat portable enchant consumes material and strengthens existing element")
	p.coins = 100
	var batteries := p.batteries
	check(p.buy("battery") and p.coins == 85 and p.batteries == batteries + 1, "vending transaction deducts coins and grants a battery")
	p.battery = 20
	check(p.use_battery() and p.battery == 80 and p.batteries == batteries, "using a battery restores charge and consumes inventory item")
	game.player.position = game.bike_position
	check(game.toggle_mount() and game.riding, "player can mount a nearby charged vehicle")
	game.player.velocity = Vector2(100, 0)
	game._physics_process(1.0)
	check(p.battery < 100 and game.player.speed_multiplier > 1.0, "moving vehicle consumes battery and increases movement speed")
	check(game.toggle_mount() and not game.riding and game.bike_position == game.player.position, "dismount leaves vehicle at player's current location")
	var supply: Dictionary = game.facilities.filter(func(f: Dictionary): return f["kind"] == "supply")[0]
	game.player.position = supply["position"]
	var before_weapons := p.inventory.size()
	game.interact()
	check(supply["used"] and p.inventory.size() <= before_weapons + 1, "supply station rolls optional weapon loot and becomes empty")
	var after_loot := p.inventory.size()
	game.interact()
	check(p.inventory.size() == after_loot, "empty station cannot be looted repeatedly")
	game.skills.offer_reward()
	check(game.skills.reward_choices.size() == 3, "skill reward offers exactly three alternatives")
	var compatible := true
	for choice in game.skills.reward_choices:
		compatible = compatible and choice["skill"] in game.skills.selected
	check(compatible, "reward options target carried skills")
	p.free_refreshes = 1
	p.coins = 10
	check(game.skills.refresh_reward() and p.free_refreshes == 0 and p.coins == 10, "refresh uses a free charge before spending coins")
	check(game.skills.refresh_reward() and p.coins == 0, "paid refresh deducts its displayed progressive cost")
	check(not game.skills.refresh_reward() and p.coins == 0, "insufficient coins cannot refresh or become negative")
	check(game.skills.take_reward(0) and game.skills.pending_rewards == 0, "choosing an enhancement resolves the pending reward")
	for menu in ["inventory", "forge", "shop", "help"]:
		game.hud.show_menu(menu)
		check(paused and game.hud.menu_kind == menu, "management menu opens safely: " + menu)
		await process_frame
	game.hud.hide_menu()
	game.player.position = game.domains["poison"] + Vector2(40, 0)
	var guardian = game.spawn_boss("guardian", "poison")
	guardian.set_physics_process(false)
	guardian.take_hit(200.0, Vector2.ZERO, false)
	var injured: float = guardian.health
	check(injured < guardian.maximum_health, "guardian takes damage while player is inside its domain")
	guardian.migrate(Vector2(1610, 700))
	guardian._physics_process(3.0)
	check(guardian.health <= injured + 2.0, "domain migration retains injury and uses very slow recovery")
	game.player.position = guardian.home + Vector2(600, 0)
	guardian.engaged = true
	guardian._physics_process(0.1)
	var returning_hp: float = guardian.health
	guardian.take_hit(500.0, Vector2.ZERO, false)
	check(guardian.health == returning_hp, "out-of-domain attacks cannot cheese returning guardian")
	game.player.position = guardian.home
	guardian.returning = false
	guardian.take_hit(10000, Vector2.ZERO, false)
	check("poison" in p.unlocked_elements and game.skills.pending_rewards == 1, "element guardian defeat unlocks element and offers skill enhancement")
	game.skills.take_reward(0)
	var hunter = game.spawn_boss("hunter")
	hunter.set_physics_process(false)
	var relics := p.miracles
	hunter.take_hit(10000, Vector2.ZERO, false)
	check(p.miracles == relics, "hunter does not drop the non-element guardian's miracle piece")
	game.skills.take_reward(0)
	var tower_guardian = game.spawn_boss("guardian", "")
	tower_guardian.set_physics_process(false)
	game.player.position = tower_guardian.home
	tower_guardian.take_hit(10000, Vector2.ZERO, false)
	check(p.miracles == relics + 1, "non-element guardian drops one miracle piece")
	game.skills.take_reward(0)
	game.player.health.reset()
	for id in game.skills.DEFINITIONS:
		game.skills.selected[0] = id
		game.skills.cooldowns[0] = 0.0
		if id == "fake_death":
			check(not game.skills.cast(0), "automatic death guard cannot be cast manually")
			continue
		check(game.skills.cast(0), "active skill executes: " + id)
		check(not game.skills.cast(0), "active skill respects cooldown: " + id)
	game.skills.selected[0] = "decoy"
	game.skills.uses["decoy"] = 9
	game.skills.cooldowns[0] = 0.0
	game.skills.cast(0)
	check(game.skills.uses["decoy"] == 10, "decoy mastery threshold is tracked in this run")
	var migrating = game.spawn_boss("guardian", "poison")
	migrating.set_physics_process(false)
	game.player.position = migrating.home
	migrating.take_hit(100.0, Vector2.ZERO, false)
	var old_hp: float = migrating.health
	var old_position: Vector2 = migrating.home
	var old_facilities: Array = game.facilities.duplicate(true)
	p.stock["battery"] = 0
	game.cycle_left = 0.01
	game._physics_process(0.1)
	check(game.facilities != old_facilities and p.stock["battery"] == 3, "cycle relocates facilities and refills stock")
	check(migrating.home != old_position and migrating.health == old_hp, "living guardian follows migrating domain without instant healing")
	# Verify that imported art can be attached without touching the actor controller.
	var image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var texture := ImageTexture.create_from_image(image)
	var appearance := ESActorAppearance.new()
	appearance.texture = texture
	var visual = load("res://scripts/presentation/actor_visual.gd").new()
	visual.actor = game.player
	visual.appearance = appearance
	game.player.add_child(visual)
	check(visual.art is Sprite2D, "presentation accepts replacement texture independently from player logic")
	visual.queue_free()
	var animated_appearance := ESActorAppearance.new()
	var frames := SpriteFrames.new()
	frames.add_animation("idle")
	frames.add_frame("idle", texture)
	frames.add_animation("run")
	frames.add_frame("run", texture)
	animated_appearance.animations = frames
	var animated_visual = load("res://scripts/presentation/actor_visual.gd").new()
	animated_visual.actor = game.player
	animated_visual.appearance = animated_appearance
	game.player.add_child(animated_visual)
	check(animated_visual.art is AnimatedSprite2D, "presentation also accepts replaceable SpriteFrames animations")
	animated_visual.queue_free()
	game.skills.pending_rewards = 0
	game.hud.hide_menu()
	game.player.position = Vector2(1050, 1000)
	game.player.health.reset()
	game.player.poison_protection = true
	game.set_physics_process(true)
	game.player.set_physics_process(true)
	game.arsenal.set_physics_process(true)
	game.skills.set_physics_process(true)
	await create_timer(0.6).timeout
	check(not game.run_over, "growth scene runs its real frame loop after forging and migration")
	game.pickups.clear()
	game.add_pickup("coins", Vector2.ZERO, 2)
	game.add_pickup("coins", Vector2(3, 3), 3)
	check(game.pickups.size() == 1 and game.pickups[0]["amount"] == 5, "nearby currency drops merge without losing value")
	game.pickups.clear()
	for i in 400:
		game.add_pickup("coins", Vector2(i * 100, 0), 2)
		game.add_pickup("parts", Vector2(i * 100, 100), 1)
	var total_coins := 0
	var total_parts := 0
	for drop in game.pickups:
		if drop["kind"] == "coins":
			total_coins += drop["amount"]
		else:
			total_parts += drop["amount"]
	check(game.pickups.size() <= 256 and total_coins == 800 and total_parts == 400, "long-run drop pooling stays bounded and preserves both resource totals")
	game.pickups.clear()
	paused = false
	game.queue_free()
	await process_frame
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
