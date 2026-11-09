extends "res://scripts/run/world_simulation.gd"

const ProgressionScript := preload("res://scripts/growth/run_progression.gd")
const SkillsScript := preload("res://scripts/growth/active_skills.gd")
const BossScript := preload("res://scripts/actors/boss.gd")
const FIRE_SUIT_PICKUP := Vector2(990, 1250)
var progression: ESRunProgression
var skills: ESActiveSkills
var facilities: Array[Dictionary] = []
var pickups: Array[Dictionary] = []
const INITIAL_DOMAINS := {"poison": Vector2(3000, 1700), "fire": Vector2(5700, 4100)}
var domains: Dictionary = INITIAL_DOMAINS.duplicate()
var revealed_chests: Array[Dictionary] = []
var castle_elite: ESEnemy
const LootRules = preload("res://scripts/growth/loot_rules.gd")
var fleet = preload("res://scripts/world/vehicle_fleet.gd").new()
var bike_position: Vector2:
	get:
		if not fleet.active.is_empty():
			return fleet.active["position"]
		return fleet.parked[0]["position"] if not fleet.parked.is_empty() else Vector2(1130, 1140)
	set(value):
		if not fleet.active.is_empty():
			fleet.active["position"] = value
		elif not fleet.parked.is_empty():
			fleet.parked[0]["position"] = value
var riding := false
var scheduled_boss := false
var fire_tick := 0.0
var contact_fire_left := 0.0

func _ready() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_title("Elemental Survival · Stage 2")
	progression = ProgressionScript.new()
	add_child(progression)
	skills = SkillsScript.new()
	skills.world = self
	add_child(skills)
	_reset_facilities(true)
	super._ready()
	skills.bind_player()
	_spawn_castle_elite()
	fleet.populate(layout)
	var devices := preload("res://scripts/presentation/device_visual.gd").new()
	devices.name = "DeviceVisual"
	devices.world = self
	devices.z_index = 8
	add_child(devices)
	progression.changed.connect(_sync_weapons)
	_sync_weapons()
	var scenery := preload("res://scripts/presentation/growth_world_visual.gd").new()
	scenery.world = self
	scenery.z_index = -1
	add_child(scenery)
	for entry in {"mount": KEY_R, "skill_1": KEY_1, "skill_2": KEY_2, "skill_3": KEY_3}:
		bind_key(entry, {"mount": KEY_R, "skill_1": KEY_1, "skill_2": KEY_2, "skill_3": KEY_3}[entry])

func create_hud() -> CanvasLayer:
	return preload("res://scripts/ui/growth_hud.gd").new()

func start_run() -> void:
	super.start_run()
	notify("第二阶段 · E 搜刮/设施 · R 载具 · 1/2/3 技能 · Tab 装备与附魔", 7.0)

func _sync_weapons() -> void:
	for i in 3:
		arsenal.specs[i] = progression.equipped[i].spec if progression.equipped[i] != null else null

func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)
	if not started or run_over:
		return
	if event.is_action_pressed("mount"):
		toggle_mount()
	for i in 3:
		if event.is_action_pressed("skill_%d" % (i + 1)):
			skills.cast(i)

