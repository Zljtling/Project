extends "res://scripts/ui/prototype_hud.gd"

var extras: VBoxContainer
var skill_labels: Array[Label] = []
var resource_label: Label
var weapon_slot := 0
var forge_target: ESWeaponInstance

func _ready() -> void:
	super._ready()
	phase_title.text = "移动世界 · 迁移与成长"
	phase_title.add_theme_font_size_override("font_size", 18)
	var skill_panel := panel_at(Vector2(22, -170), Vector2(612, 58), false, true)
	var row := HBoxContainer.new()
	column(skill_panel).add_child(row)
	row.add_theme_constant_override("separation", 24)
	for i in 3:
		skill_labels.append(label(row, "", 15, Color("c6e0be")))
	var resources := panel_at(Vector2(-310, 322), Vector2(288, 120), true)
	resource_label = label(column(resources), "", 14)
	modal_header.text = "ELEMENTAL SURVIVAL   /   PROTOTYPE 02"
	root.move_child(modal, root.get_child_count() - 1)

func _build_modal() -> void:
	super._build_modal()
	var panel := modal.get_child(0) as Panel
	panel.offset_top = -350
	panel.offset_bottom = 350
	var col := menu_body.get_parent() as VBoxContainer
	col.add_theme_constant_override("separation", 9)
	menu_body.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	col.move_child(scroll, col.get_child_count() - 4)
	extras = VBoxContainer.new()
	extras.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	extras.add_theme_constant_override("separation", 7)
	scroll.add_child(extras)

func _clear_extras() -> void:
	for child in extras.get_children():
		extras.remove_child(child)
		child.queue_free()

func action(text: String, callback: Callable, available := true) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 38
	button.disabled = not available
	button.pressed.connect(callback)
	extras.add_child(button)
	return button

func _input(event: InputEvent) -> void:
	if menu_kind == "reward" and (event.is_action_pressed("inventory") or event.is_action_pressed("pause_run") or event.is_action_pressed("help")):
		get_viewport().set_input_as_handled()
		return
	super._input(event)

func _choose_weapon_slot() -> void:
	var choose := OptionButton.new()
	for i in 3:
		var item: ESWeaponInstance = world.progression.equipped[i]
		choose.add_item("武器槽 %d：%s" % [i + 1, item.title() if item != null else "空"])
	choose.select(weapon_slot)
	choose.item_selected.connect(func(index: int):
		weapon_slot = index
		show_menu(menu_kind)
	)
	extras.add_child(choose)

