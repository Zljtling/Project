extends RefCounted
## Bounded telegraphs/projectiles, owned by the run and frozen with simulation.
var hazards: Array[Dictionary] = []
const MAX_HAZARDS := 96

func add(at: Vector2, radius: float, delay: float, lifetime: float, damage: float, velocity := Vector2.ZERO) -> void:
	if hazards.size() >= MAX_HAZARDS:
		return
	hazards.append({"position":at,"radius":radius,"delay":delay,"warning_duration":maxf(delay,0.01),"life":lifetime,"damage":damage,"velocity":velocity,"tick":0.0})

func update(world: Node, delta: float) -> void:
	for hazard in hazards:
		hazard["delay"] -= delta
		if hazard["delay"] > 0:
			continue
		hazard["life"] -= delta
		hazard["tick"] -= delta
		var old: Vector2 = hazard["position"]
		var next: Vector2 = old+hazard["velocity"]*delta
		if not world.line_of_sight(old,next):
			hazard["life"] = -1
			continue
		hazard["position"] = next
		if hazard["tick"] <= 0 and Geometry2D.get_closest_point_to_segment(world.player.position,old,next).distance_to(world.player.position) < hazard["radius"] and world.player.dash_left <= 0:
			hazard["tick"] = 1.0
			world.player.health.hurt(hazard["damage"])
			if hazard["velocity"] != Vector2.ZERO:
				hazard["life"] = -1
	hazards = hazards.filter(func(h: Dictionary): return h["life"] > 0)

func boss_attack(enemy: Node, origin: Vector2, radius: float) -> void:
	var enraged: bool = enemy.health < enemy.maximum_health*0.5
	if enemy.boss_kind == "hunter":
		enemy.charge_direction = enemy.position.direction_to(origin)
		enemy.charge_left = 0.65 if enraged else 0.45
		add(origin,65,0.2,0.4,20)
	elif enemy.element == "poison":
		for i in (5 if enraged else 3):
			add(origin+Vector2.from_angle(i*TAU/3)*95,65,0.4,3.0,7)
	elif enemy.element == "fire":
		var direction: Vector2 = enemy.position.direction_to(origin)
		for i in (7 if enraged else 5):
			add(enemy.position,17,0.2,3,12,direction.rotated((i-2)*0.22)*210)
	else:
		add(origin,radius,0.15,0.3,20)
		if enraged:
			add(origin+Vector2(150,0),radius,0.8,0.3,20)