func _physics_process(delta: float) -> void:
	if not started or run_over:
		return
	var old_cycle := cycle_index
	super._physics_process(delta)
	if run_over:
		return
	if cycle_index != old_cycle:
		_reset_facilities(false)
		scheduled_boss = false
		for element in domains:
			domains[element] = _domain_location(element)
		for enemy in enemies:
			if enemy.get("boss_kind") == "guardian":
				enemy.migrate(domains[enemy.element] if enemy.element != "" else tower_position + Vector2(300, 0))
	if not scheduled_boss and cycle_duration - cycle_left >= 90.0:
		scheduled_boss = true
		var element := "" if rng.randf() < 0.3 else ("poison" if rng.randf() < 0.5 else "fire")
		spawn_boss("hunter" if rng.randf() < 0.5 else "guardian", element)
	if riding:
		if player.velocity.length() > 5.0:
			progression.battery = maxf(0.0, progression.battery - 2.5 * delta)
		if progression.battery <= 0.0:
			toggle_mount()
	player.speed_multiplier = (1.9 if riding else 1.0) * skills.movement_multiplier()
	contact_fire_left = maxf(0.0, contact_fire_left - delta)
	if field_contains("fire", player.position):
		contact_fire_left = 8.0
		fire_tick += delta
		while fire_tick >= 0.5:
			fire_tick -= 0.5
			if not player.fire_protection:
				player.health.hurt(2.0)
	else:
		fire_tick = 0.0
	_collect_pickups()
	for facility in facilities:
		if player.position.distance_to(facility["position"]) < 430.0:
			facility["seen"] = true
	if skills.pending_rewards > 0 and not get_tree().paused:
		hud.show_menu("reward")

func field_center(element: String) -> Vector2:
	return domains.get(element, TOXIC_CENTER)

func field_radius(_element: String) -> float:
	return 1000.0

func player_visible_to_enemies() -> bool:
	return skills.invisible_left <= 0.0

func attack_interval_multiplier() -> float:
	return 1.0 / skills.attack_speed_multiplier()

func deal_player_damage(enemy: ESEnemy, amount: float, impulse: Vector2 = Vector2.ZERO, poisoned := false) -> float:
	var dealt := super.deal_player_damage(enemy, amount, impulse, poisoned)
	skills.on_damage_dealt(dealt)
	return dealt

func update_enemy_environment(enemy: ESEnemy, delta: float) -> void:
	super.update_enemy_environment(enemy, delta)
	if enemy.alive and field_contains("fire", enemy.position):
		enemy.field_fire_clock += delta
		while enemy.field_fire_clock >= 0.5 and enemy.alive:
			enemy.field_fire_clock -= 0.5
			enemy.take_environment_hit(2.0)
	else:
		enemy.field_fire_clock = 0.0

func combat_allowed() -> bool:
	return not riding

func finish_tower_migration() -> void:
	super.finish_tower_migration()
	for facility in facilities:
		if facility.get("castle", false):
			revealed_chests.erase(facility)
			facility["position"] = tower_position + TowerLayout.CHEST
	_spawn_castle_elite()
	for enemy in enemies:
		if enemy.get("boss_kind") == "guardian" and enemy.element == "":
			enemy.migrate(tower_position + Vector2(250, 0))

func is_toxic(point: Vector2) -> bool:
	return field_contains("poison", point)

func weapon_damage(slot: int, base: float) -> float:
	return progression.equipped[slot].damage(base) if slot >= 0 and progression.equipped[slot] != null else base

func weapon_elements(slot: int) -> Dictionary:
	var elements: Dictionary = progression.equipped[slot].elements.duplicate() if slot >= 0 and progression.equipped[slot] != null else {}
	if contact_fire_left > 0.0:
		elements["fire"] = maxi(1, int(elements.get("fire", 0)))
	if slot >= 0 and progression.equipped[slot] != null and progression.equipped[slot].stars == 4:
		elements["_power"] = 2.5
	return elements

func apply_elements(enemy: ESEnemy, elements: Dictionary) -> void:
	var power := float(elements.get("_power", 1.0))
	for element in elements:
		if element == "_power":
			continue
		var level := int(elements[element])
		match element:
			"poison":
				enemy.poison_left = maxf(enemy.poison_left, 3.0 + level)
				enemy.poison_damage = maxf(enemy.poison_damage, 4.0 * level * power)
			"fire":
				enemy.burn_left = maxf(enemy.burn_left, 3.0 + level)
				enemy.burn_damage = maxf(enemy.burn_damage, 5.0 * level * power)
			"water": enemy.slow_left = maxf(enemy.slow_left, 2.0 + level * 0.5)
			"wind": enemy.knockback += player.position.direction_to(enemy.position) * 70.0 * level
			"wood": player.health.heal(0.1 * level)
			"thunder":
				for other in enemies.duplicate():
					if other != enemy and other.alive and other.position.distance_to(enemy.position) < 100.0:
						deal_player_damage(other, 3.0 * level * power)
						break

