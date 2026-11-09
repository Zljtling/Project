extends RefCounted
var clock := 2.0
var windup := 0.0
var charging := 0.0
var locked := Vector2.ZERO

func direction(actor: Node, chase: Vector2, delta: float) -> Vector2:
	clock -= delta
	if actor.archetype == "charger":
		if charging > 0:
			charging -= delta
			return locked*3.2
		if windup > 0:
			windup -= delta
			if windup <= 0:
				charging = 0.55
			return Vector2.ZERO
		if clock <= 0:
			locked = actor.position.direction_to(actor.target.position)
			windup = 0.8
			clock = 3.8
		return chase*0.7
	if actor.archetype == "spitter":
		if not actor.world.line_of_sight(actor.position,actor.target.position):
			return chase
		var distance: float = actor.position.distance_to(actor.target.position)
		if clock <= 0 and distance < 480 and actor.world.has_method("enemy_patterns"):
			actor.world.enemy_patterns().add(actor.position,14,0.6,3.0,8,actor.position.direction_to(actor.target.position)*155)
			clock = 3.2
		return -chase*0.65 if distance < 170 else chase if distance > 310 else chase.orthogonal()*0.4
	return chase
