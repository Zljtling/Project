extends ESEnemy

var boss_kind := "hunter"
var element := ""
var home := Vector2.ZERO
var engaged := false
var returning := false
var migration_left := 0.0
var return_wait := 0.0
var attack_clock := 3.0
var attack_left := 0.0
var attack_origin := Vector2.ZERO
var attack_radius := 105.0
var charge_left := 0.0
var charge_direction := Vector2.ZERO

func _ready() -> void:
	maximum_health = 1200.0 if boss_kind == "hunter" else 1550.0
	health = maximum_health
	speed = 125.0 if boss_kind == "hunter" else 85.0
	attack_radius = 105.0 if boss_kind == "hunter" else 150.0
	super._ready()

func _physics_process(delta: float) -> void:
	if not alive or target.health.is_dead:
		return
	update_status(delta)
	if not alive or stun_left > 0.0:
		return
	if charge_left > 0:
		charge_left = maxf(0,charge_left-delta)
		position = world.move_actor(position,charge_direction*420*delta)
		if position.distance_to(target.position) < 40:
			target.contact_hit(20,self)
		return
	wobble += delta * 4.0
	hit_flash = maxf(0.0, hit_flash - delta)
	migration_left = maxf(0.0, migration_left - delta)
	if boss_kind == "guardian":
		var distance := target.position.distance_to(home) if world.player_visible_to_enemies() else INF
		if distance < 270.0 and not returning:
			engaged = true
		if distance > 450.0 and engaged:
			returning = true
			engaged = false
			attack_left = 0.0
			return_wait = 2.5
		if returning:
			position = world.move_actor(position, world.enemy_direction(self, home, delta) * 150.0 * delta)
			if position.distance_to(home) < 3.0:
				returning = false
		if not engaged:
			return_wait = maxf(0.0, return_wait - delta)
			if return_wait <= 0.0:
				health = minf(maximum_health, health + delta * (0.5 if migration_left > 0 else 14.0))
			return
	var destination: Vector2 = world.enemy_destination(self)
	if position.distance_to(destination) > 65.0:
		position = world.move_actor(position, world.enemy_direction(self, destination, delta) * speed * (0.6 if slow_left > 0 else 1.0) * delta)
	attack_clock -= delta
	if attack_clock <= 0.0 and attack_left <= 0.0 and world.player_visible_to_enemies():
		attack_origin = target.position
		attack_left = 1.1
		attack_clock = 4.5
	elif attack_left > 0.0:
		attack_left -= delta
		if attack_left <= 0.0:
			world.add_hit(attack_origin, Color("ff936b"), attack_radius)
			if world.has_method("enemy_patterns"):
				world.enemy_patterns().boss_attack(self,attack_origin,attack_radius)
			elif target.position.distance_to(attack_origin) < attack_radius and target.dash_left <= 0.0:
				target.health.hurt(20.0, self)

func take_hit(amount: float, _impulse: Vector2, poisoned: bool) -> void:
	if boss_kind == "guardian":
		if returning or target.position.distance_to(home) > 450.0:
			return
		engaged = true
	super.take_hit(amount, Vector2.ZERO, poisoned)

func migrate(destination: Vector2) -> void:
	home = destination
	position = home + Vector2(65, 0)
	engaged = false
	returning = false
	attack_left = 0.0
	migration_left = 30.0
	return_wait = 2.5
