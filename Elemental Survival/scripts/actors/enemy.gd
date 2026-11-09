class_name ESEnemy
extends Node2D

signal defeated(enemy: ESEnemy)
signal attack_performed
@export var appearance: ESActorAppearance = preload("res://data/appearance/enemy.tres")
var health := 28.0
var maximum_health := 28.0
var speed := 95.0
var target: ESPlayer
var world: Node2D
var poison_left := 0.0
var poison_tick := 0.0
var hit_flash := 0.0
var knockback := Vector2.ZERO
var alive := true
var wobble := 0.0
var slow_left := 0.0
var burn_left := 0.0
var poison_damage := 4.0
var burn_damage := 5.0
var navigation_left := 0.0
var navigation_target := Vector2.INF
var navigation_path := PackedVector2Array()
var stun_left := 0.0
var weaken_left := 0.0
var weaken_reduction := 0.3
var field_poison_clock := 0.0
var field_fire_clock := 0.0
var burn_tick := 0.0
var archetype := "ghoul"
var brain := preload("res://scripts/actors/enemy_brain.gd").new()

func _ready() -> void:
	var visual := preload("res://scripts/presentation/actor_visual.gd").new()
	visual.actor = self
	visual.appearance = appearance
	add_child(visual)
	wobble = randf() * TAU

func _physics_process(delta: float) -> void:
	if not alive or not is_instance_valid(target) or target.health.is_dead:
		return
	update_status(delta)
	if not alive or stun_left > 0.0:
		return
	wobble += delta * 7.0
	hit_flash = maxf(0.0, hit_flash - delta)
	var direction: Vector2 = world.enemy_direction(self, world.enemy_destination(self), delta)
	direction = brain.direction(self,direction,delta)
	var spacing := Vector2.ZERO
	for other in world.enemies:
		if other == self or not other.alive:
			continue
		var difference: Vector2 = position - other.position
		var length := difference.length_squared()
		if length > 0.01 and length < 850.0:
			spacing += difference.normalized() * (1.0 - sqrt(length) / 30.0)
	position = world.move_actor(position, (direction * speed * (0.6 if slow_left > 0 else 1.0) + spacing.limit_length() * 90.0 + knockback) * delta)
	knockback = knockback.move_toward(Vector2.ZERO, 700.0 * delta)
	if position.distance_to(target.position) < 27.0:
		if target.contact_grace <= 0 and target.dash_left <= 0:
			attack_performed.emit()
		target.contact_hit(8.0, self)
	queue_redraw()

func update_status(delta: float) -> void:
	slow_left = maxf(0.0, slow_left - delta)
	stun_left = maxf(0.0, stun_left - delta)
	weaken_left = maxf(0.0, weaken_left - delta)
	world.update_enemy_environment(self, delta)
	if not alive:
		return
	if burn_left > 0.0:
		burn_tick += minf(delta, burn_left)
		burn_left = maxf(0.0, burn_left - delta)
		while burn_tick >= 0.5 and alive:
			burn_tick -= 0.5
			world.deal_player_damage(self, burn_damage * 0.5)
	else:
		burn_tick = 0.0
	if poison_left > 0.0:
		poison_tick += minf(delta, poison_left)
		poison_left = maxf(0.0, poison_left - delta)
		while poison_tick >= 0.5 and alive:
			poison_tick -= 0.5
			world.deal_player_damage(self, poison_damage)
	else:
		poison_tick = 0.0

func take_hit(amount: float, impulse: Vector2, poisoned: bool) -> void:
	_receive_hit(amount, impulse, poisoned)

func take_environment_hit(amount: float) -> void:
	_receive_hit(amount, Vector2.ZERO, false)

func _receive_hit(amount: float, impulse: Vector2, poisoned: bool) -> void:
	if not alive:
		return
	health -= amount
	knockback += impulse
	hit_flash = 0.1
	if poisoned:
		poison_left = maxf(poison_left, 3.0)
	if health <= 0.0:
		alive = false
		defeated.emit(self)
		queue_free()

func hurt_flash_or_zero() -> float:
	return hit_flash

