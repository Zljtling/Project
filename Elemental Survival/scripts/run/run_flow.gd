extends "res://scripts/run/run_growth.gd"

const ObjectivesScript := preload("res://scripts/progression/run_objectives.gd")
const DungeonLayout = preload("res://scripts/regions/dungeon/dungeon_layout.gd")
const ENTRANCE := Vector2(370, 370)
const DUNGEON_BASE := Vector2(24000, 18000)
var objectives: ESRunObjectives
var in_dungeon := false
var won := false
var dungeon_room := 0
var room_cleared := false
var dungeon_time := 0.0
var dungeon_layout: RefCounted
var pressure := 0.0
var pressure_clock := 0.0
var recent_damage := 0.0
var heal_clock := 0.0
var dungeon_visual: Node2D
var fx_library: Node2D
var waypoint := Vector2.INF
var setup: Node

func _ready() -> void:
	objectives = ObjectivesScript.new()
	objectives.world = self
	add_child(objectives)
	super._ready()
	setup = preload("res://scripts/progression/run_setup.gd").new()
	setup.world = self
	add_child(setup)
	player.hide()
	hud.show_menu("main")
	player.health.damaged.connect(func(amount: float): recent_damage += amount)
	bind_key("map", KEY_M)
	dungeon_visual = preload("res://scripts/presentation/survival_world_visual.gd").new()
	dungeon_visual.world = self
	dungeon_visual.z_index = -1
	add_child(dungeon_visual)
	fx_library = preload("res://scripts/presentation/pixel_fx_player.gd").new()
	fx_library.z_index = 12
	add_child(fx_library)
	if "--quick-test" in OS.get_cmdline_user_args():
		cycle_speed = 30.0
		setup.open_loadout()

func create_hud() -> CanvasLayer:
	return preload("res://scripts/ui/survival_hud.gd").new()

func start_run() -> void:
	player.show()
	if setup != null:
		setup.stage = setup.Stage.PLAYING
	super.start_run()
	notify("收集三个部件，开启地牢并逃离。M 查看地图，1/2/3 施放技能。", 7.0)

func prepare_map(seed_value: int) -> void:
	# Called only before play. Replacing this one data object updates geometry,
	# navigation, geography drawing and the map without rebuilding gameplay rules.
	if started:
		return
	layout = ESWorldLayout.new(seed_value)
	layout.set_castle(tower_position)
	rng.seed = seed_value
	domains = INITIAL_DOMAINS.duplicate()
	for element in domains:
		domains[element] = _domain_location(element)
	_reset_facilities(false)
	fleet.populate(layout)
	waypoint = Vector2.INF

func _physics_process(delta: float) -> void:
	if not started or run_over:
		return
	if in_dungeon:
		_update_dungeon(delta)
		return
	var previous_cycle := cycle_index
	super._physics_process(delta)
	if run_over:
		return
	if cycle_index != previous_cycle:
		waypoint = Vector2.INF
	objectives.update(delta, Input.is_action_pressed("interact"))
	pressure_clock += delta
	if pressure_clock >= 8.0:
		pressure_clock = 0.0
		# Change cadence, not basic enemy health. Recent injury buys breathing room.
		pressure = clampf(pressure + (0.15 if recent_damage < 8.0 else -0.4), 0.0, 1.0)
		if recent_damage >= 8.0:
			spawn_clock = maxf(spawn_clock, 3.0)
		elif pressure > 0.6 and cycle_duration - cycle_left > 35.0 and enemies.size() < 85:
			spawn_enemy()
		recent_damage = 0.0
	player.speed_multiplier *= 1.0 + objectives.count() * 0.05
	heal_clock += delta
	if heal_clock >= 25.0 and player.health.current < player.health.maximum * 0.6:
		heal_clock = 0.0
		# Vending remains the primary heal; field scavenging can occasionally help.
		if kills > 0:
			notify("状态不佳：可到售卖柜购买修复，或利用高塔拉开距离。", 3.0)

func apply_component_growth() -> void:
	player.health.maximum += 20.0
	player.health.heal(20.0)
	player.dash_recharge = 1.35 * pow(0.95, objectives.count())

