class_name ESActiveSkills
extends Node

const TRAVEL_SKILLS := ["seeker", "haste", "fake_death"]
const DEFINITIONS := {
	"seeker": {"name": "寻龙尺", "category": "道具", "cooldown": 20.0, "mastery": 5, "description": "探测最近1个宝箱；成功使用5次后探测最近3个。"},
	"decoy": {"name": "诱饵", "category": "道具", "cooldown": 9.0, "mastery": 10, "description": "部署诱饵；第10次起扩大吸引范围，消失时爆炸。"},
	"turret": {"name": "袖珍炮台", "category": "道具", "cooldown": 18.0, "mastery": 5, "description": "部署炮台，每0.45秒攻击；第5次起部署双炮台，每0.25秒攻击。"},
	"wave": {"name": "震退波", "category": "伤害", "cooldown": 9.0, "mastery": 10, "description": "伤害并击退周围敌人；第10次起额外眩晕1秒。"},
	"berserk": {"name": "狂暴", "category": "伤害", "cooldown": 60.0, "mastery": 5, "description": "8秒内攻速+100%、吸血15%、移速+20%；第5次起增益数值翻倍。"},
	"execute": {"name": "斩杀", "category": "伤害", "cooldown": 50.0, "mastery": 7, "description": "伤害为周围敌人最大生命的20%；第7次起，一次击杀超过5只小怪刷新冷却。"},
	"haste": {"name": "疾行", "category": "巧劲", "cooldown": 15.0, "mastery": 10, "description": "移速+40%，持续5秒；第10次起移速+100%。"},
	"step": {"name": "闪身", "category": "巧劲", "cooldown": 8.0, "mastery": 12, "description": "朝角色面向闪身，不穿墙；第12次起最多储存2次，依次恢复。"},
	"weaken": {"name": "弱化", "category": "巧劲", "cooldown": 20.0, "mastery": 6, "description": "5秒内免伤40%，附近敌人对你再减伤30%；第6次起两项免伤数值翻倍。"},
	"fake_death": {"name": "假死", "category": "巧劲", "cooldown": 0.0, "mastery": 0, "description": "自动抵消一次致死，恢复50%生命；隐身8秒、移速+100%。每局一次，不可手动释放。"}
}
var world: Node2D
var selected: Array[String] = ["decoy", "wave", "haste"]
var cooldowns: Array[float] = [0.0, 0.0, 0.0]
var bonuses: Dictionary = {}
var uses: Dictionary = {}
var devices: Array[Dictionary] = []
var haste_left := 0.0
var passive_haste := 0.0
var berserk_left := 0.0
var weaken_left := 0.0
var invisible_left := 0.0
var fake_death_used := false
var step_charges := 1
var reward_choices: Array[Dictionary] = []
var refresh_count := 0
var pending_rewards := 0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	for id in DEFINITIONS:
		bonuses[id] = {"cooldown": 0, "power": 0, "utility": 0}
		uses[id] = 0

func bind_player() -> void:
	world.player.health.lethal_guards.append(_prevent_death)
	world.player.health.damage_filters.append(_filter_damage)

func choose(slot: int, id: String) -> void:
	if world.started or not DEFINITIONS.has(id) or slot < 0 or slot >= 3:
		return
	var previous := selected[slot]
	var other := selected.find(id)
	selected[slot] = id
	if other >= 0 and other != slot:
		selected[other] = previous

func mastered(id: String, include_next := false) -> bool:
	var threshold := int(DEFINITIONS[id]["mastery"])
	return threshold > 0 and int(uses[id]) + int(include_next) >= threshold

func cooldown_for(id: String) -> float:
	return float(DEFINITIONS[id]["cooldown"]) / (1.0 + int(bonuses[id]["cooldown"]) * 0.12) * world.skill_cooldown_multiplier()

func step_capacity() -> int:
	return 2 if mastered("step") else 1

func _recover_step(slot: int) -> void:
	if selected[slot] == "step" and cooldowns[slot] <= 0.0 and step_charges < step_capacity():
		step_charges += 1
		if step_charges < step_capacity():
			cooldowns[slot] = cooldown_for("step")

func movement_multiplier() -> float:
	var haste_bonus := (1.0 if mastered("haste") else 0.4) if haste_left > 0 else 0.0
	if passive_haste > 0:
		haste_bonus = maxf(haste_bonus, 0.4)
	return 1.0 + haste_bonus + (0.4 if mastered("berserk") else 0.2) * int(berserk_left > 0) + float(invisible_left > 0)

func attack_speed_multiplier() -> float:
	return (3.0 if mastered("berserk") else 2.0) if berserk_left > 0 else 1.0

func on_damage_dealt(amount: float) -> void:
	if berserk_left > 0 and amount > 0:
		world.player.health.heal(amount * (0.3 if mastered("berserk") else 0.15))

