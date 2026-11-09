extends SceneTree
## Behavioral checks against the real 3D physics world, not mesh counts.
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run_checks")

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL  " + description)
	else:
		print("PASS  " + description)

func settle() -> void:
	for i in 5:
		await physics_frame
		await process_frame

func run_checks() -> void:
	var scene := load("res://scenes/regions/taishi/taishi_village.tscn").instantiate() as Node3D
	root.add_child(scene)
	current_scene = scene
	await settle()
	var actor: CharacterBody3D = scene.player
	actor.set_physics_process(false)
	var house: Node3D = scene.get_node("Content/House00")
	check(house.roof.visible, "roof visible from street")
	actor.position = Vector3(-6, 0.15, 3)
	await settle()
	check(actor.move_and_collide(Vector3(0, 0, -4)) == null, "south doorway is physically passable")
	await settle()
	check(not house.roof.visible and not house.front.visible, "interior hides roof and south facade")
	check(actor.move_and_collide(Vector3(0, 0, -4)) == null, "north doorway provides second exit")
	actor.position = Vector3(-6, 0.15, -1)
	await settle()
	var hit := actor.move_and_collide(Vector3(-5, 0, 0))
	check(hit != null and actor.position.x > -9, "solid side wall blocks player")
	actor.position = Vector3(-7.95, 0.15, 3)
	await settle()
	check(actor.move_and_collide(Vector3(0, 0, -3)) != null, "facade stays physically solid while visually hidden")
	actor.position = Vector3(0, 0.2, 4)
	await settle()
	check(house.roof.visible and house.front.visible, "leaving house restores facade and roof")
	actor.set_physics_process(true)
	await settle()
	check(actor.position.y >= -0.05, "terrain supports player with gravity")
	check(scene.camera.current and scene.camera.global_position.y > actor.position.y + 10, "active elevated follow camera")
	var camera_before: float = scene.camera.global_position.x
	actor.position += Vector3(2, 0, 0)
	await settle()
	check(scene.camera.global_position.x > camera_before, "camera follows player movement")
	check(actor.sprite.hframes == 4 and actor.sprite.vframes == 4, "pixel traveler has four directions and four poses")
	actor.set_physics_process(false)
	# Tree protection uses the rendered camera projection, independently of houses.
	actor.position = Vector3(-12.7, 0.15, 3.3)
	await settle()
	scene.foliage.update_cutaway()
	var leaf: ShaderMaterial = scene.foliage.leaf_material
	var expected_uv: Vector2 = scene.camera.unproject_position(actor.global_position + Vector3(0, 0.85, 0)) / root.get_visible_rect().size
	var actual_uv: Vector2 = leaf.get_shader_parameter("target_uv")
	check(actual_uv.distance_to(expected_uv) < 0.001, "leaf cutaway follows normalized camera projection under viewport stretch")
	check(leaf.get_shader_parameter("cutaway_enabled") and leaf.get_shader_parameter("radius_ratio") > 0.02, "tree cutaway enabled with character-sized aperture")
	scene.foliage.enabled = false
	scene.foliage.update_cutaway()
	check(not leaf.get_shader_parameter("cutaway_enabled"), "cutaway can be disabled without touching tree geometry")
	scene.foliage.enabled = true
	actor.position = Vector3(-12, 0.15, 6.5)
	await settle()
	check(actor.move_and_collide(Vector3(0, 0, -2)) != null, "tree trunk collision remains solid")
	actor.position = Vector3(13.5, 0.15, 16)
	await settle()
	check(actor.move_and_collide(Vector3(0, 0, -5)) != null, "pond blocks walking across decorative water")
	actor.position = Vector3(27, 0.15, -2)
	await settle()
	check(actor.move_and_collide(Vector3(3, 0, 0)) != null, "sample boundary prevents falling off terrain")
	for name in ["Content/House02", "Content/House03", "Content/House04"]:
		var home := scene.get_node(name) as Node3D
		actor.position = home.position + Vector3(0, 0.15, 4.1)
		await settle()
		check(actor.move_and_collide(Vector3(0, 0, -4)) == null, "decorated house entrance stays open: " + name)
		await settle()
		check(not home.roof.visible, "new house retains interior cutaway: " + name)
	var grasses := scene.get_node("Content/Ground/GrassTufts") as MultiMeshInstance3D
	check(grasses.multimesh.instance_count > 500 and grasses.get_child_count() == 0, "dense vegetation uses instances instead of hundreds of nodes")
	var layout = load("res://scripts/regions/taishi/layout.gd")
	var trees_on_land := true
	for at in layout.TREES:
		trees_on_land = trees_on_land and not layout.in_pond(Vector2(at.x, at.z))
	check(trees_on_land, "tree trunks are placed on land outside pond")
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
