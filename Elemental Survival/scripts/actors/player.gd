class_name ESPlayer
extends CharacterBody2D

@export var speed := 245.0
@export var dash_speed := 780.0
@export var dash_duration := 0.16
@export var dash_recharge := 1.35
@export var appearance: ESActorAppearance = preload("res://data/appearance/player.tres")
var health: ESHealth
var dash_left := 0.0
var dash_cooldown := 0.0
var dash_direction := Vector2.RIGHT
var facing := Vector2.RIGHT
var hurt_flash := 0.0
var contact_grace := 0.0
var armor_owned := false
var poison_protection := false
var fire_armor_owned := false
var fire_protection := false
var in_poison := false
var on_tower := false
var poison_enchantment := 0.0
var toxin_clock := 0.0
var world: Node2D
var speed_multiplier := 1.0

func _ready() -> void:
	var visual := preload("res://scripts/presentation/actor_visual.gd").new()
	visual.actor = self
	visual.appearance = appearance
	add_child(visual)
	health = ESHealth.new()
	add_child(health)
	health.reset()
	health.damaged.connect(func(_amount: float): hurt_flash = 0.18)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 13.0
	shape.shape = circle
	add_child(shape)
	collision_layer = 1
	collision_mask = 0

func _physics_process(delta: float) -> void:
	if health.is_dead:
		return
	hurt_flash = maxf(0.0, hurt_flash - delta)
	contact_grace = maxf(0.0, contact_grace - delta)
	dash_cooldown = maxf(0.0, dash_cooldown - delta)
	poison_enchantment = maxf(0.0, poison_enchantment - delta)
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	direction = world.movement_direction(direction)
	if direction.length_squared() > 0.0:
		facing = direction
	if Input.is_action_just_pressed("dash") and dash_cooldown <= 0.0:
		dash_direction = direction if direction.length_squared() > 0.0 else facing
		dash_left = dash_duration
		dash_cooldown = dash_recharge
		world.play_fx("arcane/blink-out", position, 0.65)
	if dash_left > 0.0:
		dash_left -= delta
		velocity = dash_direction * dash_speed
	else:
		velocity = direction * speed * speed_multiplier
	if is_instance_valid(world):
		position = world.move_actor(position, velocity * delta)
	queue_redraw()

func update_environment(delta: float, toxic: bool) -> void:
	in_poison = toxic
	if toxic:
		# Temporary prototype tuning: exposure refreshes a short poison enchantment.
		poison_enchantment = 8.0
		toxin_clock += delta
		while toxin_clock >= 1.0:
			toxin_clock -= 1.0
			if not poison_protection:
				health.hurt(5.0)
	else:
		toxin_clock = 0.0

func contact_hit(amount: float, source: Node = null) -> void:
	if contact_grace > 0.0 or dash_left > 0.0 or not world.player_visible_to_enemies():
		return
	contact_grace = 0.65
	health.hurt(amount, source)

func equip_suit(id: String) -> bool:
	if id == "poison" and not armor_owned:
		return false
	if id == "fire" and not fire_armor_owned:
		return false
	poison_protection = id == "poison"
	fire_protection = id == "fire"
	return true

func hurt_flash_or_zero() -> float:
	return hurt_flash

