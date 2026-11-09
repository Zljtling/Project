extends Node3D
## Inspect region assets using the existing traveler, camera and foliage systems.
const Parts = preload("res://scripts/regions/shared/model_parts.gd")
const RegionModule = preload("res://scripts/regions/region_module.gd")
const NAMES := ["风车集镇", "东岸旧街", "南部农庄", "荒草聚落", "断桥街区"]
var region_root: Node3D
var player: CharacterBody3D
var camera: Camera3D
var title: Label
var selected := 0
var foliage: Node

func _ready() -> void:
	var grass := ShaderMaterial.new()
	grass.shader = preload("res://assets/regions/shared/ground_grass.gdshader")
	Parts.box(self, "Ground", Vector3(80, 0.3, 70), Vector3(0, -0.15, 0), grass, true)
	for x in [-31.0, 31.0]:
		var bound := Parts.box(self, "Boundary", Vector3(0.3, 4, 62), Vector3(x, 2, 0), grass, true)
		bound.visible = false
	for z in [-31.0, 31.0]:
		var bound := Parts.box(self, "Boundary", Vector3(62, 4, 0.3), Vector3(0, 2, z), grass, true)
		bound.visible = false
	player = preload("res://scripts/regions/shared/review_traveler.gd").new()
	add_child(player)
	camera = preload("res://scripts/regions/shared/review_camera.gd").new()
	camera.target = player
	camera.distance = 44
	camera.view_offset = Vector3(0, 1.5, -2)
	add_child(camera)
	camera.current = true
	player.view_camera = camera
	foliage = preload("res://scripts/regions/shared/foliage_visibility.gd").new()
	foliage.target = player
	foliage.camera = camera
	add_child(foliage)
	for at in [Vector3(-13, 0, -2), Vector3(13, 0, 1), Vector3(-12, 0, 8)]:
		var tree := preload("res://scripts/regions/shared/tree.gd").new()
		tree.position = at
		tree.leaf_material = foliage.leaf_material
		add_child(tree)
	var layer := CanvasLayer.new()
	add_child(layer)
	title = Label.new()
	title.position = Vector2(28, 22)
	title.add_theme_font_size_override("font_size", 25)
	layer.add_child(title)
	var help := Label.new()
	help.text = "1—5 切换区域 · WASD 移动 · Q/E 镜头远近\n区域模型展示，尚未接入完整大地图与战斗"
	help.position = Vector2(28, 65)
	layer.add_child(help)
	show_region(0)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-region="):
			show_region(int(arg.get_slice("=", 1)))
			_capture.call_deferred()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		for i in 5:
			if event.physical_keycode == KEY_1+i or event.keycode == KEY_1+i:
				show_region(i)

func show_region(index: int) -> void:
	if is_instance_valid(region_root):
		remove_child(region_root)
		region_root.queue_free()
	selected = clampi(index, 0, 4)
	region_root = RegionModule.new()
	region_root.region = selected
	region_root.leaf_material = foliage.leaf_material
	add_child(region_root)
	player.position = Vector3(-2, 0.15, 7)
	player.velocity = Vector3.ZERO
	camera._update_camera(1)
	title.text = NAMES[selected] + " / 区域模型"

func _capture() -> void:
	for i in 12:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://outputs/region-%d.png" % selected)
	get_tree().quit()
