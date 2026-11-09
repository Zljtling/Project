extends Node
## Owns pre-run transitions. It delegates geometry, spawning policy and transactions.
signal changed
enum Stage { TITLE, LOADOUT, SPAWN, PLAYING }
const SpawnLocations = preload("res://scripts/world/spawn_locations.gd")
const WEAPONS := ["blade", "needle", "orb"]
var world: Node
var stage := Stage.TITLE
var starter := "blade"
var map_seed := 0
var spawn_choices: Array[Dictionary] = []
var selected_spawn := -1
var error := ""

func open_loadout() -> void:
	if world.started:
		return
	stage = Stage.LOADOUT
	error = ""
	world.hud.show_menu("loadout")

func open_title() -> void:
	if world.started:
		return
	stage = Stage.TITLE
	world.hud.show_menu("main")

func prepare_escape(seed_value := 0) -> bool:
	if stage != Stage.LOADOUT or starter not in WEAPONS or world.started:
		return false
	map_seed = seed_value if seed_value != 0 else int(Time.get_ticks_usec()) ^ int(randi())
	if map_seed == 0:
		map_seed = 1
	world.prepare_map(map_seed)
	spawn_choices = SpawnLocations.choices(world)
	selected_spawn = -1
	if spawn_choices.is_empty():
		error = "没有可用出生点，请返回备战重试。"
		world.hud.show_menu("loadout")
		return false
	stage = Stage.SPAWN
	world.hud.show_menu("spawn")
	return true

func select_spawn(index: int) -> bool:
	if stage != Stage.SPAWN or index < 0 or index >= spawn_choices.size():
		return false
	if not SpawnLocations.is_safe(world, spawn_choices[index]["position"]):
		return false
	selected_spawn = index
	error = ""
	changed.emit()
	return true

func confirm_spawn() -> bool:
	if stage != Stage.SPAWN or selected_spawn < 0 or selected_spawn >= spawn_choices.size():
		return false
	var point: Vector2 = spawn_choices[selected_spawn]["position"]
	if not SpawnLocations.is_safe(world, point):
		error = "该位置已不可用，请重新选择出生区域。"
		selected_spawn = -1
		changed.emit()
		return false
	world.progression.set_starting_weapon(starter)
	world.player.position = point
	world.player.velocity = Vector2.ZERO
	world.player.show()
	stage = Stage.PLAYING
	world.start_run()
	world.camera.reset_smoothing()
	return true
