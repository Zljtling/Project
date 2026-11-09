extends Node3D
## Reusable landmarks and prop assemblies; no player/camera dependencies.
const Parts = preload("res://scripts/regions/shared/model_parts.gd")
const Layout = preload("res://scripts/regions/taishi/layout.gd")
var wood := Parts.material(Color("c6b2a6"), "wood", Vector3.ONE * 0.5)
var stone := Parts.material(Color("abb7b2"), "stone", Vector3.ONE * 0.4)
var metal := Parts.material(Color("404c52"))

func _ready() -> void:
	for at in [Vector3(-2.7, 0, 2.7), Vector3(2.7, 0, -6.5), Vector3(-2.7, 0, -13), Vector3(2.7, 0, 11), Vector3(10, 0, 7), Vector3(-15, 0, 8)]:
		_lantern(at)
	for x in [-10.0, 10.0]:
		for z in [-1.0, 0.5, 2.0, 3.5]:
			Parts.box(self, "FencePost", Vector3(0.16, 0.95, 0.16), Vector3(x, 0.475, z), wood, true)
		for y in [0.35, 0.75]:
			Parts.box(self, "FenceRail", Vector3(0.12, 0.12, 4.5), Vector3(x, y, 1.25), wood, true)
	for at in [Vector3(-8.3, 0, 2), Vector3(8.2, 0, -0.8), Vector3(8.3, 0, 0.3), Vector3(-8.3, 0, -9.3), Vector3(-18, 0, 4.1), Vector3(8, 0, -11.5)]:
		_crate(at)
	for at in [Vector3(-4, 0, 7), Vector3(-9, 0, -6.5), Vector3(9, 0, -11)]:
		_barrel(at)
	_well(Vector3(-5, 0, 8))
	_bench(Vector3(-8, 0, 9))
	_bench(Vector3(9, 0, 6.5))
	_cart(Vector3(-16, 0, -5))
	_ruins(Vector3(-15, 0, 15))
	_pond()

func _lantern(at: Vector3) -> void:
	var socket := Marker3D.new()
	socket.position = at+Vector3(0,2.7,0)
	socket.add_to_group("ambient_lamp_sockets")
	add_child(socket)
	Parts.cylinder(self, at + Vector3(0, 1.5, 0), 0.075, 0.055, 3, metal)
	Parts.cylinder(self, at + Vector3(0, 0.12, 0), 0.23, 0.13, 0.24, metal)
	var glow := Parts.material(Color("ffe0a0"))
	glow.emission_enabled = true
	glow.emission = Color("ffca79")
	glow.emission_energy_multiplier = 1.0
	Parts.box(self, "LampGlass", Vector3(0.35, 0.48, 0.35), at + Vector3(0, 2.9, 0), glow)
	Parts.cylinder(self, at + Vector3(0, 3.22, 0), 0.36, 0, 0.28, metal)
	Parts.box(self, "LampBase", Vector3(0.44, 0.1, 0.44), at + Vector3(0, 2.61, 0), metal)
	for x in [-0.18, 0.18]:
		Parts.box(self, "LampFrame", Vector3(0.045, 0.5, 0.4), at + Vector3(x, 2.9, 0), metal)
	var light := OmniLight3D.new()
	light.position = at + Vector3(0, 2.8, 0)
	light.light_color = Color("ffd19a")
	light.light_energy = 0.65
	light.omni_range = 4
	add_child(light)

func _crate(at: Vector3) -> void:
	Parts.box(self, "Crate", Vector3(0.85, 0.85, 0.85), at + Vector3(0, 0.425, 0), wood, true)
	for y in [0.1, 0.75]:
		Parts.box(self, "CrateBand", Vector3(0.9, 0.09, 0.9), at + Vector3(0, y, 0), metal)
	var brace := Parts.box(self, "CrateBrace", Vector3(0.1, 0.95, 0.06), at + Vector3(0, 0.43, 0.45), wood)
	brace.rotation.z = -PI/4

func _barrel(at: Vector3) -> void:
	Parts.cylinder(self, at + Vector3(0, 0.5, 0), 0.38, 0.35, 1, wood)
	for y in [0.15, 0.8]:
		Parts.cylinder(self, at + Vector3(0, y, 0), 0.4, 0.4, 0.08, metal)

func _bench(at: Vector3) -> void:
	Parts.box(self, "BenchSeat", Vector3(2, 0.14, 0.65), at + Vector3(0, 0.6, 0), wood, true)
	Parts.box(self, "BenchBack", Vector3(2, 0.6, 0.12), at + Vector3(0, 1.03, -0.3), wood)
	for x in [-0.7, 0.7]:
		Parts.box(self, "BenchLeg", Vector3(0.15, 0.6, 0.6), at + Vector3(x, 0.3, 0), metal)

