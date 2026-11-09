extends Node
## One explicit target and one shared leaf material; no per-tree polling/raycast.
@export var target: Node3D
@export var camera: Camera3D
var enabled := true
var clock := 0.0
var leaf_material := ShaderMaterial.new()

func _init() -> void:
	leaf_material.shader = preload("res://assets/regions/shared/foliage_cutaway.gdshader")
	leaf_material.set_shader_parameter("leaf_texture", preload("res://assets/regions/shared/canopy.png"))

func _process(delta: float) -> void:
	clock += delta
	leaf_material.set_shader_parameter("clock",clock)
	update_cutaway()

func update_cutaway() -> void:
	var active := enabled and is_instance_valid(target) and is_instance_valid(camera)
	leaf_material.set_shader_parameter("cutaway_enabled", active)
	if not active:
		return
	var center := target.global_position + Vector3(0, 0.85, 0)
	var screen := camera.unproject_position(center)
	var extent := camera.unproject_position(center + camera.global_basis.x * 1.15)
	# unproject_position uses logical viewport pixels; 3D may render at a different
	# resolution under canvas_items stretch. Normalize before entering the shader.
	var viewport_size := camera.get_viewport().get_visible_rect().size
	leaf_material.set_shader_parameter("target_uv", screen / viewport_size)
	leaf_material.set_shader_parameter("target_world", center)
	leaf_material.set_shader_parameter("radius_ratio", screen.distance_to(extent) / viewport_size.y)
