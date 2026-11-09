extends SceneTree
const Rules = preload("res://scripts/growth/loot_rules.gd")
const Parts = preload("res://scripts/regions/shared/model_parts.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run_checks")

func check(value: bool, title: String) -> void:
	checks += 1
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
	game.setup.prepare_escape(20261102)
	check(game.MAP_SIZE == Vector2(16000,12000),"surface area expanded fourfold")
	check(game.zones.entries.size() == 6 and game.element_centers("poison").size() == 3 and game.element_centers("fire").size() == 3,"three simultaneous regions per implemented element")
	var first: Array = game.zones.entries.duplicate(true)
	var moved := true
	var bounded := true
	for i in 8:
		game.cycle_index += 1
		var before: Array = game.zones.entries.duplicate(true)
		for element in game.domains:
			game.domains[element] = game._domain_location(element)
		game.presentation.sync_element_geometry()
		moved = moved and game.zones.entries.size() == 6 and game.zones.entries != before
		bounded = bounded and game.presentation.field_set.extra.size() == 4
	check(moved,"eight cycles resample six locations rather than swapping two sites")
	check(bounded,"replicated field ownership stays at four extras across migrations")
	check(not game.dungeon_rect().intersects(Rect2(Vector2.ZERO,game.MAP_SIZE)),"dungeon is outside enlarged surface")
	check(Rules.weapon_drops("mob",0.00499) and not Rules.weapon_drops("mob",0.005),"mob one-star weapon chance exactly 0.5 percent")
	check(Rules.weapon_stars("elite",0.4999) == 1 and Rules.weapon_stars("elite",0.5) == 2,"elite star selection has a fifty-fifty boundary")
	check(Rules.weapon_drops("boss",0.99999) and Rules.weapon_stars("boss",0.1) == 2,"boss always grants two-star weapon")
	game.setup.select_spawn(0)
	game.setup.confirm_spawn()
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.arsenal.set_physics_process(false)
	for enemy in game.enemies:
		enemy.set_physics_process(false)
	var boss = game.spawn_boss("hunter")
	var count: int = game.progression.inventory.size()
	boss.take_hit(999999,Vector2.ZERO,false)
	check(game.progression.inventory.size() == count+1 and game.progression.inventory[-1].stars == 2,"real boss death invokes guaranteed two-star transaction")
	var charger = game.spawn_enemy(game.player.position+Vector2(200,0))
	charger.archetype = "charger"
	charger.brain.clock = 0
	charger.brain.direction(charger,Vector2.LEFT,0.01)
	check(charger.brain.windup > 0 and charger.brain.locked != Vector2.ZERO,"charger telegraphs a locked direction before committing")
	game.hostile_patterns.hazards.clear()
	for i in 200:
		game.hostile_patterns.add(Vector2(100,100),20,0,0.1,1)
	check(game.hostile_patterns.hazards.size() == 96,"hostile effects have an explicit simultaneous cap")
	game.hostile_patterns.update(game,1)
	check(game.hostile_patterns.hazards.is_empty(),"expired hostile effects are released")
	var holder := Node3D.new()
	root.add_child(holder)
	var first_mesh: WeakRef
	for i in 600:
		var node := Parts.box(holder,"Test",Vector3(99+i*0.01,0.1,0.1),Vector3.ZERO,null)
		if i == 0:
			first_mesh = weakref(node.mesh)
		node.free()
	check(Parts._box_meshes.size() <= 512 and first_mesh.get_ref() == null,"cache evicts and frees obsolete meshes rather than growing forever")
	holder.free()
	for part in game.objectives.PARTS:
		game.objectives.acquire(part)
	game.player.position = game.ENTRANCE
	game.enter_dungeon()
	game.presentation._process(0.1)
	await process_frame
	check(game.presentation.surface_released and game.presentation.homes.is_empty() and game.enemies.all(func(enemy: ESEnemy): return game.dungeon_rect().has_point(enemy.position)),"one-way dungeon transition frees overworld actors and scene modules")
	print("RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
