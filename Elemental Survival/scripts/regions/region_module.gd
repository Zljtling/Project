extends Node3D
## Five authored regional landmark assemblies; shared primitives and house kit.
const Parts = preload("res://scripts/regions/shared/model_parts.gd")
const Catalog = preload("res://scripts/regions/region_catalog.gd")
const House = preload("res://scenes/regions/shared/stone_house.tscn")
@export_enum("风车集镇", "东岸旧街", "南部农庄", "荒草聚落", "断桥街区") var region := 0
var leaf_material: ShaderMaterial
var sails: Array[Node3D] = []

var wood := Parts.material(Color("bda69a"), "wood", Vector3.ONE * 0.4)
var stone := Parts.material(Color("a1ada9"), "stone", Vector3.ONE * 0.35)
var metal := Parts.material(Color("475b61"))

func _ready() -> void:
	match region:
		0: _windmill_town()
		1: _waterfront()
		2: _farm()
		3: _overgrown()
		4: _broken_bridge()
	var palettes := [Color("a3b8bd"),Color("bba4b0"),Color("bcaa92"),Color("849889"),Color("a7a4b3")]
	for i in Catalog.HOUSES[region].size():
		var home := _house(Catalog.HOUSES[region][i],palettes[(region+i%2)%5],i%4)
		home.name = "House%02d" % i
	var dressing := preload("res://scripts/regions/region_dressing.gd").new()
	dressing.name = "Dressing"
	dressing.region = region
	dressing.leaf_material = leaf_material
	add_child(dressing)
	set_process(region == 0)

func _process(delta: float) -> void:
	for blade in sails:
		blade.rotation.z += delta*0.19

func _house(at: Vector3, color: Color, variant := 0) -> Node3D:
	var house := House.instantiate()
	house.position = at
	house.roof_color = color
	house.variant = variant
	house.weathered = region == 3 or (region == 4 and variant%2 == 0)
	house.wooden_walls = region == 2 and variant%2 == 0
	add_child(house)
	return house

func _windmill_town() -> void:
	var at := Vector3(-5, 0, -3)
	Parts.cylinder(self, at+Vector3(0, 2.8, 0), 1.5, 0.95, 5.6, stone, true)
	Parts.cylinder(self, at+Vector3(0, 6.2, 0), 1.5, 0, 1.6, metal)
	Parts.box(self, "MillServicePanel", Vector3(0.6, 0.7, 0.12), at+Vector3(0, 1.3, 1.45), wood)
	for i in 4:
		var blade := Node3D.new()
		blade.name = "WindmillBlade"
		blade.position = at+Vector3(0, 4.5, 1.7)
		blade.rotation.z = PI/4+i*PI/2
		add_child(blade)
		sails.append(blade)
		Parts.box(blade, "Spar", Vector3(0.13, 3.8, 0.14), Vector3(0, 1.7, 0), wood)
		for y in [1.0, 1.55, 2.1, 2.65, 3.2]:
			Parts.box(blade, "SailSlat", Vector3(0.75, 0.28, 0.12), Vector3(0.3, y, 0), wood)
	Parts.cylinder(self, at+Vector3(0, 4.5, 1.8), 0.23, 0.23, 0.25, metal).rotation.x = PI/2
	_stall(Vector3(10, 0, 5))
	_stall(Vector3(5, 0, 17))
	_stall(Vector3(-5, 0, 17))

func _stall(at: Vector3) -> void:
	Parts.box(self, "MarketCounter", Vector3(2.8, 0.9, 0.8), at+Vector3(0, 0.45, 0), wood, true)
	for x in [-1.5, 1.5]:
		Parts.box(self, "StallPost", Vector3(0.12, 2.5, 0.12), at+Vector3(x, 1.25, 0), wood)
	var canvas := Parts.material(Color("a18a79"))
	Parts.box(self, "MarketCanopy", Vector3(3.4, 0.14, 2), at+Vector3(0, 2.5, 0), canvas)
	for x in [-0.9, 0, 0.9]:
		Parts.box(self, "ProduceBox", Vector3(0.65, 0.22, 0.6), at+Vector3(x, 1, 0), wood)
		Parts.cylinder(self, at+Vector3(x, 1.2, 0), 0.21, 0.18, 0.25, Parts.material(Color("bbaa69")))

func _waterfront() -> void:
	Parts.box(self, "Water", Vector3(34, 0.01, 14), Vector3(0, 0.01, -12),_water_material())
	Parts.walkable_platform(self,"Quay",Vector2(23,2),Vector3(0,0,-4),stone)
	Parts.walkable_platform(self,"Pier",Vector2(3.4,8),Vector3(0,0,-8),wood)
	for x in [-1.8, 1.8]:
		for z in [-5, -8, -11]:
			Parts.cylinder(self, Vector3(x, 0.1, z), 0.16, 0.13, 1, wood)
	for i in 15:
		Parts.box(self, "PierPlank", Vector3(3.4, 0.035, 0.04), Vector3(0, 0.145, -4.1-i*0.5), metal)
	for x in [-9.0, 8.0]:
		Parts.box(self, "MooringBollard", Vector3(0.25, 0.6, 0.25), Vector3(x, 0.3, -3), metal)
	# Water barriers leave the pier corridor open.
	for x in [-9, 9]:
		var edge := Parts.box(self, "WaterBoundary", Vector3(14, 3, 14), Vector3(x, 1, -12), stone, true)
		edge.visible = false
	var end := Parts.box(self, "PierEndBoundary", Vector3(4, 3, 0.2), Vector3(0, 1, -12.1), stone, true)
	end.visible = false
	Parts.box(self, "WarehouseCrate", Vector3(1.2, 1.2, 1.2), Vector3(8, 0.6, 2), wood, true)
	Parts.box(self, "WarehouseCrate", Vector3(1, 1, 1), Vector3(9.3, 0.5, 2.3), wood, true)

