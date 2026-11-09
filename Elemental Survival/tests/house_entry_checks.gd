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

func walk(actor: CharacterBody3D, direction: Vector3, frames: int) -> void:
	for i in frames:
		await physics_frame
		actor.velocity = direction * 5 + Vector3.DOWN * 0.3
		actor.move_and_slide()

func run_checks() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	current_scene = stage
	var parts = load("res://scripts/regions/shared/model_parts.gd")
	parts.box(stage, "Ground", Vector3(30, 0.4, 30), Vector3(0, -0.2, 0), parts.material(Color.GRAY), true)
	var actor = load("res://scripts/regions/shared/review_traveler.gd").new()
	stage.add_child(actor)
	actor.set_physics_process(false)
	for variant in 4:
		var house = load("res://scenes/regions/shared/stone_house.tscn").instantiate()
		house.variant = variant
		stage.add_child(house)
		actor.position = Vector3(0, 0, 5)
		await walk(actor, Vector3.FORWARD, 60)
		check(absf(actor.position.z) < 0.3, "walk into south door from ground level, variant %d" % variant)
		check(not house.roof.visible, "walking into room hides roof, variant %d" % variant)
		await walk(actor, Vector3.FORWARD, 60)
		check(actor.position.z < -4, "walk out north door, variant %d" % variant)
		house.queue_free()
		await process_frame
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
