extends Node3D
## Own all replicated elemental modules and rebuild collision atomically on migration.
const G = preload("res://scripts/world/scene_geometry.gd")
var world: Node2D
var primary_poison: Node3D
var primary_fire: Node3D
var extra: Array[Node3D] = []
var signature := ""

func sync() -> bool:
	var key := str(world.zones.entries)
	if key == signature:
		return false
	signature = key
	for node in extra:
		node.free()
	extra.clear()
	var blockers: Array[Rect2] = []
	var unused: Array[Rect2] = []
	for element in ["poison","fire"]:
		var centers: Array[Vector2] = world.element_centers(element)
		for i in centers.size():
			var module: Node3D
			if i == 0:
				module = primary_poison if element == "poison" else primary_fire
			else:
				module = load("res://scripts/regions/elemental/%s_region.gd" % element).new()
				add_child(module)
				extra.append(module)
			module.position = G.point3(centers[i])
			G.collect(module,blockers,unused)
	world.layout.dynamic_walls.assign(blockers)
	world.layout.set_castle(world.tower_position)
	return true

func _process(_delta: float) -> void:
	visible = not world.in_dungeon
