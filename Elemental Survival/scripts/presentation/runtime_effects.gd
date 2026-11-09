extends MeshInstance3D
## One batched mesh for moving shots, hit rings, skills, drops and attack warnings.
const G = preload("res://scripts/world/scene_geometry.gd")
const Poison = preload("res://scripts/regions/elemental/poison_layout.gd")
var world: Node2D
var pulses: Array[Dictionary] = []
var batch := ImmediateMesh.new()
var flashes: Array[Dictionary] = []
var ground_heights: Dictionary = {}
var poison_centers: Array[Vector2] = []

func _ready() -> void:
	mesh = batch
	var surface := StandardMaterial3D.new()
	surface.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	surface.vertex_color_use_as_albedo = true
	surface.cull_mode = BaseMaterial3D.CULL_DISABLED
	surface.no_depth_test = false
	material_override = surface
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.arsenal.attacked.connect(func(slot: int, direction: Vector2):
		if slot >= 0 and world.arsenal.specs[slot] != null and world.arsenal.specs[slot].kind == "bolt":
			if flashes.size() >= 12:
				flashes.pop_front()
			flashes.append({"position":world.player.position+direction*24,"direction":direction,"life":0.10})
	)

func pulse(point: Vector2, radius: float, color: Color) -> void:
	if pulses.size() >= 64:
		pulses.pop_front()
	pulses.append({"point":point,"radius":radius,"color":color,"life":0.4})

func _process(delta: float) -> void:
	if not world.started:
		return
	batch.clear_surfaces()
	ground_heights.clear()
	poison_centers.clear()
	if not world.in_dungeon:
		poison_centers.append_array(world.element_centers("poison"))
	var warnings: Array[Dictionary] = []
	for enemy in world.enemies:
		if enemy.get("attack_left") != null and enemy.attack_left > 0:
			warnings.append({"position":enemy.attack_origin,"radius":enemy.attack_radius,"progress":1.0-enemy.attack_left/1.1})
		elif enemy.get("slam_left") != null and enemy.slam_left > 0:
			warnings.append({"position":enemy.slam_origin,"radius":100.0,"progress":1.0-enemy.slam_left/1.1})
	batch.surface_begin(Mesh.PRIMITIVE_LINES)
	if world.has_method("enemy_patterns"):
		for hazard in world.enemy_patterns().hazards:
			_ring(hazard["position"],hazard["radius"],Color("e3b974") if hazard["delay"] > 0 else Color("ed805c"),0.25)
	for enemy in world.enemies:
		if enemy.brain.windup > 0:
			_line(enemy.position,enemy.position+enemy.brain.locked*220,Color("e7a46e"),0.3)
	_ring(world.player.position,14,Color("465647"),0.2)
	for shot in world.arsenal.shots:
		_line(shot["position"]-shot["direction"]*18,shot["position"],shot["color"],0.85)
	for effect in world.arsenal.effects:
		_ring(effect["position"],effect["radius"],effect["color"],0.23)
	for hit in world.hits:
		_ring(hit["position"],hit["radius"],hit["color"],0.3)
	for drop in world.pickups:
		var color := Color("b8cb6b") if drop["kind"] == "poison" else Color("ed9563") if drop["kind"] == "fire" else Color("e6c475")
		_ring(drop["position"],6,color,0.4)
	for pulse_data in pulses:
		pulse_data["life"] -= delta
		_ring(pulse_data["point"],pulse_data["radius"]*(1.2-pulse_data["life"]),pulse_data["color"],0.4)
	pulses = pulses.filter(func(p: Dictionary): return p["life"] > 0)
	if is_instance_valid(world.marked):
		_ring(world.marked.position,30,Color("ffd085"),0.25)
	if world.waypoint != Vector2.INF:
		_ring(world.waypoint,28,Color("edcd8e"),0.22)
	var target: Vector2 = world.waypoint
	if target == Vector2.INF:
		if world.in_dungeon and world.room_cleared:
			target = world.dungeon_door()
		elif not world.in_dungeon and world.objectives.count() == 3:
			target = world.ENTRANCE
		elif not world.in_dungeon and is_instance_valid(world.objectives.bounty):
			target = world.objectives.bounty.position
	if target != Vector2.INF and world.player.position.distance_to(target) > 70:
		var direction: Vector2 = world.player.position.direction_to(target)
		var tip: Vector2 = world.player.position+direction*105
		var base: Vector2 = tip-direction*25
		_line(base,tip,Color("edd49a"),0.45)
		_line(tip,base+direction.orthogonal()*12,Color("edd49a"),0.45)
		_line(tip,base-direction.orthogonal()*12,Color("edd49a"),0.45)
	batch.surface_end()
	# Filled ribbons / disks are visible at the actual play camera. No gameplay hitboxes here.
	var hazards: Array = world.enemy_patterns().hazards if world.has_method("enemy_patterns") else []
	var charging_warning: bool = world.enemies.any(func(e: Node): return e.brain.windup > 0)
	if not world.arsenal.shots.is_empty() or not world.arsenal.effects.is_empty() or not warnings.is_empty() or not hazards.is_empty() or not flashes.is_empty() or not world.hits.is_empty() or charging_warning:
		batch.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		for shot in world.arsenal.shots:
			var tip: Vector2 = shot["position"]
			var tail: Vector2 = tip-shot["direction"]*62
			_ribbon(tail,tip,13,Color("304846"))
			_ribbon(tail+shot["direction"]*5,tip,8,Color("63d6c5"),1.17)
			_ribbon(tip-shot["direction"]*25,tip+shot["direction"]*5,6,Color("fff4be"),1.19)
			_disc(tip,7,Color("fff9db"),1.21)
		for flash in flashes:
			var at: Vector2 = flash["position"]
			for i in 5:
				var dir := Vector2.from_angle(i*TAU/5)
				_ribbon(at+dir*5,at+dir*20,5,Color("ffe0a0"),1.25)
			flash["life"] -= delta
		flashes = flashes.filter(func(f: Dictionary): return f["life"] > 0)
		for effect in world.arsenal.effects:
			var angle: float = effect["direction"]
			var start := angle-1.15 if effect["slash"] else 0.0
			var sweep := 2.3 if effect["slash"] else TAU
			for i in 24:
				var a: Vector2 = effect["position"]+Vector2.from_angle(start+sweep*i/24.0)*effect["radius"]*0.8
				var b: Vector2 = effect["position"]+Vector2.from_angle(start+sweep*(i+1)/24.0)*effect["radius"]*0.8
				_ribbon(a,b,18,Color("537f79"),0.65)
				_ribbon(a,b,10,Color("fff0b3"),0.68)
		for hit in world.hits:
			for i in 7:
				var dir := Vector2.from_angle(i*TAU/7)
				_ribbon(hit["position"]+dir*10,hit["position"]+dir*25,5,Color("ffedb0"),1.2)
		for warning in warnings:
			_warning(warning["position"],warning["radius"],warning["progress"])
		for hazard in hazards:
			var at: Vector2 = hazard["position"]
			var velocity: Vector2 = hazard["velocity"]
			if hazard["delay"] > 0:
				if velocity == Vector2.ZERO:
					_warning(at,hazard["radius"],1.0-hazard["delay"]/hazard.get("warning_duration",0.6))
				else:
					# Preview direction without drawing a damaging-looking bullet before release.
					var dir := velocity.normalized()
					_ribbon(at,at+dir*85,7,Color("e8ab70"),0.28)
					_disc(at,11,Color("f1cd86"),1.2)
			elif velocity != Vector2.ZERO:
				var dir := velocity.normalized()
				_ribbon(at-dir*40,at,14,Color("9c3e44"),1.1)
				_disc(at,hazard["radius"]+4,Color("64363c"),1.12)
				_disc(at,hazard["radius"],Color("ed7952"),1.14)
				_disc(at-dir*2,hazard["radius"]*0.48,Color("ffdeb0"),1.16)
			else:
				_thick_ring(at,hazard["radius"],8,Color("df694d"),0.23)
				_thick_ring(at,hazard["radius"]*0.72,3,Color("e9b474"),0.24)
		for enemy in world.enemies:
			if enemy.brain.windup > 0:
				var start: Vector2 = enemy.position
				var dir: Vector2 = enemy.brain.locked
				for side in [-1,1]:
					_ribbon(start+dir.orthogonal()*18*side,start+dir*220+dir.orthogonal()*18*side,5,Color("ef925b"),0.25)
				_ribbon(start+dir*220,start+dir*192+dir.orthogonal()*22,7,Color("ffe0a0"),0.27)
				_ribbon(start+dir*220,start+dir*192-dir.orthogonal()*22,7,Color("ffe0a0"),0.27)
		batch.surface_end()