func weapon_damage(slot: int, base: float) -> float:
	return super.weapon_damage(slot, base) * (1.0 + objectives.count() * 0.15)

func weapon_elements(slot: int) -> Dictionary:
	var result: Dictionary = super.weapon_elements(slot)
	result["_power"] = float(result.get("_power", 1.0)) * (1.0 + objectives.count() * 0.15)
	return result

func attack_interval_multiplier() -> float:
	return super.attack_interval_multiplier() * pow(0.95, objectives.count())

func skill_cooldown_multiplier() -> float:
	return pow(0.95, objectives.count())

func interaction_hint() -> String:
	if in_dungeon:
		if room_cleared and player.position.distance_to(dungeon_door()) < 90:
			return "E  逃离这个世界" if dungeon_room == 2 else "E  前往下一间地牢"
		return "清理出口守卫" if dungeon_room == 2 else "清理房间中的敌人，可绕中央障碍拉开距离"
	if player.position.distance_to(ENTRANCE) < 95:
		return "E  开启地牢入口" if objectives.count() == 3 else "地牢入口 · 需要三个关键部件（%d/3）" % objectives.count()
	if not objectives.found["prism"] and player.position.distance_to(objectives.prism_position()) < 70:
		return "按住 E 提取稳相棱镜 · 保持位置，受伤会中断"
	return super.interaction_hint()

func interact() -> void:
	if in_dungeon:
		if room_cleared and player.position.distance_to(dungeon_door()) < 90:
			if dungeon_room < 2:
				_open_room(dungeon_room + 1)
			else:
				complete_run()
		return
	if player.position.distance_to(ENTRANCE) < 95:
		if objectives.count() == 3:
			hud.show_menu("enter_dungeon")
		else:
			notify("入口保持固定。集齐三个不同部件后返回这里。")
		return
	if objectives.begin_extraction():
		return
	super.interact()

func _on_enemy_defeated(enemy: ESEnemy) -> void:
	if in_dungeon:
		_drop_enemy_weapon(enemy)
		drop_element_materials(enemy.position)
		kills += 1
		add_hit(enemy.position, Color("ffdb9b"), 24.0)
		enemies.erase(enemy)
		if marked == enemy:
			marked = null
		if enemies.is_empty():
			room_cleared = true
			player.health.heal(20.0)
			notify("房间已清理 · 前往发光的出口 [E]", 5.0)
		return
	if enemy.get("boss_kind") != null:
		objectives.boss_defeated(enemy)
	super._on_enemy_defeated(enemy)
	if kills % 18 == 0:
		player.health.heal(3.0)

func enter_dungeon() -> bool:
	if in_dungeon or run_over or objectives.count() != 3 or player.position.distance_to(ENTRANCE) > 95:
		return false
	objectives.extracting = false
	if riding:
		toggle_mount()
	in_dungeon = true
	for enemy in enemies:
		# This is a one-way transition; keeping overworld actors serves no gameplay.
		enemy.queue_free()
	enemies.clear()
	marked = null
	waypoint = Vector2.INF
	skills.devices.clear()
	arsenal.shots.clear()
	arsenal.effects.clear()
	player.on_tower = false
	player.z_index = 5
	_open_room(0)
	hud.hide_menu()
	notify("进入稳定地牢 · 世界迁移暂停，部件属性完整保留。", 6.0)
	return true

func dungeon_rect() -> Rect2:
	return Rect2(DUNGEON_BASE + Vector2(dungeon_room * 1200.0, 0), DungeonLayout.SIZE)

func dungeon_door() -> Vector2:
	return dungeon_rect().position + Vector2(550, 110)

