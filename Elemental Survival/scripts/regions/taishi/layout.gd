extends RefCounted
## Sample composition data. Reused by ground, props and vegetation placement.
const EXTRA_HOUSES := [Vector3(-6, 0, -12), Vector3(6, 0, -15), Vector3(-16, 0, 1)]
const TREES := [Vector3(-13, 0, -6), Vector3(-12, 0, 5), Vector3(12, 0, -9), Vector3(14, 0, 3), Vector3(-8, 0, -20), Vector3(7, 0, -22), Vector3(-18, 0, -9), Vector3(18, 0, 7), Vector3(-15, 0, 11), Vector3(-20, 0, 8), Vector3(-22, 0, -3), Vector3(18, 0, -14), Vector3(16, 0, -20), Vector3(-16, 0, -18), Vector3(3, 0, 16), Vector3(-5, 0, 16), Vector3(21, 0, 6), Vector3(21, 0, -3), Vector3(-23, 0, -16), Vector3(-23, 0, 15), Vector3(19, 0, 17), Vector3(11, 0, 19)]
const HOUSE_CENTERS := [Vector3(-6, 0, -1), Vector3(6, 0, -4), Vector3(-6, 0, -12), Vector3(6, 0, -15), Vector3(-16, 0, 1)]
const POND := Vector2(13.5, 11.5)

static func on_road(p: Vector2) -> bool:
	return absf(p.x) < 2.7 or absf(p.y - 3.5) < 1.5 or (p.y > -10.5 and p.y < -8.5 and absf(p.x) < 10)

static func in_house(p: Vector2, margin := 0.0) -> bool:
	for center in HOUSE_CENTERS:
		if absf(p.x - center.x) < 3.5 + margin and absf(p.y - center.z) < 3 + margin:
			return true
	return false

static func in_pond(p: Vector2, margin := 0.0) -> bool:
	return ((p - POND) / Vector2(5.0 + margin, 3.4 + margin)).length_squared() < 1.0
