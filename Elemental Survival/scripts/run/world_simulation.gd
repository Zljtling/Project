extends Node2D
const TowerLayout = preload("res://scripts/regions/tower/tower_layout.gd")

const PlayerScript := preload("res://scripts/actors/player.gd")
const EnemyScript := preload("res://scripts/actors/enemy.gd")
const ArsenalScript := preload("res://scripts/combat/arsenal.gd")
const HudScript := preload("res://scripts/ui/prototype_hud.gd")
const MAP_SIZE := Vector2(16000, 12000)
const TOXIC_CENTER := Vector2(3000, 1700)
const TOXIC_RADIUS := 1000.0
const ARMOR_PICKUP := Vector2(990, 1150)
const TOWER_POINTS := [Vector2(2400, 3200), Vector2(6200, 1300), Vector2(5800, 4900)]
@export var cycle_duration := 360.0
@export var warning_duration := 60.0
@export var tower_sink_duration := 8.0
var cycle_left := 360.0
var cycle_index := 1
var cycle_speed := 1.0
var tower_position: Vector2 = TOWER_POINTS[0]
var layout := ESWorldLayout.new()
var sinking_left := 0.0
var tower_index := 0
var enemies: Array[ESEnemy] = []
var hits: Array[Dictionary] = []
var player: ESPlayer
var arsenal: Node2D
var camera: Camera2D
var hud: CanvasLayer
var font: SystemFont
var run_time := 0.0
var kills := 0
var spawn_clock := 0.0
var marked: ESEnemy
var started := false
var run_over := false
var message := ""
var message_left := 0.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	layout.set_castle(tower_position)
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "Noto Sans CJK SC", "sans-serif"])
	_setup_input()
	cycle_left = cycle_duration
	player = PlayerScript.new()
	player.world = self
	player.position = Vector2(1110, 1000)
	player.z_index = 5
	add_child(player)
	player.health.died.connect(_on_player_died)
	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(MAP_SIZE.x)
	camera.limit_bottom = int(MAP_SIZE.y)
	player.add_child(camera)
	arsenal = ArsenalScript.new()
	arsenal.player = player
	arsenal.world = self
	arsenal.z_index = 10
	add_child(arsenal)
	hud = create_hud()
	hud.world = self
	add_child(hud)
	hud.show_menu("intro")
	var scenery := Node2D.new()
	scenery.set_script(preload("res://scripts/presentation/world_visual.gd"))
	scenery.world = self
	scenery.z_index = -1
	add_child(scenery)
	var buildings := preload("res://scripts/presentation/buildings_visual.gd").new()
	buildings.world = self
	buildings.z_index = 6
	add_child(buildings)
	queue_redraw()

func create_hud() -> CanvasLayer:
	return HudScript.new()

func field_center(_element: String) -> Vector2:
	return TOXIC_CENTER

func field_radius(_element: String) -> float:
	return TOXIC_RADIUS

func poison_bridge_rect() -> Rect2:
	var radius := field_radius("poison")
	return Rect2(field_center("poison") - Vector2(radius + 128, 48), Vector2((radius + 128) * 2, 96))

func field_contains(element: String, point: Vector2) -> bool:
	if point.distance_to(field_center(element)) > field_radius(element):
		return false
	return element != "poison" or not poison_bridge_rect().has_point(point)

func material_region_contains(element: String, point: Vector2) -> bool:
	return field_contains(element,point)

func combat_allowed() -> bool:
	return true

func player_visible_to_enemies() -> bool:
	return true

func deal_player_damage(enemy: ESEnemy, amount: float, impulse: Vector2 = Vector2.ZERO, poisoned := false) -> float:
	var before := maxf(0.0, enemy.health)
	enemy.take_hit(amount, impulse, poisoned)
	return minf(before, maxf(0.0, before - enemy.health))

func update_enemy_environment(enemy: ESEnemy, delta: float) -> void:
	if is_toxic(enemy.position):
		enemy.field_poison_clock += delta
		while enemy.field_poison_clock >= 1.0 and enemy.alive:
			enemy.field_poison_clock -= 1.0
			enemy.take_environment_hit(4.0)
	else:
		enemy.field_poison_clock = 0.0

