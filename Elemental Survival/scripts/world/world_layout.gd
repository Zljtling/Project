class_name ESWorldLayout
extends RefCounted
const TowerLayout = preload("res://scripts/regions/tower/tower_layout.gd")

# Gameplay geometry is shared by characters and navigation. Art may replace
# these whitebox walls without changing the exploration rules.
const CELL := 40.0
var grid_step := CELL
var map_size := Vector2(16000, 12000)
var villages: Array[Dictionary] = []
var houses: Array[Rect2] = []
var walls: Array[Rect2] = []
var static_walls: Array[Rect2] = []
var dynamic_walls: Array[Rect2] = []
var castle := Rect2()
var navigation := AStarGrid2D.new()
var roads: Array[PackedVector2Array] = []
var generation_seed := 0
var wall_index := preload("res://scripts/world/wall_index.gd").new()

func _init(seed_value := 0) -> void:
	generation_seed = seed_value
	var centers := [Vector2(1500, 1500), Vector2(4000, 1250), Vector2(6700, 3100), Vector2(3700, 4750), Vector2(1200, 4400), Vector2(5300, 3200)]
	var names := ["苔石村", "风车集镇", "东岸旧街", "南部农庄", "荒草聚落", "断桥街区"]
	if seed_value != 0:
		var random := RandomNumberGenerator.new()
		random.seed = seed_value
		for i in range(names.size()-1, 0, -1):
			var other := random.randi_range(0, i)
			var swap: String = names[i]
			names[i] = names[other]
			names[other] = swap
		for i in centers.size():
			centers[i] += Vector2(random.randf_range(-160, 160), random.randf_range(-160, 160))
	for i in centers.size():
		var center: Vector2 = centers[i]
		villages.append({"position": center, "name": names[i]})
		# Four blocks around a broad cross street; gaps between homes form alleys.
		for offset in [Vector2(-430, -350), Vector2(190, -350), Vector2(-430, 140), Vector2(190, 140)]:
			var house := Rect2(center + offset, Vector2(240, 210))
			houses.append(house)
			_add_house(house, i % 2 == 0)
	static_walls.assign(walls)
	configure_navigation(CELL)
	_rebuild_roads()

func configure_navigation(step: float) -> void:
	grid_step = step
	navigation.region = Rect2i(Vector2i.ZERO, Vector2i(map_size / grid_step))
	navigation.cell_size = Vector2(grid_step, grid_step)
	navigation.offset = Vector2(grid_step, grid_step) * 0.5
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	navigation.update()
	_rebuild_navigation()

func _add_house(rect: Rect2, side_door: bool) -> void:
	var p := rect.position
	var s := rect.size
	walls.append(Rect2(p, Vector2(s.x, 24)))
	walls.append(Rect2(p, Vector2(24, s.y)))
	# Two entrances prevent one-door rooms from becoming unavoidable dead ends.
	walls.append(Rect2(p + Vector2(s.x - 24, 0), Vector2(24, 65 if side_door else s.y)))
	if side_door:
		walls.append(Rect2(p + Vector2(s.x - 24, 155), Vector2(24, s.y - 155)))
	walls.append(Rect2(p + Vector2(0, s.y - 24), Vector2(65, 24)))
	walls.append(Rect2(p + Vector2(175, s.y - 24), Vector2(s.x - 175, 24)))

func set_castle(center: Vector2) -> void:
	walls.assign(static_walls)
	walls.append_array(dynamic_walls)
	castle = Rect2(center+TowerLayout.BOUNDS.position,TowerLayout.BOUNDS.size)
	walls.append_array(TowerLayout.collision_rects(center))
	_rebuild_navigation()

func _rebuild_navigation() -> void:
	wall_index.rebuild(walls)
	navigation.fill_solid_region(navigation.region, false)
	for wall in walls:
		var padded := wall.grow(18)
		var start := Vector2i((padded.position - navigation.offset) / grid_step).clamp(Vector2i.ZERO, navigation.region.end - Vector2i.ONE)
		var end := Vector2i(padded.end / grid_step).clamp(Vector2i.ZERO, navigation.region.end - Vector2i.ONE)
		for x in range(start.x, end.x + 1):
			for y in range(start.y, end.y + 1):
				if padded.has_point(navigation.get_point_position(Vector2i(x, y))):
					navigation.set_point_solid(Vector2i(x, y))

