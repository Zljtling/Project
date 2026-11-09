extends Node3D
const Parts = preload("res://scripts/regions/shared/model_parts.gd")
var clock := 0.0
var lava := ShaderMaterial.new()

func _ready() -> void:
	lava.shader = preload("res://assets/regions/elemental/lava.gdshader")
	var rock := Parts.material(Color("514b48"),"stone",Vector3.ONE*0.2)
	var ground := Parts.cylinder(self,Vector3(0,0.01,0),31.25,31.25,0.02,lava)
	ground.mesh.radial_segments = 64
	var random := RandomNumberGenerator.new()
	random.seed = 321
	for i in 42:
		var angle := i*TAU/42
		var radius := 29.5+sin(i*2.3)*1.4
		var at := Vector3(cos(angle)*radius,-0.1,sin(angle)*radius)
		var stone := Parts.rock(self,at,Vector3(2.5,random.randf_range(1,3),2.1),rock)
		stone.rotation.y = angle
		_blocker(stone,1.25)
	for i in 7:
		var at := Vector3(cos(i*2.4)*13,-0.1,sin(i*2.4)*13)
		var mound := Parts.rock(self,at,Vector3(3.1,1.7,2.7),rock)
		_blocker(mound,1.35)
	var vents := preload("res://scripts/regions/elemental/vent_effects.gd").new()
	vents.name = "VentEffects"
	add_child(vents)

func _process(delta: float) -> void:
	clock += delta
	lava.set_shader_parameter("clock",clock)

func _blocker(parent: Node3D, radius: float) -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = radius
	cylinder.height = 1.5
	shape.shape = cylinder
	shape.position.y = 0.65
	body.add_child(shape)
	parent.add_child(body)
