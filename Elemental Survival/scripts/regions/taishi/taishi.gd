extends Node3D
## Composition root for the art sample, not a replacement survival game.
const Traveler = preload("res://scripts/regions/shared/review_traveler.gd")
const FollowCamera = preload("res://scripts/regions/shared/review_camera.gd")
var player: CharacterBody3D
var camera: Camera3D
const Visibility = preload("res://scripts/regions/shared/foliage_visibility.gd")
var foliage: Node

func _ready() -> void:
	foliage = Visibility.new()
	foliage.name = "FoliageVisibility"
	add_child(foliage)
	var content := preload("res://scenes/regions/taishi/taishi_module.tscn").instantiate()
	content.name = "Content"
	content.bounded = true
	content.leaf_material = foliage.leaf_material
	add_child(content)
	player = Traveler.new()
	player.name = "Traveler"
	player.position = Vector3(0, 0.2, 4)
	if "--capture-village-interior" in OS.get_cmdline_user_args():
		player.position = Vector3(-6, 0.2, -1)
	if "--capture-village-tree" in OS.get_cmdline_user_args() or "--capture-village-tree-solid" in OS.get_cmdline_user_args():
		player.position = Vector3(-12.7, 0.2, 3.3)
	if "--capture-village-garden" in OS.get_cmdline_user_args():
		player.position = Vector3(7, 0.2, 9)
	add_child(player)
	camera = FollowCamera.new()
	camera.name = "FollowCamera"
	camera.target = player
	if "--capture-village-overview" in OS.get_cmdline_user_args():
		camera.distance = 36
	add_child(camera)
	camera.current = true
	player.view_camera = camera
	foliage.target = player
	foliage.camera = camera
	foliage.enabled = not "--capture-village-tree-solid" in OS.get_cmdline_user_args()
	_build_interface()
	if Array(OS.get_cmdline_user_args()).any(func(arg: String) -> bool: return arg.begins_with("--capture-village")):
		_capture.call_deferred()

func _build_interface() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var title := Label.new()
	title.text = "苔石村 / 场景样板"
	title.position = Vector2(30, 22)
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color("f1e2bd"))
	layer.add_child(title)
	var help := Label.new()
	help.text = "WASD 移动 · Q/E 调整远近 · Home 回到路口\n南北门通行 · 房屋自动隐藏 · 树冠局部透视"
	help.position = Vector2(30, 65)
	help.add_theme_font_size_override("font_size", 17)
	help.add_theme_color_override("font_color", Color("e2dec9"))
	layer.add_child(help)
	var footer := Label.new()
	footer.text = "3D 场景 × 2D 像素人物  |  美术与空间验证，战斗系统尚未迁入"
	footer.position = Vector2(30, 754)
	footer.add_theme_font_size_override("font_size", 17)
	layer.add_child(footer)

func _capture() -> void:
	for i in 35:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var filename := "village-interior.png" if "--capture-village-interior" in OS.get_cmdline_user_args() else "village-preview.png"
	for suffix in ["tree", "tree-solid", "garden", "overview"]:
		if "--capture-village-" + suffix in OS.get_cmdline_user_args():
			filename = "village-" + suffix + ".png"
	get_viewport().get_texture().get_image().save_png("res://outputs/" + filename)
	get_tree().quit()
