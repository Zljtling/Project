extends Control

var world: Node2D
var markers: Array[Dictionary] = []
var font: Font
var map_rect := Rect2()
var world_rect := Rect2()
var label_rects: Array[Rect2] = []
signal spawn_selected(index: int)
var spawn_mode := false
var spawn_options: Array[Dictionary] = []
var selected_spawn := -1

func _ready() -> void:
	custom_minimum_size = Vector2(0, 440)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	font = world.font

func _process(_delta: float) -> void:
	queue_redraw()

func point_to_map(point: Vector2) -> Vector2:
	return map_rect.position + (point - world_rect.position) / world_rect.size * map_rect.size

func _draw() -> void:
	markers.clear()
	label_rects.clear()
	world_rect = world.dungeon_rect() if world.in_dungeon else Rect2(Vector2.ZERO, world.MAP_SIZE)
	var available := size - Vector2(24, 24)
	var factor := minf(available.x / world_rect.size.x, available.y / world_rect.size.y)
	var dimensions := world_rect.size * factor
	map_rect = Rect2((size - dimensions) * 0.5, dimensions)
	draw_rect(map_rect, Color("d8d5b3"))
	draw_rect(map_rect, Color("8e986e"), false, 2)
	for i in range(1, 6):
		var x := map_rect.position.x + dimensions.x * i / 6
		var y := map_rect.position.y + dimensions.y * i / 6
		draw_line(Vector2(x, map_rect.position.y), Vector2(x, map_rect.end.y), Color(0.4, 0.6, 0.5, 0.12))
		draw_line(Vector2(map_rect.position.x, y), Vector2(map_rect.end.x, y), Color(0.4, 0.6, 0.5, 0.12))
	if world.in_dungeon:
		_marker(world.dungeon_door(), "出口" if world.dungeon_room == 2 else "下一间", Color("e9ce8d"))
		var obstacle: Rect2 = world.dungeon_layout.obstacle
		draw_rect(Rect2(point_to_map(obstacle.position),obstacle.size*factor),Color("786c56"))
		for enemy in world.enemies:
			_marker(enemy.position, "", Color("cb7e69"), 2)
	else:
		# Geography is visible, but loot and supply locations require exploration.
		for road in world.layout.roads:
			var points := PackedVector2Array()
			for point in road:
				points.append(point_to_map(point))
			draw_polyline(points, Color("b39d70"), 3)
		for village in world.layout.villages:
			var village_point: Vector2 = point_to_map(village["position"])
			draw_rect(Rect2(village_point - Vector2(26, 21), Vector2(52, 42)), Color(0.65, 0.6, 0.43, 0.12))
		for house in world.layout.houses:
			draw_rect(Rect2(point_to_map(house.position), house.size * factor), Color("4c5b50"))
		for element in world.domains:
			var center: Vector2 = point_to_map(world.domains[element])
			var color := Color("819e5f") if element == "poison" else Color("b87656")
			if element == "poison" and world.has_method("poison_map_geometry"):
				var geometry: Dictionary = world.poison_map_geometry()
				var outline := PackedVector2Array()
				for point in geometry["outline"]:
					outline.append(point_to_map(point))
				draw_colored_polygon(outline,Color(color,0.35))
				for rock in geometry["rocks"]:
					draw_circle(point_to_map(rock["position"]),rock["radius"]*factor,Color("a4ac91"))
				for route in geometry["routes"]:
					draw_line(point_to_map(route[0]),point_to_map(route[1]),Color("c8b58e"),2)
			else:
				draw_circle(center, world.field_radius(element) * factor, Color(color, 0.22))
		var castle_rect: Rect2 = world.tower_rect()
		if world.has_method("element_centers"):
			for element in world.domains:
				for center in world.element_centers(element):
					if center == world.domains[element]:
						continue
					if element == "poison":
						var geometry: Dictionary = world.poison_map_geometry()
						var outline := PackedVector2Array()
						var offset: Vector2 = center-world.domains[element]
						for point in geometry["outline"]:
							outline.append(point_to_map(point+offset))
						draw_colored_polygon(outline,Color(0.5,0.62,0.37,0.35))
						for route in geometry["routes"]:
							draw_line(point_to_map(route[0]+offset),point_to_map(route[1]+offset),Color("c8b58e"),2)
					else:
						draw_circle(point_to_map(center),world.field_radius(element)*factor,Color(0.72,0.46,0.34,0.3))
		draw_rect(Rect2(point_to_map(castle_rect.position), castle_rect.size * factor), Color("a8a080"), false, 1)
		var colors := {"entrance": Color("e0c58b"), "tower": Color("a8b3a6"), "domain": Color("a4b777"), "forge": Color("7fb2b8"), "hunter": Color("f5bc74"), "revealed_chest": Color("f4df81")}
		for marker in world.surface_map_markers():
			_marker(marker["position"], marker["name"], colors[marker["kind"]], 5 if marker["kind"] in ["hunter", "revealed_chest"] else 4)

	if spawn_mode:
		for i in spawn_options.size():
			var choice: Dictionary = spawn_options[i]
			_marker(choice["position"], choice["name"], Color("ddb86f") if i == selected_spawn else Color("8fae83"), 7 if i == selected_spawn else 5)
			if i == selected_spawn:
				draw_arc(point_to_map(choice["position"]), 12, 0, TAU, 32, Color("f2d5a1"), 2)
		return
	_marker(world.player.position, "你", Color("fff0c2"), 6)
	if world.waypoint != Vector2.INF and world_rect.has_point(world.waypoint):
		var destination: Vector2 = point_to_map(world.waypoint)
		draw_line(point_to_map(world.player.position), destination, Color(0.96, 0.78, 0.5, 0.5), 1)
		draw_arc(destination, 9, 0, TAU, 24, Color("f4cb8d"), 2)

