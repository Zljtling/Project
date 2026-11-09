extends SceneTree
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run_checks")

func check(value: bool, message: String) -> void:
	checks += 1
	if value:
		print("PASS  ", message)
	else:
		failures += 1
		push_error("FAIL  " + message)

func settle() -> void:
	for i in 5:
		await physics_frame
		await process_frame

func run_checks() -> void:
	var gallery = load("res://scenes/regions/region_gallery.tscn").instantiate()
	root.add_child(gallery)
	current_scene = gallery
	await settle()
	var actor: CharacterBody3D = gallery.player
	actor.set_physics_process(false)
	check(gallery.camera.current, "region gallery reuses active follow camera")
	actor.position = Vector3(-5, 0.15, 0)
	await settle()
	check(actor.move_and_collide(Vector3(0, 0, -4)) != null, "windmill tower blocks player movement")
	gallery.show_region(1)
	actor.position = Vector3(7, 0.15, -3)
	await settle()
	check(actor.move_and_collide(Vector3(0, 0, -5)) != null, "waterfront blocks walking off quay into water")
	gallery.show_region(2)
	actor.position = Vector3(3, 0.15, -1)
	await settle()
	check(actor.move_and_collide(Vector3(0, 0, -4)) != null, "farm silo has solid collision")
	gallery.show_region(3)
	actor.position = Vector3(-8, 0.15, -2)
	await settle()
	check(actor.move_and_collide(Vector3(4, 0, 0)) != null, "abandoned walls remain physical obstacles")
	gallery.show_region(4)
	actor.position = Vector3(-1.5, 0, 6)
	await settle()
	for i in 156:
		await physics_frame
		actor.velocity = Vector3(5,-0.3,0)
		actor.move_and_slide()
	check(actor.position.x > 10.5, "walk from ground across intact detour bridge without a collision lip")
	actor.position = Vector3(0.8, 0.4, -4)
	await settle()
	check(actor.move_and_collide(Vector3(8, 0, 0)) != null, "missing bridge span cannot be crossed")
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
