extends "res://scripts/run/run_flow.gd"
## Runtime adapter: existing planar combat + authored 3D geography/presentation.
const Geometry = preload("res://scripts/world/scene_geometry.gd")
const PoisonLayout = preload("res://scripts/regions/elemental/poison_layout.gd")
var presentation: Node3D
var zones := preload("res://scripts/world/element_zones.gd").new()
var hostile_patterns := preload("res://scripts/combat/enemy_patterns.gd").new()

func enemy_patterns() -> RefCounted:
	return hostile_patterns

func _open_room(index: int) -> void:
	hostile_patterns.hazards.clear()
	super._open_room(index)

func surface_map_markers() -> Array[Dictionary]:
	var result := super.surface_map_markers()
	for element in ["poison","fire"]:
		var centers := element_centers(element)
		for i in range(1,centers.size()):
			result.append({"kind":"domain","position":centers[i],"name":("毒领域" if element == "poison" else "火领域")+str(i+1)})
	return result

func enter_dungeon() -> bool:
	var result := super.enter_dungeon()
	if result:
		hostile_patterns.hazards.clear()
	return result

func _ready() -> void:
	tower_position = tower_locations()[0]
	super._ready()
	presentation = preload("res://scripts/presentation/runtime_world.gd").new()
	presentation.name = "GameWorld3D"
	presentation.world = self
	add_child(presentation)
	camera.enabled = false
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-game="):
			capture_game.call_deferred(argument.get_slice("=",1))

func tower_locations() -> Array:
	return [Vector2(8000,6000),Vector2(8000,4500),Vector2(8000,7500)]

func prepare_map(seed_value: int) -> void:
	if started:
		return
	layout = ESWorldLayout.new(seed_value)
	rng.seed = seed_value
	zones = preload("res://scripts/world/element_zones.gd").new()
	presentation.rebuild_settlements()
	for element in domains:
		domains[element] = _domain_location(element)
	presentation.collision_domain = Vector2.INF
	presentation.sync_element_geometry()
	_reset_facilities(false)
	fleet.populate(layout)
	for bike in fleet.parked:
		bike["position"] = layout.resolve(bike["position"])
	for enemy in enemies:
		if enemy.has_meta("castle_elite"):
			enemy.home = tower_position+TowerLayout.ELITE
			enemy.position = layout.resolve(enemy.home)
	waypoint = Vector2.INF

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if started and not run_over:
		hostile_patterns.update(self,delta)
	if started and not in_dungeon and is_instance_valid(presentation):
		presentation.sync_element_geometry()

func _domain_location(element: String) -> Vector2:
	zones.rebuild(self)
	var positions := zones.centers(element)
	return positions[0] if not positions.is_empty() else INITIAL_DOMAINS[element]

func element_centers(element: String) -> Array[Vector2]:
	var positions := zones.centers(element)
	return positions if not positions.is_empty() else [field_center(element)]

func field_contains(element: String, point: Vector2) -> bool:
	if element == "poison":
		for center in element_centers(element):
			if PoisonLayout.hazardous((point-center)/Geometry.UNITS):
				return true
		return false
	return element_centers(element).any(func(center: Vector2): return point.distance_to(center) < field_radius(element))

func poison_prism_position() -> Vector2:
	var at: Vector3 = PoisonLayout.ISLANDS[4]
	return field_center("poison")+Vector2(at.x,at.z)*Geometry.UNITS

func material_region_contains(element: String, point: Vector2) -> bool:
	if element == "poison":
		return element_centers(element).any(func(center: Vector2): return PoisonLayout.in_pool((point-center)/Geometry.UNITS))
	return super.material_region_contains(element,point)

func poison_map_geometry() -> Dictionary:
	var outline := PackedVector2Array()
	var routes: Array[PackedVector2Array] = []
	var rocks: Array[Dictionary] = []
	var center := field_center("poison")
	for i in 96:
		var angle := i*TAU/96.0
		outline.append(center+Vector2(cos(angle),sin(angle))*PoisonLayout.RADII*PoisonLayout.shore_radius(angle)*Geometry.UNITS)
	for link in PoisonLayout.LINKS:
		routes.append(PackedVector2Array([center+link[0]*Geometry.UNITS,center+link[1]*Geometry.UNITS]))
	for i in PoisonLayout.ISLANDS.size():
		var at: Vector3 = PoisonLayout.ISLANDS[i]
		rocks.append({"position":center+Vector2(at.x,at.z)*Geometry.UNITS,"radius":PoisonLayout.ISLAND_RADII[i]*Geometry.UNITS})
	return {"outline":outline,"routes":routes,"rocks":rocks}

func indoor_loot_candidates() -> Array:
	var result: Array = []
	if is_instance_valid(presentation):
		for home in presentation.homes:
			for socket in home.get_node("LootSockets").get_children():
				result.append(Geometry.point2(socket.global_position))
	return result

