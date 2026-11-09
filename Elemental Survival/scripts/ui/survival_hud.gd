extends "res://scripts/ui/growth_hud.gd"

const SlotScript := preload("res://scripts/ui/skill_slot.gd")
var slots: Array[Control] = []
var goal_rows: Array[Label] = []
var goal_detail: Label
var weapon_summary: Label
var weapon_heading: Label
var boss_panel: Panel
var boss_title: Label
var boss_health: ProgressBar
var extraction_bar: ProgressBar
var mode_note: Label
var setup_hidden_controls: Array[CanvasItem] = []
var equipment_icons: Array[TextureRect] = []
var equipment_text: Array[Label] = []

func _ready() -> void:
	super._ready()
	for child in root.get_children():
		if child != modal and child is CanvasItem:
			child.hide()
	modal_header.text = "E L E M E N T A L   S U R V I V A L"
	var panel := panel_at(Vector2(22, 20), Vector2(262, 90))
	var col := column(panel)
	phase_title = label(col, "漂移世界  /  生存", 16, Color("eed8aa"))
	health_bar = progress(col, Color("dba476"))
	health_text = label(col, "", 14)
	panel = panel_at(Vector2(-226, 20), Vector2(204, 102), true)
	col = column(panel)
	cycle_note = label(col, "", 12, Color("92aaa2"))
	cycle_text = label(col, "06:00", 28, Color("eac68e"))
	mode_note = label(col, "M 地图 · Tab 装备", 12, Color("c2d3c8"))
	panel = panel_at(Vector2(22, 122), Vector2(262, 164))
	col = column(panel)
	label(col, "逃离目标  /  三个关键部件", 13, Color("9bb5a7"))
	for part in world.objectives.PARTS:
		goal_rows.append(label(col, "○ " + world.objectives.PARTS[part], 15))
	goal_detail = label(col, "", 13, Color("b0c1b4"))
	goal_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel = panel_at(Vector2(22, -92), Vector2(242, 70), false, true)
	resource_label = label(column(panel), "", 14)
	panel = panel_at(Vector2(-258, -170), Vector2(236, 148), true, true)
	col = column(panel)
	weapon_heading = label(col, "武器  /  自动攻击", 12, Color("94b0a2"))
	weapon_summary = label(col, "", 14)
	weapon_summary.hide()
	weapon_summary.add_theme_constant_override("line_spacing", 3)
	for i in 3:
		var equipment_row := HBoxContainer.new()
		col.add_child(equipment_row)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(30,30)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		equipment_row.add_child(icon)
		equipment_icons.append(icon)
		equipment_text.append(label(equipment_row,"",13))
	panel = Panel.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 1
	panel.anchor_bottom = 1
	panel.offset_left = -202
	panel.offset_right = 202
	panel.offset_top = -130
	panel.offset_bottom = -20
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", preload("res://scripts/ui/game_theme.gd").paper())
	root.add_child(panel)
	var row := HBoxContainer.new()
	row.position = Vector2(10, 4)
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	for i in 4:
		var slot := SlotScript.new()
		row.add_child(slot)
		slots.append(slot)
	slots[3].configure("dash", "Space", "冲刺")
	interaction = centered_label(-160, 16, Color("f2d5a1"))
	toast = centered_label(137, 16, Color("f1d39e"), true)
	toast.offset_left = -235
	toast.offset_right = 235
	toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status = Label.new()
	status.position = Vector2(26, 326)
	status.add_theme_font_size_override("font_size", 13)
	status.add_theme_color_override("font_color", Color("a9c798"))
	root.add_child(status)
	boss_panel = Panel.new()
	boss_panel.anchor_left = 0.5
	boss_panel.anchor_right = 0.5
	boss_panel.offset_left = -180
	boss_panel.offset_right = 180
	boss_panel.offset_top = 22
	boss_panel.offset_bottom = 88
	boss_panel.add_theme_stylebox_override("panel", preload("res://scripts/ui/game_theme.gd").paper())
	boss_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(boss_panel)
	col = column(boss_panel)
	boss_title = label(col, "", 14, Color("eac08d"))
	boss_health = progress(col, Color("bf795e"))
	extraction_bar = ProgressBar.new()
	extraction_bar.anchor_left = 0.5
	extraction_bar.anchor_right = 0.5
	extraction_bar.anchor_top = 1
	extraction_bar.anchor_bottom = 1
	extraction_bar.offset_left = -130
	extraction_bar.offset_right = 130
	extraction_bar.offset_top = -184
	extraction_bar.offset_bottom = -174
	extraction_bar.show_percentage = false
	extraction_bar.max_value = 3.5
	extraction_bar.add_theme_stylebox_override("background", box(Color("243b37"), Color("243b37")))
	extraction_bar.add_theme_stylebox_override("fill", box(Color("b8ce91"), Color("b8ce91")))
	root.add_child(extraction_bar)
	root.move_child(modal, root.get_child_count() - 1)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if not world.started and world.setup != null:
		if event.is_action_pressed("pause_run"):
			if menu_kind == "spawn":
				world.setup.open_loadout()
			elif menu_kind == "loadout":
				world.setup.open_title()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("map") or event.is_action_pressed("inventory") or event.is_action_pressed("help") or event.is_action_pressed("fast_cycle"):
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("map") and world.started and not world.run_over:
		if menu_kind != "reward":
			if modal.visible and menu_kind == "map":
				hide_menu()
			else:
				show_menu("map")
		get_viewport().set_input_as_handled()
		return
	super._input(event)

