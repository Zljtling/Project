extends CanvasLayer

var world: Node2D
var root: Control
var health_bar: ProgressBar
var health_text: Label
var cycle_text: Label
var cycle_note: Label
var status: Label
var interaction: Label
var toast: Label
var stats: Label
var dash_label: Label
var weapon_bars: Array[ProgressBar] = []
var modal: ColorRect
var menu_kind := ""
var menu_title: Label
var menu_body: Label
var primary_button: Button
var armor_button: Button
var fast_button: Button
var minimap: Control
var theme_data: Theme
var phase_title: Label
var weapon_labels: Array[Label] = []
var modal_header: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 30
	theme_data = Theme.new()
	theme_data.default_font = world.font
	theme_data.default_font_size = 16
	theme_data.set_color("font_color", "Label", Color("d4e3de"))
	theme_data.set_stylebox("normal", "Button", box(Color("294541"), Color("4d7268")))
	theme_data.set_stylebox("hover", "Button", box(Color("3c5b4c"), Color("bfe5a2")))
	theme_data.set_stylebox("pressed", "Button", box(Color("1e3637"), Color("f2be7d")))
	theme_data.set_stylebox("focus", "Button", box(Color(0, 0, 0, 0), Color("e4ba77")))
	theme_data.set_color("font_color", "Button", Color("f2ebd7"))
	preload("res://scripts/ui/game_theme.gd").apply(theme_data)
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = theme_data
	add_child(root)
	var left := panel_at(Vector2(22, 20), Vector2(320, 137))
	var col := column(left)
	label(col, "ELEMENTAL  /  SURVIVAL", 13, Color("9ab3a4"))
	phase_title = label(col, "移动世界 · 战斗与场景原型", 21, Color("f4ddb0"))
	health_bar = progress(col, Color("e3aa78"))
	health_text = label(col, "", 14)
	var right := panel_at(Vector2(-310, 20), Vector2(288, 128), true)
	col = column(right)
	cycle_note = label(col, "世界变化倒计时", 13, Color("a1b8af"))
	cycle_text = label(col, "06:00", 33, Color("f7d7a4"))
	stats = label(col, "", 14)
	var map_panel := panel_at(Vector2(-202, 162), Vector2(180, 146), true)
	var map_col := column(map_panel)
	label(map_col, "区域概览", 12, Color("9ab3a4"))
	minimap = Control.new()
	minimap.custom_minimum_size = Vector2(156, 100)
	map_col.add_child(minimap)
	minimap.draw.connect(draw_map)
	var bottom := panel_at(Vector2(22, -103), Vector2(612, 81), false, true)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 10)
	bottom.add_child(margin)
	margin.add_child(row)
	for spec in world.arsenal.specs:
		var slot := VBoxContainer.new()
		slot.custom_minimum_size = Vector2(125, 0)
		row.add_child(slot)
		weapon_labels.append(label(slot, spec.title + "  ★", 16, spec.color))
		weapon_bars.append(progress(slot, spec.color))
	var dash_box := VBoxContainer.new()
	row.add_child(dash_box)
	dash_label = label(dash_box, "", 14, Color("9de1cd"))
	label(dash_box, "Space 冲刺", 13)
	var hint_panel := panel_at(Vector2(-358, -110), Vector2(336, 88), true, true)
	col = column(hint_panel)
	label(col, "WASD 移动  ·  右键标记 / 取消", 14)
	label(col, "E 交互  ·  Tab 背包  ·  Esc 暂停", 14)
	label(col, "F1 操作说明  ·  F6 世界计时加速", 13, Color("9ab3a4"))
	status = Label.new()
	status.position = Vector2(24, 170)
	status.add_theme_font_size_override("font_size", 15)
	root.add_child(status)
	interaction = centered_label(-166, 19, Color("f5dcaa"))
	toast = centered_label(24, 17, Color("f5dcaa"), true)
	_build_modal()

func panel_at(position: Vector2, size: Vector2, right := false, bottom := false) -> Panel:
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if right:
		panel.anchor_left = 1.0
		panel.anchor_right = 1.0
	if bottom:
		panel.anchor_top = 1.0
		panel.anchor_bottom = 1.0
	panel.position = position
	panel.size = size
	panel.add_theme_stylebox_override("panel", preload("res://scripts/ui/game_theme.gd").paper())
	root.add_child(panel)
	return panel

func column(parent: Control) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 9)
	parent.add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 5)
	margin.add_child(col)
	return col

