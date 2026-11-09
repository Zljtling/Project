extends RefCounted
## Builds pre-run UI using the HUD's common controls; owns no simulation state.

static func build(hud: Node, kind: String) -> void:
	var flow = hud.world.setup
	hud.armor_button.hide()
	hud.fast_button.hide()
	match kind:
		"main":
			hud.menu_title.text = "Elemental Survival"
			hud.menu_body.text = "探索每局重排的世界，收集三个部件，寻找出口。"
			hud.primary_button.text = "开始游戏"
			var cover := TextureRect.new()
			cover.name = "JournalCover"
			cover.texture = preload("res://assets/ui/forest/journal_cover.svg")
			cover.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			cover.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			cover.custom_minimum_size.y = 190
			hud.extras.add_child(cover)
			hud.action("三维区域复核 · 六处聚落", func():
				hud.get_tree().paused = false
				hud.get_tree().change_scene_to_file("res://scenes/regions/region_review.tscn")
			)
			hud.action("退出游戏", func(): hud.get_tree().quit())
		"loadout":
			hud.menu_title.text = "逃离前的准备"
			hud.menu_body.text = "选择三个技能和一把初始武器。\n其余武器在局内搜集；开始逃离后选择出生区域。"
			for i in 3:
				hud._skill_picker(i)
			var option := OptionButton.new()
			option.name = "StarterWeapon"
			for id in flow.WEAPONS:
				var weapon: ESWeaponSpec = load("res://data/weapons/%s.tres" % id)
				option.add_icon_item(load("res://assets/ui/icons/%s.svg" % weapon.kind),"初始武器：" + weapon.title)
			option.select(flow.WEAPONS.find(flow.starter))
			option.item_selected.connect(func(index: int): flow.starter = flow.WEAPONS[index])
			hud.extras.add_child(option)
			for id in hud.world.skills.selected:
				hud.label(hud.extras, "%s：%s" % [hud.world.skills.DEFINITIONS[id]["name"], hud.world.skills.DEFINITIONS[id]["description"]], 14).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			if not flow.error.is_empty():
				hud.label(hud.extras, flow.error, 14)
			hud.action("返回主菜单", flow.open_title)
			hud.primary_button.text = "开始逃离"
		"spawn":
			hud.menu_title.text = "选择出生区域 · 世界已暂停"
			hud.menu_body.text = "从六个聚落区域中选择出生地，再确认出生。\n不提供野外或元素领域出生点；确认前倒计时与敌人保持暂停。"
			var map_view := preload("res://scripts/ui/world_map.gd").new()
			map_view.name = "SpawnMap"
			map_view.world = hud.world
			map_view.spawn_mode = true
			map_view.spawn_options = flow.spawn_choices
			map_view.selected_spawn = flow.selected_spawn
			map_view.spawn_selected.connect(func(index: int):
				if flow.select_spawn(index):
					hud.show_menu("spawn")
			)
			hud.extras.add_child(map_view)
			map_view.custom_minimum_size.y = 380
			var selected: String = flow.spawn_choices[flow.selected_spawn]["name"] if flow.selected_spawn >= 0 else "尚未选择"
			hud.label(hud.extras, "出生区域：" + selected, 16)
			if not flow.error.is_empty():
				hud.label(hud.extras, flow.error, 14)
			hud.action("返回备战", flow.open_loadout)
			hud.primary_button.text = "确认出生"
			hud.primary_button.disabled = flow.selected_spawn < 0
