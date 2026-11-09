extends RefCounted
## Forest fieldbook: warm paper, wooden edges, sage controls. Shared by all screens.
const INK := Color("493f30")
const GREEN := Color("496950")
const PAPER := preload("res://assets/ui/forest/paper_panel.svg")

static func paper() -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = PAPER
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
		style.set_texture_margin(side,40)
		style.set_content_margin(side,16)
	return style

static func primary(button: Button) -> void:
	for state in ["normal","hover","pressed"]:
		button.add_theme_stylebox_override(state,frame(Color("66835f") if state == "hover" else Color("3f6148") if state == "pressed" else GREEN,Color("a7b67a")))
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		button.add_theme_color_override(state,Color("fff0ce"))

static func frame(fill: Color, edge: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(1)
	style.set_corner_radius_all(9)
	style.shadow_color = Color(0.06,0.07,0.06,0.6)
	style.shadow_size = 3
	style.shadow_offset = Vector2(2,3)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

static func apply(theme: Theme) -> void:
	theme.set_color("font_color","Label",INK)
	for type in ["Button","OptionButton","CheckButton"]:
		for state in ["normal","hover","pressed","disabled","focus"]:
			var fill := Color("d6ddba") if state == "hover" else Color("b7c5a1") if state == "pressed" else Color("e6d6af")
			var edge := Color("69805b") if state in ["hover","focus"] else Color("a28a60")
			if state == "disabled":
				fill = Color("d2cbb6")
				edge = Color("b4ab96")
			var style := frame(fill,edge)
			if state == "focus":
				style.bg_color = Color.TRANSPARENT
				style.set_border_width_all(3)
				style.shadow_size = 0
			theme.set_stylebox(state,type,style)
		for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
			theme.set_color(state,type,INK)
		theme.set_color("font_disabled_color",type,Color("8c8573"))
		theme.set_constant("icon_max_width",type,32)
	theme.set_stylebox("panel","PopupMenu",paper())
	theme.set_stylebox("hover","PopupMenu",frame(Color("c3cdaa"),Color("84966c")))
	theme.set_color("font_color","PopupMenu",INK)
	theme.set_color("font_hover_color","PopupMenu",INK)
