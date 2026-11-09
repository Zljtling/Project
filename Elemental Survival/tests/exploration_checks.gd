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

func run_checks() -> void:
	var game = load("res://scenes/validation/planar_run.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.skills.choose(0, "seeker")
	check(game.skills.selected[0] == "seeker", "seeker can be selected before starting")
	game.start_run()
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.arsenal.set_physics_process(false)
	game.skills.set_physics_process(false)
	for enemy in game.enemies:
		enemy.set_physics_process(false)
	check(game.MAP_SIZE.x * game.MAP_SIZE.y > 9 * 2600 * 1900, "world has over nine times the previous explorable area")
	check(game.layout.villages.size() == 6 and game.layout.houses.size() == 24, "six settlements have 24 enterable houses")
	check(game.field_radius("poison") == 1000 and game.field_radius("fire") == 1000, "both elements use enlarged radius")
	check(game.is_toxic(game.domains["poison"] + Vector2(0, 950)) and not game.is_toxic(game.domains["poison"] + Vector2(0, 1050)), "poison gameplay boundary matches enlarged presentation")
	var supplies := 0
	var chests := 0
	var castle_chests := 0
	var connected := true
	for facility in game.facilities:
		facility["seen"] = true
		supplies += int(facility["kind"] == "supply")
		chests += int(facility["kind"] == "chest")
		castle_chests += int(facility.get("castle", false))
		check(game.layout.clear_point(facility["position"], 18), "facility is reachable outside a wall: %s" % facility["kind"])
		var path: PackedVector2Array = game.layout.navigation.get_point_path(game.layout.nearest_cell(game.player.position), game.layout.nearest_cell(facility["position"]))
		connected = connected and not path.is_empty() and path[path.size() - 1].distance_to(facility["position"]) < 80
	check(connected, "every facility connects to the road network through walkable doors")
	check(supplies == 10 and chests == 8, "map uses ten supplies and eight chests including castle")
	check(castle_chests == 1, "castle contains exactly one fixed chest")
	var allowed := ["entrance", "tower", "domain", "forge", "hunter"]
	var correct_markers := true
	for marker in game.surface_map_markers():
		correct_markers = correct_markers and marker["kind"] in allowed
	check(correct_markers and game.revealed_chests.is_empty(), "even discovered loot, supplies and shops never auto-mark")
	var hunter = game.spawn_boss("hunter")
	hunter.set_physics_process(false)
	var guardian = game.spawn_boss("guardian", "fire")
	guardian.set_physics_process(false)
	var hunter_marked := false
	var guardian_marked := false
	for marker in game.surface_map_markers():
		hunter_marked = hunter_marked or marker["position"] == hunter.position
		guardian_marked = guardian_marked or (marker["position"] == guardian.position and marker["kind"] == "hunter")
	check(hunter_marked and not guardian_marked, "hunter is tracked without exposing territorial guardian as a loot marker")
	var candidates: Array[Dictionary] = []
	for facility in game.facilities:
		if facility["kind"] == "chest":
			candidates.append(facility)
	candidates.sort_custom(func(a: Dictionary, b: Dictionary): return game.player.position.distance_squared_to(a["position"]) < game.player.position.distance_squared_to(b["position"]))
	check(game.skills.cast(0), "first seeker activation succeeds")
	check(game.revealed_chests.size() == 1 and game.revealed_chests[0] == candidates[0], "seeker reveals exactly the nearest unopened chest")
	check(game.skills.cooldowns[0] == 20 and game.skills.uses["seeker"] == 1, "seeker starts at 20 second cooldown and tracks successful uses")
	check(not game.skills.cast(0), "seeker cannot bypass cooldown")
	for i in 4:
		game.skills.cooldowns[0] = 0
		game.skills.cast(0)
	check(game.skills.uses["seeker"] == 5 and game.revealed_chests.size() == 3, "fifth activation immediately unlocks three-chest mastery")
	check(game.revealed_chests == candidates.slice(0, 3), "mastery selects nearest three distinct chests")
	game.revealed_chests[0]["used"] = true
	var marked_chests := 0
	for marker in game.surface_map_markers():
		marked_chests += int(marker["kind"] == "revealed_chest")
	check(marked_chests == 2, "looted chest disappears from scanned map marks")
	game.skills.cooldowns[0] = 0
	game.skills.cast(0)
	check(game.revealed_chests.size() == 3 and game.revealed_chests[0] == candidates[1], "repeated scan excludes consumed chest")
	game.bike_position = game.player.position
	game.arsenal.shots.append({"life": 1})
	game.skills.devices.append({"kind": "turret"})
	check(game.toggle_mount() and not game.combat_allowed(), "mounting disables combat")
	check(game.arsenal.shots.is_empty() and game.skills.devices.is_empty(), "mount clears residual projectiles and attacking deployments")
	game.skills.selected[1] = "wave"
	game.skills.cooldowns[1] = 0
	var enemy: ESEnemy = game.spawn_enemy(game.player.position + Vector2(65, 0))
	enemy.set_physics_process(false)
	var enemy_hp := enemy.health
	for i in 3:
		game.arsenal.cooldowns[i] = 0.0
	game.arsenal._physics_process(1.0)
	game.arsenal.attack(game.arsenal.specs[0], enemy, 0)
	check(enemy.health == enemy_hp and game.arsenal.shots.is_empty(), "riding blocks automatic and direct weapon attacks")
	check(not game.skills.cast(1) and game.skills.cooldowns[1] == 0, "riding rejects offensive skills without consuming cooldown")
	game.hud._process(0.0)
	check(game.hud.slots[1].blocked and not game.hud.slots[0].blocked, "riding HUD distinguishes blocked combat skill from usable seeker")
	game.skills.cooldowns[0] = 0
	check(game.skills.cast(0), "noncombat seeker remains usable while riding")
	game.toggle_mount()
	game.arsenal.attack(game.arsenal.specs[0], enemy, 0)
	check(enemy.health < enemy_hp, "dismount restores normal weapon damage")
	var center: Vector2 = game.tower_position
	var from := center + Vector2(0, 500)
	var inside: Vector2 = game.move_actor(from, Vector2(0, -300))
	check(game.tower_rect().has_point(inside), "player walks through castle south gate without E")
	var follower: ESEnemy = game.spawn_enemy(from)
	follower.set_physics_process(false)
	game.player.position = center
	follower.speed = 180
	for i in 160:
		follower._physics_process(0.025)
	check(game.tower_rect().has_point(follower.position), "monster follows player through the same castle gate")
	check(is_instance_valid(game.castle_elite) and game.castle_elite.health == 420, "castle has its fixed elite")
	var elite_count := 0
	for foe in game.enemies:
		elite_count += int(foe.has_meta("castle_elite"))
	check(elite_count == 1, "fixed elite does not duplicate")
	var house: Rect2 = game.layout.houses[0]
	from = house.position + Vector2(120, 260)
	inside = game.move_actor(from, Vector2(0, -160))
	check(house.has_point(inside), "house south door is walkable")
	var blocked: Vector2 = game.move_actor(house.position + Vector2(45, -80), Vector2(0, 240))
	check(blocked.y < house.position.y, "dash-sized motion cannot tunnel through house north wall")
	check(not game.line_of_sight(house.position + Vector2(120, -60), house.get_center()), "house walls block weapon targeting")
	var indoor_enemy: ESEnemy = game.spawn_enemy(house.get_center())
	indoor_enemy.set_physics_process(false)
	game.player.position = house.position + Vector2(120, 290)
	for i in 400:
		indoor_enemy._physics_process(0.025)
	check(indoor_enemy.position.distance_to(game.player.position) < 70, "navigation leads an indoor enemy out through a door")
	# Confirm A* can route around the solid north wall to reach a player inside.
	var path_enemy: ESEnemy = game.spawn_enemy(house.position + Vector2(120, -100))
	path_enemy.set_physics_process(false)
	game.player.position = house.get_center()
	path_enemy.speed = 150
	for i in 500:
		path_enemy._physics_process(0.025)
	check(path_enemy.position.distance_to(game.player.position) < 75, "navigation routes around a blocked wall to an open door")
	game.reveal_nearest_chests(3)
	var old_elite_hp: float = game.castle_elite.health
	game.castle_elite.take_hit(35, Vector2.ZERO, false)
	game._reset_facilities(false)
	check(game.revealed_chests.is_empty(), "world relocation clears every chest scan")
	game.finish_tower_migration()
	check(game.castle_elite.health == old_elite_hp - 35 and game.tower_rect().has_point(game.castle_elite.position), "living castle elite migrates without refilling health")
	var valid_facilities := true
	for facility in game.facilities:
		valid_facilities = valid_facilities and game.layout.clear_point(facility["position"], 18)
	check(valid_facilities, "relocated facilities remain clear of rebuilt castle walls")
	for facility in game.facilities:
		if facility["kind"] == "chest":
			facility["used"] = true
	game.skills.cooldowns[0] = 0
	var empty_uses: int = game.skills.uses["seeker"]
	check(not game.skills.cast(0) and game.skills.cooldowns[0] == 0 and game.skills.uses["seeker"] == empty_uses, "empty scan consumes neither cooldown nor mastery use")
	# Several transitions also exercise reserved castle sites and regenerated loot.
	var migration_valid := true
	game.rng.seed = 412027
	for cycle in 6:
		game.cycle_left = 0.01
		game._physics_process(0.02)
		game.finish_tower_migration()
		for facility in game.facilities:
			migration_valid = migration_valid and game.layout.clear_point(facility["position"], 18)
		migration_valid = migration_valid and game.domains["poison"].distance_to(game.domains["fire"]) >= 2450
	check(migration_valid, "six further migrations preserve clear loot placements and separated element regions")
	game.castle_elite.take_hit(10000, Vector2.ZERO, false)
	game.finish_tower_migration()
	elite_count = 0
	for foe in game.enemies:
		elite_count += int(foe.has_meta("castle_elite") and foe.alive)
	check(elite_count == 1 and game.castle_elite.health == 420, "next castle replaces a slain elite exactly once")
	game.player.position = game.ENTRANCE
	for part in ["core", "prism", "gear"]:
		game.objectives.acquire(part)
	check(game.enter_dungeon(), "expanded surface still connects to stable dungeon")
	game.skills.cooldowns[0] = 0
	var uses_before: int = game.skills.uses["seeker"]
	check(not game.skills.cast(0) and game.skills.cooldowns[0] == 0 and game.skills.uses["seeker"] == uses_before, "seeker cannot remotely reveal surface chests from dungeon")
	check(game.dungeon_rect().position.x > game.MAP_SIZE.x, "dungeon coordinates do not overlap the expanded surface")
	paused = false
	game.queue_free()
	await process_frame
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