func _filter_damage(amount: float, source: Node) -> float:
	if weaken_left > 0:
		amount *= 0.2 if mastered("weaken") else 0.6
	if is_instance_valid(source) and source.get("weaken_left") != null and source.weaken_left > 0:
		amount *= 1.0 - source.weaken_reduction
	return amount

func _prevent_death(health: ESHealth) -> void:
	if "fake_death" not in selected or fake_death_used or not world.started or world.run_over:
		return
	fake_death_used = true
	uses["fake_death"] = 1
	health.heal(health.maximum * 0.5)
	invisible_left = 8.0 * (1.0 + int(bonuses["fake_death"]["utility"]) * 0.15)
	world.player.contact_grace = 1.0
	world.notify("假死触发 · 恢复50%生命 · 隐身与移速+100%持续8秒 · 本局次数已耗尽", 8)
	world.play_fx("arcane/blink-out", world.player.position, 1.2)

func _physics_process(delta: float) -> void:
	if not world.started or world.run_over:
		return
	for i in 3:
		cooldowns[i] = maxf(0.0, cooldowns[i] - delta)
		_recover_step(i)
	haste_left = maxf(0.0, haste_left - delta)
	passive_haste = maxf(0.0, passive_haste - delta)
	berserk_left = maxf(0.0, berserk_left - delta)
	weaken_left = maxf(0.0, weaken_left - delta)
	invisible_left = maxf(0.0, invisible_left - delta)
	for device in devices:
		device["life"] -= delta
		if device["kind"] == "turret":
			device["clock"] -= delta
			if device["clock"] <= 0:
				device["clock"] = 0.25 if device["mastered"] else 0.45
				var target: ESEnemy = world.find_target(device["position"], 300.0)
				if target != null and world.line_of_sight(device["position"], target.position):
					world.deal_player_damage(target, 14.0 * device["power"])
					world.add_hit(target.position, Color("9cd6e8"))
		if device["life"] <= 0 and device["kind"] == "decoy" and device["mastered"]:
			area_damage(device["position"], 160.0, 55.0 * device["power"], 250.0)
	devices = devices.filter(func(d: Dictionary): return d["life"] > 0)

func cast(slot: int) -> bool:
	if not world.started or world.run_over or world.get_tree().paused or slot < 0 or slot >= 3:
		return false
	var id := selected[slot]
	if id == "fake_death":
		world.notify("假死会在致死时自动触发，每局一次，无需手动施放。")
		return false
	_recover_step(slot)
	if (id == "step" and step_charges <= 0) or (id != "step" and cooldowns[slot] > 0):
		return false
	if not world.combat_allowed() and id not in TRAVEL_SKILLS:
		world.notify("骑行时不能战斗，请按 R 下车。")
		return false
	var player: ESPlayer = world.player
	var origin := player.position
	var cursor: Vector2 = world.get_global_mouse_position()
	var destination: Vector2 = world.move_actor(origin, (cursor - origin).limit_length(260.0))
	var power := 1.0 + int(bonuses[id]["power"]) * 0.2
	var utility := 1.0 + int(bonuses[id]["utility"]) * 0.15
	var was_mastered := mastered(id)
	var upgraded := mastered(id, true)
	var killed_basic := 0
	match id:
		"seeker":
			if world.reveal_nearest_chests(3 if upgraded else 1) == 0:
				return false
		"decoy":
			devices.append({"kind": id, "position": destination, "life": 6.0 * utility, "clock": 0.0, "power": power, "mastered": upgraded})
		"turret":
			devices = devices.filter(func(d: Dictionary): return d["kind"] != "turret")
			for i in (2 if upgraded else 1):
				var point: Vector2 = world.move_actor(destination, Vector2((i * 2 - 1) * 32 if upgraded else 0, 0))
				devices.append({"kind": id, "position": point, "life": 8.0 * utility, "clock": 0.0, "power": power, "mastered": upgraded})
		"wave":
			area_damage(origin, 180.0 * utility, 55.0 * power, 650.0, 1.0 if upgraded else 0.0)
		"berserk":
			var old_speed := attack_speed_multiplier()
			berserk_left = 8.0 * utility
			var new_speed := 3.0 if upgraded else 2.0
			for i in world.arsenal.cooldowns.size():
				world.arsenal.cooldowns[i] *= old_speed / new_speed
		"execute":
			for enemy in world.enemies.duplicate():
				if enemy.alive and enemy.position.distance_to(origin) <= 120.0 * utility and world.line_of_sight(origin, enemy.position):
					world.deal_player_damage(enemy, enemy.maximum_health * 0.2)
					if not enemy.alive and enemy.get("boss_kind") == null and not enemy.has_meta("castle_elite"):
						killed_basic += 1
			world.add_hit(origin, Color("e7b18f"), 120 * utility)
		"haste": haste_left = 5.0 * utility
		"step":
			player.position = world.move_actor(origin, player.facing.normalized() * 190.0 * utility)
			player.contact_grace = 0.5
			step_charges -= 1
			if upgraded and not was_mastered:
				step_charges += 1
		"weaken":
			weaken_left = 5.0 * utility
			for enemy in world.enemies:
				if enemy.alive and enemy.position.distance_to(origin) <= 150.0 * utility and world.line_of_sight(origin, enemy.position):
					enemy.weaken_left = 5.0 * utility
					enemy.weaken_reduction = 0.6 if upgraded else 0.3
	uses[id] += 1
	if id != "step" or cooldowns[slot] <= 0.0:
		cooldowns[slot] = cooldown_for(id)
	if id == "execute" and upgraded and killed_basic > 5:
		cooldowns[slot] = 0.0
		world.notify("熟能生巧：斩杀击杀超过5只小怪，冷却已刷新！", 5)
	elif upgraded and not was_mastered:
		world.notify("熟能生巧：%s已强化 · %s" % [DEFINITIONS[id]["name"], DEFINITIONS[id]["description"]], 6)
	_apply_weapon_passives(id, destination)
	var feedback := {"wave": "impacts/ground-slam", "berserk": "fire/fire-ring", "execute": "melee/sword-slash", "haste": "holy/blessing", "step": "arcane/blink-in", "weaken": "holy/divine-shield"}
	world.play_fx(feedback.get(id, "spawn/poof"), destination if id in ["decoy", "turret"] else origin, 1.0)
	return true

