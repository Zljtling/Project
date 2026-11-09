extends RefCounted
## Local layouts keep clear door approaches; identities are independent of world placement.
const NAMES := ["风车集镇", "东岸旧街", "南部农庄", "荒草聚落", "断桥街区", "苔石村"]
const HOUSES := [
	[Vector3(5,0,-2), Vector3(-15,0,-4), Vector3(15,0,-3), Vector3(-15,0,8), Vector3(14,0,9), Vector3(-6,0,-15), Vector3(6,0,-15)],
	[Vector3(-4,0,0), Vector3(4,0,-1), Vector3(-15,0,1), Vector3(14,0,1), Vector3(-13,0,12), Vector3(0,0,12), Vector3(13,0,12), Vector3(6,0,22)],
	[Vector3(-5,0,-2), Vector3(-17,0,-4), Vector3(-17,0,10), Vector3(-5,0,14), Vector3(15,0,-5), Vector3(15,0,11), Vector3(-6,0,-15), Vector3(7,0,-15)],
	[Vector3(4,0,-4), Vector3(-13,0,-13), Vector3(0,0,-16), Vector3(14,0,-14), Vector3(-15,0,10), Vector3(-2,0,10), Vector3(13,0,10), Vector3(-16,0,21)],
	[Vector3(-6,0,1), Vector3(-16,0,-12), Vector3(-16,0,1), Vector3(-16,0,14), Vector3(-7,0,15), Vector3(17,0,-12), Vector3(17,0,0), Vector3(17,0,13)]
]
const EXCLUSIONS := [
	[Rect2(-9,-7,8,8), Rect2(8,3,5,4), Rect2(-8,15,16,5)],
	[Rect2(-18,-20,36,17)],
	[Rect2(0,-7,6,6), Rect2(-1,1,11,8), Rect2(-9,1,6,4)],
	[Rect2(-7,-6,7,9)],
	[Rect2(-1,-17,12,35)]
]
const ROADS := [
	[[Vector2(0,-24),Vector2(0,24)], [Vector2(-25,5),Vector2(25,5)], [Vector2(-21,-10),Vector2(21,-10)]],
	[[Vector2(-25,6),Vector2(25,6)], [Vector2(-7,3),Vector2(-7,25)]],
	[[Vector2(-10,-25),Vector2(-10,25)], [Vector2(-25,9),Vector2(25,9)]],
	[[Vector2(-8,-25),Vector2(-8,25)], [Vector2(-25,5),Vector2(25,5)]],
	[[Vector2(-11,-25),Vector2(-11,25)], [Vector2(12,-25),Vector2(12,25)], [Vector2(-25,6),Vector2(0,6)], [Vector2(10,6),Vector2(25,6)]]
]

static func reserved(region: int, point: Vector2, margin := 0.0) -> bool:
	for at in HOUSES[region]:
		if Rect2(Vector2(at.x-4, at.z-3.5),Vector2(8,8)).grow(margin).has_point(point):
			return true
	for rect in EXCLUSIONS[region]:
		if rect.grow(margin).has_point(point):
			return true
	for road in ROADS[region]:
		if Geometry2D.get_closest_point_to_segment(point, road[0], road[1]).distance_to(point) < 2+margin:
			return true
	return false
