extends RefCounted
const Rules = preload("res://scripts/growth/loot_rules.gd")

static func build(world: Node) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var indoor_candidates: Array = world.indoor_loot_candidates() if world.has_method("indoor_loot_candidates") else []
	var order := [0, 1, 2, 3, 4, 5]
	for i in range(order.size()-1, 0, -1):
		var j: int = world.rng.randi_range(0, i)
		var swap: int = order[i]
		order[i] = order[j]
		order[j] = swap
	for i in Rules.SHOPS:
		var village: Dictionary = world.layout.villages[order[i]]
		var point := _village_point(world, village["position"], result)
		if point != Vector2.INF:
			result.append(_facility("shop", point, {"village": village["name"]}))
	for i in 4:
		var village: Dictionary = world.layout.villages[order[i]]
		var point := _village_point(world, village["position"], result)
		if point != Vector2.INF:
			result.append(_facility("forge", point))
	for kind in ["supply", "chest"]:
		for i in (Rules.SUPPLIES if kind == "supply" else Rules.CHESTS):
			var point := Vector2.INF
			for attempt in 400:
				var candidate := Vector2(world.rng.randf_range(260, world.MAP_SIZE.x-260), world.rng.randf_range(260, world.MAP_SIZE.y-260))
				if attempt < 100 and world.rng.randf() < 0.5:
					if not indoor_candidates.is_empty():
						candidate = indoor_candidates[world.rng.randi_range(0,indoor_candidates.size()-1)]
					else:
						var house: Rect2 = world.layout.houses[world.rng.randi_range(0,world.layout.houses.size()-1)]
						candidate = house.get_center()
				if not _valid(world, candidate, result, Rules.MIN_CACHE_DISTANCE):
					continue
				point = candidate
				break
			if point != Vector2.INF:
				result.append(_facility(kind, point, {"indoor": world.layout.houses.any(func(house: Rect2): return house.has_point(point))}))
	result.append(_facility("chest", world.tower_position + world.TowerLayout.CHEST, {"castle": true}))
	return result

static func _valid(world: Node, point: Vector2, existing: Array[Dictionary], distance: float) -> bool:
	var indoor: bool = world.has_method("indoor_loot_candidates") and world.layout.houses.any(func(house: Rect2): return house.has_point(point))
	if not world.layout.clear_point(point, 20 if indoor else 75):
		return false
	for center in world.tower_locations():
		if Rect2(center-Vector2(580, 540), Vector2(1160, 1080)).has_point(point):
			return false
	for facility in existing:
		var minimum := distance if facility["kind"] in ["chest", "supply"] else 120.0
		if point.distance_to(facility["position"]) < minimum:
			return false
	return true

static func _village_point(world: Node, center: Vector2, existing: Array[Dictionary]) -> Vector2:
	for offset in [Vector2(40, 260), Vector2(-180, 0), Vector2(350, 0), Vector2(40, -280), Vector2(-510, 100)]:
		if _valid(world, center+offset, existing, 140):
			return center+offset
	for radius in [320,480,640]:
		for i in 12:
			var point: Vector2 = center+Vector2.from_angle(i*TAU/12.0)*radius
			if _valid(world,point,existing,140):
				return point
	return Vector2.INF

static func _facility(kind: String, point: Vector2, extra := {}) -> Dictionary:
	var result := {"kind": kind, "position": point, "used": false, "seen": false}
	result.merge(extra)
	return result