func _apply_weapon_passives(id: String, destination: Vector2) -> void:
	for item in world.progression.equipped:
		if item == null or item.stars < 3:
			continue
		var category: String = DEFINITIONS[id]["category"]
		if item.spec.kind == "slash" and category == "道具":
			passive_haste = 5.0
		elif item.spec.kind == "bolt" and category == "伤害":
			area_damage(destination, 140.0, 15.0, 0.0)
			for enemy in world.enemies:
				if enemy.alive and enemy.position.distance_to(destination) <= 140.0 and world.line_of_sight(destination, enemy.position):
					enemy.slow_left = 5.0
					enemy.burn_left = 5.0
		elif item.spec.kind == "pulse" and category == "巧劲":
			world.player.health.heal(5.0)

func area_damage(point: Vector2, radius: float, damage: float, impulse: float, stun := 0.0) -> void:
	if not world.combat_allowed():
		return
	world.arsenal.effects.append({"position": point, "radius": radius, "direction": 0.0, "slash": false, "life": 0.2, "color": Color("f2ca89")})
	for enemy in world.enemies.duplicate():
		if enemy.alive and enemy.position.distance_to(point) <= radius and world.line_of_sight(point, enemy.position):
			var dealt: float = world.deal_player_damage(enemy, damage, (enemy.position - point).normalized() * impulse)
			if enemy.alive and dealt > 0:
				enemy.stun_left = maxf(enemy.stun_left, stun)

func lure_for(enemy: ESEnemy) -> Vector2:
	for device in devices:
		var radius := 340.0 if device["mastered"] else 230.0
		if device["kind"] == "decoy" and enemy.position.distance_to(device["position"]) <= radius:
			return device["position"]
	return world.player.position

func offer_reward() -> void:
	pending_rewards += 1
	if pending_rewards == 1:
		refresh_count = 0
		_generate_choices()

func _generate_choices() -> void:
	var pool: Array[Dictionary] = []
	for id in selected:
		if id == "fake_death" and fake_death_used:
			continue
		for kind in ["cooldown", "power", "utility"]:
			if id == "seeker" and kind != "cooldown":
				continue
			if id == "fake_death" and kind != "utility":
				continue
			if id in ["execute", "berserk"] and kind == "power":
				continue
			if kind == "power" and DEFINITIONS[id]["category"] == "巧劲":
				continue
			pool.append({"skill": id, "kind": kind})
	reward_choices.clear()
	for i in mini(3, pool.size()):
		var index := rng.randi_range(0, pool.size() - 1)
		reward_choices.append(pool.pop_at(index))

func refresh_reward() -> bool:
	if pending_rewards <= 0:
		return false
	var price := 5 * (refresh_count + 1)
	if world.progression.free_refreshes > 0:
		world.progression.free_refreshes -= 1
	elif world.progression.coins >= price:
		world.progression.coins -= price
	else:
		return false
	refresh_count += 1
	_generate_choices()
	return true

func take_reward(index: int) -> bool:
	if pending_rewards <= 0 or index < 0 or index >= reward_choices.size():
		return false
	var choice := reward_choices[index]
	bonuses[choice["skill"]][choice["kind"]] += 1
	pending_rewards -= 1
	reward_choices.clear()
	if pending_rewards > 0:
		refresh_count = 0
		_generate_choices()
	return true