func enemy_destination(enemy: ESEnemy) -> Vector2:
	if not player_visible_to_enemies():
		return enemy.home if enemy.get("home") != null else enemy.position
	if enemy.has_meta("castle_elite") and not tower_rect().grow(180).has_point(player.position):
		return enemy.home
	return skills.lure_for(enemy)

func _spawn_castle_elite() -> void:
	if is_instance_valid(castle_elite) and castle_elite.alive:
		castle_elite.home = tower_position + TowerLayout.ELITE
		castle_elite.position = castle_elite.home
		castle_elite.slam_left = 0.0
		return
	castle_elite = preload("res://scripts/actors/castle_elite.gd").new()
	castle_elite.world = self
	castle_elite.target = player
	castle_elite.home = tower_position + TowerLayout.ELITE
	castle_elite.position = castle_elite.home
	castle_elite.z_index = 4
	add_child(castle_elite)
	enemies.append(castle_elite)
	castle_elite.defeated.connect(_on_enemy_defeated)

func _domain_location(element: String) -> Vector2:
	for attempt in 100:
		var point := Vector2(rng.randf_range(1250, MAP_SIZE.x - 1250), rng.randf_range(1250, MAP_SIZE.y - 1250))
		if point.distance_to(player.position) < 1250 or point.distance_to(tower_position) < 1750:
			continue
		var valid := true
		for other in domains:
			if other != element and point.distance_to(domains[other]) < 2450:
				valid = false
		if valid and layout.clear_point(point, 90):
			return point
	return domains[element]

func reveal_nearest_chests(count: int) -> int:
	if get("in_dungeon") == true:
		notify("寻龙尺：地牢内没有可探测的宝箱。")
		return 0
	var candidates: Array[Dictionary] = []
	for facility in facilities:
		if facility["kind"] == "chest" and not facility["used"]:
			candidates.append(facility)
	candidates.sort_custom(func(a: Dictionary, b: Dictionary): return player.position.distance_squared_to(a["position"]) < player.position.distance_squared_to(b["position"]))
	revealed_chests.clear()
	for i in mini(count, candidates.size()):
		revealed_chests.append(candidates[i])
	if revealed_chests.is_empty():
		notify("寻龙尺：本轮已无未开启的宝箱。")
	else:
		notify("寻龙尺：已标记最近的 %d 个宝箱，按 M 查看。%s" % [revealed_chests.size(), "熟能生巧：现在每次可探测 3 个！" if count == 3 and skills.uses["seeker"] == 4 else ""], 6)
	return revealed_chests.size()

func surface_map_markers() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	result.append({"kind": "entrance", "position": Vector2(370, 370), "name": "固定地牢入口"})
	result.append({"kind": "tower", "position": tower_position, "name": "特殊高塔 · 城堡"})
	for element in domains:
		result.append({"kind": "domain", "position": domains[element], "name": "毒领域" if element == "poison" else "火领域"})
	for facility in facilities:
		if facility["kind"] == "forge":
			result.append({"kind": "forge", "position": facility["position"], "name": "锻造房"})
	for enemy in enemies:
		if enemy.alive and enemy.get("boss_kind") == "hunter":
			result.append({"kind": "hunter", "position": enemy.position, "name": "★ 部件追猎者" if enemy.has_meta("key_part") else "追猎者"})
	for chest in revealed_chests:
		if not chest["used"] and facilities.has(chest):
			result.append({"kind": "revealed_chest", "position": chest["position"], "name": "寻龙尺 · 宝箱"})
	return result