func _primary() -> void:
	if not world.started and world.setup != null:
		match menu_kind:
			"main": world.setup.open_loadout()
			"loadout": world.setup.prepare_escape()
			"spawn":
				if not world.setup.confirm_spawn():
					show_menu("spawn")
		return
	super._primary()

func hide_menu() -> void:
	if world.setup != null and not world.started:
		return
	for item in setup_hidden_controls:
		item.show()
	setup_hidden_controls.clear()
	super.hide_menu()

func show_menu(kind: String) -> void:
	if kind == "intro" and world.setup != null:
		kind = "loadout"
	super.show_menu(kind)
	var panel := modal.get_child(0) as Panel
	panel.offset_left = -310
	panel.offset_right = 310
	panel.offset_top = -350
	panel.offset_bottom = 350
	if kind in ["inventory","forge","shop"]:
		panel.offset_left = -390
		panel.offset_right = 390
		fast_button.hide()
	if kind == "forge":
		panel.offset_left = -520
		panel.offset_right = 520
	if kind == "main":
		panel.offset_left = -360
		panel.offset_right = 360
		panel.offset_top = -290
		panel.offset_bottom = 290
	elif kind == "loadout":
		panel.offset_top = -320
		panel.offset_bottom = 320
	if kind in ["main", "loadout", "spawn"]:
		for child in root.get_children():
			if child is CanvasItem and child != modal and child.visible:
				setup_hidden_controls.append(child)
				child.hide()
		preload("res://scripts/ui/run_setup_panel.gd").build(self, kind)
		if kind == "spawn":
			panel.offset_left = -430
			panel.offset_right = 430
		return
	match kind:
		"intro":
			menu_title.text = "带好技能，逃离漂移世界"
			menu_body.text = "收集核心、棱镜和齿轮，开启固定地牢入口。\n开局选择三个技能，本局不能更换；可在途中持续强化。"
			for child in extras.get_children():
				if child is Label and child.text.begins_with("第二阶段测试"):
					child.text = "完整流程：探索与成长 → 收集部件 → 地牢撤离\nM 查看地图；F6 可加速世界计时进行测试。"
			for id in world.skills.selected:
				var description := label(extras, "%s：%s" % [world.skills.DEFINITIONS[id]["name"], world.skills.DEFINITIONS[id]["description"]], 14)
				description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		"map":
			menu_title.text = "地图 · 世界已暂停"
			menu_body.text = ("地牢 %d / 3：清理敌人，前往北侧门。" % (world.dungeon_room + 1)) if world.in_dungeon else "仅显示入口、元素领域、追猎者、高塔与锻造房。\n宝箱需用寻龙尺探测，补给站需自行寻找。\n点击地图设置路标，按 M 或 Esc 返回。"
			panel.offset_left = -430
			panel.offset_right = 430
			var map_view := preload("res://scripts/ui/world_map.gd").new()
			map_view.world = world
			extras.add_child(map_view)
			armor_button.hide()
			fast_button.hide()
		"forge":
			if not world.objectives.found["gear"] and not world.in_dungeon:
				label(extras, "逃离部件：校准齿轮", 17, Color("e3c38f"))
				action("组装齿轮：75 零件 + 毒材 8 + 火材 8", func():
					if world.objectives.craft_gear():
						show_menu("forge")
					else:
						menu_body.text = "材料不足。需要零件 75、毒材料 8、火材料 8。"
				)
		"enter_dungeon":
			menu_title.text = "开启最终地牢"
			menu_body.text = "三个部件已齐备，属性加成会保留。\n\n进入后开始稳定地牢的三段挑战，无法返回地表。\n地表计时与敌人冻结，部件不消耗。\n\n确认准备好武器、防护、技能与生命值后再进入。"
			action("准备就绪 · 进入地牢", func(): world.enter_dungeon())
			primary_button.text = "再准备一下"
		"help":
			menu_title.text = "操作与逃离目标"
			menu_body.text = "WASD 移动 · Space 冲刺 · 右键标记集火\n1 / 2 / 3 使用技能 · R 上下载具\nE 交互 · Tab 装备与附魔 · M 地图 · Esc 暂停\n\n核心：击杀 BOSS，时间保底会明确标记携带者。\n棱镜：准备防毒装备，在毒领域按住 E 提取。\n齿轮：到锻造房，用零件与毒、火材料组装。\n\n集齐后到固定入口进入地牢，清理三间房并抵达出口。\n地牢中央障碍可以阻挡弹丸，绕到侧面寻找攻击机会。"
		"pause":
			menu_body.text = "敌人、技能冷却和世界计时已暂停。\n\n" + world.objectives.target_description()
			action("查看地图 [M]", func(): show_menu("map"))
			action("退出游戏", func(): get_tree().quit())
		"victory":
			menu_title.text = "逃离成功"
			menu_body.text = "你已集齐三个部件，突破地牢并抵达出口。\n\n生存 %02d:%02d · 击败 %d 个敌人\n世界周期 %d · 地牢用时 %02d:%02d\n\n当前为完整流程原型，感谢试玩。" % [int(world.run_time) / 60, int(world.run_time) % 60, world.kills, world.cycle_index, int(world.dungeon_time) / 60, int(world.dungeon_time) % 60]
			primary_button.text = "重新开局"
			fast_button.hide()
		"death":
			menu_body.text = "本次探索结束。\n\n部件 %d/3 · 击败 %d 个敌人\n生存 %02d:%02d\n\n下一局可以调整技能搭配，利用领域和高塔减少正面压力。" % [world.objectives.count(), world.kills, int(world.run_time) / 60, int(world.run_time) % 60]

