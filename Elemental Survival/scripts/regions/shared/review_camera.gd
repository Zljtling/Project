extends Camera3D
## Fixed yaw, elevated perspective. Tracks only its explicitly assigned target.
@export var target: Node3D
@export var keyboard_zoom := true
@export var distance := 26.0
var view_offset := Vector3(0, 0.8, 0)

func _ready() -> void:
	fov = 40
	far = 160
	_update_camera(1.0)

func _process(delta: float) -> void:
	if keyboard_zoom and Input.is_physical_key_pressed(KEY_Q):
		distance = minf(62, distance + delta * 10)
	if keyboard_zoom and Input.is_physical_key_pressed(KEY_E):
		distance = maxf(15, distance - delta * 10)
	_update_camera(1.0 - exp(-6.0 * delta))

func _update_camera(weight: float) -> void:
	if not is_instance_valid(target):
		return
	var focus := target.global_position + view_offset
	var offset := Vector3(0.25, 0.80, 0.5454).normalized() * distance
	global_position = global_position.lerp(focus + offset, weight)
	look_at(global_position - offset)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if projection == Camera3D.PROJECTION_ORTHOGONAL:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				size = maxf(14,size-1.5)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				size = minf(34,size+1.5)
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = maxf(15,distance-2)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = minf(62,distance+2)
