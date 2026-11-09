extends "res://scripts/regions/shared/swaying_vegetation.gd"
## Seeded world vegetation in one batch; paths, rooms and elemental sites stay clear.
var world: Node2D

func populate() -> void:
	var random := RandomNumberGenerator.new()
	random.seed = world.layout.generation_seed+771
	var blade := QuadMesh.new()
	blade.size = Vector2(0.65,0.55)
	var poses: Array[Transform3D] = []
	for i in 1300:
		var center := Vector2(random.randf_range(100,world.MAP_SIZE.x-100),random.randf_range(100,world.MAP_SIZE.y-100))
		if not world.layout.clear_point(center,30):
			continue
		# Keep all migration sites clear; the batch need not rebuild when the tower moves.
		if world.tower_locations().any(func(at: Vector2): return Rect2(at+world.TowerLayout.BOUNDS.position,world.TowerLayout.BOUNDS.size).grow(40).has_point(center)):
			continue
		if world.zones.entries.any(func(z: Dictionary): return center.distance_to(z["position"]) < 1120):
			continue
		var on_road := false
		for road in world.layout.roads:
			for j in range(road.size()-1):
				if Geometry2D.get_closest_point_to_segment(center,road[j],road[j+1]).distance_to(center) < 42:
					on_road = true
		if on_road:
			continue
		for j in 8:
			var at := center/32+Vector2.from_angle(random.randf()*TAU)*random.randf_range(0,1.1)
			poses.append(Transform3D(Basis(Vector3.UP,random.randf()*TAU),Vector3(at.x,0.25,at.y)))
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = blade
	multimesh.instance_count = poses.size()
	for i in poses.size():
		multimesh.set_instance_transform(i,poses[i])
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
