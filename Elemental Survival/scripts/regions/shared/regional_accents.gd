extends Node3D
## Decorative batches only: no collision or loot sockets; preserve authored circulation.
const Catalog = preload("res://scripts/regions/region_catalog.gd")
const Taishi = preload("res://scripts/regions/taishi/layout.gd")
var region := 0

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 47117+region*73
	var flowers: Array[Transform3D] = []
	var stones: Array[Transform3D] = []
	for i in 280:
		var p := Vector2(rng.randf_range(-25,25),rng.randf_range(-24,22))
		if _reserved(p):
			continue
		# Cluster accents so open grass reads as a broad shape instead of uniform confetti.
		if sin(p.x*0.31+region)*cos(p.y*0.27) > 0.42 and flowers.size() < 72:
			var basis := Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*rng.randf_range(0.7,1.15))
			flowers.append(Transform3D(basis,Vector3(p.x,0,p.y)))
		if i%3 == 0 and stones.size() < 72:
			var basis := Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3(rng.randf_range(0.16,0.38),0.08,rng.randf_range(0.12,0.3)))
			stones.append(Transform3D(basis,Vector3(p.x,0.015,p.y)))
	_batch("FlowerPatches",_flower_mesh(),flowers,Color.WHITE)
	var pebble := SphereMesh.new()
	pebble.radial_segments = 5
	pebble.rings = 2
	_batch("ScatteredPebbles",pebble,stones,Color("8f9980"))

func _reserved(p: Vector2) -> bool:
	if region < 5:
		return Catalog.reserved(region,p,0.6)
	return Taishi.on_road(p) or Taishi.in_house(p,0.8) or Taishi.in_pond(p,1.0)

func _flower_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for flower in 3:
		var root := Vector3(cos(flower*2.4)*0.23,0,sin(flower*2.4)*0.23)
		var tip := root+Vector3(0,0.34+flower*0.08,0)
		_triangle(surface,root+Vector3(-0.018,0,0),root+Vector3(0.018,0,0),tip,Color("526d43"))
		var petals := Color("c6a6b8") if flower == 0 else Color("d5c993")
		for i in 5:
			var angle := i*TAU/5
			var edge := tip+Vector3(cos(angle)*0.14,-0.025,sin(angle)*0.14)
			var side := Vector3(-sin(angle)*0.065,0,cos(angle)*0.065)
			_triangle(surface,tip,edge-side,edge+side,petals)
	surface.generate_normals()
	return surface.commit()

func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	surface.set_color(color)
	for vertex in [a,b,c]:
		surface.add_vertex(vertex)

func _batch(label: String, mesh: Mesh, transforms: Array[Transform3D], color: Color) -> void:
	var batch := MultiMeshInstance3D.new()
	batch.name = label
	batch.multimesh = MultiMesh.new()
	batch.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	batch.multimesh.mesh = mesh
	batch.multimesh.instance_count = transforms.size()
	for i in transforms.size():
		batch.multimesh.set_instance_transform(i,transforms[i])
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 1
	batch.material_override = material
	batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(batch)