func nearest_facility() -> Dictionary:
	for facility in facilities:
		if not facility["used"] and player.position.distance_to(facility["position"]) < 80 and line_of_sight(player.position,facility["position"]):
			return facility
	return {}

func movement_direction(input: Vector2) -> Vector2:
	if not is_instance_valid(presentation):
		return input
	var basis: Basis = presentation.view_camera.global_basis
	return (Vector2(basis.x.x,basis.x.z).normalized()*input.x+Vector2(basis.z.x,basis.z.z).normalized()*input.y).limit_length()

func _unhandled_input(event: InputEvent) -> void:
	if started and not run_over and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT and is_instance_valid(presentation):
		var view: Camera3D = presentation.view_camera
		var hit = Plane(Vector3.UP,0).intersects_ray(view.project_ray_origin(event.position),view.project_ray_normal(event.position))
		if hit != null:
			mark_at(Geometry.point2(hit))
		return
	super._unhandled_input(event)

func play_fx(id: String, point: Vector2, scale_value := 1.0) -> void:
	if is_instance_valid(presentation) and is_instance_valid(presentation.effects):
		presentation.effects.pulse(point,24*scale_value,Color("b3d6ae") if "poison" in id else Color("e6c38f"))

func capture_game(kind: String) -> void:
	setup.open_loadout()
	if kind in ["art","forge","inventory"]:
		setup.starter = "needle"
	setup.prepare_escape(20261102)
	setup.select_spawn(0)
	setup.confirm_spawn()
	player.set_physics_process(false)
	spawn_clock = 9999
	player.contact_grace = 9999
	if kind in ["fire","fire-close"]:
		player.position = field_center("fire")+Vector2(0,1100)
		if kind == "fire-close":
			player.position = field_center("fire")+Vector2(4,18)*Geometry.UNITS
	elif kind == "poison" or kind == "poison-close":
		player.position = field_center("poison")+Vector2(-5,0)*Geometry.UNITS
	elif kind == "village":
		player.position = layout.villages[0]["position"]+Vector2(0,500)
	elif kind == "room":
		for facility in facilities:
			if facility.get("indoor",false):
				player.position = facility["position"]+Vector2(24,0)
				break
	elif kind == "dungeon":
		for part in objectives.PARTS:
			objectives.acquire(part)
		player.position = ENTRANCE
		enter_dungeon()
		skills.selected[0] = "turret"
		skills.cast(0)
	elif kind in ["art","forge","inventory"]:
		player.position = layout.villages[0]["position"]+Vector2(0,750)
		if kind == "art":
			var nearby := 0
			for facility in facilities:
				if nearby < 2 and facility["kind"] == ("supply" if nearby == 0 else "chest"):
					facility["position"] = player.position+(Vector2(-100,70) if nearby == 0 else Vector2(100,-170))
					nearby += 1
		for index in 6:
			var foe := spawn_enemy(player.position+Vector2(150+index*35,-80+index*35))
			foe.set_physics_process(false)
		for entry in [["hunter","",Vector2(-150,-70)],["guardian","poison",Vector2(-130,120)],["guardian","fire",Vector2(220,140)]]:
			var boss := spawn_boss(entry[0],entry[1])
			boss.position = layout.resolve(player.position+entry[2])
			boss.set_physics_process(false)
		arsenal.attack(arsenal.specs[0],enemies[1],0)
		arsenal._physics_process(0.1)
		arsenal.set_physics_process(false)
	presentation.view_camera.set_process(false)
	for i in 8:
		await get_tree().process_frame
	var focus := Geometry.point3(field_center("poison"),0.5) if kind.begins_with("poison") else Geometry.point3(layout.villages[0]["position"],0.5)
	if kind == "fire":
		focus = Geometry.point3(field_center("fire"),0.5)
	var distance := 100.0 if kind == "poison" else 44.0 if kind == "poison-close" else 78.0
	presentation.view_camera.size = 74.0 if kind == "poison" else 32.0 if kind == "poison-close" else 58.0
	if kind == "fire":
		presentation.view_camera.size = 74
		distance = 100
	elif kind == "fire-close":
		focus = Geometry.point3(player.position,0.8)
		presentation.view_camera.size = 24
		distance = 38
	if kind in ["room","dungeon"]:
		focus = Geometry.point3(player.position,0.5)
		distance = 25.0 if kind == "room" else 38.0
		presentation.view_camera.size = 19.0 if kind == "room" else 32.0
	if kind in ["art","forge","inventory"]:
		focus = Geometry.point3(player.position,0.8)
		distance = 38
		presentation.view_camera.size = 24
	presentation.view_camera.global_position = focus+Vector3(0.25,0.8,0.5454).normalized()*distance
	presentation.view_camera.look_at(focus)
	for i in 40:
		await get_tree().process_frame
	if kind in ["forge","inventory"]:
		for i in 8:
			progression.random_weapon()
		hud.show_menu(kind)
		for i in 6:
			await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://outputs/game-%s.png" % kind)
	get_tree().quit()
