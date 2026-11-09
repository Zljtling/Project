extends Node3D
## Nearby categories, with depth-tested markers and no labels through house walls.
const Parts = preload("res://scripts/regions/shared/model_parts.gd")
var world: Node2D
var kind := "chest"
var halo: MeshInstance3D
var tag: Label3D
var time := 0.0
const COLORS := {"chest":Color("eac56d"),"supply":Color("9ecbb1"),"shop":Color("9bc6df"),"forge":Color("e4a57a")}
const TITLES := {"chest":"◆ 宝箱","supply":"＋ 补给","shop":"▣ 售卖柜","forge":"⚒ 锻造台"}

func _ready() -> void:
	halo = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.65
	ring.outer_radius = 0.71
	ring.rings = 24
	ring.ring_segments = 6
	halo.mesh = ring
	halo.position.y = 0.08
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = COLORS[kind]
	halo.material_override = material
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(halo)
	tag = Label3D.new()
	tag.font = world.font
	tag.text = TITLES[kind]+"  [E]"
	tag.font_size = 32
	tag.pixel_size = 0.016
	tag.position.y = 2.15 if kind in ["shop","forge"] else 1.5
	tag.modulate = COLORS[kind]
	tag.outline_modulate = Color("273530")
	tag.outline_size = 9
	# CPU sight checks block walls; foliage should not swallow readable text.
	tag.no_depth_test = true
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(tag)

func _process(delta: float) -> void:
	time += delta
	var at := Vector2(global_position.x,global_position.z)*32
	var distance: float = at.distance_to(world.player.position)
	var readable: bool = distance < 420 and world.line_of_sight(world.player.position,at)
	halo.visible = readable
	tag.visible = readable and distance < 300
	halo.scale = Vector3.ONE*(1.0+sin(time*2)*0.045)
