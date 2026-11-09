extends Node3D
## Compose accepted regional modules around the live simulation. No second economy.
const Parts = preload("res://scripts/regions/shared/model_parts.gd")
const G = preload("res://scripts/world/scene_geometry.gd")
const Catalog = preload("res://scripts/regions/region_catalog.gd")
const Poison = preload("res://scripts/regions/elemental/poison_layout.gd")
var world: Node2D
var settlements: Node3D
var modules: Array[Node3D] = []
var homes: Array[Node3D] = []
var proxies: Dictionary = {}
var player_proxy: Node3D
var view_camera: Camera3D
var foliage: Node
var poison: Node3D
var fire: Node3D
var castle: Node3D
var facilities: Node3D
var devices: Node3D
var bikes: Node3D
var dungeon: Node3D
var effects: MeshInstance3D
var prism: Node3D
var door: Node3D
var armor: Array[Node3D] = []
var cached_cycle := -1
var device_key := ""
var tower_at := Vector2.INF
var dungeon_index := -1
var collision_domain := Vector2.INF
var field_set: Node3D
var surface_released := false
var meadow: MultiMeshInstance3D
var lighting: Node3D

func _ready() -> void:
	lighting = preload("res://scripts/presentation/world_lighting.gd").new()
	lighting.world = world
	add_child(lighting)
	var grass := ShaderMaterial.new()
	grass.shader = preload("res://assets/regions/shared/ground_grass.gdshader")
	Parts.box(self,"WorldGround",Vector3(580,0.4,455),Vector3(250,-0.2,187.5),grass)
	player_proxy = preload("res://scripts/presentation/runtime_actor.gd").new()
	player_proxy.actor = world.player
	player_proxy.is_player = true
	add_child(player_proxy)
	player_proxy.hide()
	var weapons := preload("res://scripts/presentation/orbit_weapons.gd").new()
	weapons.world = world
	add_child(weapons)
	view_camera = preload("res://scripts/regions/shared/review_camera.gd").new()
	view_camera.target = player_proxy
	view_camera.keyboard_zoom = false
	view_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	view_camera.size = 22
	view_camera.distance = 32
	view_camera.far = 220
	add_child(view_camera)
	view_camera.current = true
	lighting.camera = view_camera
	foliage = preload("res://scripts/regions/shared/foliage_visibility.gd").new()
	foliage.target = player_proxy
	foliage.camera = view_camera
	add_child(foliage)
	poison = preload("res://scripts/regions/elemental/poison_region.gd").new()
	poison.name = "PoisonRegion"
	add_child(poison)
	fire = preload("res://scripts/regions/elemental/fire_region.gd").new()
	fire.name = "FireRegion"
	add_child(fire)
	var hot := Parts.material(Color("694635"))
	field_set = preload("res://scripts/presentation/element_field_set.gd").new()
	field_set.world = world
	field_set.primary_poison = poison
	field_set.primary_fire = fire
	add_child(field_set)
	effects = preload("res://scripts/presentation/runtime_effects.gd").new()
	effects.world = world
	add_child(effects)
	prism = Node3D.new()
	add_child(prism)
	Parts.cylinder(prism,Vector3(0,1.1,0),0.4,0,1.4,Parts.material(Color("e2eaa2")))
	_label(prism,"稳相棱镜 · 按住 E 提取",Vector3(0,2.3,0))
	door = Node3D.new()
	add_child(door)
	for x in [-1.4,1.4]:
		Parts.box(door,"DoorPillar",Vector3(0.4,2.5,0.5),Vector3(x,1.25,0),hot)
	Parts.box(door,"DoorLintel",Vector3(3.2,0.45,0.5),Vector3(0,2.5,0),hot)
	_label(door,"地牢入口 · E",Vector3(0,3.2,0))
	for entry in [[world.ARMOR_PICKUP,"生化服",Color("a9c86a")],[world.FIRE_SUIT_PICKUP,"消防服",Color("dc976d")]]:
		var marker := Node3D.new()
		marker.position = G.point3(entry[0])
		add_child(marker)
		Parts.box(marker,"SuitCase",Vector3(0.7,0.65,0.5),Vector3(0,0.33,0),Parts.material(entry[2]))
		_label(marker,entry[1],Vector3(0,1.3,0))
		armor.append(marker)
	_hide_legacy_art()

