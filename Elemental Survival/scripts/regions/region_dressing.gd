extends Node3D
## Static regional paths, vegetation and yard props; dense grass is instanced.
const Parts = preload("res://scripts/regions/shared/model_parts.gd")
const Catalog = preload("res://scripts/regions/region_catalog.gd")
const StreetProps = preload("res://scripts/regions/shared/street_props.gd")
var region := 0
var leaf_material: ShaderMaterial

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 8831+region
	var dirt := Parts.material(Color("b2a58d"), "dirt", Vector3.ONE*0.4)
	var slate := Parts.material(Color("687a78"))
	var wood := Parts.material(Color("ad9690"), "wood", Vector3.ONE*0.4)
	var metal := Parts.material(Color("435759"))
	for road in Catalog.ROADS[region]:
		var a: Vector2 = road[0]
		var b: Vector2 = road[1]
		Parts.box(self, "Street", Vector3(absf(a.x-b.x)+3,0.03,absf(a.y-b.y)+3),Vector3((a.x+b.x)*0.5,0.015,(a.y+b.y)*0.5),dirt)
	for at in Catalog.HOUSES[region]:
		StreetProps.lamp(self,at+Vector3(3.7,0,3.9),metal)
		StreetProps.planter(self,at+Vector3(1.9,0,3.2),wood)
		for z in [2.7,3.25,3.8]:
			Parts.paving_slab(self,at+Vector3(0,0,z),slate)
		Parts.box(self,"YardCrate",Vector3(0.65,0.65,0.65),at+Vector3(-2.3,0.325,3.1),wood,true)
		for y in [0.12,0.53]:
			Parts.box(self,"CrateBand",Vector3(0.68,0.07,0.68),at+Vector3(-2.3,y,3.1),slate)
		for x in [-3.6,3.6]:
			Parts.cylinder(self,at+Vector3(x,0.4,1.5),0.35,0.3,0.8,wood)
	for at in [Vector3(-22,0,4),Vector3(22,0,17)]:
		StreetProps.bench(self,at,wood,metal)
	# Trees use the same cutaway material supplied by the scene host.
	if leaf_material != null:
		var count := 0
		for i in 160:
			var p := Vector2(rng.randf_range(-26,26),rng.randf_range(-25,26))
			if Catalog.reserved(region,p,1.8):
				continue
			var tree := preload("res://scripts/regions/shared/tree.gd").new()
			tree.position = Vector3(p.x,0,p.y)
			tree.leaf_material = leaf_material
			tree.size = rng.randf_range(0.8,1.2)
			add_child(tree)
			count += 1
			if count == 22:
				break
	var transforms: Array[Transform3D] = []
	for i in 700:
		var p := Vector2(rng.randf_range(-27,27),rng.randf_range(-26,27))
		if not Catalog.reserved(region,p):
			transforms.append(Transform3D(Basis(Vector3.RIGHT,-atan2(0.8,0.6)),Vector3(p.x,0.22,p.y)))
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.65,0.5)
	var batch := preload("res://scripts/regions/shared/swaying_vegetation.gd").new()
	batch.name = "GrassTufts"
	batch.multimesh = MultiMesh.new()
	batch.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	batch.multimesh.mesh = mesh
	batch.multimesh.instance_count = transforms.size()
	for i in transforms.size():
		batch.multimesh.set_instance_transform(i,transforms[i])
	batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(batch)
	var accents := preload("res://scripts/regions/shared/regional_accents.gd").new()
	accents.name = "MeadowAccents"
	accents.region = region
	add_child(accents)
