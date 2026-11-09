extends Node3D
## 3D trunk/branches with layered pixel leaf clusters. Leaves never own collision.
const Parts = preload("res://scripts/regions/shared/model_parts.gd")
var leaf_material: ShaderMaterial
var size := 1.0

func _ready() -> void:
	var bark := Parts.material(Color("a99588"), "wood", Vector3.ONE * 0.6)
	var trunk := Parts.cylinder(self, Vector3(0, 1.3, 0), 0.26, 0.15, 2.6, bark)
	var body := StaticBody3D.new()
	body.name = "TrunkCollision"
	var shape := CollisionShape3D.new()
	var capsule := CylinderShape3D.new()
	capsule.radius = 0.27
	capsule.height = 2.6
	shape.shape = capsule
	body.add_child(shape)
	trunk.add_child(body)
	for side in [-1.0, 1.0]:
		var branch := Parts.cylinder(self, Vector3(side * 0.35, 2, 0), 0.12, 0.06, 1.2, bark)
		branch.rotation.z = side * -0.65
	for at in [Vector3(-0.9, 2.7, 0), Vector3(0.85, 2.85, -0.12), Vector3(0, 3.7, -0.15)]:
		var leaves := MeshInstance3D.new()
		leaves.name = "LeafCluster"
		var quad := QuadMesh.new()
		quad.size = Vector2(3.4, 3.4) * size
		leaves.mesh = quad
		leaves.position = at * size
		leaves.rotation.x = -atan2(0.80, 0.60)
		leaves.material_override = leaf_material
		add_child(leaves)
