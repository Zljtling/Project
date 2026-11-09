extends Node2D
signal attacked(slot: int, direction: Vector2)

var specs: Array[ESWeaponSpec] = [preload("res://data/weapons/blade.tres"), preload("res://data/weapons/needle.tres"), preload("res://data/weapons/orb.tres")]
var cooldowns: Array[float] = [0.0, 0.12, 0.5]
var effects: Array[Dictionary] = []
var shots: Array[Dictionary] = []
var world: Node2D
var player: ESPlayer

func _ready() -> void:
	var visual := preload("res://scripts/presentation/combat_visual.gd").new()
	visual.arsenal = self
	add_child(visual)

func _physics_process(delta: float) -> void:
	if player.health.is_dead:
		return
	if not world.combat_allowed():
		for i in cooldowns.size():
			cooldowns[i] = maxf(0.0, cooldowns[i] - delta)
		shots.clear()
		effects.clear()
		return
	for index in specs.size():
		cooldowns[index] = maxf(0.0, cooldowns[index] - delta)
		if specs[index] == null:
			continue
		if cooldowns[index] > 0.0:
			continue
		var reach := specs[index].reach
		var target: ESEnemy = world.find_target(player.position, reach)
		if target != null:
			attack(specs[index], target, index)
			cooldowns[index] = specs[index].interval * world.attack_interval_multiplier()
	for shot in shots:
		shot["life"] -= delta
		var old: Vector2 = shot["position"]
		var next: Vector2 = old + shot["direction"] * 740.0 * delta
		if not world.line_of_sight(old, next):
			shot["life"] = -1.0
			continue
		for enemy in world.enemies.duplicate():
			if not enemy.alive:
				continue
			var nearest := Geometry2D.get_closest_point_to_segment(enemy.position, old, next)
			if nearest.distance_squared_to(enemy.position) < 21.0 * 21.0:
				world.deal_player_damage(enemy, shot["damage"], shot["direction"] * 110.0, shot["poison"])
				if enemy.alive:
					world.apply_elements(enemy, shot["elements"])
				shot["life"] = -1.0
				world.add_hit(enemy.position, shot["color"])
				break
		shot["position"] = next
	shots = shots.filter(func(s: Dictionary): return s["life"] > 0.0)
	for effect in effects:
		effect["life"] -= delta
	effects = effects.filter(func(e: Dictionary): return e["life"] > 0.0)
	queue_redraw()

func attack(spec: ESWeaponSpec, target: ESEnemy, slot: int = -1) -> void:
	if not world.combat_allowed():
		return
	var direction := (target.position - player.position).normalized()
	attacked.emit(slot,direction)
	var poisoned := player.poison_enchantment > 0.0
	var color := Color("b9f76f") if poisoned else spec.color
	var damage: float = world.weapon_damage(slot, spec.damage)
	var elements: Dictionary = world.weapon_elements(slot)
	if spec.kind == "bolt":
		shots.append({"position": player.position, "direction": direction, "life": 0.8, "damage": damage, "poison": poisoned, "color": color, "elements": elements})
	else:
		var center := player.position if spec.kind == "slash" else target.position
		var radius := spec.reach if spec.kind == "slash" else 70.0
		effects.append({"position": center, "radius": radius, "direction": direction.angle(), "slash": spec.kind == "slash", "life": 0.2, "color": color})
		for enemy in world.enemies.duplicate():
			if not enemy.alive:
				continue
			var offset: Vector2 = enemy.position - center
			if offset.length() <= radius and world.line_of_sight(center, enemy.position) and (spec.kind != "slash" or offset.normalized().dot(direction) > 0.25):
				world.deal_player_damage(enemy, damage, offset.normalized() * 190.0, poisoned)
				if enemy.alive:
					world.apply_elements(enemy, elements)
				world.add_hit(enemy.position, color)

