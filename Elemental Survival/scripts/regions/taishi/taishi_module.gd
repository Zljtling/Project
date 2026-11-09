extends Node3D
## Taishi content without a player, camera, UI or map boundary; safe to compose.
const Parts = preload("res://scripts/regions/shared/model_parts.gd")
const Layout = preload("res://scripts/regions/taishi/layout.gd")
var leaf_material: ShaderMaterial
var bounded := false

func _ready() -> void:
	var ground := preload("res://scripts/regions/taishi/ground.gd").new()
	ground.name = "Ground"
	ground.include_boundaries = bounded
	add_child(ground)
	add_child(preload("res://scripts/regions/taishi/props.gd").new())
	for i in Layout.HOUSE_CENTERS.size():
		var house := preload("res://scenes/regions/shared/stone_house.tscn").instantiate()
		house.name = "House%02d" % i
		house.position = Layout.HOUSE_CENTERS[i]
		house.variant = [0,0,1,2,3][i]
		house.roof_color = [Color("9ab2b2"),Color(1.15,0.85,0.85),Color("c2afa1"),Color("9fa7be"),Color("a4b7bf")][i]
		add_child(house)
	for at in Layout.TREES:
		var tree := preload("res://scripts/regions/shared/tree.gd").new()
		tree.position = at
		tree.leaf_material = leaf_material
		add_child(tree)
