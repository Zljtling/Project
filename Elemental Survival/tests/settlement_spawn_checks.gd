extends SceneTree
const Policy = preload("res://scripts/world/spawn_locations.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run_checks")

func check(value: bool, label: String) -> void:
	checks += 1
	if value:
		print("PASS  ",label)
	else:
		failures += 1
		push_error("FAIL  "+label)

func run_checks() -> void:
	var game = load("res://scenes/game_run.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	var flow = game.setup
	for seed_value in [1,7,1024,2048,20261102,424242]:
		flow.open_loadout()
		check(flow.prepare_escape(seed_value),"real 3D map prepares settlement selection: %d" % seed_value)
		var names := {}
		var valid: bool = flow.spawn_choices.size() == 6
		for choice in flow.spawn_choices:
			names[choice["name"]] = true
			var matched := false
			for village in game.layout.villages:
				if village["name"] == choice["name"]:
					matched = choice["position"].distance_to(village["position"]) <= Policy.SETTLEMENT_RADIUS
			valid = valid and matched and choice["kind"] == "village" and Policy.is_safe(game,choice["position"])
		check(valid and names.size() == 6,"exactly one safe landing belongs to each of the six settlements: %d" % seed_value)
		var map_view = game.hud.extras.get_node("SpawnMap")
		check(map_view.spawn_options == flow.spawn_choices and paused and not game.started,"map exposes only the six choices while the world remains paused: %d" % seed_value)
	var original: Dictionary = flow.spawn_choices[0].duplicate()
	var wilderness := Vector2.INF
	for y in range(700,11000,700):
		for x in range(700,15000,700):
			var candidate := Vector2(x,y)
			if not game.layout.clear_point(candidate,35) or game.tower_rect().grow(120).has_point(candidate):
				continue
			if game.layout.villages.any(func(v: Dictionary): return candidate.distance_to(v["position"]) < 1000):
				continue
			if game.zones.entries.any(func(z: Dictionary): return candidate.distance_to(z["position"]) < 1300):
				continue
			wilderness = candidate
			break
		if wilderness != Vector2.INF:
			break
	check(wilderness != Vector2.INF and not Policy.is_safe(game,wilderness),"clear non-elemental wilderness is rejected by authoritative spawn policy")
	flow.spawn_choices[0]["position"] = wilderness
	check(not flow.select_spawn(0),"selection rejects a forged outdoor coordinate")
	flow.spawn_choices[0] = original.duplicate()
	flow.select_spawn(0)
	flow.spawn_choices[0]["position"] = wilderness
	check(not flow.confirm_spawn() and not game.started and paused,"confirmation revalidates settlement membership and cannot start outdoors")
	flow.spawn_choices[0] = original.duplicate()
	# Block every preferred landing with a temporary facility. The bounded fallback must stay local.
	var original_facilities: Array = game.facilities.duplicate()
	var center: Vector2 = game.layout.villages[0]["position"]
	for offset in [Vector2.ZERO,Vector2(40,300),Vector2(40,-300),Vector2(-500,0),Vector2(500,0),Vector2(0,550),Vector2(0,-550)]:
		game.facilities.append({"kind":"supply","position":center+offset})
	var choices := Policy.choices(game)
	var fallback_valid := false
	for choice in choices:
		if choice["name"] == game.layout.villages[0]["name"]:
			fallback_valid = Policy.is_safe(game,choice["position"]) and choice["position"].distance_to(center) <= Policy.SETTLEMENT_RADIUS
	check(choices.size() == 6 and fallback_valid,"blocked preferred landings use another safe spot in the same settlement")
	game.facilities.assign(original_facilities)
	flow.select_spawn(0)
	check(flow.confirm_spawn() and game.player.position == original["position"],"approved settlement selection still places the player and starts the run")
	print("RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