func _rebuild_roads() -> void:
	roads.clear()
	if villages.is_empty():
		return
	# The shared navigation geometry supplies connected, traversable routes.
	# Ring edges close the loop; internal village streets keep their own width.
	for i in villages.size():
		var from: Vector2 = villages[i]["position"]
		var to: Vector2 = villages[(i+1)%villages.size()]["position"]
		var path := navigation.get_point_path(nearest_cell(from), nearest_cell(to))
		if path.size() > 1:
			roads.append(path)

func clear_point(point: Vector2, radius := 18.0) -> bool:
	if not Rect2(Vector2(radius, radius), map_size - Vector2.ONE * radius * 2).has_point(point):
		return false
	for index in wall_index.query(Rect2(point-Vector2.ONE*radius,Vector2.ONE*radius*2)):
		var wall := walls[index]
		if wall.grow(radius).has_point(point):
			return false
	return true

func resolve(point: Vector2, radius := 14.0) -> Vector2:
	point = point.clamp(Vector2.ONE * 35, map_size - Vector2.ONE * 35)
	for index in wall_index.query(Rect2(point-Vector2.ONE*(radius+80),Vector2.ONE*(radius+80)*2)):
		var wall := walls[index]
		var bounds := wall.grow(radius)
		if not bounds.has_point(point):
			continue
		var offsets := [point.x - bounds.position.x, bounds.end.x - point.x, point.y - bounds.position.y, bounds.end.y - point.y]
		match offsets.find(offsets.min()):
			0: point.x = bounds.position.x - 0.1
			1: point.x = bounds.end.x + 0.1
			2: point.y = bounds.position.y - 0.1
			3: point.y = bounds.end.y + 0.1
	return point

func move_actor(origin: Vector2, motion: Vector2) -> Vector2:
	# Substeps keep dash and fast knockback from passing through thin walls.
	var count := maxi(1, ceili(motion.length() / 10.0))
	var step := motion / count
	var point := origin
	for i in count:
		point = resolve(point + Vector2(step.x, 0))
		point = resolve(point + Vector2(0, step.y))
	return point

func line_clear(origin: Vector2, target: Vector2) -> bool:
	for index in wall_index.query(Rect2(origin,Vector2.ZERO).expand(target).grow(18)):
		var wall := walls[index]
		var rect := wall.grow(18)
		if rect.has_point(origin) or rect.has_point(target) or Geometry2D.segment_intersects_segment(origin, target, rect.position, Vector2(rect.end.x, rect.position.y)) != null or Geometry2D.segment_intersects_segment(origin, target, Vector2(rect.end.x, rect.position.y), rect.end) != null or Geometry2D.segment_intersects_segment(origin, target, rect.end, Vector2(rect.position.x, rect.end.y)) != null or Geometry2D.segment_intersects_segment(origin, target, Vector2(rect.position.x, rect.end.y), rect.position) != null:
			return false
	return true

func nearest_cell(point: Vector2) -> Vector2i:
	var cell := Vector2i(point / grid_step).clamp(Vector2i.ZERO, navigation.region.end - Vector2i.ONE)
	if not navigation.is_point_solid(cell):
		return cell
	for radius in range(1, 8):
		for x in range(-radius, radius + 1):
			for y in range(-radius, radius + 1):
				var candidate := cell + Vector2i(x, y)
				if navigation.is_in_boundsv(candidate) and not navigation.is_point_solid(candidate):
					return candidate
	return cell

func direction_for(enemy: ESEnemy, destination: Vector2, delta: float) -> Vector2:
	enemy.navigation_left -= delta
	if enemy.navigation_left <= 0.0 or destination.distance_to(enemy.navigation_target) > 160:
		enemy.navigation_left = 0.65 + fmod(enemy.get_instance_id(), 11) * 0.03
		enemy.navigation_target = destination
		if line_clear(enemy.position, destination):
			enemy.navigation_path = PackedVector2Array()
		else:
			enemy.navigation_path = navigation.get_point_path(nearest_cell(enemy.position), nearest_cell(destination), true)
			if not enemy.navigation_path.is_empty():
				enemy.navigation_path.remove_at(0)
	while not enemy.navigation_path.is_empty() and enemy.position.distance_to(enemy.navigation_path[0]) < 14:
		enemy.navigation_path.remove_at(0)
	var goal := destination if enemy.navigation_path.is_empty() else enemy.navigation_path[0]
	return enemy.position.direction_to(goal)
