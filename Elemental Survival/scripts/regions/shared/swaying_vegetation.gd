extends MultiMeshInstance3D
## Shared wind material recipe; no per-blade scripts or physics nodes.
var wind_clock := 0.0
var wind_material := ShaderMaterial.new()

func _ready() -> void:
	wind_material.shader = preload("res://assets/regions/shared/meadow_wind.gdshader")
	wind_material.set_shader_parameter("blades",preload("res://assets/regions/shared/meadow_blades.png"))
	material_override = wind_material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	extra_cull_margin = 0.2

func _process(delta: float) -> void:
	wind_clock += delta
	wind_material.set_shader_parameter("clock",wind_clock)