func _hide_legacy_art() -> void:
	for child in world.get_children():
		if child is CanvasItem:
			child.hide()
	world.camera.enabled = false

func rebuild_settlements() -> void:
	if is_instance_valid(settlements):
		settlements.free()
	modules.clear()
	homes.clear()
	settlements = Node3D.new()
	settlements.name = "Settlements"
	add_child(settlements)
	var random := RandomNumberGenerator.new()
	random.seed = world.layout.generation_seed
	var anchors := [Vector2(1800,1800),Vector2(8000,1600),Vector2(14200,1800),Vector2(14200,10200),Vector2(8000,10400),Vector2(1800,10200)]
	world.layout.houses.clear()
	world.layout.walls.clear()
	for i in world.layout.villages.size():
		var village: Dictionary = world.layout.villages[i]
		village["position"] = anchors[i]+Vector2(random.randf_range(-45,45),random.randf_range(-45,45))
		var index: int = Catalog.NAMES.find(village["name"])
		var module: Node3D
		if index == 5:
			module = preload("res://scenes/regions/taishi/taishi_module.tscn").instantiate()
		else:
			module = preload("res://scripts/regions/region_module.gd").new()
			module.region = index
		module.leaf_material = foliage.leaf_material
		module.position = G.point3(village["position"])
		settlements.add_child(module)
		modules.append(module)
		G.collect(module,world.layout.walls,world.layout.houses)
		for child in module.get_children():
			if child.is_in_group("enterable_house"):
				homes.append(child)
	world.layout.static_walls.assign(world.layout.walls)
	world.layout.configure_navigation(20)
	world.layout.set_castle(world.tower_position)
	world.layout._rebuild_roads()
	# Long roads follow the same traversable AStar paths shown on the map.
	var road_material := Parts.material(Color("b3a285"),"dirt",Vector3.ONE*0.4)
	for road in world.layout.roads:
		var start := 0
		for i in range(1,road.size()):
			if i < road.size()-1 and (road[i]-road[i-1]).normalized().is_equal_approx((road[i+1]-road[i]).normalized()):
				continue
			var a := G.point3(road[start])
			var b := G.point3(road[i])
			var strip := Parts.box(settlements,"WorldRoad",Vector3(a.distance_to(b)+0.03,0.018,1.5),(a+b)*0.5+Vector3(0,0.008,0),road_material)
			strip.rotation.y = -Vector2.RIGHT.angle_to(road[i]-road[start])
			start = i
	cached_cycle = -1
	if is_instance_valid(meadow):
		meadow.free()
	meadow = preload("res://scripts/presentation/meadow_dressing.gd").new()
	meadow.world = world
	add_child(meadow)
	meadow.populate()

