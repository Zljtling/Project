extends Node2D

var world: Node2D

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if world.get("in_dungeon") == true:
		return
	var visible := Rect2(world.player.position - Vector2(900, 650), Vector2(1800, 1300))
	for wall in world.layout.walls:
		if not visible.intersects(wall.grow(80)):
			continue
		var castle_wall: bool = world.tower_rect().encloses(wall)
		var tint := Color("a49a7b") if castle_wall else Color("a09b7e")
		if castle_wall and world.sinking_left > 0:
			tint.a = 0.4 + absf(sin(world.run_time * 9)) * 0.5
		# Low walls with visible top faces provide a 2.5D height cue.
		draw_rect(wall, Color("4b4b40"))
		draw_rect(Rect2(wall.position - Vector2(0, 22), wall.size), tint)
		draw_rect(Rect2(wall.position - Vector2(0, 22), wall.size), Color("525f50"), false, 2)
	for house in world.layout.houses:
		if not visible.intersects(house):
			continue
		var nearby: bool = house.grow(75).has_point(world.player.position)
		var roof := Rect2(house.position - Vector2(8, 32), house.size + Vector2(16, 10))
		var color := Color("596d64")
		color.a = 0.10 if nearby else 0.94
		draw_rect(roof, color)
		draw_rect(roof, Color(0.65, 0.72, 0.6, 0.18 if nearby else 0.7), false, 2)
		if not nearby:
			for i in 5:
				draw_line(roof.position + Vector2(0, i * 40), roof.position + Vector2(roof.size.x, i * 40), Color(0.2, 0.3, 0.25, 0.5), 2)
		# Door thresholds stay visible even while the roof hides the room.
		draw_line(house.position + Vector2(70, house.size.y), house.position + Vector2(170, house.size.y), Color("dfc28b"), 5)