func _free_location() -> Vector2:
	for attempt in 40:
		var point := Vector2(rng.randf_range(220, MAP_SIZE.x - 220), rng.randf_range(250, MAP_SIZE.y - 220))
		if point.distance_to(player.position if player != null else Vector2(1110, 1000)) < 250:
			continue
		if tower_rect().grow(100).has_point(point) or not layout.clear_point(point, 75):
			continue
		var reserved := false
		for center in TOWER_POINTS:
			if Rect2(center - Vector2(580, 540), Vector2(1160, 1080)).has_point(point):
				reserved = true
		if reserved:
			continue
		var overlap := false
		for facility in facilities:
			if point.distance_to(facility["position"]) < 180:
				overlap = true
		if not overlap:
			return point
	return Vector2(400, 400)

func _reset_facilities(initial: bool) -> void:
	facilities = preload("res://scripts/world/facility_placement.gd").build(self)
	revealed_chests.clear()
	progression.reset_stock()
	if not initial:
		notify("补给设施搬迁并补满。", 5.0)

func nearest_facility() -> Dictionary:
	for facility in facilities:
		if not facility["used"] and player.position.distance_to(facility["position"]) < 80:
			return facility
	return {}

func interaction_hint() -> String:
	if not player.fire_armor_owned and player.position.distance_to(FIRE_SUIT_PICKUP) < 80:
		return "E  拾取消防员套装 · 免疫火领域伤害"
	var facility := nearest_facility()
	if not facility.is_empty():
		return "E  " + {"forge": "进入锻造房", "shop": "打开万能售卖柜", "supply": "搜刮补给站", "chest": "打开宝箱"}[facility["kind"]]
	return super.interaction_hint()

func interact() -> void:
	if riding:
		toggle_mount()
	if not player.fire_armor_owned and player.position.distance_to(FIRE_SUIT_PICKUP) < 80:
		player.fire_armor_owned = true
		player.equip_suit("fire")
		notify("已穿戴消防员套装 · 免疫火领域伤害 · Tab 可切换生化套装")
		return
	var facility := nearest_facility()
	if facility.is_empty():
		if riding:
			toggle_mount()
		super.interact()
		return
	match facility["kind"]:
		"forge": hud.show_menu("forge")
		"shop": hud.show_menu("shop")
		"supply", "chest":
			facility["used"] = true
			progression.coins += 20
			progression.parts += 6
			var loot: Array[String] = ["金币 +20", "零件 +6"]
			if LootRules.weapon_drops(facility["kind"], rng.randf()):
				loot.append(progression.random_weapon().title())
			if rng.randf() < 0.25:
				progression.batteries += 1
				loot.append("电池 +1")
			if facility["kind"] == "chest":
				var suit: String = LootRules.armor_drop(rng.randf(), rng.randf())
				if suit == "poison":
					if player.armor_owned and not player.fire_armor_owned:
						suit = "fire"
				elif suit == "fire" and player.fire_armor_owned and not player.armor_owned:
					suit = "poison"
				if suit == "poison":
					player.armor_owned = true
					loot.append("生化套装（Tab 穿戴）")
				elif suit == "fire":
					player.fire_armor_owned = true
					loot.append("消防员套装（Tab 穿戴）")
				skills.offer_reward()
				hud.show_menu("reward")
			notify("搜刮获得：" + "、".join(loot), 7.0)

func toggle_mount() -> bool:
	if riding:
		riding = false
		fleet.active["position"] = player.position
		fleet.active["battery"] = progression.battery
		fleet.parked.push_front(fleet.active)
		fleet.active = {}
		return true
	var bike: Dictionary = fleet.nearest(player.position)
	if bike.is_empty() or float(bike["battery"]) <= 0:
		notify("请靠近有电的电动车。每处聚落均有停车点。")
		return false
	fleet.parked.erase(bike)
	fleet.active = bike
	progression.battery = bike["battery"]
	riding = true
	arsenal.shots.clear()
	arsenal.effects.clear()
	skills.devices.clear()
	notify("骑行模式 · R 下车战斗；寻龙尺仍可使用。")
	return true

func vehicle_charge() -> float:
	if riding:
		return progression.battery
	var bike: Dictionary = fleet.nearest(player.position)
	return float(bike["battery"]) if not bike.is_empty() else -1.0

