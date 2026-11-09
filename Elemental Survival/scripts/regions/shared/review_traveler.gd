extends CharacterBody3D
## Sample movement only; no combat/equipment logic is duplicated here.
@export var speed := 5.0
var home_position := Vector3(0,0.2,4)
var sprite: Sprite3D
var direction := 0
var walk_time := 0.0
var view_camera: Camera3D

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.25
	capsule.height = 1.2
	shape.shape = capsule
	shape.position.y = 0.6
	add_child(shape)
	sprite = Sprite3D.new()
	sprite.texture = preload("res://assets/regions/shared/traveler.png")
	sprite.hframes = 4
	sprite.vframes = 4
	sprite.pixel_size = 0.065
	sprite.position.y = 0.83
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.no_depth_test = false
	add_child(sprite)

func _physics_process(delta: float) -> void:
	var input := Vector2(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))).limit_length()
	var motion := Vector3(input.x, 0, input.y)
	if is_instance_valid(view_camera):
		var right := view_camera.global_basis.x
		var down := view_camera.global_basis.z
		right.y = 0
		down.y = 0
		motion = right.normalized() * input.x + down.normalized() * input.y
	velocity.x = motion.x * speed
	velocity.z = motion.z * speed
	velocity.y -= 18.0 * delta
	if is_on_floor():
		velocity.y = 0
	move_and_slide()
	if input.length_squared() > 0:
		if absf(input.x) > absf(input.y):
			direction = 2 if input.x > 0 else 1
		else:
			direction = 0 if input.y > 0 else 3
		walk_time += delta
	else:
		walk_time = 0
	sprite.frame = direction * 4 + (int(walk_time * 8) % 4)
	if Input.is_physical_key_pressed(KEY_HOME):
		global_position = home_position