func line_of_sight(origin: Vector2, target: Vector2) -> bool:
	return not Rect2(Vector2.ZERO, MAP_SIZE).has_point(origin) or layout.line_clear(origin, target)

func move_actor(origin: Vector2, motion: Vector2) -> Vector2:
	if not Rect2(Vector2.ZERO, MAP_SIZE).has_point(origin):
		return constrain_player(origin + motion, false)
	return layout.move_actor(origin, motion)

func enemy_direction(enemy: ESEnemy, destination: Vector2, delta: float) -> Vector2:
	if not Rect2(Vector2.ZERO, MAP_SIZE).has_point(enemy.position):
		return enemy.position.direction_to(destination)
	return layout.direction_for(enemy, destination, delta)

func weapon_damage(_slot: int, base: float) -> float:
	return base

func weapon_elements(_slot: int) -> Dictionary:
	return {}

func apply_elements(_enemy: ESEnemy, _elements: Dictionary) -> void:
	pass

func enemy_destination(_enemy: ESEnemy) -> Vector2:
	return player.position

func attack_interval_multiplier() -> float:
	return 1.0

func skill_cooldown_multiplier() -> float:
	return 1.0

func play_fx(_id: String, _point: Vector2, _scale_value := 1.0) -> void:
	pass

func _setup_input() -> void:
	var keys := {"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN], "move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT], "dash": [KEY_SPACE], "interact": [KEY_E], "inventory": [KEY_TAB], "pause_run": [KEY_ESCAPE], "help": [KEY_F1], "fast_cycle": [KEY_F6]}
	for action in keys:
		for key in keys[action]:
			bind_key(action, key)

func bind_key(action: String, key: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	# Physical bindings preserve WASD across layouts. Logical bindings also support
	# remote keyboards, accessibility tools and key events without a scan code.
	var physical := InputEventKey.new()
	physical.physical_keycode = key
	var logical := InputEventKey.new()
	logical.keycode = key
	for event in [physical, logical]:
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)

func start_run() -> void:
	started = true
	get_tree().paused = false
	hud.hide_menu()
	notify("先拾取左下方的生化套装，再前往右侧毒领域。")

func _unhandled_input(event: InputEvent) -> void:
	if not started or run_over:
		return
	if event.is_action_pressed("interact"):
		interact()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		mark_at(get_global_mouse_position())

func _physics_process(delta: float) -> void:
	if not started or run_over:
		return
	run_time += delta
	message_left = maxf(0.0, message_left - delta)
	player.on_tower = tower_rect().has_point(player.position)
	player.update_environment(delta, is_toxic(player.position))
	if run_over:
		return
	advance_world(delta)
	spawn_clock -= delta
	if spawn_clock <= 0.0:
		spawn_clock = maxf(0.28, 1.0 - run_time / 260.0)
		if enemies.size() < 90:
			spawn_enemy()
	if is_instance_valid(marked) and not marked.alive:
		marked = null
	for hit in hits:
		hit["life"] -= delta
	hits = hits.filter(func(hit: Dictionary): return hit["life"] > 0.0)
	queue_redraw()

func advance_world(delta: float) -> void:
	var previous := cycle_left
	cycle_left -= delta * cycle_speed
	if previous > warning_duration and cycle_left <= warning_duration:
		notify("世界即将变化：高塔会下陷，请提前选择撤离路线。", 6.0)
	if cycle_left <= 0.0:
		cycle_left += cycle_duration
		cycle_index += 1
		sinking_left = tower_sink_duration
		notify("高塔开始下陷！旧塔将在 8 秒后消失。", 6.0)
	if sinking_left > 0.0:
		sinking_left = maxf(0.0, sinking_left - delta)
		if sinking_left <= 0.0:
			finish_tower_migration()

