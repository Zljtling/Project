extends Node3D
## Review-scene cache placement uses safe room sockets, never doorway coordinates.
## Interactions here validate space/use; gameplay rewards remain in the existing game.
signal searched(kind: String)
const Parts = preload("res://scripts/regions/shared/model_parts.gd")
const Rules = preload("res://scripts/growth/loot_rules.gd")
var caches: Array[Dictionary] = []
var ready_for_review := false

func populate(houses: Array[Node], seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var candidates: Array[Marker3D] = []
	for house in houses:
		if not house.has_node("LootSockets"):
			continue
		var sockets := house.get_node("LootSockets").get_children()
		candidates.append(sockets[rng.randi_range(0,sockets.size()-1)])
	for i in range(candidates.size()-1,0,-1):
		var j := rng.randi_range(0,i)
		var swap := candidates[i]
		candidates[i] = candidates[j]
		candidates[j] = swap
	var total := mini(candidates.size(),Rules.SUPPLIES+Rules.CHESTS)
	for i in total:
		var kind := "supply" if i < Rules.SUPPLIES else "chest"
		var at := candidates[i].global_position
		var node := Node3D.new()
		node.name = "RoomCache%d" % i
		add_child(node)
		node.global_position = at
		var surface := Parts.material(Color("b2a27f") if kind == "supply" else Color("bca161"),"wood",Vector3.ONE*0.5)
		Parts.box(node,"Container",Vector3(0.7,0.65,0.55),Vector3(0,0.325,0),surface,true)
		var band := Parts.material(Color("5b6b6b"))
		for x in [-0.22,0.22]:
			Parts.box(node,"Band",Vector3(0.06,0.69,0.58),Vector3(x,0.345,0),band)
		caches.append({"kind":kind,"node":node,"used":false,"socket":candidates[i]})
	ready_for_review = true

func nearest(point: Vector3) -> Dictionary:
	var found: Dictionary = {}
	var distance := 1.5
	for cache in caches:
		var delta: float = point.distance_to(cache["node"].global_position)
		if not cache["used"] and delta < distance:
			distance = delta
			found = cache
	return found

func search(point: Vector3) -> bool:
	var cache := nearest(point)
	if cache.is_empty():
		return false
	cache["used"] = true
	cache["node"].scale.y = 0.55
	searched.emit(cache["kind"])
	return true
