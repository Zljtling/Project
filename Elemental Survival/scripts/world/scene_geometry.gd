extends RefCounted
## Import authored collision into the existing planar simulation and AStar grid.
## Ground/roofs are excluded by height; hidden water barriers remain authoritative.
const UNITS := 32.0

static func point3(point: Vector2, height := 0.0) -> Vector3:
	return Vector3(point.x/UNITS,height,point.y/UNITS)

static func point2(point: Vector3) -> Vector2:
	return Vector2(point.x,point.z)*UNITS

static func collect(node: Node, walls: Array[Rect2], houses: Array[Rect2]) -> void:
	if node is Node3D and node.is_in_group("enterable_house"):
		houses.append(Rect2(point2(node.global_position)-Vector2(3,2.4)*UNITS,Vector2(6,4.8)*UNITS))
	if node is CollisionShape3D and node.get_parent() is StaticBody3D and not node.disabled:
		var extent := Vector3.ZERO
		if node.shape is BoxShape3D:
			extent = node.shape.size*0.5
		elif node.shape is CylinderShape3D:
			extent = Vector3(node.shape.radius,node.shape.height*0.5,node.shape.radius)
		if extent != Vector3.ZERO:
			# A single axis-aligned box around a diagonal rail fills its bridge.
			# Subdivide thin rotated blockers before projecting to the planar grid.
			var longest := maxf(extent.x,extent.z)
			var shortest := minf(extent.x,extent.z)
			var diagonal := absf(node.global_basis.x.x) > 0.01 and absf(node.global_basis.x.z) > 0.01
			if node.shape is BoxShape3D and diagonal and longest > shortest*3.0:
				var count := ceili(longest*2/0.4)
				var size := extent*2
				var axis := 0 if extent.x > extent.z else 2
				size[axis] /= count
				for i in count:
					var start := -extent
					start[axis] += size[axis]*i
					_append_bounds(node.global_transform*AABB(start,size),walls)
			else:
				_append_bounds(node.global_transform*AABB(-extent,extent*2),walls)
	for child in node.get_children():
		collect(child,walls,houses)

static func _append_bounds(bounds: AABB, walls: Array[Rect2]) -> void:
	if bounds.end.y > 0.35 and bounds.position.y < 1.5:
		walls.append(Rect2(Vector2(bounds.position.x,bounds.position.z)*UNITS,Vector2(bounds.size.x,bounds.size.z)*UNITS))