func _open_room(index: int) -> void:
	for enemy in enemies:
		enemy.queue_free()
	enemies.clear()
	marked = null
	pickups.clear()
	dungeon_room = index
	dungeon_layout = DungeonLayout.new(dungeon_rect())
	waypoint = Vector2.INF
	arsenal.shots.clear()
	arsenal.effects.clear()
	hits.clear()
	skills.devices.clear()
	if is_instance_valid(fx_library):
		fx_library.clear_effects()
	room_cleared = false
	var room := dungeon_rect()
	player.position = room.position + Vector2(550, 700)
	player.contact_grace = 1.5
	camera.limit_left = int(room.position.x)
	camera.limit_top = int(room.position.y)
	camera.limit_right = int(room.end.x)
	camera.limit_bottom = int(room.end.y)
	camera.reset_smoothing()
	camera.force_update_scroll()
	if is_instance_valid(dungeon_visual):
		dungeon_visual.queue_redraw()
	for i in (12 + index * 6):
		var enemy := spawn_enemy(room.position + Vector2(rng.randf_range(130, 970), rng.randf_range(200, 650)))
		enemy.speed = rng.randf_range(80, 120)
	if index == 2:
		var boss: ESEnemy = BossScript.new()
		boss.world = self
		boss.target = player
		boss.boss_kind = "hunter"
		boss.home = dungeon_layout.resolve(room.get_center())
		boss.position = room.position + Vector2(550, 300)
		boss.set_meta("display_name", "出口守卫")
		boss.z_index = 4
		add_child(boss)
		boss.maximum_health = 3500.0
		boss.health = 3500.0
		boss.speed = 100.0
		boss.attack_radius = 140.0
		boss.defeated.connect(_on_enemy_defeated)
		enemies.append(boss)
	if has_method("play_fx"):
		play_fx("arcane/blink-in", player.position, 1.4)
	notify(DungeonLayout.NAMES[index]+(" · 击败守卫后抵达出口 [E]" if index == 2 else " · 绕障碍拉扯敌人，清场后前往北侧门 [E]"),5.0)

func _update_dungeon(delta: float) -> void:
	run_time += delta
	dungeon_time += delta
	message_left = maxf(0, message_left - delta)
	player.update_environment(delta, false)
	player.speed_multiplier = skills.movement_multiplier() * (1.0 + objectives.count() * 0.05)
	contact_fire_left = 0.0
	_collect_pickups()
	for hit in hits:
		hit["life"] -= delta
	hits = hits.filter(func(hit: Dictionary): return hit["life"] > 0.0)
	if skills.pending_rewards > 0 and not get_tree().paused:
		hud.show_menu("reward")

func constrain_player(point: Vector2, upstairs: bool) -> Vector2:
	if in_dungeon:
		return dungeon_layout.resolve(point)
	return super.constrain_player(point, upstairs)

func move_actor(origin: Vector2, motion: Vector2) -> Vector2:
	return dungeon_layout.move_actor(origin,motion) if in_dungeon else super.move_actor(origin,motion)

func line_of_sight(origin: Vector2, target: Vector2) -> bool:
	return dungeon_layout.line_clear(origin,target) if in_dungeon else super.line_of_sight(origin,target)

func enemy_direction(enemy: ESEnemy, destination: Vector2, delta: float) -> Vector2:
	return dungeon_layout.direction_for(enemy,destination,delta) if in_dungeon else super.enemy_direction(enemy,destination,delta)

func spawn_enemy(at: Vector2 = Vector2.INF) -> ESEnemy:
	if in_dungeon:
		at = dungeon_layout.resolve(player.position+Vector2(150,0) if at == Vector2.INF else at)
	return super.spawn_enemy(at)

func add_pickup(kind: String, point: Vector2, amount: int) -> void:
	super.add_pickup(kind,dungeon_layout.resolve(point) if in_dungeon else point,amount)

func toggle_mount() -> bool:
	if in_dungeon:
		return false
	return super.toggle_mount()

func complete_run() -> bool:
	if not in_dungeon or dungeon_room != 2 or not room_cleared or run_over or player.position.distance_to(dungeon_door()) > 90:
		return false
	won = true
	run_over = true
	hud.show_menu("victory")
	return true

func play_fx(id: String, point: Vector2, scale_value := 1.0) -> void:
	if is_instance_valid(fx_library):
		fx_library.play_effect.call_deferred(id, point, scale_value)

func add_hit(point: Vector2, color: Color, radius: float = 10.0) -> void:
	super.add_hit(point, color, radius)
	if radius >= 20:
		play_fx("spawn/poof", point, 0.65)
	elif rng.randf() < 0.35:
		play_fx("impacts/hit-flash", point, 0.6)
