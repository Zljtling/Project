extends Node3D
## Terrain, paths and small vegetation. Dense details use MultiMesh batches.
const Parts = preload("res://scripts/regions/shared/model_parts.gd")
const Layout = preload("res://scripts/regions/taishi/layout.gd")
@export var include_boundaries := true
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = 441
	var grass := ShaderMaterial.new()
	grass.shader = preload("res://assets/regions/shared/ground_grass.gdshader")
	var dirt := Parts.material(Color("dfd4be"), "dirt", Vector3.ONE * 0.5)
	var stone := Parts.material(Color("7c8881"))
	Parts.box(self, "Terrain", Vector3(100, 0.4, 90), Vector3(0, -0.2, -2), grass, true)
	if include_boundaries:
		for x in [-28.0, 28.0]:
			var boundary := Parts.box(self, "MapBoundary", Vector3(0.5, 4, 55), Vector3(x, 2, -2), grass, true)
			boundary.visible = false
		for z in [-28.0, 24.0]:
			var boundary := Parts.box(self, "MapBoundary", Vector3(56, 4, 0.5), Vector3(0, 2, z), grass, true)
			boundary.visible = false
	Parts.box(self, "MainRoad", Vector3(4.1, 0.02, 53), Vector3(0, 0.015, -2), dirt)
	Parts.box(self, "CrossRoad", Vector3(40, 0.02, 2.3), Vector3(-2, 0.02, 3.5), dirt)
	Parts.box(self, "BackLane", Vector3(20, 0.02, 2.2), Vector3(0, 0.025, -9.5), dirt)
	for i in 86:
		var side := -1 if i % 2 == 0 else 1
		Parts.box(self, "PathEdge", Vector3(rng.randf_range(0.12, 0.55), 0.018, 0.9), Vector3(side * 2.1, 0.02, -27 + i * 0.65), dirt)
	for at in Layout.HOUSE_CENTERS:
		Parts.box(self, "Apron", Vector3(6.6, 0.02, 5.6), at + Vector3(0, 0.03, 0), dirt)
		for z in [2.85, 3.4]:
			Parts.box(self, "DoorStone", Vector3(1.6, 0.07, 0.45), at + Vector3(0, 0.035, z), stone)
	# Broken stone paving: broad shapes, varied seams, tiny moss gaps.
	for row in 35:
		for column in 3:
			var pos := Vector3((column - 1) * 1.15 + (0.12 if row%2 else 0), 0.04, -24 + row * 1.25)
			var slab := Parts.paving_slab(self, pos, stone)
			slab.rotation.y = rng.randf_range(-0.12, 0.12)
	_scatter_vegetation()
	var accents := preload("res://scripts/regions/shared/regional_accents.gd").new()
	accents.name = "MeadowAccents"
	accents.region = 5
	add_child(accents)

func _scatter_vegetation() -> void:
	var grass_mat := Parts.material(Color.WHITE)
	grass_mat.albedo_texture = preload("res://assets/regions/shared/meadow_blades.png")
	grass_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	grass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	grass_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	grass_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var blade := QuadMesh.new()
	blade.size = Vector2(0.65, 0.5)
	var grasses: Array[Transform3D] = []
	var flowers: Array[Transform3D] = []
	for i in 1600:
		var p := Vector2(rng.randf_range(-27, 27), rng.randf_range(-26, 22))
		if Layout.on_road(p) or Layout.in_house(p, 0.2) or Layout.in_pond(p, 0.6):
			continue
		var basis := Basis(Vector3.RIGHT, -atan2(0.8, 0.6))
		grasses.append(Transform3D(basis, Vector3(p.x, 0.22, p.y)))
		if i%3 == 0:
			flowers.append(Transform3D(Basis.IDENTITY, Vector3(p.x+0.15, 0.22, p.y)))
	_batch("GrassTufts", blade, grass_mat, grasses)
	var petal := BoxMesh.new()
	petal.size = Vector3(0.09, 0.06, 0.09)
	_batch("Wildflowers", petal, Parts.material(Color("e8da9e")), flowers)

func _batch(label: String, mesh: Mesh, surface: Material, transforms: Array[Transform3D]) -> void:
	var batch := preload("res://scripts/regions/shared/swaying_vegetation.gd").new() if label == "GrassTufts" else MultiMeshInstance3D.new()
	batch.name = label
	batch.multimesh = MultiMesh.new()
	batch.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	batch.multimesh.mesh = mesh
	batch.multimesh.instance_count = transforms.size()
	for i in transforms.size():
		batch.multimesh.set_instance_transform(i, transforms[i])
	batch.material_override = surface
	batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(batch)