func label(parent: Node, text: String, size := 16, _color := Color("493f30")) -> Label:
	var item := Label.new()
	item.text = text
	item.add_theme_font_size_override("font_size", size)
	item.add_theme_color_override("font_color", Color("496950") if size >= 20 else Color("493f30"))
	parent.add_child(item)
	return item

func progress(parent: Node, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 8)
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", box(Color("233b3b"), Color("233b3b")))
	bar.add_theme_stylebox_override("fill", box(color, color))
	parent.add_child(bar)
	return bar

func centered_label(y: float, size: int, color: Color, top := false) -> Label:
	var item := Label.new()
	item.anchor_left = 0.5
	item.anchor_right = 0.5
	item.anchor_top = 0.0 if top else 1.0
	item.anchor_bottom = item.anchor_top
	item.offset_left = -430
	item.offset_right = 430
	item.offset_top = y
	item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item.add_theme_font_size_override("font_size", size)
	item.add_theme_color_override("font_color", color)
	item.add_theme_color_override("font_outline_color",Color("303b2c"))
	item.add_theme_constant_override("outline_size",4)
	root.add_child(item)
	return item

func box(background: Color, border: Color) -> StyleBoxFlat:
	return preload("res://scripts/ui/game_theme.gd").frame(background,border)

func _build_modal() -> void:
	modal = ColorRect.new()
	modal.color = Color(0.04,0.05,0.04,0.72)
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(modal)
	var panel := Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -310
	panel.offset_right = 310
	panel.offset_top = -248
	panel.offset_bottom = 248
	panel.add_theme_stylebox_override("panel", preload("res://scripts/ui/game_theme.gd").paper())
	modal.add_child(panel)
	var col := column(panel)
	var margin := col.get_parent() as MarginContainer
	for side in ["left","right","top","bottom"]:
		margin.add_theme_constant_override("margin_"+side,24)
	col.add_theme_constant_override("separation", 15)
	modal_header = label(col, "ELEMENTAL SURVIVAL   /   PROTOTYPE 01", 13, Color("9cc3a9"))
	menu_title = label(col, "", 30, Color("f5d5a2"))
	menu_body = label(col, "", 17)
	menu_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	armor_button = Button.new()
	armor_button.custom_minimum_size.y = 42
	armor_button.pressed.connect(func():
		world.player.equip_suit("" if world.player.poison_protection else "poison")
		_refresh_armor_button()
	)
	col.add_child(armor_button)
	fast_button = Button.new()
	fast_button.custom_minimum_size.y = 40
	fast_button.pressed.connect(toggle_fast)
	col.add_child(fast_button)
	primary_button = Button.new()
	preload("res://scripts/ui/game_theme.gd").primary(primary_button)
	primary_button.custom_minimum_size.y = 46
	primary_button.pressed.connect(_primary)
	col.add_child(primary_button)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("fast_cycle") and not world.run_over:
		toggle_fast()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory") and world.started and not world.run_over:
		if modal.visible:
			hide_menu()
		else:
			show_menu("inventory")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause_run") and world.started and not world.run_over:
		if modal.visible:
			hide_menu()
		else:
			show_menu("pause")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("help") and not world.run_over:
		show_menu("help")
		get_viewport().set_input_as_handled()

func toggle_fast() -> void:
	world.cycle_speed = 6.0 if world.cycle_speed == 1.0 else 1.0
	fast_button.text = "世界计时 ×%d  ·  点击切换测试速度" % int(world.cycle_speed)
	world.notify("仅世界变化计时 ×%d；移动、伤害和武器速度保持正常。" % int(world.cycle_speed))

func _primary() -> void:
	if world.run_over:
		get_tree().paused = false
		get_tree().reload_current_scene()
	elif not world.started:
		world.start_run()
	else:
		hide_menu()