func _process(delta: float) -> void:
	if world.setup != null and not world.started:
		return
	super._process(delta)
	if slots.is_empty():
		return
	for i in 3:
		var id: String = world.skills.selected[i]
		if slots[i].skill_id != id:
			slots[i].configure(id, str(i + 1), world.skills.DEFINITIONS[id]["name"])
		slots[i].remaining = world.skills.cooldowns[i]
		slots[i].blocked = world.riding and id not in world.skills.TRAVEL_SKILLS
		slots[i].blocked_label = "下车"
		var threshold: int = world.skills.DEFINITIONS[id]["mastery"]
		slots[i].mastery_ready = world.skills.mastered(id)
		slots[i].badge_text = "%d/%d" % [mini(world.skills.uses[id], threshold), threshold] if threshold > 0 else "自动"
		if id == "step":
			slots[i].badge_text = "%d/%d" % [world.skills.step_charges, world.skills.step_capacity()]
			if world.skills.step_charges > 0:
				slots[i].remaining = 0.0
		if id == "fake_death" and world.skills.fake_death_used:
			slots[i].blocked = true
			slots[i].blocked_label = "已用"
		slots[i].duration = world.skills.cooldown_for(id)
		slots[i].queue_redraw()
	slots[3].remaining = world.player.dash_cooldown
	slots[3].duration = world.player.dash_recharge
	slots[3].queue_redraw()
	var parts: Array = world.objectives.PARTS.keys()
	for i in 3:
		var have: bool = world.objectives.found[parts[i]]
		goal_rows[i].text = ("◆ " if have else "◇ ") + world.objectives.PARTS[parts[i]]
		goal_rows[i].modulate = Color("749563") if have else Color.WHITE
	goal_detail.text = "地牢 %d/3：清理敌人并抵达出口" % (world.dungeon_room + 1) if world.in_dungeon else world.objectives.target_description()
	resource_label.text = "金币 %d · 零件 %d\n电量 %d%% · 电池 %d" % [world.progression.coins, world.progression.parts, int(world.progression.battery), world.progression.batteries]
	var weapons: Array[String] = []
	for i in 3:
		var item: ESWeaponInstance = world.progression.equipped[i]
		weapons.append(item.spec.title + " " + "★".repeat(item.stars) if item != null else "— 空槽")
		equipment_text[i].text = weapons[-1]
		var desired_path: String = "res://assets/ui/icons/%s.svg" % item.spec.kind if item != null else "res://assets/ui/icons/bag.svg"
		if equipment_icons[i].texture == null or equipment_icons[i].texture.resource_path != desired_path:
			equipment_icons[i].texture = load(desired_path)
		equipment_icons[i].modulate.a = 1.0 if item != null else 0.25
	weapon_heading.text = "骑行禁攻 · R 下车" if world.riding else "武器  /  自动攻击"
	weapon_summary.text = "\n".join(weapons)
	if world.in_dungeon:
		cycle_note.text = "稳定地牢 · 第 %d 间" % (world.dungeon_room + 1)
		cycle_text.text = "%02d:%02d" % [int(world.dungeon_time) / 60, int(world.dungeon_time) % 60]
		cycle_text.modulate = Color.WHITE
		mode_note.text = "世界迁移已停止"
	else:
		mode_note.text = "即将变化 · 尽快撤离高塔" if world.cycle_left <= world.warning_duration else ("骑行禁攻 · R 下车" if world.riding else "M 地图 · Tab 装备")
	toast.offset_top = 134
	if world.skills.berserk_left > 0:
		status.text += "\n狂暴 %.1fs · 攻速与吸血提升" % world.skills.berserk_left
	if world.skills.weaken_left > 0:
		status.text += "\n弱化 %.1fs · 双层免伤生效" % world.skills.weaken_left
	if world.skills.invisible_left > 0:
		status.text += "\n假死隐身 %.1fs · 移速 +100%%" % world.skills.invisible_left
	if world.player.fire_protection:
		status.text += "\n消防员套装 · 火领域免疫"
	extraction_bar.visible = world.objectives.extracting
	extraction_bar.value = world.objectives.extraction_progress
	var boss: ESEnemy
	for enemy in world.enemies:
		if enemy.get("boss_kind") != null and enemy.alive and (enemy.has_meta("key_part") or enemy.position.distance_to(world.player.position) < 580):
			boss = enemy
			break
	boss_panel.visible = boss != null
	if boss != null:
		boss_title.text = boss.get_meta("display_name", "追猎者" if boss.boss_kind == "hunter" else "领域镇守者")
		if boss.has_meta("key_part"):
			boss_title.text = "★ 携带部件 · " + boss_title.text
		boss_health.max_value = boss.maximum_health
		boss_health.value = boss.health
