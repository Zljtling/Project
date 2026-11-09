extends Node2D

var actor: Node2D
var appearance: ESActorAppearance
var art: Node2D
var last_position := Vector2.ZERO

func _ready() -> void:
	last_position = actor.position
	if appearance.animations != null:
		var animated := AnimatedSprite2D.new()
		animated.sprite_frames = appearance.animations
		art = animated
	elif appearance.texture != null:
		var sprite := Sprite2D.new()
		sprite.texture = appearance.texture
		art = sprite
	if art != null:
		art.scale = appearance.sprite_scale
		art.position = appearance.sprite_offset
		add_child(art)

func _process(_delta: float) -> void:
	if actor is ESPlayer:
		modulate.a = 0.35 if not actor.world.player_visible_to_enemies() else 1.0
	if art is AnimatedSprite2D:
		var moving := actor.position.distance_squared_to(last_position) > 0.01
		var animation := appearance.move_animation if moving else appearance.idle_animation
		if art.sprite_frames.has_animation(animation):
			art.play(animation)
	if art != null:
		art.modulate = Color.WHITE if actor.hurt_flash_or_zero() <= 0.0 else Color("ffbcb0")
	last_position = actor.position
	queue_redraw()

func _draw() -> void:
	var is_player := appearance.placeholder == "player"
	var radius := 15.0 if is_player else 13.0
	if actor.has_meta("castle_elite"):
		radius = 22.0
		draw_string(actor.world.font, Vector2(-50, -40), "高塔精英 · 碎城者", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("f5d5a2"))
		if actor.get("slam_left") != null and actor.slam_left > 0.0:
			var center: Vector2 = actor.slam_origin - actor.position
			draw_circle(center, 100, Color(1, 0.35, 0.18, 0.15))
			draw_arc(center, 100, 0, TAU, 40, Color("ef9e6f"), 3)
	if not is_player and actor.get("boss_kind") != null:
		radius = 29.0
		if actor.attack_left > 0.0:
			var center: Vector2 = actor.attack_origin - actor.position
			draw_circle(center, actor.attack_radius, Color(1, 0.35, 0.18, 0.12))
			draw_arc(center, actor.attack_radius, 0, TAU, 48, Color("ef9e6f"), 3)
		var title := "追猎者" if actor.boss_kind == "hunter" else "领域镇守者"
		title = actor.get_meta("display_name", title)
		if actor.has_meta("key_part"):
			title = "★ 部件目标 · " + title
		if actor.returning:
			title += " · 归位"
		draw_string(actor.world.font, Vector2(-42, -50), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("f5d5a2"))
	draw_set_transform(Vector2(0, radius * 0.7), 0, Vector2(1.4, 0.45))
	draw_circle(Vector2.ZERO, radius, Color(0.02, 0.05, 0.06, 0.5))
	draw_set_transform(Vector2.ZERO)
	if art == null:
		if is_player:
			if actor.dash_left > 0.0:
				draw_line(-actor.facing * 42.0, Vector2.ZERO, Color(0.3, 0.95, 0.85, 0.5), 18.0)
			var body := Color("ffe0a0") if actor.hurt_flash <= 0.0 else Color.WHITE
			draw_circle(Vector2.ZERO, radius, Color("142027"))
			draw_circle(Vector2.ZERO, 12.0, body)
			draw_circle(Vector2(-4, -4), 3.0, Color("fff2d2"))
			draw_line(actor.facing * 8.0, actor.facing * 20.0, Color("263338"), 5.0)
		else:
			var tint := Color("c47b72") if actor.poison_left <= 0.0 else Color("a6c96a")
			if actor.get("boss_kind") != null:
				tint = Color("df946c") if actor.boss_kind == "hunter" else Color("a6ba68")
			if actor.hit_flash > 0.0:
				tint = Color.WHITE
			var bounce: float = sin(actor.wobble) * 1.8
			draw_circle(Vector2(0, bounce), radius, Color("392b32"))
			draw_circle(Vector2(0, bounce - 2), radius - 2.5, tint)
			draw_circle(Vector2(-4, bounce - 3), 2, Color("201f2a"))
			draw_circle(Vector2(4, bounce - 3), 2, Color("201f2a"))
	if is_player:
		if actor.poison_protection:
			draw_arc(Vector2.ZERO, 18.0, 0, TAU, 32, Color("8ee477"), 2.0)
		if actor.poison_enchantment > 0.0:
			draw_circle(Vector2(15, -17), 4.0, Color("b4f965"))
	else:
		if actor.stun_left > 0:
			draw_arc(Vector2(0, -radius - 14), 10, 0, TAU, 20, Color("ffe29a"), 2)
		if actor.weaken_left > 0:
			draw_arc(Vector2.ZERO, radius + 5, 0, TAU, 24, Color("a9c7ef"), 2)
		var maximum: float = actor.maximum_health
		if actor.health < maximum:
			draw_line(Vector2(-radius, -radius - 9), Vector2(radius, -radius - 9), Color("382f37"), 3)
			draw_line(Vector2(-radius, -radius - 9), Vector2(-radius + radius * 2 * maxf(actor.health, 0) / maximum, -radius - 9), Color("f7b58a"), 3)