func show_menu(kind: String) -> void:
	menu_kind = kind
	modal.show()
	get_tree().paused = true
	armor_button.visible = kind == "inventory"
	fast_button.visible = kind != "death"
	fast_button.text = "世界计时 ×%d  ·  点击切换测试速度" % int(world.cycle_speed)
	primary_button.text = "开始探索" if not world.started else "继续游戏"
	match kind:
		"intro", "help":
			menu_title.text = "会变化的世界"
			menu_body.text = "阶段一 · 战斗与场景测试\n\nWASD 移动，Space 冲刺，武器自动攻击。\n右键点击敌人标记集火；右键空地取消。\n\n左下拾取生化套装 [E]，右侧进入毒领域。\n无防护会中毒；进入领域可临时获得毒附魔。\n高塔城堡直接走入，怪物同样能进入。\n\nTab 打开背包并暂停，可切换防毒装备。\nF6 加速世界计时，观察预警与高塔下陷。"
		"inventory":
			menu_title.text = "背包 · 世界已暂停"
			menu_body.text = "已装备：弧刃 / 追风针 / 震荡核\n\n防护槽：整套防护装备，占用一个槽。\n毒附魔：接触领域后短暂保留，附带持续毒伤。\n\n本原型用固定武器验证战斗和环境利用。\n锻造、技能与完整装备成长在后续阶段加入。"
			_refresh_armor_button()
		"pause":
			menu_title.text = "暂歇片刻"
			menu_body.text = "敌人、世界倒计时和战斗效果均已暂停。\n\n尝试把敌人引入毒领域，再登上高塔。\n用右键集火清理退路，留意高塔下陷预警。\n\nF1 随时查看操作说明。"
		"death":
			menu_title.text = "本次探索结束"
			menu_body.text = "生存 %02d:%02d  ·  击败 %d 个敌人\n经历第 %d 个世界周期\n\n可以尝试更早穿上生化套装，或在被包围前冲刺离开。\n\n这是玩法测试场；完整逃离目标在后续阶段加入。" % [int(world.run_time) / 60, int(world.run_time) % 60, world.kills, world.cycle_index]
			primary_button.text = "重新开局"

func _refresh_armor_button() -> void:
	armor_button.disabled = not world.player.armor_owned
	if not world.player.armor_owned:
		armor_button.text = "尚未拾取生化套装 · 前往地图上的绿色装备箱"
	else:
		armor_button.text = "生化套装：已穿戴 · 点击脱下" if world.player.poison_protection else "生化套装：未穿戴 · 点击穿上"

func hide_menu() -> void:
	modal.hide()
	menu_kind = ""
	if world.started and not world.run_over:
		get_tree().paused = false

func _process(_delta: float) -> void:
	if not is_instance_valid(world.player):
		return
	health_bar.max_value = world.player.health.maximum
	health_bar.value = world.player.health.current
	health_text.text = "%d / %d 生命" % [ceili(world.player.health.current), int(world.player.health.maximum)]
	var remaining := ceili(world.cycle_left)
	cycle_text.text = "%02d:%02d" % [remaining / 60, remaining % 60]
	cycle_note.text = "第 %d 轮  /  世界计时 ×%d" % [world.cycle_index, int(world.cycle_speed)]
	cycle_text.modulate = Color("ffb278") if world.cycle_left <= world.warning_duration else Color.WHITE
	stats.text = "击败 %d  ·  场上 %d  ·  生存 %02d:%02d" % [world.kills, world.enemies.size(), int(world.run_time) / 60, int(world.run_time) % 60]
	var lines: Array[String] = []
	if world.player.poison_protection:
		lines.append("● 生化套装 / 毒气免疫")
	if world.player.in_poison:
		lines.append("● 身处硫酸池" if world.player.poison_protection else "！硫酸持续伤害 · 尽快离开")
	if world.player.poison_enchantment > 0.0:
		lines.append("● 毒附魔 %.1fs" % world.player.poison_enchantment)
	if world.player.on_tower:
		lines.append("▲ 高塔城堡 / 敌人同样可以进入")
	if is_instance_valid(world.marked):
		lines.append("◎ 已标记优先目标")
	status.text = "\n".join(lines)
	interaction.text = world.interaction_hint()
	toast.text = world.message if world.message_left > 0.0 else ""
	# Keep the center clear; temporary guidance sits below the top HUD.
	toast.offset_top = 166
	for i in weapon_bars.size():
		weapon_bars[i].value = 100.0 * (1.0 - world.arsenal.cooldowns[i] / world.arsenal.specs[i].interval) if world.arsenal.specs[i] != null else 0.0
	dash_label.text = "就绪" if world.player.dash_cooldown <= 0.0 else "%.1fs" % world.player.dash_cooldown
	minimap.queue_redraw()

func draw_map() -> void:
	var scale_map: Vector2 = Vector2(156, 100) / world.MAP_SIZE
	minimap.draw_rect(Rect2(Vector2.ZERO, Vector2(156, 100)), Color("1d3737"))
	minimap.draw_circle(world.field_center("poison") * scale_map, 11, Color("769b4f"))
	minimap.draw_rect(Rect2(world.tower_position * scale_map - Vector2(5, 5), Vector2(10, 10)), Color("dfbe88"))
	if not world.player.armor_owned:
		minimap.draw_circle(world.ARMOR_PICKUP * scale_map, 3, Color("b7ee8d"))
	minimap.draw_circle(world.player.position * scale_map, 4, Color("ffe4ba"))
