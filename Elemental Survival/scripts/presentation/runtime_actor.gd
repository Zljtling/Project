extends Node3D
## One-way presentation of an existing actor. No movement, damage or input rules.
const Geometry = preload("res://scripts/world/scene_geometry.gd")
var actor: Node2D
var is_player := false
var sprite: Sprite3D
var bar: Label3D
var last := Vector2.ZERO
var art_id := "player"
var body_scale := 1.0
var motion_state := preload("res://scripts/presentation/actor_motion.gd").new()
var last_attack_clock := 0.0

func _ready() -> void:
	last = actor.position
	sprite = Sprite3D.new()
	if not is_player:
		art_id = "elite" if actor.has_meta("castle_elite") else "ghoul"
		if actor.get("boss_kind") != null:
			art_id = "hunter" if actor.boss_kind == "hunter" else ("fire_guardian" if actor.element == "fire" else "poison_guardian" if actor.element == "poison" else "stone_guardian")
		elif not actor.has_meta("castle_elite") and actor.get("archetype") != null:
			art_id = actor.archetype
	sprite.texture = load("res://assets/actors/cartoon/sheets/%s.svg" % art_id)
	sprite.hframes = 8
	sprite.vframes = 4
	sprite.pixel_size = 0.017 if is_player else 0.014
	sprite.position.y = 1.12
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	add_child(sprite)
	if is_player:
		actor.world.arsenal.attacked.connect(func(_slot: int, _direction: Vector2): motion_state.attack())
	else:
		actor.attack_performed.connect(motion_state.attack)
	bar = Label3D.new()
	bar.position.y = 2.3
	bar.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bar.font_size = 26
	bar.pixel_size = 0.01
	bar.outline_size = 6
	bar.font = actor.world.font
	add_child(bar)
	if not is_player and (actor.get("boss_kind") != null or actor.has_meta("castle_elite")):
		body_scale = 1.7
		sprite.scale = Vector3.ONE*body_scale
		bar.position.y = 3.8

func sync(delta: float, height: float) -> void:
	position = Geometry.point3(actor.position,height)
	visible = actor.world.started and (is_player or actor.alive)
	actor.hide()
	var motion := actor.position-last
	var facing: Vector2 = actor.facing if is_player else motion
	var camera := get_viewport().get_camera_3d()
	if camera != null:
		var right := Vector2(camera.global_basis.x.x,camera.global_basis.x.z).normalized()
		var down := Vector2(camera.global_basis.z.x,camera.global_basis.z.z).normalized()
		facing = Vector2(facing.dot(right),facing.dot(down))
	var flash: float = actor.hurt_flash if is_player else actor.hit_flash
	var windup := false
	var charging: bool = actor.dash_left > 0 if is_player else false
	if not is_player:
		windup = actor.brain.windup > 0 or (actor.get("attack_left") != null and actor.attack_left > 0) or (actor.get("slam_left") != null and actor.slam_left > 0)
		charging = actor.brain.charging > 0 or (actor.get("charge_left") != null and actor.charge_left > 0)
		if actor.archetype == "spitter":
			windup = windup or actor.brain.clock > 2.6
			if last_attack_clock > 2.6 and actor.brain.clock <= 2.6:
				motion_state.attack()
			last_attack_clock = actor.brain.clock
		if motion_state.pose == "windup" and not windup:
			motion_state.attack()
		if windup and camera != null:
			var toward: Vector2 = actor.position.direction_to(actor.target.position)
			var right := Vector2(camera.global_basis.x.x,camera.global_basis.x.z).normalized()
			var down := Vector2(camera.global_basis.z.x,camera.global_basis.z.z).normalized()
			facing = Vector2(toward.dot(right),toward.dot(down))
	motion_state.advance(delta,motion.length(),facing,flash > 0,windup,charging)
	sprite.frame_coords = Vector2i(motion_state.frame_index,motion_state.direction_row)
	sprite.scale = Vector3(motion_state.stretch.x,motion_state.stretch.y,1)*body_scale
	sprite.position.y = 144*sprite.pixel_size*body_scale*motion_state.stretch.y*0.5+motion_state.offset
	var tint := Color.WHITE
	if not is_player and actor.poison_left > 0:
		tint = Color("a3be6b")
	sprite.modulate = Color("fff1d1") if flash > 0 else tint
	if is_player:
		sprite.modulate.a = 1.0 if actor.world.player_visible_to_enemies() else 0.35
		bar.visible = false
	else:
		var boss: bool = actor.get("boss_kind") != null or actor.has_meta("castle_elite")
		bar.visible = actor.health < actor.maximum_health or boss
		var title := ""
		if boss:
			title = actor.get_meta("display_name","高塔精英" if actor.has_meta("castle_elite") else "领域镇守者" if actor.get("boss_kind") == "guardian" else "追猎者")+"\n"
		bar.text = title+"%d / %d" % [maxi(0,int(actor.health)),int(actor.maximum_health)]
	last = actor.position
