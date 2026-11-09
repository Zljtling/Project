extends SceneTree
var count := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run_checks")

func check(value: bool, title: String) -> void:
	count += 1
	if not value:
		failures += 1
		push_error("FAIL  "+title)
	else:
		print("PASS  ",title)

func run_checks() -> void:
	var game = load("res://scenes/game_run.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.setup.open_loadout()
	game.setup.starter = "needle"
	game.setup.prepare_escape(20261102)
	game.setup.select_spawn(0)
	game.setup.confirm_spawn()
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.arsenal.set_physics_process(false)
	check(game.presentation.view_camera.projection == Camera3D.PROJECTION_ORTHOGONAL,"actual game uses orthographic framing for sprites and combat")
	var variants := {}
	for entry in [["hunter",""],["guardian","poison"],["guardian","fire"],["guardian",""]]:
		var boss = game.spawn_boss(entry[0],entry[1])
		boss.set_physics_process(false)
	for role in ["ghoul","charger","spitter"]:
		var mob = game.spawn_enemy()
		mob.archetype = role
		mob.set_physics_process(false)
	game.presentation._process(0.1)
	variants[game.presentation.player_proxy.sprite.texture.resource_path] = true
	for proxy in game.presentation.proxies.values():
		variants[proxy.sprite.texture.resource_path] = true
	check(variants.size() == 9,"player, ghoul, elite and four boss roles have independent sprite sheets")
	game.arsenal.shots.append({"position":game.player.position+Vector2(60,0),"direction":Vector2.RIGHT,"life":0.8,"color":Color.WHITE})
	game.presentation.effects._process(0.01)
	check(game.presentation.effects.batch.get_surface_count() == 2,"live projectile adds a filled triangle batch instead of relying on thin lines")
	var cache: Dictionary = game.facilities.filter(func(f: Dictionary): return f.get("indoor",false))[0]
	game.player.position = cache["position"]
	game.presentation._process(0.01)
	var marker = game.presentation.facilities.get_child(game.facilities.find(cache)).get_child(-1)
	marker._process(0.1)
	check(marker.tag.visible and marker.halo.visible,"nearby reachable indoor loot has category label and halo")
	game.player.position += Vector2(1600,0)
	marker._process(0.1)
	check(not marker.tag.visible and not marker.halo.visible,"distant loot does not clutter screen or reveal through the world")
	for i in 4:
		game.progression.random_weapon()
	game.hud.show_menu("forge")
	var forge = game.hud.extras.get_node("ForgePanel")
	check(forge.find_child("RecipePreview",true,false) != null and forge.find_child("ForgeInventoryGrid",true,false) != null,"forge has visible recipe slots and selectable inventory cards")
	check(forge.find_child("RecipePreview",true,false).get_parent() != forge.find_child("InventoryScroll",true,false),"inventory scroll is separate from the always visible recipe")
	game.hud.show_menu("inventory")
	var grid = game.hud.extras.get_node("InventoryGrid")
	var item = game.progression.inventory[1]
	grid.get_child(1).pressed.emit()
	check(game.progression.equipped[0] == item,"grid inventory selection equips the actual owned weapon")
	print("RESULT: %d checks, %d failures" % [count,failures])
	quit(1 if failures else 0)
