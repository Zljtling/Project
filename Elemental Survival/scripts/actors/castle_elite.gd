extends ESEnemy

var home := Vector2.ZERO
var slam_clock := 3.0
var slam_left := 0.0
var slam_origin := Vector2.ZERO

func _ready() -> void:
	maximum_health = 420.0
	health = maximum_health
	speed = 108.0
	set_meta("castle_elite", true)
	super._ready()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not alive or target.health.is_dead or stun_left > 0.0:
		return
	if not world.tower_rect().grow(180).has_point(target.position):
		slam_left = 0.0
		return
	if slam_left > 0.0:
		slam_left -= delta
		if slam_left <= 0.0:
			world.add_hit(slam_origin, Color("ffb16b"), 100)
			if target.position.distance_to(slam_origin) < 100 and target.dash_left <= 0:
				target.health.hurt(18, self)
	else:
		slam_clock -= delta
		if slam_clock <= 0.0 and position.distance_to(target.position) < 260 and world.player_visible_to_enemies():
			slam_origin = target.position
			slam_left = 1.0
			slam_clock = 4.0