func _process(delta: float) -> void:
	# Hide only legacy canvas art; simulation and HUD retain their existing nodes.
	_hide_legacy_art()
	player_proxy.sync(delta,_surface_height(world.player.position))
	if not world.started:
		return
	if world.in_dungeon:
		if not surface_released:
			_release_surface()
		door.position = G.point3(world.dungeon_door())
		_sync_actors(delta)
		_sync_devices()
		if dungeon_index != world.dungeon_room:
			_build_dungeon()
		return
	poison.position = G.point3(world.field_center("poison"))
	fire.position = G.point3(world.field_center("fire"))
	poison.visible = not world.in_dungeon
	fire.visible = not world.in_dungeon
	prism.visible = not world.in_dungeon and not world.objectives.found["prism"]
	prism.position = G.point3(world.objectives.prism_position(),0.2)
	armor[0].visible = not world.in_dungeon and not world.player.armor_owned
	armor[1].visible = not world.in_dungeon and not world.player.fire_armor_owned
	door.position = G.point3(world.dungeon_door() if world.in_dungeon else world.ENTRANCE)
	_sync_actors(delta)
	for home in homes:
		var local_point: Vector3 = home.to_local(player_proxy.position)
		var inside: bool = absf(local_point.x) < 3.4 and absf(local_point.z) < 3.3 and not world.in_dungeon
		home.roof.visible = not inside
		home.front.visible = not inside
	if cached_cycle != world.cycle_index:
		_rebuild_facilities()
		cached_cycle = world.cycle_index
	for i in world.facilities.size():
		var node: Node3D = facilities.get_child(i)
		node.position = G.point3(world.facilities[i]["position"],_surface_height(world.facilities[i]["position"]))
		node.visible = not world.in_dungeon and not world.facilities[i]["used"]
	if tower_at != world.tower_position:
		_build_castle()
	castle.visible = not world.in_dungeon
	castle.position.y = -castle.SINK_DEPTH*smoothstep(0.0,1.0,1.0-world.sinking_left/world.tower_sink_duration) if world.sinking_left > 0 else 0.0
	_sync_devices()
	_sync_bikes()
	if world.in_dungeon and dungeon_index != world.dungeon_room:
		_build_dungeon()
	if is_instance_valid(dungeon):
		dungeon.visible = world.in_dungeon

func sync_element_geometry() -> void:
	if collision_domain == Vector2.INF:
		field_set.signature = ""
	if field_set.sync():
		collision_domain = world.field_center("poison")
		if is_instance_valid(meadow):
			meadow.populate()

func _release_surface() -> void:
	surface_released = true
	homes.clear()
	modules.clear()
	for node in [settlements,meadow,poison,fire,field_set,castle,facilities,bikes,prism]:
		if is_instance_valid(node):
			node.queue_free()
	for marker in armor:
		marker.queue_free()
	armor.clear()

func _surface_height(point: Vector2) -> float:
	if world.in_dungeon:
		return 0.0
	for center in world.element_centers("poison"):
			var local: Vector2 = (point-center)/G.UNITS
			if Poison.in_pool(local) and Poison.is_safe(local):
				return Poison.surface_height(local)
	return 0.0

func _sync_actors(delta: float) -> void:
	var live := {}
	for enemy in world.enemies:
		if not is_instance_valid(enemy) or not enemy.alive:
			continue
		var id: int = enemy.get_instance_id()
		live[id] = true
		if not proxies.has(id):
			var proxy := preload("res://scripts/presentation/runtime_actor.gd").new()
			proxy.actor = enemy
			add_child(proxy)
			proxies[id] = proxy
		proxies[id].sync(delta,_surface_height(enemy.position))
	for id in proxies.keys():
		if not live.has(id):
			proxies[id].queue_free()
			proxies.erase(id)

func _rebuild_facilities() -> void:
	if is_instance_valid(facilities):
		facilities.free()
	facilities = Node3D.new()
	add_child(facilities)
	for item in world.facilities:
		var holder := Node3D.new()
		facilities.add_child(holder)
		var colors := {"chest":Color("bc9763"),"supply":Color("819b81"),"shop":Color("678f96"),"forge":Color("8f7c71")}
		var kind: String = item["kind"]
		var material := Parts.material(colors[kind])
		if kind in ["chest","supply"]:
			Parts.box(holder,"Container",Vector3(0.9,0.65,0.65),Vector3(0,0.325,0),material)
			for x in [-0.3,0.3]:
				Parts.box(holder,"MetalBand",Vector3(0.08,0.69,0.69),Vector3(x,0.345,0),Parts.material(Color("52594f")))
		else:
			Parts.box(holder,"Facility",Vector3(1,1.8,0.7),Vector3(0,0.9,0),material)
			Parts.box(holder,"Display",Vector3(0.7,0.65,0.04),Vector3(0,1.25,0.38),Parts.material(Color("b9cfad")))
		if kind == "chest":
			Parts.box(holder,"ChestLid",Vector3(0.98,0.2,0.71),Vector3(0,0.69,0),Parts.material(Color("bd925b")))
			Parts.box(holder,"GoldenLatch",Vector3(0.17,0.25,0.08),Vector3(0,0.5,0.37),Parts.material(Color("efd48d")))
		var marker := preload("res://scripts/presentation/interaction_marker.gd").new()
		marker.world = world
		marker.kind = kind
		holder.add_child(marker)

