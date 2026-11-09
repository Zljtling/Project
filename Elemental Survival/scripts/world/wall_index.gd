extends RefCounted
## Broad phase only; precise movement/LOS tests remain in WorldLayout.
const BUCKET := 256.0
var cells: Dictionary = {}

func rebuild(walls: Array[Rect2]) -> void:
	cells.clear()
	for i in walls.size():
		var start := Vector2i((walls[i].position/BUCKET).floor())
		var end := Vector2i((walls[i].end/BUCKET).floor())
		for x in range(start.x,end.x+1):
			for y in range(start.y,end.y+1):
				var key := Vector2i(x,y)
				if not cells.has(key):
					cells[key] = []
				cells[key].append(i)

func query(bounds: Rect2) -> Array:
	var found := {}
	var start := Vector2i((bounds.position/BUCKET).floor())
	var end := Vector2i((bounds.end/BUCKET).floor())
	for x in range(start.x,end.x+1):
		for y in range(start.y,end.y+1):
			for index in cells.get(Vector2i(x,y),[]):
				found[index] = true
	var result := found.keys()
	result.sort()
	return result
