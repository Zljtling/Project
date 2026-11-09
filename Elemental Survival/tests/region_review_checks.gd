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

func run_checks() -> void:
	var stage = load("res://scenes/regions/region_review.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await process_frame
	var actor: CharacterBody3D = stage.player
	actor.set_physics_process(false)
	check(stage.modules.size() == 6, "six regions are composed in one world")
	var houses := get_nodes_in_group("enterable_house")
	check(houses.size() == 44, "expanded regions provide 44 enterable houses")
	check(stage.loot.caches.size() == 17, "review loot reuses the ten-supply seven-chest budget")
	var supplies := 0
	var socket_placement := true
	for cache in stage.loot.caches:
		supplies += int(cache["kind"] == "supply")
		socket_placement = socket_placement and cache["node"].global_position.is_equal_approx(cache["socket"].global_position)
	check(supplies == 10 and socket_placement, "indoor caches occupy randomized house sockets")
	for region in range(6):
		var module: Node3D = stage.modules[region]
		var local_houses := houses.filter(func(home: Node): return module.is_ancestor_of(home))
		check(local_houses.size() >= (5 if region == 5 else 7), "region has a neighborhood rather than one landmark: %d" % region)
		for home in local_houses:
			actor.global_position = home.global_position+Vector3(0,0,4.1)
			for i in 50:
				await physics_frame
				actor.velocity = Vector3(0,-0.3,-5)
				actor.move_and_slide()
			check(absf(actor.global_position.z-home.global_position.z) < 0.5, "walk through real door without teleporting over threshold: "+home.name)
			await physics_frame
			check(not home.roof.visible, "entered house reveals interior: "+home.name)
	var cache: Dictionary = stage.loot.caches[0]
	actor.global_position = cache["node"].global_position+Vector3(0.9,0.04,0)
	var cache_position: Vector3 = cache["node"].global_position
	check(stage.loot.search(actor.global_position), "indoor container can be searched from walkable floor")
	check(not stage.loot.search(cache_position), "same indoor container cannot be searched twice")
	var mesh_a = load("res://scripts/regions/shared/model_parts.gd").box(stage,"CacheA",Vector3.ONE,Vector3(0,10,0),null)
	var mesh_b = load("res://scripts/regions/shared/model_parts.gd").box(stage,"CacheB",Vector3.ONE,Vector3(0,12,0),null)
	check(mesh_a.mesh == mesh_b.mesh, "repeated box models share immutable mesh resources")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	stage._unhandled_key_input(escape)
	for i in 3:
		await process_frame
	var menu = current_scene
	check(menu is Node2D and paused and menu.hud.menu_kind == "main", "review Escape returns to paused game main menu")
	var review_button: Button
	for child in menu.hud.extras.get_children():
		if child is Button and child.text.begins_with("三维区域复核"):
			review_button = child
	check(review_button != null, "main menu exposes the integrated region review entry")
	if review_button != null:
		review_button.pressed.emit()
		for i in 3:
			await process_frame
		check(current_scene is Node3D and not paused and current_scene.modules.size() == 6, "main menu button opens six-region review world")
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