func _sync_devices() -> void:
	var signature := ""
	for device in world.skills.devices:
		signature += str(device["position"])+device["kind"]
	if signature == device_key:
		return
	device_key = signature
	if is_instance_valid(devices):
		devices.free()
	devices = Node3D.new()
	add_child(devices)
	for device in world.skills.devices:
		var holder := Node3D.new()
		holder.position = G.point3(device["position"],_surface_height(device["position"]))
		devices.add_child(holder)
		var material := Parts.material(Color("759b9e"))
		Parts.cylinder(holder,Vector3(0,0.35,0),0.5,0.3,0.7,material)
		Parts.box(holder,"Turret" if device["kind"] == "turret" else "Decoy",Vector3(0.9,0.45,0.6),Vector3(0,0.9,0),material)
		if device["kind"] == "turret":
			Parts.box(holder,"Cannon",Vector3(0.25,0.22,0.9),Vector3(0,1,-0.65),material)
		_label(holder,"炮台" if device["kind"] == "turret" else "诱饵",Vector3(0,1.6,0))

func _sync_bikes() -> void:
	if not is_instance_valid(bikes) or bikes.get_child_count() != world.fleet.parked.size()+int(world.riding):
		if is_instance_valid(bikes):
			bikes.free()
		bikes = Node3D.new()
		add_child(bikes)
		for i in world.fleet.parked.size()+int(world.riding):
			var holder := Node3D.new()
			bikes.add_child(holder)
			var frame := Parts.material(Color("718f8b"))
			for z in [-0.55,0.55]:
				var wheel := Parts.cylinder(holder,Vector3(0,0.32,z),0.32,0.32,0.16,Parts.material(Color("333d3e")))
				wheel.rotation.z = PI/2
			Parts.box(holder,"BikeBody",Vector3(0.4,0.4,1.05),Vector3(0,0.55,0),frame)
			Parts.box(holder,"BikeSeat",Vector3(0.48,0.12,0.6),Vector3(0,0.88,0.25),frame)
			Parts.box(holder,"Handlebar",Vector3(0.8,0.1,0.1),Vector3(0,1.1,-0.55),frame)
			_label(holder,"电动车 · R",Vector3(0,1.9,0))
	var index := 0
	for bike in world.fleet.parked:
		bikes.get_child(index).position = G.point3(bike["position"])
		index += 1
	if world.riding:
		bikes.get_child(index).position = G.point3(world.player.position)
	bikes.visible = not world.in_dungeon

func _build_castle() -> void:
	if is_instance_valid(castle):
		castle.free()
	castle = preload("res://scripts/regions/tower/tower_region.gd").new()
	castle.position = G.point3(world.tower_position)
	castle.target = player_proxy
	castle.camera = view_camera
	add_child(castle)
	tower_at = world.tower_position
	_label(castle,"迁移高塔 · 废城堡",Vector3(0,1.2,-1))

func _build_dungeon() -> void:
	if is_instance_valid(dungeon):
		dungeon.free()
	dungeon = preload("res://scripts/regions/dungeon/dungeon_room.gd").new()
	dungeon.layout = world.dungeon_layout
	dungeon.room_index = world.dungeon_room
	add_child(dungeon)
	dungeon_index = world.dungeon_room

func _label(parent: Node3D, text: String, at: Vector3) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = at
	label.font = world.font
	label.font_size = 24
	label.pixel_size = 0.012
	label.outline_size = 5
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(label)
	return label
