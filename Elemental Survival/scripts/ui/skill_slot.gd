extends Control

var skill_id := "dash"
var key_label := "Space"
var title := "冲刺"
var remaining := 0.0
var blocked := false
var blocked_label := "下车"
var badge_text := ""
var mastery_ready := false
var duration := 1.0
var texture: Texture2D
var font: Font

func configure(id: String, key: String, display: String) -> void:
	skill_id = id
	key_label = key
	title = display
	texture = load("res://assets/ui/icons/%s.svg" % id)
	queue_redraw()

func _ready() -> void:
	custom_minimum_size = Vector2(86, 94)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font = get_theme_default_font()

func _draw() -> void:
	var active := remaining <= 0.0 and not blocked
	var rect := Rect2(Vector2(10, 12), Vector2(66, 62))
	draw_style_box(_style(Color("efe6c9"), Color("7d9463") if active else Color("a7a28e")), rect)
	if texture != null:
		draw_texture_rect(texture, Rect2(Vector2(17, 17), Vector2(52, 52)), false, Color.WHITE if active else Color("9e9f91"))
	if blocked:
		draw_rect(rect.grow(-2), Color(0.02, 0.04, 0.06, 0.7))
		draw_string(font, Vector2(25, 50), blocked_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("e1b28b"))
	elif not active:
		var fraction := clampf(remaining / maxf(duration, 0.01), 0.0, 1.0)
		var points := PackedVector2Array([Vector2(43, 43)])
		for i in 33:
			points.append(Vector2(43, 43) + Vector2.from_angle(-PI / 2 + fraction * TAU * i / 32) * 31.0)
		draw_colored_polygon(points, Color(0.02, 0.04, 0.06, 0.78))
		var text := "%.1f" % remaining if remaining < 10 else str(ceili(remaining))
		draw_string(font, Vector2(43 - font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x / 2, 51), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("fff0d1"))
	draw_style_box(_style(Color("e4d5b2"), Color("9a865d")),Rect2(8,2,40 if key_label == "Space" else 20,17))
	draw_string(font, Vector2(12, 15), key_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("514733"))
	if badge_text != "":
		draw_string(font, Vector2(49, 12), badge_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("76603d") if mastery_ready else Color("60704e"))
	var label_width := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	draw_string(font, Vector2(43 - label_width / 2, 90), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("493f30"))

func _style(background: Color, outline: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = outline
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	return style
