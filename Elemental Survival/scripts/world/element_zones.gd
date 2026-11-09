extends RefCounted
## Seeded constrained sampling; no dependency on renderer or loot random streams.
const COUNT_PER_ELEMENT := 3
var entries: Array[Dictionary] = []
var cycle := -1

func rebuild(world: Node) -> void:
	if cycle == world.cycle_index and not entries.is_empty():
		return
	var random := RandomNumberGenerator.new()
	random.seed = world.layout.generation_seed ^ (world.cycle_index*104729)
	var next: Array[Dictionary] = []
	for element in ["poison","fire"]:
		for i in COUNT_PER_ELEMENT:
			var chosen := Vector2.INF
			for attempt in 2000:
				var at := Vector2(random.randf_range(1300,world.MAP_SIZE.x-1300),random.randf_range(1300,world.MAP_SIZE.y-1300))
				if world.started and at.distance_to(world.player.position) < 1400:
					continue
				if world.layout.villages.any(func(v: Dictionary): return at.distance_to(v["position"]) < 2050):
					continue
				if next.any(func(z: Dictionary): return at.distance_to(z["position"]) < 2250):
					continue
				if world.tower_locations().any(func(p: Vector2): return at.distance_to(p) < 1650):
					continue
				if entries.any(func(z: Dictionary): return at.distance_to(z["position"]) < 700):
					continue
				chosen = at
				break
			if chosen == Vector2.INF:
				# Preserve a valid layout atomically instead of partially moving zones.
				return
			next.append({"element":element,"position":chosen,"id":"%s_%d" % [element,i]})
	entries = next
	cycle = world.cycle_index

func centers(element: String) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for zone in entries:
		if zone["element"] == element:
			result.append(zone["position"])
	return result