func _well(at: Vector3) -> void:
	for i in 12:
		var angle := TAU*i/12
		var brick := Parts.box(self, "WellStone", Vector3(0.45, 0.8, 0.33), at + Vector3(cos(angle)*0.8, 0.4, sin(angle)*0.8), stone, true)
		brick.rotation.y = -angle + PI/2
	for x in [-1.0, 1.0]:
		Parts.box(self, "WellPost", Vector3(0.16, 2.1, 0.16), at + Vector3(x, 1.05, 0), wood)
	Parts.box(self, "WellBeam", Vector3(2.3, 0.18, 0.24), at + Vector3(0, 2, 0), wood)
	Parts.box(self, "WellRope", Vector3(0.035, 1.4, 0.035), at + Vector3(0, 1.25, 0), wood)
	Parts.cylinder(self, at + Vector3(0, 0.12, 0), 0.65, 0.65, 0.1, Parts.material(Color("294e55")))

func _cart(at: Vector3) -> void:
	Parts.box(self, "CartBed", Vector3(1.5, 0.18, 2.3), at + Vector3(0, 0.7, 0), wood, true)
	for x in [-0.8, 0.8]:
		Parts.box(self, "CartSide", Vector3(0.12, 0.65, 2.3), at + Vector3(x, 1.05, 0), wood)
		var wheel := Parts.cylinder(self, at + Vector3(x*1.2, 0.45, 0.2), 0.45, 0.45, 0.14, metal)
		wheel.rotation.z = PI/2
		Parts.box(self, "CartHandle", Vector3(0.1, 0.1, 1.8), at + Vector3(x*0.6, 0.65, 1.7), wood)

func _ruins(at: Vector3) -> void:
	for x in [-2.0, 2.0]:
		Parts.box(self, "PillarBase", Vector3(0.9, 0.25, 0.9), at + Vector3(x, 0.125, 0), stone, true)
		Parts.box(self, "RuinedPillar", Vector3(0.52, 2.7, 0.55), at + Vector3(x, 1.5, 0), stone, true)
		Parts.box(self, "PillarCapital", Vector3(0.8, 0.2, 0.8), at + Vector3(x, 2.9, 0), stone)
	for side in [-1.0, 1.0]:
		for i in 4:
			var angle: float = PI/2 + side * (i+0.5) * PI/9
			var brick := Parts.box(self, "ArchVoussoir", Vector3(0.72, 0.52, 0.65), at + Vector3(cos(angle)*2.1, 2.55+sin(angle)*2.1, 0), stone)
			brick.rotation.z = angle-PI/2
	for i in 5:
		Parts.rock(self, at + Vector3(-3+i*1.3, 0, 2), Vector3(0.65, 0.45, 0.5), stone)

func _pond() -> void:
	var center := Vector3(Layout.POND.x, 0.04, Layout.POND.y)
	var bank := Parts.cylinder(self, center, 1, 1, 0.05, Parts.material(Color("716c50")))
	(bank.mesh as CylinderMesh).radial_segments = 40
	bank.scale = Vector3(5.7, 1, 3.95)
	var water_material := ShaderMaterial.new()
	water_material.shader = preload("res://assets/regions/shared/pond_water.gdshader")
	preload("res://scripts/regions/shared/material_animation.gd").attach(self,water_material)
	var water := Parts.cylinder(self, center + Vector3(0, 0.04, 0), 1, 1, 0.04, water_material)
	(water.mesh as CylinderMesh).radial_segments = 40
	water.scale = Vector3(5, 1, 3.4)
	# Keep the decorative pond non-traversable; no invisible walking on water.
	var barrier := StaticBody3D.new()
	barrier.name = "PondCollision"
	var shape := CollisionShape3D.new()
	var volume := ConvexPolygonShape3D.new()
	var points := PackedVector3Array()
	for i in 16:
		var angle := TAU*i/16
		for y in [-0.2, 1.0]:
			points.append(Vector3(cos(angle)*5, y, sin(angle)*3.4))
	volume.points = points
	shape.shape = volume
	barrier.position = center
	barrier.add_child(shape)
	add_child(barrier)
	for i in 15:
		var angle := TAU*i/15
		Parts.rock(self, center + Vector3(cos(angle)*(5.5+0.15*sin(i*5)), 0.06, sin(angle)*3.75), Vector3(0.45+0.12*(i%3), 0.35+0.1*(i%3), 0.45), stone)
	for i in 9:
		Parts.box(self, "WaterGlint", Vector3(0.28+(i%3)*0.1, 0.015, 0.045), center + Vector3(sin(i*7)*3.7, 0.08, cos(i*4)*2.6), Parts.material(Color("8bb2a2")))