func finish_tower_migration() -> void:
	if player.on_tower:
		player.on_tower = false
		player.z_index = 5
		player.contact_grace = 1.5
	tower_index = (tower_index + 1) % tower_locations().size()
	tower_position = tower_locations()[tower_index]
	layout.set_castle(tower_position)
	player.position = layout.resolve(player.position)
	for enemy in enemies:
		enemy.navigation_left = 0.0
		enemy.position = layout.resolve(enemy.position)
	sinking_left = 0.0
	notify("旧高塔消失，新高塔已出现。敌人依然留在世界中。", 5.0)

func tower_locations() -> Array:
	return TOWER_POINTS

func movement_direction(input: Vector2) -> Vector2:
	return input

func is_toxic(point: Vector2) -> bool:
	return field_contains("poison", point)

func tower_rect() -> Rect2:
	return Rect2(tower_position + TowerLayout.BOUNDS.position, TowerLayout.BOUNDS.size)

func constrain_player(point: Vector2, _upstairs: bool) -> Vector2:
	return layout.resolve(point)

func interaction_hint() -> String:
	if not player.armor_owned and player.position.distance_to(ARMOR_PICKUP) < 80.0:
		return "E  拾取并穿上生化套装"
	if player.on_tower:
		return "高塔城堡 · 可直接通行 · 留意精英与世界变化"
	return ""

func interact() -> void:
	if not player.armor_owned and player.position.distance_to(ARMOR_PICKUP) < 80.0:
		player.armor_owned = true
		player.equip_suit("poison")
		notify("已穿戴生化套装 · Tab 可脱下，比较毒区的风险与收益。")
	queue_redraw()

func mark_at(point: Vector2) -> void:
	var nearest: ESEnemy
	var distance := 65.0 * 65.0
	for enemy in enemies:
		if not enemy.alive:
			continue
		var squared := enemy.position.distance_squared_to(point)
		if squared < distance:
			distance = squared
			nearest = enemy
	marked = null if nearest == marked else nearest

func find_target(origin: Vector2, reach: float) -> ESEnemy:
	if is_instance_valid(marked) and marked.alive and origin.distance_to(marked.position) <= reach and line_of_sight(origin, marked.position):
		return marked
	var nearest: ESEnemy
	var distance := reach * reach
	for enemy in enemies:
		if enemy.alive:
			var squared := origin.distance_squared_to(enemy.position)
			if squared < distance and line_of_sight(origin, enemy.position):
				distance = squared
				nearest = enemy
	return nearest

func spawn_enemy(at: Vector2 = Vector2.INF) -> ESEnemy:
	var enemy: ESEnemy = EnemyScript.new()
	var roll := rng.randf()
	if has_method("enemy_patterns"):
		enemy.archetype = "charger" if roll < 0.18 else "spitter" if roll < 0.34 else "ghoul"
	enemy.world = self
	enemy.target = player
	enemy.speed = rng.randf_range(72.0, 112.0)
	if at == Vector2.INF:
		var angle := rng.randf() * TAU
		enemy.position = (player.position + Vector2.from_angle(angle) * rng.randf_range(680.0, 850.0)).clamp(Vector2(24, 24), MAP_SIZE - Vector2(24, 24))
	else:
		enemy.position = at
	if Rect2(Vector2.ZERO, MAP_SIZE).has_point(enemy.position):
		enemy.position = layout.resolve(enemy.position)
	enemy.z_index = 3
	add_child(enemy)
	enemies.append(enemy)
	enemy.defeated.connect(_on_enemy_defeated)
	return enemy

func _on_enemy_defeated(enemy: ESEnemy) -> void:
	kills += 1
	add_hit(enemy.position, Color("ffda96"), 22.0)
	enemies.erase(enemy)
	if marked == enemy:
		marked = null

func add_hit(point: Vector2, color: Color, radius: float = 10.0) -> void:
	hits.append({"position": point, "color": color, "radius": radius, "life": 0.25})

func notify(text: String, seconds: float = 4.0) -> void:
	message = text
	message_left = seconds

func _on_player_died() -> void:
	if run_over:
		return
	run_over = true
	hud.show_menu("death")

