extends Node3D
## Bounded vent animation: 14 flame cards and 42 pooled ember instances per region.
const VENT_COUNT := 7
const EMBERS_PER_VENT := 6
var clock := 0.0
var flame_material := ShaderMaterial.new()
var embers := MultiMeshInstance3D.new()
var anchors: Array[Vector3] = []
var sample_left := 0.0

func _ready() -> void:
	flame_material.shader = preload("res://assets/regions/elemental/vent_flame.gdshader")
	var card := QuadMesh.new()
	card.size = Vector2(1.8,4.0)
	for i in VENT_COUNT:
		var at := Vector3(cos(i*2.4)*13,0,sin(i*2.4)*13)
		anchors.append(at)
		for angle in [0.0,PI/2]:
			var flame := MeshInstance3D.new()
			flame.name = "VentFlame"
			flame.mesh = card
			flame.material_override = flame_material
			flame.position = at+Vector3(0,2.9,0)
			flame.rotation.y = angle+i*1.7
			flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			flame.extra_cull_margin = 1.0
			add_child(flame)
	var spark := SphereMesh.new()
	spark.radius = 0.045
	spark.height = 0.09
	spark.radial_segments = 4
	spark.rings = 2
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.vertex_color_use_as_albedo = true
	glow.emission_enabled = true
	glow.emission = Color("ff9a46")
	glow.emission_energy_multiplier = 1.4
	embers.material_override = glow
	embers.multimesh = MultiMesh.new()
	embers.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	embers.multimesh.use_colors = true
	embers.multimesh.mesh = spark
	embers.multimesh.instance_count = VENT_COUNT*EMBERS_PER_VENT
	embers.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(embers)
	_update_embers()

func _process(delta: float) -> void:
	clock += delta
	sample_left -= delta
	if sample_left > 0:
		return
	var camera := get_viewport().get_camera_3d()
	if camera != null and camera.global_position.distance_to(global_position) > 125:
		sample_left = 0.25
		return
	sample_left = 1.0/30.0
	flame_material.set_shader_parameter("clock",clock)
	_update_embers()

func _update_embers() -> void:
	for i in VENT_COUNT*EMBERS_PER_VENT:
		var phase := fposmod(clock*0.24+i*0.618,1.0)
		var drift := Vector3(sin(i*3.1+phase*5)*phase,phase*4.2+1.0,cos(i*1.7+phase*3)*phase)
		var size := sin(phase*PI)*1.2
		var basis := Basis.IDENTITY.scaled(Vector3.ONE*maxf(0.01,size))
		embers.multimesh.set_instance_transform(i,Transform3D(basis,anchors[i/EMBERS_PER_VENT]+drift))
		embers.multimesh.set_instance_color(i,Color("ffbc70").lerp(Color("b34b28"),phase))
