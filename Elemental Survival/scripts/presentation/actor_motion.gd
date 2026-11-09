extends RefCounted
## Presentation-only state. Distance drives feet; wall-blocked actors do not moonwalk.
var phase := 0.0
var idle_time := 0.0
var attack_left := 0.0
var direction_row := 0
var frame_index := 0
var pose := "idle"
var stretch := Vector2.ONE
var offset := 0.0

func attack() -> void:
	attack_left = 0.22

func advance(delta: float, distance: float, facing: Vector2, hurt: bool, windup: bool, charging: bool) -> void:
	idle_time += delta
	attack_left = maxf(0.0,attack_left-delta)
	if facing.length_squared() > 0.01:
		direction_row = (1 if facing.x > 0 else 3) if absf(facing.x) > absf(facing.y) else (0 if facing.y >= 0 else 2)
	var moving := distance > 0.05
	if moving:
		phase = fmod(phase+distance/13.0,6.0)
	frame_index = 1+int(phase) if moving else 0
	pose = "walk" if moving else "idle"
	stretch = Vector2.ONE
	offset = sin(idle_time*2.5)*0.012
	if hurt:
		pose = "hurt"
		stretch = Vector2(1.10,0.91)
	elif windup:
		pose = "windup"
		frame_index = 7
		stretch = Vector2(1.08,0.90)
	elif attack_left > 0 or charging:
		pose = "attack"
		# Automatic fire must not freeze the gait while the player keeps running.
		if not moving:
			frame_index = 7
		stretch = Vector2(0.94,1.07)
		offset = sin(attack_left/0.22*PI)*0.06
	elif not moving:
		stretch.y = 1.0+sin(idle_time*2.5)*0.009
