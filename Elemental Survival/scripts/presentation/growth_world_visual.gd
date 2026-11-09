extends Node2D

var world: Node2D

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if world.get("in_dungeon") == true:
		return
	if world.player == null:
		return
	var font: Font = world.font
	var names := {"forge": "锻造房", "shop": "万能售卖柜", "supply": "补给站", "chest": "宝箱"}
	for facility in world.facilities:
		var point: Vector2 = facility["position"]
		var empty: bool = facility["used"]
		var tint := Color("78bfc8") if facility["kind"] == "shop" else Color("d8ad76")
		if empty:
			tint = Color("536460")
		draw_circle(point, 35.0, Color(tint, 0.09))
		draw_rect(Rect2(point - Vector2(22, 20), Vector2(44, 40)), Color("243c3b"))
		draw_rect(Rect2(point - Vector2(22, 20), Vector2(44, 40)), tint, false, 2)
		draw_string(font, point + Vector2(-45, 53), names[facility["kind"]] + (" · 空" if empty else " [E]"), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, tint)
	var fire: Vector2 = world.domains["fire"]
	var radius: float = world.field_radius("fire")
	draw_circle(fire, radius + 30, Color("3c352d"))
	draw_circle(fire, radius, Color("633626"))
	draw_arc(fire, radius, 0, TAU, 96, Color("df884a"), 4)
	for i in 34:
		var point := fire + Vector2.from_angle(i * 2.4) * (100 + fmod(i * 193.0, radius - 130))
		var end := point + Vector2.from_angle(i * 1.8) * 65
		draw_line(point, end, Color("b46235"), 13)
		draw_line(point, end, Color("ea9a47"), 3)
	draw_string(font, fire + Vector2(-70, -60), "熔岩地带", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("ffd19e"))
	draw_string(font, fire + Vector2(-125, -28), "消防员套装免疫环境火伤害", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("dfb992"))
	if not world.player.fire_armor_owned:
		var suit: Vector2 = world.FIRE_SUIT_PICKUP
		draw_rect(Rect2(suit - Vector2(20, 18), Vector2(40, 36)), Color("543b2b"))
		draw_rect(Rect2(suit - Vector2(20, 18), Vector2(40, 36)), Color("e3a469"), false, 2)
		draw_string(font, suit + Vector2(-55, 55), "消防员套装 [E]", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("e3bd87"))
	for vehicle in world.fleet.parked:
		var bike: Vector2 = vehicle["position"]
		draw_line(bike - Vector2(17, 0), bike + Vector2(17, 0), Color("99d0cd"), 6)
		draw_circle(bike - Vector2(18, 0), 7, Color("223131"))
		draw_circle(bike + Vector2(18, 0), 7, Color("223131"))
		draw_string(font, bike + Vector2(-49, 34), "电动车 [R]", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("badfce"))
	if world.riding:
		draw_arc(world.player.position, 23, 0, TAU, 24, Color("9cddd1"), 3)
