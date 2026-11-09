extends Node3D
## Visual module only. poison_layout.gd owns the authoritative safety geometry.
const Layout = preload("res://scripts/regions/elemental/poison_layout.gd")
const Parts = preload("res://scripts/regions/shared/model_parts.gd")
var clock := 0.0
var acid := ShaderMaterial.new()
var fumes: Array[ShaderMaterial] = []
var bubbles: Array[MeshInstance3D] = []
var rng := RandomNumberGenerator.new()
var sample_left := 0.0

func _ready() -> void:
	rng.seed = 8721
	acid.shader = preload("res://assets/regions/elemental/acid.gdshader")
	_pool()
	var wood := Parts.material(Color("81765c"),"wood",Vector3.ONE*0.5)
	var stone := Parts.material(Color("9ca99a"),"stone",Vector3.ONE*0.25)
	# Low rock tops are walk-on shelves; broad bevels meet the pool at ground level.
	for i in Layout.ISLANDS.size():
		_island(Layout.ISLANDS[i],Layout.ISLAND_RADII[i],stone)
	for link in Layout.LINKS:
		_bridge(link[0],link[1],wood)
	for i in 54:
		var angle := i*TAU/54.0
		var at := Vector2(cos(angle),sin(angle))*Layout.RADII*(Layout.shore_radius(angle)+0.055)
		if Layout.is_safe(at, -3.8):
			continue
		var size := Vector3(rng.randf_range(1.8,3.8),rng.randf_range(1.2,3),rng.randf_range(1.6,3.2))
		var rock := Parts.rock(self,Vector3(at.x,-0.2,at.y),size,stone)
		rock.rotation.y = angle
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var bounds := BoxShape3D.new()
		bounds.size = size*Vector3(1.25,0.85,1.25)
		shape.shape = bounds
		shape.position.y = size.y*0.4
		body.add_child(shape)
		rock.add_child(body)
	for i in 26:
		var point := _liquid_point()
		var sphere := SphereMesh.new()
		sphere.radius = rng.randf_range(0.16,0.45)
		sphere.height = sphere.radius*2
		sphere.radial_segments = 8
		sphere.rings = 4
		var bubble := MeshInstance3D.new()
		bubble.mesh = sphere
		bubble.material_override = Parts.material(Color("a9b665"))
		bubble.position = Vector3(point.x,0.12,point.y)
		bubble.set_meta("phase",rng.randf())
		add_child(bubble)
		bubbles.append(bubble)
	for i in 22:
		var point := _liquid_point()
		var material := ShaderMaterial.new()
		material.shader = preload("res://assets/regions/elemental/fume.gdshader")
		material.set_shader_parameter("phase",rng.randf())
		fumes.append(material)
		var mesh := QuadMesh.new()
		mesh.size = Vector2(3.5,2.6)
		var plume := MeshInstance3D.new()
		plume.mesh = mesh
		plume.material_override = material
		plume.position = Vector3(point.x,0.4,point.y)
		plume.rotation.y = 0.43
		plume.rotation.x = -0.45
		plume.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(plume)
	for at in [Vector3(-32,0,2.4),Vector3(32,0,2.4),Vector3(0,0,-29)]:
		Parts.box(self,"WarningPost",Vector3(0.12,1.7,0.12),at+Vector3(0,0.85,0),wood)
		Parts.box(self,"AcidWarning",Vector3(1.5,0.75,0.12),at+Vector3(0,1.6,0),Parts.material(Color("b6a064")))
		for x in [-0.4,0,0.4]:
			var stripe := Parts.box(self,"WarningStripe",Vector3(0.12,0.65,0.14),at+Vector3(x,1.6,0.02),Parts.material(Color("484a37")))
			stripe.rotation.z = -0.4

func _pool() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 96:
		for point in [_rim((i+1)*TAU/96.0),Vector3(0,0.06,0),_rim(i*TAU/96.0)]:
			surface.set_normal(Vector3.UP)
			surface.add_vertex(point)
	var pool := MeshInstance3D.new()
	pool.name = "SulfuricPool"
	pool.mesh = surface.commit()
	pool.material_override = acid
	add_child(pool)

