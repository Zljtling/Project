extends SceneTree
const Rules = preload("res://scripts/growth/loot_rules.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run_checks")

func check(value: bool, message: String) -> void:
	checks += 1
	if value:
		print("PASS  ", message)
	else:
		failures += 1
		push_error("FAIL  " + message)

func run_checks() -> void:
	var game = load("res://scenes/validation/planar_run.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.start_run()
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.arsenal.set_physics_process(false)
	game.skills.set_physics_process(false)
	var p: ESRunProgression = game.progression
	p.set_starting_weapon("needle")
	check(p.inventory.size() == 1 and p.equipped[1] == null and p.equipped[2] == null, "start with one selected weapon")
	var spare1 := p.random_weapon()
	var spare2 := p.random_weapon()
	check(p.equip(1, spare1) and p.equip(2, spare2) and not p.equip(3, spare1), "loot weapons fill slots two and three; no fourth slot")
	check(Rules.weapon_drops("supply", 0.119) and not Rules.weapon_drops("supply", 0.12), "supply weapon chance is 12 percent")
	check(Rules.weapon_drops("chest", 0.249) and not Rules.weapon_drops("chest", 0.25), "chest weapon chance is 25 percent")
	check(Rules.weapon_drops("boss", 0.999) and Rules.weapon_stars("boss",0.0) == 2, "boss always drops a two-star weapon")
	var armor_count := 0
	var outside_count := 0
	var inside_count := 0
	for i in 10000:
		armor_count += int(Rules.armor_drop(i/10000.0, 0.2) != "")
		outside_count += int(Rules.material_drops(false, i/10000.0))
		inside_count += int(Rules.material_drops(true, i/10000.0))
	check(armor_count == 200, "equipment occupies exactly 2 percent of chest roll interval")
	check(outside_count == 500 and inside_count == 3000, "element materials use 5 percent outside and 30 percent inside")
	var caches: Array[Dictionary] = []
	var shops: Array[Dictionary] = []
	for facility in game.facilities:
		if facility["kind"] in ["chest", "supply"] and not facility.get("castle", false):
			caches.append(facility)
		elif facility["kind"] == "shop":
			shops.append(facility)
	check(caches.size() == 17 and shops.size() == 3, "map reduces caches and limits vending to three settlements")
	game.rng.seed = 20261102
	var room_layout: Array[Dictionary] = preload("res://scripts/world/facility_placement.gd").build(game)
	check(room_layout.any(func(f: Dictionary): return f.get("indoor",false)), "full gameplay placement can put caches inside houses")
	var separated := true
	for i in caches.size():
		for j in range(i+1, caches.size()):
			separated = separated and caches[i]["position"].distance_to(caches[j]["position"]) >= 650
	check(separated, "ordinary loot caches are at least 650 units apart")
	var shop_villages: Array[String] = []
	var shops_inside := true
	for shop in shops:
		shop_villages.append(shop["village"])
		var village: Dictionary = game.layout.villages.filter(func(v: Dictionary): return v["name"] == shop["village"])[0]
		shops_inside = shops_inside and Rect2(village["position"]-Vector2(570, 470), Vector2(1140, 940)).has_point(shop["position"])
	check(shops_inside and shop_villages[0] != shop_villages[1] and shop_villages[1] != shop_villages[2] and shop_villages[0] != shop_villages[2], "shops occupy three distinct villages and stay inside their bounds")
	check(game.fleet.parked.size() == 6, "six villages begin with six parked electric bikes")
	var bikes_reachable := true
	for village in game.layout.villages:
		var bike: Dictionary = game.fleet.nearest(village["position"], 300)
		bikes_reachable = bikes_reachable and not bike.is_empty() and game.layout.clear_point(bike["position"], 35)
	check(bikes_reachable, "every village has a reachable parking point")
	game.player.position = game.bike_position
	game.toggle_mount()
	p.battery = 23
	game.toggle_mount()
	check(game.fleet.parked[0]["battery"] == 23, "dismounted bike retains its charge")
	p.batteries = 1
	check(game.recharge_vehicle() and game.fleet.parked[0]["battery"] == 83 and p.batteries == 0, "battery item recharges the actual nearby parked vehicle")
	game.player.position = Vector2(400, 600)
	p.batteries = 1
	check(not game.recharge_vehicle() and p.batteries == 1, "battery is not consumed when no vehicle is nearby")
	game.player.position = game.fleet.parked[1]["position"]
	game.toggle_mount()
	check(p.battery == 100, "another parked bike has its own full battery")
	game.toggle_mount()
	var main := p.equipped[0]
	main.elements = {"fire": 5}
	p.unlocked_elements.append("fire")
	p.materials["fire"] = 99
	check(not p.enchant(main, "fire") and p.materials["fire"] == 99, "level-five enchant cannot spend further materials")
	spare1.elements = {"fire": 4}
	spare2.elements = {"fire": 4}
	check(p.combine(main, [spare1, spare2]) and main.elements["fire"] == 5, "combined enchantments clamp to level five")
	game.pickups.clear()
	game.player.position = game.domains["fire"]
	var material_before: int = p.materials["fire"]
	game._physics_process(3)
	check(p.materials["fire"] == material_before, "standing in a field no longer generates materials")
	var material_random := RandomNumberGenerator.new()
	var material_seed := 0
	for seed_value in 10000:
		material_random.seed = seed_value
		material_random.randf()
		var roll := material_random.randf()
		if roll >= 0.05 and roll < 0.30:
			material_seed = seed_value
			break
	game.pickups.clear()
	game.player.position = Vector2(400, 600)
	game.rng.seed = material_seed
	game.drop_element_materials(game.domains["fire"])
	check(game.pickups.any(func(drop: Dictionary): return drop["kind"] == "fire"), "element drop uses enemy death position rather than player position")
	game.pickups.clear()
	game.rng.seed = material_seed
	game.drop_element_materials(Vector2(400, 600))
	check(not game.pickups.any(func(drop: Dictionary): return drop["kind"] == "fire"), "same roll does not drop fire materials outside fire region")
	# Deterministically force both armor outcomes through actual chest interaction.
	for desired in ["poison", "fire"]:
		var random := RandomNumberGenerator.new()
		for seed_value in 10000:
			random.seed = seed_value
			random.randf()
			random.randf()
			if Rules.armor_drop(random.randf(), random.randf()) == desired:
				game.rng.seed = seed_value
				break
		game.facilities.assign([{"kind": "chest", "position": Vector2(400, 600), "used": false, "seen": false}])
		game.player.position = Vector2(400, 600)
		game.interact()
		check(game.player.armor_owned if desired == "poison" else game.player.fire_armor_owned, "chest can grant wearable armor: " + desired)
		while game.skills.pending_rewards > 0:
			game.skills.take_reward(0)
		game.hud.hide_menu()
	# Dungeon cast must draw above the dungeon floor and still deal damage.
	for part in game.objectives.PARTS:
		game.objectives.acquire(part)
	game.player.position = game.ENTRANCE
	check(game.enter_dungeon(), "enter dungeon for turret regression")
	for enemy in game.enemies:
		enemy.set_physics_process(false)
	game.skills.selected[0] = "turret"
	game.skills.cooldowns[0] = 0
	check(game.skills.cast(0) and game.skills.devices.size() == 1, "turret deploys inside dungeon")
	var turret: Vector2 = game.skills.devices[0]["position"]
	var target: ESEnemy = game.enemies[0]
	for other in game.enemies:
		other.position = game.dungeon_rect().position+Vector2(100, 100)
	target.position = turret+Vector2(0, 40)
	var hp := target.health
	game.skills._physics_process(0.1)
	check(target.health < hp, "dungeon turret continues attacking")
	check(game.get_node("DeviceVisual").z_index > game.dungeon_visual.z_index, "turret visual is above dungeon floor")
	if "--capture-turret" in OS.get_cmdline_user_args():
		game.fx_library.clear_effects()
		game.fx_library.hide()
		for i in 8:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://outputs/dungeon-turret.png")
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
