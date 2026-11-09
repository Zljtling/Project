extends Node2D

var world: Node2D

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if world.player == null:
		return
	var font: Font = world.font
	if world.in_dungeon:
		_draw_dungeon(font)
	else:
		var entrance: Vector2 = world.ENTRANCE
		var open: bool = world.objectives.count() == 3
		var tint := Color("d4c38c") if open else Color("72817b")
		draw_rect(Rect2(entrance - Vector2(60, 55), Vector2(120, 110)), Color("132429"))
		draw_arc(entrance, 58, PI, TAU, 32, tint, 9)
		draw_line(entrance + Vector2(-58, 0), entrance + Vector2(-58, 56), tint, 9)
		draw_line(entrance + Vector2(58, 0), entrance + Vector2(58, 56), tint, 9)
		for i in 3:
			draw_circle(entrance + Vector2(-25 + i * 25, 32), 6, Color("ebc982") if i < world.objectives.count() else Color("3f514d"))
		draw_string(font, entrance + Vector2(-64, 88), "固定地牢入口  %d/3" % world.objectives.count(), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, tint)
		if not world.objectives.found["prism"]:
			var point: Vector2 = world.objectives.prism_position()
			var corners := PackedVector2Array([point + Vector2(0, -22), point + Vector2(14, 0), point + Vector2(0, 22), point + Vector2(-14, 0)])
			draw_colored_polygon(corners, Color("d4dca0"))
			draw_string(font, point + Vector2(-43, -37), "稳相棱镜", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("e3e6b9"))
	_draw_waypoint(font)

func _draw_dungeon(font: Font) -> void:
	var room: Rect2 = world.dungeon_rect()
	draw_rect(room.grow(300), Color("0a131d"))
	draw_rect(room, Color("1b252d"))
	for x in range(int(room.position.x), int(room.end.x), 75):
		draw_line(Vector2(x, room.position.y), Vector2(x, room.end.y), Color("27343b"), 1)
	for y in range(int(room.position.y), int(room.end.y), 75):
		draw_line(Vector2(room.position.x, y), Vector2(room.end.x, y), Color("27343b"), 1)
	draw_rect(room.grow(-30), Color("536363"), false, 7)
	draw_string(font, room.position + Vector2(55, 80), world.DungeonLayout.NAMES[world.dungeon_room], HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("c6baa0"))
	draw_rect(world.dungeon_layout.obstacle,Color("53635c"))
	draw_rect(world.dungeon_layout.obstacle,Color("aaa68a"),false,4)
	var door: Vector2 = world.dungeon_door()
	var color := Color("cfe5a2") if world.room_cleared else Color("7a5b52")
	draw_rect(Rect2(door - Vector2(58, 35), Vector2(116, 65)), Color("132528"))
	draw_rect(Rect2(door - Vector2(58, 35), Vector2(116, 65)), color, false, 4)
	draw_string(font, door + Vector2(-48, 5), "逃离 [E]" if world.dungeon_room == 2 else "下一间 [E]", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, color)

func _draw_waypoint(font: Font) -> void:
	var target: Vector2 = world.waypoint
	if target == Vector2.INF:
		if world.in_dungeon:
			if not world.room_cleared:
				return
			target = world.dungeon_door()
		elif world.objectives.count() == 3:
			target = world.ENTRANCE
		elif is_instance_valid(world.objectives.bounty) and world.objectives.bounty.alive:
			target = world.objectives.bounty.position
		else:
			return
	var offset: Vector2 = target - world.player.position
	if offset.length() < 65:
		return
	var direction := offset.normalized()
	var point: Vector2 = world.player.position + direction * 76
	var normal := direction.orthogonal()
	draw_colored_polygon(PackedVector2Array([point + direction * 12, point - direction * 7 + normal * 7, point - direction * 7 - normal * 7]), Color("ead096"))
	draw_string(font, point + Vector2(12, 5), "距离 " + str(int(offset.length())), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("d0c7ab"))
