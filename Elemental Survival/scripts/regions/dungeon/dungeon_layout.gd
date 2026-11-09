extends RefCounted
## One room owns one blocker; simulation and presentation share its footprint.
const SIZE := Vector2(1100,1000)
const BLOCKER := Rect2(430,380,240,180)
const NAMES := ["断柱回廊","废弃工坊","出口大厅"]
const CELL := 40.0
var room: Rect2
var obstacle: Rect2
var navigation := AStarGrid2D.new()

func _init(bounds: Rect2) -> void:
	room = bounds
	obstacle = Rect2(room.position+BLOCKER.position,BLOCKER.size)
	navigation.region = Rect2i(Vector2i(room.position/CELL),Vector2i((room.size/CELL).ceil()))
	navigation.cell_size = Vector2.ONE*CELL
	navigation.offset = Vector2.ONE*CELL*0.5
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	navigation.update()
	for x in range(navigation.region.position.x,navigation.region.end.x):
		for y in range(navigation.region.position.y,navigation.region.end.y):
			var cell := Vector2i(x,y)
			navigation.set_point_solid(cell,not clear_point(navigation.get_point_position(cell),18))

func clear_point(point: Vector2, radius := 14.0) -> bool:
	return room.grow(-45).has_point(point) and not obstacle.grow(radius).has_point(point)

func resolve(point: Vector2) -> Vector2:
	point = point.clamp(room.position+Vector2.ONE*45,room.end-Vector2.ONE*45)
	var padded := obstacle.grow(14)
	if padded.has_point(point):
		var distances := [point.x-padded.position.x,padded.end.x-point.x,point.y-padded.position.y,padded.end.y-point.y]
		match distances.find(distances.min()):
			0: point.x = padded.position.x-0.1
			1: point.x = padded.end.x+0.1
			2: point.y = padded.position.y-0.1
			3: point.y = padded.end.y+0.1
	return point

func move_actor(origin: Vector2, motion: Vector2) -> Vector2:
	var steps := maxi(1,ceili(motion.length()/10.0))
	var step := motion/steps
	var point := resolve(origin)
	for i in steps:
		point = resolve(point+Vector2(step.x,0))
		point = resolve(point+Vector2(0,step.y))
	return point

func line_clear(origin: Vector2, target: Vector2) -> bool:
	if not room.has_point(origin) or not room.has_point(target):
		return false
	var rect := obstacle.grow(18)
	if rect.has_point(origin) or rect.has_point(target):
		return false
	var corners := [rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]
	for i in 4:
		if Geometry2D.segment_intersects_segment(origin,target,corners[i],corners[(i+1)%4]) != null:
			return false
	return true

func nearest_cell(point: Vector2) -> Vector2i:
	var cell := Vector2i(resolve(point)/CELL).clamp(navigation.region.position,navigation.region.end-Vector2i.ONE)
	if not navigation.is_point_solid(cell):
		return cell
	for radius in range(1,5):
		for x in range(-radius,radius+1):
			for y in range(-radius,radius+1):
				var candidate := cell+Vector2i(x,y)
				if navigation.is_in_boundsv(candidate) and not navigation.is_point_solid(candidate):
					return candidate
	return cell

func direction_for(enemy: ESEnemy, destination: Vector2, delta: float) -> Vector2:
	enemy.navigation_left -= delta
	if enemy.navigation_left <= 0 or destination.distance_to(enemy.navigation_target) > 80:
		enemy.navigation_left = 0.35
		enemy.navigation_target = destination
		enemy.navigation_path = PackedVector2Array() if line_clear(enemy.position,destination) else navigation.get_point_path(nearest_cell(enemy.position),nearest_cell(destination))
	while not enemy.navigation_path.is_empty() and enemy.position.distance_to(enemy.navigation_path[0]) < 14:
		enemy.navigation_path.remove_at(0)
	var goal := destination if enemy.navigation_path.is_empty() else enemy.navigation_path[0]
	return enemy.position.direction_to(goal)
