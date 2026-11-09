extends Node3D
## Visual-only equipment slots: transactions and damage remain in the arsenal.
var world: Node2D
var slots: Array[Sprite3D] = []
var recoil := [0.0,0.0,0.0]
var time := 0.0
var textures: Dictionary = {}
var aim := [Vector2.RIGHT,Vector2.RIGHT,Vector2.RIGHT]

func _ready() -> void:
	for i in 3:
		var sprite := Sprite3D.new()
		sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		sprite.pixel_size = 0.010
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		add_child(sprite)
		slots.append(sprite)
	world.arsenal.attacked.connect(func(slot: int,direction: Vector2):
		if slot >= 0 and slot < 3:
			recoil[slot] = 0.18
			aim[slot] = direction
	)

func _process(delta: float) -> void:
	time += delta
	position = Vector3(world.player.position.x/32,0,world.player.position.y/32)
	if is_instance_valid(world.presentation):
		position.y = world.presentation._surface_height(world.player.position)
	var camera := get_viewport().get_camera_3d()
	for i in 3:
		var item: ESWeaponInstance = world.progression.equipped[i]
		var sprite := slots[i]
		sprite.visible = world.started and item != null and not world.riding
		if item == null:
			continue
		if not textures.has(item.spec.kind):
			textures[item.spec.kind] = load("res://assets/weapons/%s.svg" % item.spec.kind)
		sprite.texture = textures[item.spec.kind]
		recoil[i] = maxf(0,recoil[i]-delta)
		var angle: float = aim[i].angle() if recoil[i] > 0 else -0.4+i*TAU/3+sin(time*0.8)*0.1
		var distance := 1.25+sin(recoil[i]/0.18*PI)*0.35
		sprite.position = Vector3(cos(angle)*distance,1.15+sin(time*2+i)*0.07,sin(angle)*distance*0.65)
		if camera != null:
			var direction: Vector2 = aim[i] if recoil[i] > 0 else world.player.facing
			var right := Vector2(camera.global_basis.x.x,camera.global_basis.x.z).normalized()
			var down := Vector2(camera.global_basis.z.x,camera.global_basis.z.z).normalized()
			var screen_angle := Vector2(direction.dot(right),direction.dot(down)).angle()
			sprite.basis = camera.global_basis*Basis(Vector3.BACK,-screen_angle-0.3)
