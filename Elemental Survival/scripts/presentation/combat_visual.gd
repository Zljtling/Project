extends Node2D

var arsenal: Node2D

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if is_instance_valid(arsenal.world.marked):
		var point: Vector2 = arsenal.world.marked.position
		draw_arc(point, 23.0, 0, TAU, 32, Color("ffc17f"), 2)
		draw_line(point + Vector2(0, -37), point + Vector2(0, -24), Color("ffc17f"), 3)
	for shot in arsenal.shots:
		var point: Vector2 = shot["position"]
		draw_line(point - shot["direction"] * 17.0, point, shot["color"], 3.5, true)
	for effect in arsenal.effects:
		var color: Color = effect["color"]
		color.a = effect["life"] / 0.2
		if effect["slash"]:
			draw_arc(effect["position"], effect["radius"] * 0.8, effect["direction"] - 1.15, effect["direction"] + 1.15, 24, color, 7.0, true)
		else:
			draw_circle(effect["position"], effect["radius"] * (1.2 - color.a * 0.4), Color(color, color.a * 0.15))
			draw_arc(effect["position"], effect["radius"] * (1.2 - color.a * 0.4), 0, TAU, 40, color, 3.0, true)
