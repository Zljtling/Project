extends RefCounted
## Parked vehicles retain their own battery charge; the mounted HUD uses progression.
var parked: Array[Dictionary] = []
var active: Dictionary = {}

func populate(layout: ESWorldLayout) -> void:
	parked.clear()
	active = {}
	for village in layout.villages:
		var point: Vector2 = village["position"] + Vector2(40, 120)
		parked.append({"position": point, "battery": 100.0, "village": village["name"]})

func nearest(point: Vector2, radius := 90.0) -> Dictionary:
	var result: Dictionary = {}
	var closest := radius
	for bike in parked:
		var distance: float = point.distance_to(bike["position"])
		if distance <= closest:
			result = bike
			closest = distance
	return result
