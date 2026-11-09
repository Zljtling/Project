extends SceneTree
const Poison = preload("res://scripts/regions/elemental/poison_layout.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run_checks")

func check(value: bool, title: String) -> void:
	checks += 1
	if value:
		print("PASS  ",title)
	else:
		failures += 1
		push_error("FAIL  "+title)

func run_checks() -> void:
	var game = load("res://scenes/game_run.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.setup.open_loadout()
	game.setup.prepare_escape(20261102)
	game.setup.select_spawn(0)
	game.setup.confirm_spawn()
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.arsenal.set_physics_process(false)
	for enemy in game.enemies:
		enemy.set_physics_process(false)
	var presentation = game.presentation
	presentation._process(0.01)
	var lighting = presentation.lighting
	var sockets := get_nodes_in_group("ambient_lamp_sockets")
	check(sockets.size() >= 40,"authored settlement lanterns register light sockets")
	var lamp_position: Vector3 = sockets[0].global_position
	game.player.position = Vector2(lamp_position.x,lamp_position.z)*32
	lighting._process(0.3)
	var visible_lamps := 0
	for lamp in lighting.local_lights:
		visible_lamps += int(lamp.visible)
	check(lighting.local_lights.size() == 4 and visible_lamps > 0 and visible_lamps <= 4,"nearby settlement activates at most four reused lights")
	check(lighting.local_lights.all(func(lamp: OmniLight3D): return not lamp.shadow_enabled),"decorative lamps do not allocate additional shadow maps")
	game.player.position = game.field_center("fire")
	var old_color: Color = lighting.environment.ambient_light_color
	lighting._process(0.3)
	check(lighting.biome == "fire" and lighting.environment.ambient_light_color != old_color and lighting.environment.ambient_light_color != lighting.ambient_target,"entering fire region interpolates lighting rather than snapping")
	var poison = presentation.poison
	var vents = presentation.fire.get_node("VentEffects")
	var camera: Camera3D = presentation.view_camera
	camera.set_process(false)
	camera.global_position = vents.global_position+Vector3(0,25,18)
	vents.sample_left = 0
	var old_transform: Transform3D = vents.embers.multimesh.get_instance_transform(5)
	vents._process(0.2)
	check(vents.embers.multimesh.instance_count == 42 and vents.embers.multimesh.get_instance_transform(5) != old_transform,"nearby fire animates the bounded ember batch")
	var rendered_clock: float = vents.flame_material.get_shader_parameter("clock")
	camera.global_position = vents.global_position+Vector3(350,25,18)
	vents.sample_left = 0
	vents._process(0.3)
	check(vents.clock > rendered_clock and vents.flame_material.get_shader_parameter("clock") == rendered_clock,"distant vents keep logical phase without uploading per-frame animation")
	camera.global_position = poison.global_position+Vector3(0,25,18)
	poison.sample_left = 0
	poison._process(0.2)
	check(poison.bubbles.size() == 26 and poison.fumes.size() == 22 and poison.acid.get_shader_parameter("clock") == poison.clock,"poison keeps bounded bubbles and smoke synchronized with its shader")
	var effects = presentation.effects
	effects._process(0.01)
	var bridge: Vector2 = game.field_center("poison")+Vector2(1,0)*32
	var expected := Poison.surface_height(Vector2(1,0))
	check(is_equal_approx(effects._point(bridge,0.25).y,expected+0.25),"attack warnings sit above the actual curved bridge deck")
	var acid: Vector2 = game.field_center("poison")+Vector2(12,-13)*32
	check(is_equal_approx(effects._point(acid,1.15).y,1.15),"projectiles over liquid retain their intended height")
	for i in 5000:
		effects._point(Vector2(i*0.13,123),0.2)
	check(effects.ground_heights.size() <= 4096,"effect height cache stays bounded under heavy geometry")
	var accents: Array[Node] = presentation.settlements.find_children("MeadowAccents","",true,false)
	var clear_paths: bool = accents.size() == 6
	for accent in accents:
		for batch in accent.get_children():
			clear_paths = clear_paths and batch.multimesh.instance_count <= 72
			for i in batch.multimesh.instance_count:
				var at: Vector3 = batch.multimesh.get_instance_transform(i).origin
				clear_paths = clear_paths and not accent._reserved(Vector2(at.x,at.z))
	check(clear_paths,"six settlements keep bounded accents outside doors roads and ponds")
	var windmill: Node3D
	for module in presentation.modules:
		if module.get("region") == 0:
			windmill = module
	var sail_angle: float = windmill.sails[0].rotation.z
	windmill._process(0.5)
	check(windmill.sails[0].rotation.z != sail_angle,"windmill landmark rotates without changing collision geometry")
	game.hud.show_menu("inventory")
	var before := [lighting.clock,vents.clock,poison.clock,presentation.meadow.wind_clock,presentation.foliage.clock,windmill.sails[0].rotation.z]
	for i in 3:
		await process_frame
	check(paused and before == [lighting.clock,vents.clock,poison.clock,presentation.meadow.wind_clock,presentation.foliage.clock,windmill.sails[0].rotation.z],"inventory pause freezes light flicker fumes embers grass canopy and sails")
	paused = false
	var old_extra: WeakRef = weakref(presentation.field_set.extra[-1])
	game.cycle_index += 1
	for element in game.domains:
		game.domains[element] = game._domain_location(element)
	presentation.sync_element_geometry()
	check(old_extra.get_ref() == null and presentation.field_set.extra.size() == 4,"migration destroys obsolete effect owners while keeping four extra regions")
	var old_embers: WeakRef = weakref(vents.embers.multimesh)
	for part in game.objectives.PARTS:
		game.objectives.acquire(part)
	game.player.position = game.ENTRANCE
	check(game.enter_dungeon(),"actual dungeon transition remains available")
	presentation._process(0.1)
	await process_frame
	lighting._process(0.3)
	effects._process(0.01)
	check(old_embers.get_ref() == null and get_nodes_in_group("ambient_lamp_sockets").is_empty(),"dungeon transition releases ember resources and settlement light sockets")
	check(lighting.biome == "dungeon" and lighting.local_lights.all(func(lamp: OmniLight3D): return not lamp.visible),"dungeon lighting cannot retain outdoor lamp assignments")
	check(effects.poison_centers.is_empty() and is_equal_approx(effects._point(game.player.position,0.25).y,0.25),"dungeon effects clear surface height data")
	print("RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
