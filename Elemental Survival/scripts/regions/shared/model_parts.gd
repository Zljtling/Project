extends RefCounted
## Small mesh construction helpers. No input, gameplay state or scene layout.
static var _box_meshes: Dictionary = {}
static var _textured_materials: Dictionary = {}
const MAX_CACHED_BOXES := 512

static func material(color: Color, texture_name := "", tiles := Vector3.ONE) -> StandardMaterial3D:
	var key := "%s:%s:%s" % [color.to_html(), texture_name, tiles]
	if not texture_name.is_empty() and _textured_materials.has(key):
		return _textured_materials[key]
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 0.94
	if not texture_name.is_empty():
		result.albedo_texture = load("res://assets/regions/shared/%s.png" % texture_name)
		result.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		result.uv1_triplanar = true
		result.uv1_scale = tiles
		_textured_materials[key] = result
		if _textured_materials.size() > 256:
			_textured_materials.erase(_textured_materials.keys()[0])
	return result

static func box(parent: Node3D, label: String, size: Vector3, at: Vector3, surface: Material, solid := false) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = label
	if not _box_meshes.has(size):
		if _box_meshes.size() >= MAX_CACHED_BOXES:
			_box_meshes.erase(_box_meshes.keys()[0])
		var new_mesh := BoxMesh.new()
		new_mesh.size = size
		_box_meshes[size] = new_mesh
	var mesh: BoxMesh = _box_meshes[size]
	part.mesh = mesh
	part.material_override = surface
	part.position = at
	parent.add_child(part)
	if solid:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var bounds := BoxShape3D.new()
		bounds.size = size
		shape.shape = bounds
		body.add_child(shape)
		part.add_child(body)
	return part

static func cylinder(parent: Node3D, at: Vector3, bottom: float, top: float, height: float, surface: Material, solid := false) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = bottom
	mesh.top_radius = top
	mesh.height = height
	mesh.radial_segments = 7
	part.mesh = mesh
	part.material_override = surface
	part.position = at
	parent.add_child(part)
	if solid:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var volume := CylinderShape3D.new()
		volume.radius = maxf(bottom, top)
		volume.height = height
		shape.shape = volume
		body.add_child(shape)
		part.add_child(body)
	return part

static func walkable_platform(parent: Node3D, label: String, footprint: Vector2, at: Vector3, surface: Material) -> MeshInstance3D:
	# Like house floors, the physical surface is at at.y, with a tiny visual lift.
	var part := box(parent,label,Vector3(footprint.x,0.2,footprint.y),at+Vector3(0,-0.065,0),surface,true)
	part.get_child(0).position.y = -0.035
	return part

static func gable(parent: Node3D, x: float, surface: Material) -> void:
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	builder.set_material(surface)
	builder.set_normal(Vector3(signf(x), 0, 0))
	var points := [Vector3(x, 2.7, -2.4), Vector3(x, 4.05, 0), Vector3(x, 2.7, 2.4)]
	if x < 0:
		points.reverse()
	for point in points:
		builder.add_vertex(point)
	var part := MeshInstance3D.new()
	part.name = "Gable"
	part.mesh = builder.commit()
	parent.add_child(part)

static func rock(parent: Node3D, at: Vector3, size: Vector3, surface: Material) -> MeshInstance3D:
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ring: Array[Vector3] = []
	for i in 7:
		var angle := TAU * i / 7
		var radius := 0.86 + 0.12 * sin(i * 7.3)
		ring.append(Vector3(cos(angle) * radius, 0, sin(angle) * radius))
	for i in 7:
		var a := ring[i]
		var b := ring[(i + 1) % 7]
		var top_a := a * Vector3(0.65, 0, 0.65) + Vector3(0.12, 0.8 + 0.12 * sin(i * 2), 0)
		var top_b := b * Vector3(0.65, 0, 0.65) + Vector3(0.12, 0.8 + 0.12 * sin((i+1) * 2), 0)
		for point in [b, top_a, a, top_b, top_a, b, top_b, Vector3(0, 1, 0), top_a]:
			builder.add_vertex(point * size)
	builder.generate_normals()
	var part := MeshInstance3D.new()
	part.name = "WeatheredRock"
	part.mesh = builder.commit()
	part.material_override = surface
	part.position = at
	parent.add_child(part)
	return part

static func paving_slab(parent: Node3D, at: Vector3, surface: Material) -> MeshInstance3D:
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	var outline := [Vector3(-0.52, 0.05, -0.5), Vector3(0.35, 0.05, -0.55), Vector3(0.52, 0.05, -0.4), Vector3(0.5, 0.05, 0.4), Vector3(0.38, 0.05, 0.53), Vector3(-0.46, 0.05, 0.48)]
	for i in outline.size():
		builder.set_normal(Vector3.UP)
		for point in [outline[(i+1)%outline.size()], Vector3(0, 0.05, 0), outline[i]]:
			builder.add_vertex(point)
	var part := MeshInstance3D.new()
	part.name = "PavingSlab"
	part.mesh = builder.commit()
	part.material_override = surface
	part.position = at
	parent.add_child(part)
	return part
