extends Button
## Reusable inventory/forge slot. Selection is delegated to its owner.
var weapon: ESWeaponInstance
var equipped_slot := -1
var selected := false

func _ready() -> void:
	custom_minimum_size = Vector2(128,154)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tooltip_text = weapon.title()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("c6d5b0") if selected else Color("f1e7cb")
	style.border_color = Color("5c7953") if selected else Color("b7a078")
	style.set_corner_radius_all(9)
	style.set_border_width_all(3 if selected else 2)
	add_theme_stylebox_override("normal",style)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 8
	column.offset_right = -8
	column.offset_top = 6
	column.offset_bottom = -6
	add_child(column)
	var icon := TextureRect.new()
	icon.custom_minimum_size.y = 68
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = load("res://assets/ui/icons/%s.svg" % weapon.spec.kind)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(icon)
	for value in [weapon.spec.title,"★".repeat(weapon.stars),"已装备 · %d" % (equipped_slot+1) if equipped_slot >= 0 else "背包"]:
		var label := Label.new()
		label.text = value
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size",13)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(label)
