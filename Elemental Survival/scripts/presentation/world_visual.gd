extends Node2D

var world: Node2D
var font: Font

func _ready() -> void:
	font = world.font

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, world.MAP_SIZE), Color("152a2c"))
	for x in range(0, int(world.MAP_SIZE.x), 80):
		draw_line(Vector2(x, 0), Vector2(x, world.MAP_SIZE.y), Color(0.3, 0.55, 0.5, 0.06))
	for y in range(0, int(world.MAP_SIZE.y), 80):
		draw_line(Vector2(0, y), Vector2(world.MAP_SIZE.x, y), Color(0.3, 0.55, 0.5, 0.06))
	# Deterministic ground flecks; visual landmarks never obstruct movement.
	for i in 180:
		var point: Vector2 = Vector2(fmod(i * 173.7, world.MAP_SIZE.x), fmod(i * 319.3, world.MAP_SIZE.y))
		draw_line(point, point + Vector2(4, -7), Color("29413c"), 2)
	draw_rect(Rect2(Vector2(20, 20), world.MAP_SIZE - Vector2(40, 40)), Color("44605a"), false, 4)
	_draw_settlements()
	_draw_field()
	_draw_tower()
	if not world.player.armor_owned:
		draw_circle(world.ARMOR_PICKUP, 30, Color(0.4, 0.85, 0.55, 0.08))
		draw_style_box(_box(Color("274b3e"), Color("a3dc83")), Rect2(world.ARMOR_PICKUP - Vector2(20, 18), Vector2(40, 36)))
		draw_line(world.ARMOR_PICKUP + Vector2(-8, 0), world.ARMOR_PICKUP + Vector2(8, 0), Color("e1f7bb"), 4)
		_label(world.ARMOR_PICKUP + Vector2(-54, 53), "生化套装  [E]", Color("d8eabd"), 16)
	for hit in world.hits:
		var color: Color = hit["color"]
		color.a = hit["life"] / 0.25
		draw_arc(hit["position"], hit["radius"] * (1.6 - color.a), 0, TAU, 12, color, 2)

func _draw_field() -> void:
	var center: Vector2 = world.field_center("poison")
	var radius: float = world.field_radius("poison")
	# One metre uses 64 plan pixels in the whitebox; the two-metre shore is
	# safe ground outside the basin. The bridge shares the gameplay footprint.
	draw_arc(center, radius + 64, 0, TAU, 128, Color("625e45"), 128)
	draw_circle(center, radius, Color("162f25"))
	draw_circle(center, radius - 28, Color("375b28"))
	draw_arc(center, radius, 0, TAU, 128, Color("b1c570"), 5, true)
	for i in 55:
		var angle: float = i * 2.4 + world.run_time * 0.025
		var point: Vector2 = center + Vector2.from_angle(angle) * (100 + fmod(i * 137.0, radius - 140))
		draw_circle(point, 8.0 + sin(world.run_time + i) * 3.0, Color(0.65, 0.85, 0.25, 0.24))
	var bridge: Rect2 = world.poison_bridge_rect()
	draw_rect(Rect2(bridge.position + Vector2(0, 12), bridge.size), Color("1b3229"))
	draw_rect(bridge, Color("8c8061"))
	for x in range(int(bridge.position.x), int(bridge.end.x), 24):
		draw_line(Vector2(x, bridge.position.y), Vector2(x, bridge.end.y), Color("5c5946"), 2)
	draw_line(bridge.position, Vector2(bridge.end.x, bridge.position.y), Color("c8bb92"), 5)
	draw_line(Vector2(bridge.position.x, bridge.end.y), bridge.end, Color("c8bb92"), 5)
	_label(center + Vector2(-75, -150), "硫酸池 · 深度 1m", Color("d2ed95"), 24)
	_label(center + Vector2(-140, -117), "桥上与岸边安全 · 入池才受影响", Color("b9ce9e"), 16)

func _draw_settlements() -> void:
	# Broad roads link settlements; the changing castle and domains occupy open land.
	for road in world.layout.roads:
		draw_polyline(road, Color("273b35"), 80)
	for village in world.layout.villages:
		var point: Vector2 = village["position"]
		draw_rect(Rect2(point - Vector2(540, 450), Vector2(1100, 920)), Color("2b3d35"))
		draw_line(point + Vector2(-540, 0), point + Vector2(560, 0), Color("4a5140"), 115)
		draw_line(point + Vector2(40, -450), point + Vector2(40, 470), Color("4a5140"), 110)
		_label(point + Vector2(-55, -410), village["name"], Color("a5b496"), 24)
	for house in world.layout.houses:
		draw_rect(house, Color("635b48"))
		draw_rect(house.grow(-28), Color("38443b"))
		draw_rect(Rect2(house.position + Vector2(65, 60), Vector2(90, 60)), Color("686044"), false, 2)

func _draw_tower() -> void:
	var rect: Rect2 = world.tower_rect()
	var warn: bool = world.cycle_left <= world.warning_duration or world.sinking_left > 0.0
	var alpha := 1.0 if world.sinking_left <= 0.0 else 0.4 + 0.5 * absf(sin(world.run_time * 9))
	draw_rect(Rect2(rect.position + Vector2(0, 25), rect.size), Color("0b1d23"))
	draw_rect(rect, Color(Color("625f51"), alpha))
	draw_rect(rect.grow(-44), Color(Color("404b46"), alpha))
	for x in range(int(rect.position.x + 40), int(rect.end.x), 80):
		draw_line(Vector2(x, rect.position.y + 40), Vector2(x, rect.end.y - 40), Color(0.8, 0.8, 0.65, 0.08))
	for y in range(int(rect.position.y + 40), int(rect.end.y), 80):
		draw_line(Vector2(rect.position.x + 40, y), Vector2(rect.end.x - 40, y), Color(0.8, 0.8, 0.65, 0.08))
	# Gates and shallow ramps are traversed by movement, with no interaction gate.
	for side in [-1, 1]:
		var ramp := Rect2(world.tower_position + Vector2(-95, side * 440 - (0 if side == 1 else 70)), Vector2(190, 70))
		draw_rect(ramp, Color("77735d"))
		for i in 7:
			draw_line(ramp.position + Vector2(0, i * 10), ramp.position + Vector2(190, i * 10), Color("4c574c"), 2)
	_label(world.tower_position + Vector2(-95, 70), "旧日高塔 · 城堡庭院", Color("f2d6a3"), 24)
	_label(world.tower_position + Vector2(-105, 100), "自由出入 · 精英镇守 · 藏有宝箱", Color("c7beaa"), 16)
	if warn:
		draw_rect(rect, Color("ffc17f"), false, 4)
		_label(world.tower_position + Vector2(-90, 140), "正在下陷 · 即将归于地表" if world.sinking_left > 0.0 else "本轮结束后下陷", Color("ffc17f"), 20)

func _label(point: Vector2, text: String, color: Color, size: int) -> void:
	if font != null:
		draw_string(font, point, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _box(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	return style
