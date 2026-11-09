extends SceneTree
const G = preload("res://scripts/world/scene_geometry.gd")
const P = preload("res://scripts/regions/elemental/poison_layout.gd")
const Spawn = preload("res://scripts/world/spawn_locations.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run_checks")

func check(value: bool, description: String) -> void:
	checks += 1
	if value:
		print("PASS  ",description)
	else:
		failures += 1
		push_error("FAIL  "+description)

func run_checks() -> void:
	var game = load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	check(game.get_script() == load("res://scripts/run/game_run.gd"),"F5 runs integrated 2.5D game rather than the review scene")
	check(paused and not game.started and game.hud.menu_kind == "main","integrated game preserves paused title flow")
	game.hud.primary_button.pressed.emit()
	game.setup.starter = "needle"
	check(game.setup.prepare_escape(20261102),"loadout generates actual 3D world before spawn selection")
	check(paused and game.layout.houses.size() == 44 and game.presentation.homes.size() == 44,"map and scene share all 44 authored houses")
	check(game.presentation.modules.size() == 6,"all six accepted regions are in the actual run")
	var first_layout: Array = game.layout.villages.duplicate(true)
	var first_walls: Array = game.layout.static_walls.duplicate()
	game.setup.open_loadout()
	game.setup.prepare_escape(20261102)
	check(first_layout == game.layout.villages and first_walls == game.layout.static_walls,"same seed reproduces identities, geography and model collisions")
	var reachable_homes := 0
	for home in game.presentation.homes:
		var center := G.point2(home.global_position)
		var at := center+Vector2(0,4.1)*G.UNITS
		for i in 70:
			at = game.move_actor(at,Vector2(0,-2))
		check(absf(at.y-center.y) < 20 and absf(at.x-center.x) < 1,"walk continuously through model doorway: "+str(center))
		var path: PackedVector2Array = game.layout.navigation.get_point_path(game.layout.nearest_cell(center+Vector2(0,6)*G.UNITS),game.layout.nearest_cell(center))
		reachable_homes += int(not path.is_empty())
		if path.is_empty():
			print("NAV DEBUG ",center)
	check(reachable_homes == 44,"enemy navigation connects through all authored doorways")
	check(game.layout.walls.size() > 200 and game.layout.static_walls.size() > 150,"movement and line of sight use model walls and landmark blockers")
	var indoor := 0
	var reachable := true
	for facility in game.facilities:
		indoor += int(facility.get("indoor",false))
		reachable = reachable and game.layout.clear_point(facility["position"],18)
	check(game.facilities.size() == 25 and indoor > 0 and reachable,"real reward containers include reachable indoor placements within existing budget: total %d indoor %d" % [game.facilities.size(),indoor])
	check(game.fleet.parked.size() == 6,"one live electric bike per settlement survives integration")
	var all_safe: bool = not game.setup.spawn_choices.is_empty()
	for choice in game.setup.spawn_choices:
		all_safe = all_safe and Spawn.is_safe(game,choice["position"])
	check(all_safe,"every offered spawn passes actual geometry and danger exclusions")
	check(game.setup.select_spawn(0) and game.setup.confirm_spawn(),"confirm spawn starts combat in the integrated world")
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.skills.set_physics_process(false)
	game.arsenal.set_physics_process(false)
	for enemy in game.enemies:
		enemy.set_physics_process(false)
	check(game.progression.equipped[0].spec == load("res://data/weapons/needle.tres") and game.progression.equipped[1] == null and game.progression.equipped[2] == null,"one initial weapon and three available equipment slots are retained")
	game.presentation._process(0.1)
	check(game.presentation.player_proxy.visible and game.presentation.view_camera.current and not game.camera.enabled,"live player has one active 3D camera")
	var center: Vector2 = game.field_center("poison")
	for i in P.ISLANDS.size():
		var stone: Vector2 = Vector2(P.ISLANDS[i].x,P.ISLANDS[i].z)
		check(not game.is_toxic(center+stone*G.UNITS),"rest stone is genuinely safe: %d" % i)
	var bridge_safe := true
	var bridge_walkable := true
	for link in P.LINKS:
		for i in 41:
			bridge_safe = bridge_safe and not game.is_toxic(center+link[0].lerp(link[1],i/40.0)*G.UNITS)
		var a: Vector2 = center+link[0]*G.UNITS
		var b: Vector2 = center+link[1]*G.UNITS
		var at := a
		for i in ceili(a.distance_to(b)/3.0)+100:
			at = game.move_actor(at,at.direction_to(b)*minf(3.0,at.distance_to(b)))
		bridge_walkable = bridge_walkable and at.distance_to(b) < 2
		if at.distance_to(b) >= 2:
			print("CROSSING DEBUG ",link," stop ",(at-center)/G.UNITS)
	check(bridge_safe,"every connected bridge including angled branches is safe end to end")
	check(bridge_walkable,"bridge rails and shore boulders leave all crossings and stone junctions physically open")
	check(game.layout.dynamic_walls.size() > 40,"large shore boulders and bridge rails block movement and attacks")
	var liquid := center+Vector2(0,18)*G.UNITS
	check(game.is_toxic(liquid) and not game.is_toxic(center+Vector2(0,29)*G.UNITS),"only acid footprint damages; dry outer shore is safe")
	check(not Spawn.is_safe(game,center+Vector2(-5,0)*G.UNITS),"safe bridge inside danger area is still forbidden as a selectable spawn")
	check(game.material_region_contains("poison",center+Vector2(-5,0)*G.UNITS),"safe pool stones still count as in-region for the thirty-percent material roll")
	game.player.health.reset()
	var hp: float = game.player.health.current
	game.player.update_environment(1.0,game.is_toxic(liquid))
	check(game.player.health.current == hp-5,"unprotected player takes existing poison damage on acid")
	game.player.update_environment(2.0,false)
	check(game.player.health.current == hp-5 and game.player.toxin_clock == 0,"resting on safe surface resets exposure without continuing acid damage")
	game.player.armor_owned = true
	game.player.equip_suit("poison")
	game.player.update_environment(2.0,true)
	check(game.player.health.current == hp-5,"existing biochemical suit protects against pool exposure")
	game.player.equip_suit("")
	game.player.position = G.point2(game.presentation.homes[0].global_position)
	game.presentation._process(0.1)
	check(not game.presentation.homes[0].roof.visible and not game.presentation.homes[0].front.visible,"actual player entry reveals roof and front facade")
	# Real container interaction uses the existing loot transaction, not review loot.
	var room_cache: Dictionary = {}
	for facility in game.facilities:
		if facility.get("indoor",false):
			room_cache = facility
			break
	game.player.position = room_cache["position"]
	check(game.nearest_facility() == room_cache,"indoor container participates in actual interaction lookup")
	var coins: int = game.progression.coins
	game.interact()
	check(room_cache["used"] and game.progression.coins > coins,"searching indoor box grants actual run loot once")
	var coins_after: int = game.progression.coins
	game.interact()
	check(game.progression.coins == coins_after,"used indoor box cannot grant duplicate rewards")
	while game.skills.pending_rewards > 0:
		game.skills.take_reward(0)
	game.hud.hide_menu()
	var village_before: Array = game.layout.villages.duplicate(true)
	var poison_before: Vector2 = game.field_center("poison")
	game.cycle_index += 1
	for element in game.domains:
		game.domains[element] = game._domain_location(element)
	game.presentation.sync_element_geometry()
	game._reset_facilities(false)
	game.finish_tower_migration()
	game.presentation._process(0.1)
	check(game.layout.villages == village_before and game.field_center("poison") != poison_before,"cycle moves elemental fields while settlements remain fixed")
	check(G.point2(game.presentation.poison.position) == game.field_center("poison") and G.point2(game.presentation.castle.position) == game.tower_position,"migrated poison and tower art follow authoritative gameplay positions")
	for part in game.objectives.PARTS:
		game.objectives.acquire(part)
	game.player.position = game.ENTRANCE
	check(game.enter_dungeon(),"actual 3D run can enter the existing dungeon progression")
	for enemy in game.enemies:
		enemy.set_physics_process(false)
	game.skills.selected[0] = "turret"
	game.skills.cooldowns[0] = 0
	check(game.skills.cast(0),"turret deploys after real dungeon transition")
	game.presentation._process(0.1)
	check(game.presentation.dungeon.visible and game.presentation.devices.get_child_count() == 1 and game.presentation.surface_released,"dungeon floor, combat actors and turret have visible 3D counterparts")
	var turret: Vector2 = game.skills.devices[0]["position"]
	var target: ESEnemy = game.enemies[0]
	for enemy in game.enemies:
		enemy.position = game.dungeon_rect().position+Vector2(100,100)
	target.position = turret+Vector2(0,40)
	var health := target.health
	game.skills._physics_process(0.1)
	check(target.health < health,"visible dungeon turret still deals real damage")
	print("RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
