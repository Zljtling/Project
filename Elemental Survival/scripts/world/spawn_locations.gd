extends RefCounted
## Only authored settlements offer spawn choices. Danger exclusions still apply.
const EDGE_MARGIN := 100.0
const DANGER_MARGIN := 100.0
const SETTLEMENT_RADIUS := 600.0

static func is_safe(world: Node, point: Vector2) -> bool:
	if not point.is_finite() or not Rect2(Vector2.ONE * EDGE_MARGIN, world.MAP_SIZE - Vector2.ONE * EDGE_MARGIN * 2).has_point(point):
		return false
	if not world.layout.villages.any(func(village: Dictionary): return point.distance_to(village["position"]) <= SETTLEMENT_RADIUS):
		return false
	if not world.layout.clear_point(point, 35) or world.tower_rect().grow(120).has_point(point):
		return false
	for element in world.domains:
		var centers: Array = world.element_centers(element) if world.has_method("element_centers") else [world.domains[element]]
		for center in centers:
			if point.distance_to(center) < world.field_radius(element) + DANGER_MARGIN:
				return false
	for enemy in world.enemies:
		if enemy.alive and point.distance_to(enemy.position) < 180:
			return false
	for facility in world.facilities:
		if point.distance_to(facility["position"]) < 65:
			return false
	return true

static func choices(world: Node) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for village in world.layout.villages:
		var center: Vector2 = village["position"]
		var found := Vector2.INF
		for offset in [Vector2.ZERO, Vector2(40, 300), Vector2(40, -300), Vector2(-500, 0), Vector2(500, 0), Vector2(0, 550), Vector2(0, -550)]:
			if is_safe(world, center+offset):
				found = center+offset
				break
		# If a prop/enemy occupies the preferred landing, search inside this settlement only.
		if found == Vector2.INF:
			for radius in [150.0,300.0,450.0,550.0]:
				for i in 24:
					var candidate: Vector2 = center+Vector2.from_angle(i*TAU/24.0)*radius
					if is_safe(world,candidate):
						found = candidate
						break
				if found != Vector2.INF:
					break
		if found != Vector2.INF:
			result.append({"name": village["name"], "position": found, "kind": "village"})
	return result
