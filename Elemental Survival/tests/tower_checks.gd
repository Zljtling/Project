extends SceneTree
const L = preload("res://scripts/regions/tower/tower_layout.gd")
const G = preload("res://scripts/world/scene_geometry.gd")
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

func walk_route(game: Node, points: Array[Vector2]) -> bool:
	var at := points[0]
	for destination in points.slice(1):
		for i in ceili(at.distance_to(destination)/4.0)+20:
			at = game.move_actor(at,at.direction_to(destination)*minf(4.0,at.distance_to(destination)))
		if at.distance_to(destination) > 1:
			print("ROUTE STOP ",at-game.tower_position," expected ",destination-game.tower_position)
			return false
	return true

func run_checks() -> void:
	var game = load("res://scenes/game_run.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.setup.open_loadout()
	game.setup.prepare_escape(20261102)
	game.setup.select_spawn(0)
	game.setup.confirm_spawn()
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.skills.set_physics_process(false)
	game.arsenal.set_physics_process(false)
	game.presentation.set_process(false)
	for enemy in game.enemies:
		enemy.set_physics_process(false)
	game.presentation._process(0.0)
	var center: Vector2 = game.tower_position
	var tower: Node3D = game.presentation.castle
	var solids: Array[Rect2] = []
	var houses: Array[Rect2] = []
	G.collect(tower,solids,houses)
	var matching := solids.size() == L.collision_rects(center).size()
	for rect in L.collision_rects(center):
		matching = matching and solids.any(func(other: Rect2): return other.is_equal_approx(rect))
	check(matching,"authored tower solids match movement/navigation footprints exactly")
	check(game.castle_elite.home == center+L.ELITE and game.layout.clear_point(game.castle_elite.position,25),"elite starts in the central court without collision")
	for i in L.GATES.size():
		var gate: Vector2 = L.GATES[i]
		var direction := gate.normalized()
		check(walk_route(game,[center+gate+direction*100,center+gate-direction*100]),"player walks through outer gate %d" % i)
		var path: PackedVector2Array = game.layout.navigation.get_point_path(game.layout.nearest_cell(center+gate+direction*100),game.layout.nearest_cell(center+L.ELITE))
		check(not path.is_empty() and Array(path).all(func(p: Vector2): return game.layout.clear_point(p,14)),"navigation reaches central court from gate %d" % i)
	check(walk_route(game,[center+Vector2(0,480),center+Vector2(0,-240),center+Vector2(250,-240),center+Vector2(250,0)]),"short route passes through elite court to east gallery")
	check(walk_route(game,[center+Vector2(0,480),center+Vector2(0,210),center+Vector2(-225,210),center+Vector2(-225,-220),center+Vector2(250,-220),center+Vector2(250,0)]),"long route loops around west gallery and north court")
	for side in [-1,1]:
		check(walk_route(game,[center+L.CHEST,center+Vector2(220+side*220,260)]),"treasury exit remains traversable on side %d" % side)
	check(not game.layout.line_clear(center+Vector2(130,-120),center+Vector2(220,-120)),"gallery wall blocks projectiles")
	check(game.layout.line_clear(center+Vector2(-250,0),center+Vector2(250,0)),"cross-court opening allows shots")
	game.player.position = center+Vector2(0,160)
	game.presentation._process(0.0)
	tower._process(0.0)
	check(tower.cutaway_materials.size() == 5 and tower.stone.get_shader_parameter("cutaway_enabled"),"tower shares five materials with player cutaway enabled")
	var old_clock: float = tower.clock
	paused = true
	await process_frame
	await process_frame
	check(tower.clock == old_clock,"tower banners freeze while game is paused")
	paused = false
	var sockets := get_nodes_in_group("ambient_lamp_sockets").size()
	var children := tower.get_child_count()
	var elite_hp: float = game.castle_elite.health-25
	game.castle_elite.health = elite_hp
	var chest: Dictionary = {}
	for facility in game.facilities:
		if facility.get("castle",false):
			chest = facility
	chest["used"] = true
	for move in 3:
		var previous_center: Vector2 = game.tower_position
		var old_model: WeakRef = weakref(game.presentation.castle)
		var old_material: WeakRef = weakref(game.presentation.castle.stone)
		game.sinking_left = game.tower_sink_duration
		game.advance_world(4.0)
		game.presentation._process(0.0)
		check(is_equal_approx(game.presentation.castle.position.y,-game.presentation.castle.SINK_DEPTH*0.5) and game.presentation.castle.scale == Vector3.ONE and game.tower_position == previous_center,"tower sinks without flattening or migrating before eight seconds")
		game.advance_world(4.0)
		game.presentation._process(0.0)
		await process_frame
		await process_frame
		check(old_model.get_ref() == null and old_material.get_ref() == null,"migration releases the previous tower and its cutaway materials")
		check(game.presentation.castle.get_child_count() == children and get_nodes_in_group("ambient_lamp_sockets").size() == sockets,"repeated migration keeps geometry and lamp socket counts bounded")
		check(game.layout.clear_point(previous_center+L.TOWERS[0]["rect"].get_center()) and not game.layout.clear_point(game.tower_position+L.TOWERS[0]["rect"].get_center()),"migration removes old blockers and installs new blockers")
		check(chest["used"] and chest["position"] == game.tower_position+L.CHEST and game.castle_elite.health == elite_hp and game.castle_elite.home == game.tower_position+L.ELITE,"migration preserves chest consumption and elite health at shared anchors")
	print("RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
