extends RefCounted
## Local metres. The same footprint drives liquid art, safe surfaces and damage.
const RADII := Vector2(29, 25)
const WIDTH := 2.6
const ISLANDS := [Vector3(-17,0,0),Vector3(-5,0,0),Vector3(7,0,0),Vector3(19,0,0),Vector3(-5,0,-10),Vector3(7,0,11)]
const ISLAND_RADII := [3.4,4.1,3.8,3.4,3.6,3.8]
const LINKS := [
	[Vector2(-32,0),Vector2(-17,0)], [Vector2(-17,0),Vector2(-5,0)],
	[Vector2(-5,0),Vector2(7,0)], [Vector2(7,0),Vector2(19,0)],
	[Vector2(19,0),Vector2(32,0)], [Vector2(-5,0),Vector2(-5,-10)],
	[Vector2(-5,-10),Vector2(0,-28)], [Vector2(7,0),Vector2(7,11)],
	[Vector2(7,11),Vector2(14,27)]
]

static func shore_radius(angle: float) -> float:
	return 1.0 + 0.035*sin(angle*5.0)+0.022*cos(angle*9.0)

static func in_pool(point: Vector2) -> bool:
	var normalized := point / RADII
	return normalized.length() < shore_radius(normalized.angle())

static func is_safe(point: Vector2, margin := 0.0) -> bool:
	for i in ISLANDS.size():
		var center := Vector2(ISLANDS[i].x,ISLANDS[i].z)
		if point.distance_to(center) <= ISLAND_RADII[i]-margin:
			return true
	for link in LINKS:
		if Geometry2D.get_closest_point_to_segment(point,link[0],link[1]).distance_to(point) <= WIDTH*0.5-margin:
			return true
	return false

static func hazardous(point: Vector2) -> bool:
	return in_pool(point) and not is_safe(point)

static func surface_height(point: Vector2) -> float:
	for link in LINKS:
		var nearest := Geometry2D.get_closest_point_to_segment(point,link[0],link[1])
		if nearest.distance_to(point) < WIDTH*0.5:
			var fraction: float = link[0].distance_to(nearest)/link[0].distance_to(link[1])
			return 0.18+sin(fraction*PI)*0.45
	return 0.18
