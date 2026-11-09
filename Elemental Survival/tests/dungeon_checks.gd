extends SceneTree
const G = preload("res://scripts/world/scene_geometry.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run_checks")

func check(value: bool, message: String) -> void:
	checks += 1
	if value:
		print("PASS  ",message)
	else:
		failures += 1
		push_error("FAIL  "+message)

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
	for part in game.objectives.PARTS:
		game.objectives.acquire(part)
	game.player.position = game.ENTRANCE
	check(game.enter_dungeon(),"actual run enters dungeon with three components")
	var previous_model: WeakRef
	var previous_layout: WeakRef
	for room_index in 3:
		if room_index > 0:
			game._open_room(room_index)
		game.presentation._process(0.0)
		await process_frame
		if previous_model != null:
			check(previous_model.get_ref() == null and previous_layout.get_ref() == null,"room change releases previous scene and navigation")
		previous_model = weakref(game.presentation.dungeon)
		previous_layout = weakref(game.dungeon_layout)
		var base: Vector2 = game.dungeon_rect().position
		check(game.enemies.size() == 12+room_index*6+int(room_index == 2),"room %d preserves encounter budget" % room_index)
		check(game.enemies.all(func(e: ESEnemy): return game.dungeon_layout.clear_point(e.position)),"room %d spawns enemies outside obstacle" % room_index)
		for enemy in game.enemies:
			enemy.set_physics_process(false)
		var walls: Array[Rect2] = []
		var houses: Array[Rect2] = []
		G.collect(game.presentation.dungeon.obstacle,walls,houses)
		check(walls.size() == 1 and walls[0].is_equal_approx(game.dungeon_layout.obstacle),"room %d model and simulation share exactly one footprint" % room_index)
		var at := base+Vector2(350,300)
		var loop_clear := true
		for offset in [Vector2(750,300),Vector2(750,650),Vector2(350,650),Vector2(350,300)]:
			var goal: Vector2 = base+offset
			for i in 200:
				at = game.move_actor(at,at.direction_to(goal)*minf(4,at.distance_to(goal)))
			loop_clear = loop_clear and at.distance_to(goal) < 1
		check(loop_clear,"room %d has a complete four-sided kiting loop" % room_index)
		var stopped: Vector2 = game.move_actor(base+Vector2(350,470),Vector2(450,0))
		check(stopped.x < base.x+430 and game.dungeon_layout.clear_point(stopped),"fast dash cannot tunnel through obstacle")
		var path: PackedVector2Array = game.dungeon_layout.navigation.get_point_path(game.dungeon_layout.nearest_cell(base+Vector2(550,700)),game.dungeon_layout.nearest_cell(game.dungeon_door()))
		check(not path.is_empty() and Array(path).all(func(p: Vector2): return game.dungeon_layout.clear_point(p)),"spawn connects to exit through padded navigation")
		game.player.position = base+Vector2(250,340)
		game.player.health.reset()
		var hp: float = game.player.health.current
		for i in 100:
			game._update_dungeon(0.1)
		check(game.player.health.current == hp,"ten seconds at former trap location causes no environmental damage")
		# Use actual encounter actors, retaining the exit guardian for its charge check.
		var enemy: ESEnemy = game.enemies[0]
		var boss: ESEnemy = game.enemies[-1] if room_index == 2 else null
		for other in game.enemies.duplicate():
			if other != enemy and other != boss:
				other.queue_free()
				game.enemies.erase(other)
		if boss != null:
			boss.position = base+Vector2(350,470)
			boss.charge_direction = Vector2.RIGHT
			boss.charge_left = 1
			boss._physics_process(0.8)
			check(boss.position.x < base.x+430,"exit guardian charge is blocked by stone dais")
			boss.position = base+Vector2(950,850)
		for start in [Vector2(350,470),Vector2(750,470)]:
			enemy.position = base+start
			enemy.archetype = "ghoul"
			enemy.navigation_left = 0
			enemy.knockback = Vector2.ZERO
			game.player.position = base+Vector2(1100-start.x,470)
			game.player.contact_grace = 999
			for i in 900:
				enemy._physics_process(1.0/60)
			check(enemy.position.distance_to(game.player.position) < 45,"melee enemy navigates around cover from x=%d" % start.x)
		enemy.health = 1000
		enemy.position = base+Vector2(690,470)
		game.player.position = base+Vector2(400,470)
		game.arsenal.cooldowns.assign([999.0,999.0,999.0])
		game.arsenal.attack(load("res://data/weapons/needle.tres"),enemy)
		game.arsenal._physics_process(0.5)
		check(enemy.health == 1000 and game.arsenal.shots.is_empty(),"player bolt is absorbed by central cover")
		game.skills.devices.assign([{"kind":"turret","position":game.player.position,"life":8.0,"clock":0.0,"power":1.0,"mastered":false}])
		game.skills._physics_process(0.1)
		check(enemy.health == 1000,"turret cannot shoot through cover")
		game.player.position = base+Vector2(400,300)
		enemy.position = base+Vector2(690,300)
		game.skills.devices[0]["position"] = game.player.position
		game.skills.devices[0]["clock"] = 0.0
		game.skills._physics_process(0.1)
		check(enemy.health < 1000,"turret hits target after moving around cover")
		var before: float = enemy.health
		game.arsenal.attack(load("res://data/weapons/needle.tres"),enemy)
		game.arsenal._physics_process(0.45)
		check(enemy.health < before,"player bolt hits through open flank")
		game.player.position = base+Vector2(700,470)
		game.player.health.reset()
		game.hostile_patterns.add(base+Vector2(400,470),14,0,2,8,Vector2(1000,0))
		game.hostile_patterns.update(game,0.3)
		check(game.player.health.current == game.player.health.maximum and game.hostile_patterns.hazards.is_empty(),"enemy projectile is absorbed before hitting player behind cover")
		game.player.position = base+Vector2(700,300)
		game.hostile_patterns.add(base+Vector2(400,300),14,0,2,8,Vector2(1000,0))
		game.hostile_patterns.update(game,0.3)
		check(game.player.health.current == game.player.health.maximum-8,"enemy projectile remains dangerous in an open lane")
		game.add_pickup("coins",game.dungeon_layout.obstacle.get_center(),2)
		check(game.pickups.all(func(drop: Dictionary): return game.dungeon_layout.clear_point(drop["position"])),"loot is placed on accessible ground")
		game.skills.selected[0] = "turret"
		game.skills.cooldowns[0] = 0
		check(game.skills.cast(0) and game.skills.devices.all(func(d: Dictionary): return game.dungeon_layout.clear_point(d["position"])),"real turret deployment resolves a safe position")
		for other in game.enemies.duplicate():
			other.take_hit(100000,Vector2.ZERO,false)
		check(game.room_cleared,"all surviving enemies can be killed to unlock exit")
		game.hostile_patterns.add(base+Vector2(100,100),20,1,2,8)
	game._open_room(0)
	check(game.pickups.is_empty() and game.skills.devices.is_empty() and game.hostile_patterns.hazards.is_empty() and game.arsenal.shots.is_empty(),"changing rooms clears abandoned loot, devices and attacks")
	print("RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
