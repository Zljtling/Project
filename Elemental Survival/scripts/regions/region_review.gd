extends Node3D
## All six regions in one connected review world; no duplicate combat/economy.
const Parts = preload("res://scripts/regions/shared/model_parts.gd")
const Catalog = preload("res://scripts/regions/region_catalog.gd")
const IDS := ["windmill_town","waterfront","farm","overgrown","broken_bridge","taishi"]
const CENTERS := [Vector3(-75,0,-60),Vector3(0,0,-60),Vector3(75,0,-60),Vector3(-75,0,25),Vector3(0,0,25),Vector3(75,0,25)]
var modules: Array[Node3D] = []
var player: CharacterBody3D
var camera: Camera3D
var foliage: Node
var loot: Node3D
var title: Label
var hint: Label
var selected := 5
var toast := ""

func _ready() -> void:
	var material := ShaderMaterial.new()
	material.shader = preload("res://assets/regions/shared/ground_grass.gdshader")
	Parts.box(self,"WorldGround",Vector3(310,0.4,230),Vector3(0,-0.2,-17),material,true)
	var road := Parts.material(Color("b6a88b"),"dirt",Vector3.ONE*0.4)
	# Wide connecting roads remain clear of local building footprints.
	Parts.box(self,"NorthLink",Vector3(210,0.02,3),Vector3(0,0.01,-25),road)
	Parts.box(self,"SouthLink",Vector3(210,0.02,3),Vector3(0,0.01,61),road)
	for x in [-37,38]:
		Parts.box(self,"WorldSpine",Vector3(3,0.02,89),Vector3(x,0.01,18),road)
	for x in [-151,151]:
		Parts.box(self,"WorldBoundary",Vector3(0.5,4,225),Vector3(x,2,-17),road,true).hide()
	for z in [-128,94]:
		Parts.box(self,"WorldBoundary",Vector3(302,4,0.5),Vector3(0,2,z),road,true).hide()
	for center in CENTERS:
		Parts.box(self,"RegionApproach",Vector3(3,0.02,38),center+Vector3(-27,0.01,24),road)
	player = preload("res://scripts/regions/shared/review_traveler.gd").new()
	player.name = "Traveler"
	add_child(player)
	camera = preload("res://scripts/regions/shared/review_camera.gd").new()
	camera.target = player
	camera.distance = 40
	camera.keyboard_zoom = false
	camera.view_offset = Vector3(0,1.5,-2)
	add_child(camera)
	camera.current = true
	player.view_camera = camera
	foliage = preload("res://scripts/regions/shared/foliage_visibility.gd").new()
	foliage.target = player
	foliage.camera = camera
	add_child(foliage)
	for i in 6:
		var module: Node3D
		if i == 5:
			module = _taishi_module()
			module.leaf_material = foliage.leaf_material
		else:
			module = preload("res://scripts/regions/region_module.gd").new()
			module.region = i
			module.leaf_material = foliage.leaf_material
		module.name = IDS[i]
		module.position = CENTERS[i]
		add_child(module)
		modules.append(module)
	loot = preload("res://scripts/regions/shared/room_loot.gd").new()
	loot.name = "RoomLoot"
	add_child(loot)
	loot.populate(get_tree().get_nodes_in_group("enterable_house"),20261102)
	loot.searched.connect(func(kind: String): toast = "已检查"+("宝箱" if kind == "chest" else "补给箱")+" · 空间交互已验证")
	_build_ui()
	visit_region(5)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-review="):
			visit_region(int(arg.get_slice("=",1)))
			_capture.call_deferred()

func _taishi_module() -> Node3D:
	# Reuse Taishi's layout/models without its second camera, player or UI.
	return preload("res://scenes/regions/taishi/taishi_module.tscn").instantiate()

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(20,18)
	layer.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	title = Label.new()
	title.add_theme_font_size_override("font_size",23)
	column.add_child(title)
	var help := Label.new()
	help.text = "1—6 切换区域 · WASD 移动 · Shift 快行 · 滚轮调整远近\nE 检查室内箱子 · Home 返回区域入口 · Esc 返回主菜单\n区域复核：战斗、奖励及元素/高塔区域尚未接入"
	column.add_child(help)
	hint = Label.new()
	column.add_child(hint)

func _process(_delta: float) -> void:
	if not is_instance_valid(player) or hint == null:
		return
	player.speed = 12 if Input.is_physical_key_pressed(KEY_SHIFT) else 5
	var closest := selected
	var distance := INF
	for i in CENTERS.size():
		var delta: float = player.global_position.distance_squared_to(CENTERS[i])
		if delta < distance:
			distance = delta
			closest = i
	if closest != selected:
		selected = closest
		player.home_position = CENTERS[selected]+Vector3(-10 if selected != 5 else 0,0.04,24 if selected != 5 else 4)
		title.text = "%d / %s · 区域复核" % [selected+1,Catalog.NAMES[selected]]
	var cache: Dictionary = loot.nearest(player.global_position)
	hint.text = "E 检查"+("宝箱" if cache.get("kind","") == "chest" else "补给箱") if not cache.is_empty() else toast

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	for i in 6:
		if event.physical_keycode == KEY_1+i or event.keycode == KEY_1+i:
			visit_region(i)
	if event.physical_keycode == KEY_E or event.keycode == KEY_E:
		loot.search(player.global_position)
	if event.keycode == KEY_HOME or event.physical_keycode == KEY_HOME:
		visit_region(selected)
	if event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))

func visit_region(index: int) -> void:
	selected = clampi(index,0,5)
	player.global_position = CENTERS[selected]+Vector3(-10 if selected != 5 else 0,0.04,24 if selected != 5 else 4)
	player.velocity = Vector3.ZERO
	player.home_position = player.global_position
	camera._update_camera(1)
	if title != null:
		title.text = "%d / %s · 区域复核" % [selected+1,Catalog.NAMES[selected]]

func _capture() -> void:
	camera.set_process(false)
	var focus: Vector3 = CENTERS[selected]+Vector3(0,1,3)
	camera.global_position = focus+Vector3(0.25,0.8,0.5454).normalized()*60
	camera.look_at(focus)
	if "--review-interior" in OS.get_cmdline_user_args() and not loot.caches.is_empty():
		var cache: Dictionary = loot.caches[0]
		player.global_position = cache["node"].global_position+Vector3(-0.85,0.04,0)
		focus = player.global_position+Vector3(0,0.8,0)
		camera.global_position = focus+Vector3(0.25,0.8,0.5454).normalized()*22
		camera.look_at(focus)
	for i in 18:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var file := "region-room-loot.png" if "--review-interior" in OS.get_cmdline_user_args() else "region-review-%d.png" % selected
	get_viewport().get_texture().get_image().save_png("res://outputs/"+file)
	get_tree().quit()
