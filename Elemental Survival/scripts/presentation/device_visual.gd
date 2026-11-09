extends Node2D
## Above both overworld and dungeon floors. Simulation stays in active_skills.gd.
var world: Node2D

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	for drop in world.pickups:
		var colors := {"coins": Color("e2b65c"), "parts": Color("a9c2a5"), "fire": Color("ee9166"), "poison": Color("b5d278")}
		draw_circle(drop["position"], 4, colors.get(drop["kind"], Color.WHITE))
	for device in world.skills.devices:
		var point: Vector2 = device["position"]
		var tint := Color("e3ca88") if device["kind"] == "decoy" else Color("8bd3df")
		draw_circle(point, 13, Color("273e3d"))
		draw_arc(point, 15, 0, TAU, 24, tint, 2)
		if device["kind"] == "turret":
			draw_line(point+Vector2(-15, 13), point, Color("667c7d"), 4)
			draw_line(point+Vector2(15, 13), point, Color("667c7d"), 4)
			draw_rect(Rect2(point-Vector2(11, 10), Vector2(22, 16)), Color("546e78"))
			draw_rect(Rect2(point+Vector2(2, -8), Vector2(22, 6)), tint)
		draw_string(world.font, point + Vector2(-22, -26), "诱饵" if device["kind"] == "decoy" else "炮台", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, tint)
