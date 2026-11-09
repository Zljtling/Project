extends SceneTree
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run_checks")

func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS  ", description)
	else:
		failures += 1
		push_error("FAIL  " + description)

func choose_target(hud: Node, weapon: ESWeaponInstance) -> Node:
	var panel = hud.extras.get_node("ForgePanel")
	var index: int = panel.targets.find(weapon)
	panel.find_child("TargetPicker",true,false).item_selected.emit(index)
	return panel

func run_checks() -> void:
	var game = load("res://scenes/validation/planar_run.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.start_run()
	var p: ESRunProgression = game.progression
	var equipped_before := p.equipped.duplicate()
	var target := p.random_weapon()
	var first := p.random_weapon()
	var second := p.random_weapon()
	first.elements = {"fire": 2}
	second.elements = {"poison": 1}
	game.hud.show_menu("forge")
	var panel := choose_target(game.hud, target)
	check(panel.main == target and target not in p.equipped, "forge selects backpack weapon without equipping it")
	check(panel.materials.has(first) and panel.materials.has(second), "forge suggests two spare same-star materials")
	check(not panel.find_child("ConfirmCombine",true,false).disabled, "spare weapon can upgrade directly from forge")
	check(paused, "forge keeps world paused")
	if "--capture-forge" in OS.get_cmdline_user_args():
		for i in 5:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://outputs/forge-preview.png")
		quit()
		return
	panel.find_child("ConfirmCombine",true,false).pressed.emit()
	check(target.stars == 2 and target in p.inventory and target not in p.equipped, "upgraded spare remains in backpack")
	check(p.equipped == equipped_before, "upgrading spare preserves all three equipped slots")
	check(first not in p.inventory and second not in p.inventory and target.elements == {"fire": 2, "poison": 1}, "only chosen ingredients consumed and enchantments inherited")
	panel = game.hud.extras.get_node("ForgePanel")
	check(panel.main == target, "forge keeps upgraded target selected after refresh")
	panel = choose_target(game.hud, p.equipped[0])
	check(panel.find_child("ConfirmCombine",true,false).disabled and panel.materials == [null, null], "equipped materials never auto-consumed when backpack is empty")
	panel.find_child("AllowEquippedMaterials",true,false).button_pressed = true
	check(panel.materials == [null, null], "equipped materials require explicit selection after opt-in")
	panel.find_child("Material0",true,false).item_selected.emit(1)
	panel.find_child("Material1",true,false).item_selected.emit(1)
	check(panel.materials[0] == null and panel.find_child("ConfirmCombine",true,false).disabled, "same material cannot occupy both ingredient slots")
	panel.find_child("Material0",true,false).item_selected.emit(2)
	panel.find_child("ConfirmCombine",true,false).pressed.emit()
	check(p.equipped[0].stars == 2 and p.equipped[1] == null and p.equipped[2] == null, "explicitly chosen equipped materials consume only their own slots")
	target.stars = 3
	p.miracles = 1
	game.hud.show_menu("forge")
	panel = choose_target(game.hud, target)
	panel.find_child("ConfirmBreakthrough",true,false).pressed.emit()
	check(target.stars == 4 and p.miracles == 0 and target not in p.equipped, "backpack weapon supports four-star breakthrough without equipping")
	p.inventory.clear()
	p.equipped.fill(null)
	game.hud.show_menu("forge")
	panel = game.hud.extras.get_node("ForgePanel")
	check(not (panel.find_child("TargetPicker",true,false) != null), "empty inventory has a safe empty state")
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