func _ribbon(a: Vector2, b: Vector2, width: float, color: Color, height := 1.15) -> void:
	var side := a.direction_to(b).orthogonal()*width*0.5
	batch.surface_set_color(color)
	for point in [a-side,a+side,b+side,a-side,b+side,b-side]:
		batch.surface_add_vertex(_point(point,height))

func _disc(center: Vector2, radius: float, color: Color, height: float) -> void:
	batch.surface_set_color(color)
	for i in 16:
		for point in [center,center+Vector2.from_angle(i*TAU/16)*radius,center+Vector2.from_angle((i+1)*TAU/16)*radius]:
			batch.surface_add_vertex(_point(point,height))

func _thick_ring(center: Vector2, radius: float, width: float, color: Color, height: float, fraction := 1.0) -> void:
	for i in 40:
		if float(i)/40 > fraction:
			break
		_ribbon(center+Vector2.from_angle(i*TAU/40)*radius,center+Vector2.from_angle((i+1)*TAU/40)*radius,width,color,height)

func _warning(center: Vector2, radius: float, progress: float) -> void:
	_thick_ring(center,radius,10,Color("733c37"),0.24)
	_thick_ring(center,radius,5,Color("f0a06d"),0.26)
	_thick_ring(center,radius*0.87,6,Color("ffe0a0"),0.28,clampf(progress,0,1))
	_ribbon(center+Vector2(-10,-10),center+Vector2(10,10),4,Color("f7c396"),0.27)
	_ribbon(center+Vector2(-10,10),center+Vector2(10,-10),4,Color("f7c396"),0.27)

func _line(a: Vector2, b: Vector2, color: Color, height: float) -> void:
	batch.surface_set_color(color)
	batch.surface_add_vertex(_point(a,height))
	batch.surface_add_vertex(_point(b,height))

func _point(point: Vector2, height: float) -> Vector3:
	if ground_heights.has(point):
		return G.point3(point,height+float(ground_heights[point]))
	var ground := 0.0
	for center in poison_centers:
		var local := (point-center)/32.0
		# Reject distant regions before bridge/shore queries; all effects share this frame's cache.
		if absf(local.x) <= 32 and absf(local.y) <= 29 and Poison.in_pool(local) and Poison.is_safe(local):
			ground = Poison.surface_height(local)
			break
	if ground_heights.size() < 4096:
		ground_heights[point] = ground
	return G.point3(point,height+ground)

func _ring(center: Vector2, radius: float, color: Color, height: float) -> void:
	for i in 32:
		_line(center+Vector2.from_angle(i*TAU/32.0)*radius,center+Vector2.from_angle((i+1)*TAU/32.0)*radius,color,height)
