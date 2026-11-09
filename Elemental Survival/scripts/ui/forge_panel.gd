extends VBoxContainer
## Inventory-based forge UI. Transactions remain in ESRunProgression.
signal target_selected(weapon: ESWeaponInstance)
signal crafted(weapon: ESWeaponInstance)
var progression: ESRunProgression
var main: ESWeaponInstance
var targets: Array[ESWeaponInstance] = []
var materials: Array[ESWeaponInstance] = [null, null]
var allow_equipped := false
var message := ""

func configure(source: ESRunProgression, preferred: ESWeaponInstance) -> void:
	progression = source
	main = preferred if preferred in source.inventory else null
	if main == null and not source.inventory.is_empty():
		main = source.inventory[0]
	_suggest_materials()
	_rebuild()

func _candidates() -> Array[ESWeaponInstance]:
	var result: Array[ESWeaponInstance] = []
	if main == null or main.stars >= 3:
		return result
	for item in progression.inventory:
		if item != main and item.stars == main.stars and (allow_equipped or item not in progression.equipped):
			result.append(item)
	return result

func _suggest_materials() -> void:
	materials = [null, null]
	var candidates := _candidates()
	# Equipped items are always an explicit choice, including after opt-in.
	var slot := 0
	for item in candidates:
		if item not in progression.equipped:
			materials[slot] = item
			slot += 1
			if slot == 2:
				break

func _describe(item: ESWeaponInstance) -> String:
	var slot := progression.equipped.find(item)
	var title := item.spec.title + " " + "★".repeat(item.stars)
	for element in item.elements:
		title += " %s%d" % [progression.ELEMENT_NAMES.get(element, element), item.elements[element]]
	return "%s %s · #%d" % ["[装备槽 %d]" % (slot+1) if slot >= 0 else "[背包]", title, progression.inventory.find(item)+1]

func _text(value: String) -> void:
	var text := Label.new()
	text.text = value
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("font_size", 14)
	add_child(text)