func show_menu(kind: String) -> void:
	super.show_menu(kind)
	_clear_extras()
	primary_button.disabled = false
	var p: ESRunProgression = world.progression
	match kind:
		"intro":
			menu_title.text = "选择技能，开始探索"
			menu_body.text = "三个技能槽自由搭配类别，开局后不能更换。\n1 / 2 / 3 释放技能，R 上下载具，E 搜刮与设施。"
			for i in 3:
				_skill_picker(i)
			label(extras, "第二阶段测试：补给 / 锻造 / 附魔 / BOSS / 技能\nF6 仅加速世界周期，方便观察迁移和 BOSS 出场。", 15)
		"inventory":
			menu_title.text = "装备与随身附魔 · 已暂停"
			menu_body.text = "金币 %d  /  零件 %d  /  电池 %d  /  神拼图 %d\n毒材料 %d  /  火材料 %d  /  降温芯片 %d" % [p.coins, p.parts, p.batteries, p.miracles, p.materials["poison"], p.materials["fire"], p.chips]
			_choose_weapon_slot()
			if world.player.fire_armor_owned:
				action("消防员套装：%s · 点击%s" % ["已穿戴" if world.player.fire_protection else "未穿戴", "脱下" if world.player.fire_protection else "穿上"], func():
					world.player.equip_suit("" if world.player.fire_protection else "fire")
					show_menu("inventory")
				)
			label(extras, "防护槽只有一个：生化套装与消防员套装互相替换。", 14)
			var grid := GridContainer.new()
			grid.name = "InventoryGrid"
			grid.columns = 4
			grid.add_theme_constant_override("h_separation",8)
			grid.add_theme_constant_override("v_separation",8)
			extras.add_child(grid)
			for item in p.inventory:
				var card := preload("res://scripts/ui/item_card.gd").new()
				card.weapon = item
				card.equipped_slot = p.equipped.find(item)
				card.selected = p.equipped[weapon_slot] == item
				card.pressed.connect(func():
					p.equip(weapon_slot, item)
					show_menu("inventory")
				)
				grid.add_child(card)
			var main: ESWeaponInstance = p.equipped[weapon_slot]
			if main != null:
				for element in p.unlocked_elements:
					var level := int(main.elements.get(element, 0))
					var cost := 2 + level
					action("%s附魔 %d/5%s" % [p.ELEMENT_NAMES[element], level, " · 已满级" if level >= 5 else " → 消耗 %d 材料（持有 %d）" % [cost, p.materials[element]]], func():
						if not p.enchant(main, element):
							menu_body.text = "材料不足，或新元素超过当前武器的附魔容量。"
						else:
							show_menu("inventory")
					, level < 5)
			if p.unlocked_elements.is_empty():
				label(extras, "击杀元素镇守者后，可在这里主动附魔。", 14)
			var charge: float = world.vehicle_charge()
			action("靠近电动车可使用电池" if charge < 0 else "使用电池：电量 +60（当前车辆 %d%%）" % int(charge), func():
				world.recharge_vehicle()
				show_menu("inventory")
			, p.batteries > 0 and charge >= 0 and charge < 100)
			if p.chips > 0:
				for id in world.skills.selected:
					if id == "fake_death":
						continue
					action("降温芯片 → " + world.skills.DEFINITIONS[id]["name"], func():
						p.chips -= 1
						world.skills.bonuses[id]["cooldown"] += 1
						show_menu("inventory")
					)
		"forge":
			menu_title.text = "锻造房 · 已暂停"
			menu_body.text = "直接升级全部持有武器，无需先装备。\n保留目标武器，另消耗两把同星武器；附魔合并继承。"
			var forge := preload("res://scripts/ui/forge_panel.gd").new()
			forge.name = "ForgePanel"
			forge.target_selected.connect(func(item: ESWeaponInstance): forge_target = item)
			forge.crafted.connect(func(item: ESWeaponInstance):
				forge_target = item
				show_menu("forge")
			)
			forge.configure(p, forge_target)
			extras.add_child(forge)
		"shop":
			menu_title.text = "万能售卖柜 · 已暂停"
			menu_body.text = "金币：%d。库存每个世界周期补满，售卖柜会搬迁。" % p.coins
			var names := {"battery": "电池 +1", "heal": "医疗包：恢复 35 生命", "chip": "降温芯片 +1", "refresh": "免费刷新次数 +1～3（随机）"}
			var prices: Dictionary = p.PRICES
			for product in names:
				action("%s · %d 金币 · 剩余 %d" % [names[product], prices[product], p.stock[product]], func():
					if p.buy(product):
						if product == "heal":
							world.player.health.heal(35.0)
						elif product == "refresh":
							world.notify("购买获得 %d 次免费刷新。" % p.last_refresh_yield)
					show_menu("shop")
				, p.coins >= prices[product] and p.stock[product] > 0 and (product != "heal" or world.player.health.current < world.player.health.maximum))
		"reward":
			menu_title.text = "技能强化 · 三选一"
			menu_body.text = "仅生成适配本局技能的选项。\n金币 %d / 免费刷新 %d / 本次付费刷新 %d 金币" % [p.coins, p.free_refreshes, 5 * (world.skills.refresh_count + 1)]
			primary_button.disabled = true
			primary_button.text = "选择一项后继续"
			for i in world.skills.reward_choices.size():
				var choice: Dictionary = world.skills.reward_choices[i]
				var titles := {"cooldown": "冷却缩短", "power": "威力提升", "utility": "范围 / 持续效果提升"}
				action(world.skills.DEFINITIONS[choice["skill"]]["name"] + " · " + titles[choice["kind"]], func():
					world.skills.take_reward(i)
					if world.skills.pending_rewards > 0:
						show_menu("reward")
					else:
						hide_menu()
				)
			action("刷新三个选项（优先使用免费次数）", func():
				if world.skills.refresh_reward():
					show_menu("reward")
				else:
					menu_body.text = "金币不足，且没有免费刷新次数。"
			)
		"help":
			menu_title.text = "迁移与成长 · 操作说明"
			menu_body.text = "WASD 移动 / Space 冲刺 / 右键集火\n1、2、3 释放技能 / R 上下载具 / E 交互\nTab 装备、附魔、电池与芯片 / Esc 暂停\n\n搜刮补给获得武器和材料，到锻造房升星。\nBOSS 每轮第 90 个世界秒后出现；橙色为追猎，绿色为镇守。\n击杀元素镇守者解锁对应主动附魔；非元素镇守者掉神拼图。\n\n周期变化时设施补满并迁移，元素领域一起移动。\nF6 可加速世界周期，战斗速度不加速。"
		"pause":
			menu_body.text = "敌人、倒计时和战斗效果已暂停。\n\n本阶段目标：搜刮 → 技能与武器成长 → 挑战 BOSS → 应对迁移。\n完整地牢与逃离流程留在第三阶段。"

func _skill_picker(slot: int) -> void:
	var option := OptionButton.new()
	var ids: Array = world.skills.DEFINITIONS.keys()
	for id in ids:
		option.add_icon_item(load("res://assets/ui/icons/%s.svg" % id),"技能 %d：%s [%s]" % [slot + 1, world.skills.DEFINITIONS[id]["name"], world.skills.DEFINITIONS[id]["category"]])
	option.select(ids.find(world.skills.selected[slot]))
	option.item_selected.connect(func(index: int):
		world.skills.choose(slot, ids[index])
		show_menu("intro")
	)
	extras.add_child(option)

func _process(delta: float) -> void:
	super._process(delta)
	if resource_label == null:
		return
	var p: ESRunProgression = world.progression
	resource_label.text = "金币 %d  /  零件 %d\n电量 %d%%  /  备用电池 %d\n毒材 %d  /  火材 %d\nR 上下载具 · Tab 管理成长" % [p.coins, p.parts, int(p.battery), p.batteries, p.materials["poison"], p.materials["fire"]]
	for i in 3:
		var id: String = world.skills.selected[i]
		var cooldown: float = world.skills.cooldowns[i]
		skill_labels[i].text = "%d %s · %s" % [i + 1, world.skills.DEFINITIONS[id]["name"], "就绪" if cooldown <= 0 else "%.1fs" % cooldown]
		var item: ESWeaponInstance = p.equipped[i]
		weapon_labels[i].text = item.spec.title + " " + "★".repeat(item.stars) if item != null else "空武器槽"

func draw_map() -> void:
	super.draw_map()
	var scale_map: Vector2 = Vector2(156, 100) / world.MAP_SIZE
	for facility in world.facilities:
		if facility["kind"] == "forge":
			minimap.draw_circle(facility["position"] * scale_map, 3, Color("80c6d3") if facility["kind"] == "shop" else Color("d9b17e"))
	minimap.draw_circle(world.domains["fire"] * scale_map, 8, Color("af7053"))