func recharge_vehicle() -> bool:
	var charge := vehicle_charge()
	if charge < 0 or charge >= 100 or progression.batteries <= 0:
		return false
	progression.battery = charge
	if not progression.use_battery():
		return false
	if not riding:
		fleet.nearest(player.position)["battery"] = progression.battery
	return true

func spawn_boss(kind: String, element: String = "") -> ESEnemy:
	var boss: ESEnemy = BossScript.new()
	boss.world = self
	boss.target = player
	boss.boss_kind = kind
	boss.element = element if kind == "guardian" else ""
	boss.home = (domains[element] if domains.has(element) else tower_position + Vector2(250, 0)) if kind == "guardian" else _free_location()
	if kind == "hunter":
		boss.home = layout.resolve((player.position + Vector2.from_angle(rng.randf() * TAU) * 900).clamp(Vector2(50, 50), MAP_SIZE - Vector2(50, 50)))
	boss.position = layout.resolve(boss.home)
	boss.z_index = 4
	add_child(boss)
	enemies.append(boss)
	boss.defeated.connect(_on_enemy_defeated)
	notify("追猎者出现：会持续追击你。" if kind == "hunter" else "领域镇守者出现：可以选择挑战，获得对应附魔能力。", 6.0)
	return boss

func _on_enemy_defeated(enemy: ESEnemy) -> void:
	_drop_enemy_weapon(enemy)
	var boss_kind = enemy.get("boss_kind")
	var point := enemy.position
	if boss_kind != null:
		progression.coins += 70 if boss_kind == "hunter" else 100
		progression.parts += 25 if boss_kind == "hunter" else 40
		if enemy.element != "":
			if enemy.element not in progression.unlocked_elements:
				progression.unlocked_elements.append(enemy.element)
			progression.materials[enemy.element] += 12
		elif boss_kind == "guardian":
			progression.miracles += 1
		skills.offer_reward()
	elif enemy.has_meta("castle_elite"):
		add_pickup("coins", point, 35)
		add_pickup("parts", point, 12)
	else:
		drop_element_materials(point)
		add_pickup("coins", point, 2)
		if kills % 4 == 0:
			add_pickup("parts", point + Vector2(8, 8), 1)
	super._on_enemy_defeated(enemy)

func add_pickup(kind: String, point: Vector2, amount: int) -> void:
	var closest: Dictionary = {}
	var distance := INF
	var same_kind_count := 0
	for pickup in pickups:
		if pickup["kind"] != kind or pickup["used"]:
			continue
		same_kind_count += 1
		var squared: float = point.distance_squared_to(pickup["position"])
		if squared < distance:
			distance = squared
			closest = pickup
	if not closest.is_empty() and (distance < 48.0 * 48.0 or same_kind_count >= 128):
		closest["amount"] += amount
	else:
		pickups.append({"kind": kind, "position": point, "amount": amount, "used": false})

func _collect_pickups() -> void:
	for drop in pickups:
		if player.position.distance_to(drop["position"]) < 65.0:
			if drop["kind"] == "coins":
				progression.coins += drop["amount"]
			elif drop["kind"] == "parts":
				progression.parts += drop["amount"]
			elif progression.materials.has(drop["kind"]):
				progression.materials[drop["kind"]] += drop["amount"]
			drop["used"] = true
	pickups = pickups.filter(func(p: Dictionary): return not p["used"])

func drop_element_materials(point: Vector2) -> void:
	for element in domains:
		if LootRules.material_drops(material_region_contains(element, point) and get("in_dungeon") != true, rng.randf()):
			add_pickup(element, point, 1)

func _drop_enemy_weapon(enemy: ESEnemy) -> void:
	var kind := "boss" if enemy.get("boss_kind") != null else "elite" if enemy.has_meta("castle_elite") else "mob"
	if LootRules.weapon_drops(kind,rng.randf()):
		progression.random_weapon(LootRules.weapon_stars(kind,rng.randf()))