func _marker(point: Vector2, title: String, color: Color, radius := 4.0) -> void:
	var position_in_map := point_to_map(point)
	draw_circle(position_in_map, radius+1.5,Color("697851"))
	draw_circle(position_in_map, radius, color)
	if title != "":
		var text_width := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		var candidates := [Vector2(9, -7), Vector2(-text_width - 9, -7), Vector2(9, 20), Vector2(-text_width - 9, 20), Vector2(9, -27), Vector2(-text_width - 9, -27), Vector2(9, 40)]
		for offset in candidates:
			var bounds := Rect2(position_in_map + offset - Vector2(0, 16), Vector2(text_width, 21))
			var overlaps := not map_rect.encloses(bounds)
			for existing in label_rects:
				if existing.grow(2).intersects(bounds):
					overlaps = true
			if overlaps:
				continue
			label_rects.append(bounds)
			if absf(offset.y) > 20:
				draw_line(position_in_map, position_in_map + offset - Vector2(2, 4), Color(color, 0.4), 1)
			draw_string_outline(font,position_in_map+offset,title,HORIZONTAL_ALIGNMENT_LEFT,-1,14,3,Color("ece7cb"))
			draw_string(font, position_in_map + offset, title, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("48563c"))
			break
	markers.append({"screen": position_in_map, "position": point, "name": title})

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if spawn_mode:
			var nearest := -1
			var distance := 18.0
			for i in spawn_options.size():
				var delta: float = event.position.distance_to(point_to_map(spawn_options[i]["position"]))
				if delta < distance:
					nearest = i
					distance = delta
			if nearest >= 0:
				spawn_selected.emit(nearest)
			accept_event()
			return
		if map_rect.has_point(event.position):
			world.waypoint = world_rect.position + (event.position - map_rect.position) / map_rect.size * world_rect.size
			for marker in markers:
				if event.position.distance_to(marker["screen"]) < 18:
					world.waypoint = marker["position"]
					break
			accept_event()