func _farm() -> void:
	Parts.cylinder(self, Vector3(3, 2.5, -4), 1.3, 1.3, 5, stone, true)
	Parts.cylinder(self, Vector3(3, 5.5, -4), 1.5, 0, 1.2, metal)
	for y in [0.5, 2.4, 4.4]:
		Parts.cylinder(self, Vector3(3, y, -4), 1.33, 1.33, 0.08, metal)
	for z in range(2, 8):
		Parts.box(self, "TilledRow", Vector3(8, 0.05, 0.65), Vector3(4, 0.025, z), Parts.material(Color("72624e")))
		for x in range(1, 8):
			Parts.cylinder(self, Vector3(x, 0.3, z), 0.13, 0.04, 0.6, Parts.material(Color("83944e")))
	for at in [Vector3(-7, 0.45, 3), Vector3(-5.5, 0.45, 3), Vector3(-6.2, 1.35, 3)]:
		Parts.box(self, "HayBale", Vector3(1.3, 0.9, 0.85), at, Parts.material(Color("baaa6e")), true)
	for x in [-1.0, 9.0]:
		for z in [1.0, 4.0, 8.0]:
			Parts.box(self, "FarmFencePost", Vector3(0.12, 0.9, 0.12), Vector3(x, 0.45, z), wood, true)
		Parts.box(self, "FarmFenceRail", Vector3(0.1, 0.12, 7), Vector3(x, 0.6, 4.5), wood)

func _overgrown() -> void:
	for x in [-6.0, -2.0]:
		Parts.box(self, "AbandonedWall", Vector3(0.5, 1.6, 5), Vector3(x, 0.8, -2), stone, true)
	for i in 5:
		Parts.rock(self, Vector3(-6+i, 0, 1), Vector3(0.65, 0.4+(i%2)*0.3, 0.55), stone)
	Parts.box(self, "DoorwayRemnant", Vector3(4.4, 0.35, 0.5), Vector3(-4, 2.3, -4.5), stone)
	for x in [-6, -2]:
		Parts.box(self, "RuinedDoorpost", Vector3(0.45, 2.3, 0.5), Vector3(x, 1.15, -4.5), stone)
	var moss := Parts.material(Color("567455"))
	for i in 12:
		Parts.box(self, "WallMoss", Vector3(0.52, 0.12, 0.35), Vector3(-6, 0.5+(i%4)*0.3, -4+(i/4)*1.1), moss)
	for i in 3:
		var beam := Parts.box(self, "FallenBeam", Vector3(0.25, 0.25, 3), Vector3(-4+i*0.8, 0.2, 0), wood)
		beam.rotation.y = i*0.7

func _broken_bridge() -> void:
	Parts.box(self, "Ravine", Vector3(10, 0.08, 30), Vector3(5, -0.03, -1),_water_material())
	for x in [0.0, 10.0]:
		for segment in [Vector2(-16, -6), Vector2(-2, 4.7), Vector2(7.3, 14)]:
			Parts.box(self, "RetainingWall", Vector3(0.6, 0.5, segment.y-segment.x), Vector3(x, 0, segment.x*0.5+segment.y*0.5), stone, true)
	for x in [0.6, 8.9]:
		Parts.walkable_platform(self,"BrokenBridgeDeck",Vector2(3,3.8),Vector3(x,0,-4),stone)
		for z in [-6.0, -2.0]:
			Parts.box(self, "BridgeParapet", Vector3(3, 0.55, 0.3), Vector3(x, 0.6, z), stone, true)
	# A separate intact low crossing demonstrates a usable alternative route.
	Parts.walkable_platform(self,"DetourFootbridge",Vector2(11,2.4),Vector3(5,0,6),wood)
	for z in [4.7, 7.3]:
		Parts.box(self, "DetourRail", Vector3(11, 0.12, 0.12), Vector3(5, 0.85, z), wood)
	for segment in [Vector2(-16, -6), Vector2(-2, 4.7), Vector2(7.3, 18)]:
		var stop := Parts.box(self, "RavineBoundary", Vector3(9, 3, segment.y-segment.x), Vector3(5, 1, segment.x*0.5+segment.y*0.5), stone, true)
		stop.visible = false
	var stop := Parts.box(self, "BrokenSpanBoundary", Vector3(5.2, 3, 4), Vector3(4.75, 1, -4), stone, true)
	stop.visible = false

func _water_material() -> ShaderMaterial:
	var water := ShaderMaterial.new()
	water.shader = preload("res://assets/regions/shared/pond_water.gdshader")
	preload("res://scripts/regions/shared/material_animation.gd").attach(self,water)
	return water