func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	targets.assign(progression.inventory)
	_text("升级目标 · 可直接选择背包或已装备武器")
	if targets.is_empty():
		_text("没有可升级的武器。")
		return
	var picker := OptionButton.new()
	picker.name = "TargetPicker"
	picker.clip_text = true
	picker.custom_minimum_size.y = 38
	for item in targets:
		picker.add_item(_describe(item))
	picker.select(targets.find(main))
	picker.item_selected.connect(func(index: int):
		main = targets[index]
		message = ""
		_suggest_materials()
		target_selected.emit(main)
		_rebuild()
	)
	add_child(picker)
	var grid := GridContainer.new()
	grid.name = "ForgeInventoryGrid"
	grid.columns = 4
	grid.add_theme_constant_override("h_separation",8)
	grid.add_theme_constant_override("v_separation",8)
	add_child(grid)
	for item in targets:
		var card := preload("res://scripts/ui/item_card.gd").new()
		card.weapon = item
		card.selected = item == main
		card.equipped_slot = progression.equipped.find(item)
		card.pressed.connect(func():
			main = item
			message = ""
			_suggest_materials()
			target_selected.emit(main)
			_rebuild()
		)
		grid.add_child(card)
	var recipe := HBoxContainer.new()
	recipe.name = "RecipePreview"
	recipe.add_theme_constant_override("separation",8)
	add_child(recipe)
	for index in 4:
		if index == 3:
			var arrow := Label.new()
			arrow.text = "  →  "
			arrow.add_theme_font_size_override("font_size",28)
			recipe.add_child(arrow)
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(96,100)
		slot.add_theme_stylebox_override("panel",preload("res://scripts/ui/game_theme.gd").frame(Color("c5d4ae") if index == 3 else Color("f1e7cb"),Color("758959") if index == 3 else Color("b09b72")))
		var content := VBoxContainer.new()
		slot.add_child(content)
		var caption := Label.new()
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.add_theme_font_size_override("font_size",13)
		var ingredient: ESWeaponInstance = main if index in [0,3] else materials[index-1]
		if ingredient != null:
			var icon := TextureRect.new()
			icon.custom_minimum_size.y = 38
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.texture = load("res://assets/ui/icons/%s.svg" % ingredient.spec.kind)
			content.add_child(icon)
		caption.text = ("成品\n" if index == 3 else "目标\n" if index == 0 else "材料 %d\n" % index)+(ingredient.spec.title if ingredient != null else "空")+"\n"+("★".repeat(mini(4,main.stars+1)) if index == 3 else "★".repeat(ingredient.stars) if ingredient != null else "—")
		content.add_child(caption)
		recipe.add_child(slot)
	if main.stars < 3:
		var toggle := CheckButton.new()
		toggle.name = "AllowEquippedMaterials"
		toggle.text = "允许手动选择已装备武器作为材料"
		toggle.button_pressed = allow_equipped
		toggle.toggled.connect(func(value: bool):
			allow_equipped = value
			_suggest_materials()
			_rebuild()
		)
		add_child(toggle)
		var candidates := _candidates()
		for slot in 2:
			_material_picker(slot, candidates)
		_text("材料附魔合并继承；目标保留原装备/背包位置。")
		if materials.any(func(item: ESWeaponInstance) -> bool: return item != null and item in progression.equipped):
			_text("注意：所选材料含已装备武器，消耗后对应装备槽会留空。")
		var confirm := Button.new()
		confirm.name = "ConfirmCombine"
		confirm.text = "确认消耗所选两把材料 · 升至 %d 星" % (main.stars+1)
		preload("res://scripts/ui/game_theme.gd").primary(confirm)
		confirm.custom_minimum_size.y = 42
		confirm.disabled = materials[0] == null or materials[1] == null or materials[0] == materials[1]
		confirm.pressed.connect(_combine)
		add_child(confirm)
		if confirm.disabled:
			_text("需要两把同星材料武器；也可以手动调整材料。")
	elif main.stars == 3:
		_text("三星突破四星：消耗 1 个神拼图（持有 %d）。" % progression.miracles)
		var breakthrough := Button.new()
		breakthrough.name = "ConfirmBreakthrough"
		breakthrough.text = "确认四星突破"
		breakthrough.custom_minimum_size.y = 42
		breakthrough.disabled = progression.miracles <= 0
		breakthrough.pressed.connect(func():
			if progression.breakthrough(main):
				crafted.emit(main)
		)
		add_child(breakthrough)
	else:
		_text("这把武器已达到四星。")
	if not message.is_empty():
		_text(message)
	_organize_workbench(grid)

func _organize_workbench(grid: GridContainer) -> void:
	# Independent inventory scroll keeps the transaction visible with large backpacks.
	var children := get_children()
	var workbench := HBoxContainer.new()
	workbench.name = "Workbench"
	workbench.add_theme_constant_override("separation",20)
	add_child(workbench)
	var recipe_column := VBoxContainer.new()
	recipe_column.name = "RecipeColumn"
	recipe_column.custom_minimum_size.x = 500
	recipe_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	recipe_column.add_theme_constant_override("separation",8)
	workbench.add_child(recipe_column)
	for child in children:
		remove_child(child)
		if child != grid:
			recipe_column.add_child(child)
	var scroll := ScrollContainer.new()
	scroll.name = "InventoryScroll"
	scroll.custom_minimum_size = Vector2(286,390)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	workbench.add_child(scroll)
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)

func _material_picker(slot: int, candidates: Array[ESWeaponInstance]) -> void:
	var picker := OptionButton.new()
	picker.name = "Material%d" % slot
	picker.clip_text = true
	picker.custom_minimum_size.y = 36
	picker.add_item("材料 %d · 请选择同星武器" % (slot+1))
	for item in candidates:
		picker.add_item("材料 %d · %s" % [slot+1,_describe(item)])
	picker.select(candidates.find(materials[slot])+1 if materials[slot] != null else 0)
	picker.item_selected.connect(func(index: int):
		materials[slot] = candidates[index-1] if index > 0 else null
		if materials[slot] != null and materials[1-slot] == materials[slot]:
			materials[1-slot] = null
		_rebuild()
	)
	add_child(picker)

func _combine() -> void:
	if progression.combine(main, materials):
		crafted.emit(main)
	else:
		message = "材料已变化，未消耗武器；请重新选择。"
		_suggest_materials()
		_rebuild()