func _rim(angle: float) -> Vector3:
	var at := Vector2(cos(angle),sin(angle))*Layout.RADII*Layout.shore_radius(angle)
	return Vector3(at.x,0.06,at.y)

func _island(at: Vector3, radius: float, stone: Material) -> void:
	var island := Node3D.new()
	island.name = "RestStone"
	island.position = at
	add_child(island)
	# Flat, broad top with a shallow bevel; art/safety radii share one source.
	var body := Parts.cylinder(island,Vector3(0,-0.13,0),radius+0.5,radius,0.5,stone)
	body.mesh.radial_segments = 18
	var moss := Parts.material(Color("718976"),"stone",Vector3.ONE*0.3)
	for i in 9:
		var angle := i*TAU/9
		var edge := at+Vector3(cos(angle)*radius*0.92,-0.12,sin(angle)*radius*0.92)
		Parts.rock(self,edge,Vector3(0.65,0.35,0.55),moss)

func _bridge(a: Vector2, b: Vector2, wood: Material) -> void:
	var holder := Node3D.new()
	holder.name = "ConnectingBridge"
	holder.position = Vector3((a.x+b.x)*0.5,0,(a.y+b.y)*0.5)
	holder.rotation.y = -Vector2.RIGHT.angle_to(b-a)
	add_child(holder)
	var length := a.distance_to(b)
	var stone := Parts.material(Color("b8b6a0"),"stone",Vector3.ONE*0.4)
	var count := ceili(length/0.45)
	for i in count:
		var fraction := (i+0.5)/count
		var x := -length*0.5+length*fraction
		var y := 0.18+sin(fraction*PI)*0.45
		Parts.box(holder,"ArchDeckStone",Vector3(length/count+0.02,0.18,Layout.WIDTH),Vector3(x,y-0.09,0),stone)
		if fraction > 0.12 and fraction < 0.88:
			for side in [-1,1]:
				Parts.box(holder,"LowStoneParapet",Vector3(length/count+0.02,0.3,0.17),Vector3(x,y+0.2,side*(Layout.WIDTH*0.5+0.08)),stone,true)
	for side in [-1,1]:
		for i in range(1,maxi(2,ceili(length/2.5))):
			var fraction := float(i)/maxi(2,ceili(length/2.5))
			var x := -length*0.5+length*fraction
			var y := 0.18+sin(fraction*PI)*0.45
			Parts.box(holder,"CarvedRailPost",Vector3(0.24,0.65,0.24),Vector3(x,y+0.3,side*(Layout.WIDTH*0.5+0.08)),stone)
			Parts.cylinder(holder,Vector3(x,y+0.7,side*(Layout.WIDTH*0.5+0.08)),0.18,0.08,0.15,stone)
	for x in [-length*0.3,length*0.3]:
		Parts.box(holder,"ArchPier",Vector3(0.5,0.65,Layout.WIDTH+0.25),Vector3(x,-0.15,0),stone)

func _rail_trim(point: Vector2) -> float:
	for i in Layout.ISLANDS.size():
		if point.distance_to(Vector2(Layout.ISLANDS[i].x,Layout.ISLANDS[i].z)) < 0.1:
			return Layout.ISLAND_RADII[i]+0.25
	return 0.0

func _liquid_point() -> Vector2:
	for attempt in 100:
		var at := Vector2(rng.randf_range(-28,28),rng.randf_range(-24,24))
		if Layout.hazardous(at) and not Layout.is_safe(at,-1.2):
			return at
	return Vector2(0,18)

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
	acid.set_shader_parameter("clock",clock)
	for material in fumes:
		material.set_shader_parameter("clock",clock)
	for bubble in bubbles:
		var phase := fmod(clock*0.32+float(bubble.get_meta("phase")),1.0)
		bubble.position.y = 0.08+phase*0.6
		bubble.scale = Vector3.ONE*(0.4+sin(phase*PI)*0.8)
		bubble.visible = phase < 0.88
