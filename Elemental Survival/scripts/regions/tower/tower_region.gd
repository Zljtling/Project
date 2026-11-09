extends Node3D
## Authored castle presentation. TowerLayout owns every walk-blocking footprint.
const Layout = preload("res://scripts/regions/tower/tower_layout.gd")
const Parts = preload("res://scripts/regions/shared/model_parts.gd")
const G = preload("res://scripts/world/scene_geometry.gd")
const SINK_DEPTH := 18.0
var target: Node3D
var camera: Camera3D
var cutaway_materials: Array[ShaderMaterial] = []
var banner := ShaderMaterial.new()
var clock := 0.0
var stone: ShaderMaterial
var trim: ShaderMaterial
var dark: ShaderMaterial
var roof: ShaderMaterial
var gold: ShaderMaterial

func _ready() -> void:
	name = "RuinedCitadel"
	stone = _material(Color("a8a48b"),"stone",0.38)
	trim = _material(Color("c5b995"),"stone",0.28)
	dark = _material(Color("424b48"),"stone",0.45)
	roof = _material(Color("5c8284"),"roof",0.45)
	gold = _material(Color("ac8650"),"wood",0.3)
	banner.shader = preload("res://assets/regions/tower/banner.gdshader")
	Parts.box(self,"CitadelFoundation",Vector3(30,0.16,27.5),Vector3(0,-0.07,0),stone)
	Parts.box(self,"InnerCourtPaving",Vector3(9.6,0.025,8.8),Vector3(0,0.03,-0.5),trim)
	Parts.box(self,"TreasuryPaving",Vector3(7.25,0.025,5.375),G.point3(Vector2(220,260),0.04),trim)
	for part in Layout.walls():
		var rect: Rect2 = part["rect"]
		var height: float = part["height"]
		var at := G.point3(rect.get_center())
		var size := Vector3(rect.size.x/32,height,rect.size.y/32)
		var solid := Parts.box(self,"TowerSolid",size,at+Vector3(0,height*0.5,0),stone,true)
		solid.set_meta("layout_rect",rect)
		if part["kind"] == "tower":
			solid.name = part["name"]
			_tower(at,size,height)
		else:
			_wall_detail(at,size,part["kind"])
	for i in Layout.GATES.size():
		var gate := Node3D.new()
		gate.name = "CitadelGate%d" % i
		gate.position = G.point3(Layout.GATES[i])
		gate.rotation.y = PI/2 if i%2 else 0.0
		add_child(gate)
		_arch(gate,3.42,2.4)
	for x in [92.0,348.0]:
		var door := Node3D.new()
		door.name = "TreasuryArch"
		door.position = G.point3(Vector2(x,260))
		door.rotation.y = PI/2
		add_child(door)
		_arch(door,1.9,2.3)
	for x in [-8.2,8.2]:
		for z in [-6.8,-3.4,0,3.4]:
			Parts.paving_slab(self,Vector3(x,0.025,z),trim)
	for side in [-1,1]:
		_arcade(side,-158,-78)
		_arcade(side,82,146)
	for at in [Vector3(-5.6,0,-4.8),Vector3(5.6,0,-4.8),Vector3(-5.6,0,3.6),Vector3(5.6,0,3.6)]:
		_lantern(at+Vector3(0,2.15,0))
	# Rubble stays on solid wall footprints, never inside the circulation routes.
	for i in 12:
		var x := -14.4+i*0.67
		Parts.rock(self,Vector3(x,2.12,-13.35),Vector3(0.3,0.2+(i%3)*0.09,0.35),dark)
	var emblem := Parts.cylinder(self,Vector3(0,0.058,-0.8),1.6,1.6,0.012,dark)
	emblem.mesh.radial_segments = 12
	Parts.cylinder(self,Vector3(0,0.068,-0.8),1.35,1.35,0.012,stone).mesh.radial_segments = 12
	for angle in [0.0,PI/2]:
		var inlay := Parts.box(self,"CourtInlay",Vector3(1.8,0.012,0.13),Vector3(0,0.08,-0.8),gold)
		inlay.rotation.y = angle+PI/4

func _material(color: Color, texture: String, scale_value: float) -> ShaderMaterial:
	var result := ShaderMaterial.new()
	result.shader = preload("res://assets/regions/tower/stone_cutaway.gdshader")
	result.set_shader_parameter("surface_texture",load("res://assets/regions/shared/%s.png" % texture))
	result.set_shader_parameter("tint",color)
	result.set_shader_parameter("tile_scale",scale_value)
	cutaway_materials.append(result)
	return result

func _wall_detail(at: Vector3, size: Vector3, kind: String) -> void:
	Parts.box(self,"WallCoping",Vector3(size.x+0.13,0.16,size.z+0.13),at+Vector3(0,size.y,0),trim)
	Parts.box(self,"WallFooting",Vector3(size.x+0.08,0.25,size.z+0.08),at+Vector3(0,0.125,0),dark)
	if kind == "column":
		Parts.box(self,"ColumnCapital",Vector3(0.72,0.22,0.72),at+Vector3(0,size.y,0),trim)
		return
	var along_x := size.x > size.z
	var length := size.x if along_x else size.z
	var count := maxi(1,int(length/1.25))
	for i in count:
		var offset := -length*0.5+(i+0.5)*length/count
		var position_offset := Vector3(offset,0,0) if along_x else Vector3(0,0,offset)
		if kind == "curtain":
			Parts.box(self,"Battlement",Vector3(0.55,0.48,0.65) if along_x else Vector3(0.65,0.48,0.55),at+position_offset+Vector3(0,size.y+0.3,0),stone)
		elif kind == "gallery":
			Parts.box(self,"GalleryButtress",Vector3(0.83,size.y+0.15,0.34),at+position_offset+Vector3(0,size.y*0.5,0),trim)

func _tower(at: Vector3, size: Vector3, height: float) -> void:
	for y in [0.35,height*0.46,height-0.3]:
		Parts.box(self,"KeepBeltCourse",Vector3(size.x+0.22,0.25,size.z+0.22),at+Vector3(0,y,0),trim)
	for side in [-1,1]:
		Parts.box(self,"KeepCorner",Vector3(0.28,height,0.3),at+Vector3(side*(size.x*0.5-0.14),height*0.5,size.z*0.5-0.12),trim)
	for y in [height*0.35,height*0.68]:
		for x in [-0.75,0.75]:
			_window(at+Vector3(x,y,size.z*0.5+0.03),0.0)
		_window(at+Vector3(size.x*0.5+0.03,y,0),PI/2)
	var parapet := Parts.box(self,"TowerCornice",Vector3(size.x+0.65,0.35,size.z+0.65),at+Vector3(0,height+0.1,0),trim)
	parapet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var roof_height := 4.8 if height > 10 else 3.0
	var cap := Parts.cylinder(self,at+Vector3(0,height+0.4+roof_height*0.5,0),size.x*0.8,0.10,roof_height,roof)
	cap.mesh.radial_segments = 4
	cap.rotation.y = PI/4
	for i in range(1,5):
		var fraction := i/5.0
		var radius := lerpf(size.x*0.8,0.10,fraction)
		var ridge := Parts.cylinder(self,at+Vector3(0,height+0.4+roof_height*fraction,0),radius+0.045,radius,0.065,dark)
		ridge.mesh.radial_segments = 4
		ridge.rotation.y = PI/4
	Parts.cylinder(self,at+Vector3(0,height+roof_height+0.82,0),0.065,0.045,0.8,gold)
	_flag(at+Vector3(-size.x*0.3,height*0.66,size.z*0.5+0.2))
	_lantern(at+Vector3(size.x*0.28,1.8,size.z*0.5+0.35))

func _arcade(side: int, front: float, back: float) -> void:
	# Ground piers are authored in Layout; arches/roofs are overhead only.
	var midpoint := side*244.0/32.0
	for z in [front,back]:
		var arch := Node3D.new()
		arch.name = "GalleryArcade"
		arch.position = Vector3(midpoint,0,z/32.0)
		add_child(arch)
		_arch(arch,66.0/32.0,2.5)
	var span := (back-front)/32.0+0.9
	Parts.box(self,"GalleryRoofEaves",Vector3(4.95,0.17,span),Vector3(midpoint,4.88,(front+back)/64.0),dark)
	var roof_panel := Parts.box(self,"GalleryLeadRoof",Vector3(4.95,0.12,span),Vector3(midpoint,5.02,(front+back)/64.0),roof)
	roof_panel.rotation.z = side*0.035
	for x in [-1.8,-0.9,0.0,0.9,1.8]:
		Parts.box(self,"GalleryRoofSeam",Vector3(0.04,0.07,span),Vector3(midpoint+x,5.10+side*x*0.035,(front+back)/64.0),trim)

func _window(at: Vector3, yaw: float) -> void:
	var holder := Node3D.new()
	holder.position = at
	holder.rotation.y = yaw
	add_child(holder)
	Parts.box(holder,"WindowFrame",Vector3(0.68,1.35,0.13),Vector3.ZERO,trim)
	Parts.box(holder,"WindowRecess",Vector3(0.48,1.13,0.15),Vector3(0,0,0.02),dark)
	Parts.box(holder,"WindowMullion",Vector3(0.065,1.1,0.18),Vector3(0,0,0.04),gold)
	Parts.box(holder,"WindowTransom",Vector3(0.5,0.065,0.18),Vector3(0,0.1,0.04),gold)

func _arch(parent: Node3D, radius: float, spring: float) -> void:
	for side in [-1,1]:
		Parts.box(parent,"ArchPier",Vector3(0.48,spring,0.65),Vector3(side*radius,spring*0.5,0),trim)
		Parts.box(parent,"ArchCapital",Vector3(0.64,0.2,0.78),Vector3(side*radius,spring,0),trim)
	var stone_count := 13
	for i in stone_count:
		var angle := (i+0.5)*PI/stone_count
		var block := Parts.box(parent,"ArchVoussoir",Vector3(radius*PI/stone_count+0.04,0.43,0.72),Vector3(cos(angle)*radius,spring+sin(angle)*radius,0),trim if i%3 else stone)
		block.rotation.z = angle-PI/2
	Parts.box(parent,"ArchKeystone",Vector3(0.5,0.65,0.85),Vector3(0,spring+radius,0),gold)

func _flag(at: Vector3) -> void:
	Parts.box(self,"BannerBracket",Vector3(1.1,0.07,0.1),at+Vector3(0,0.9,0),dark)
	var fabric := MeshInstance3D.new()
	fabric.name = "CitadelBanner"
	var quad := QuadMesh.new()
	quad.size = Vector2(0.8,1.7)
	fabric.mesh = quad
	fabric.position = at
	fabric.material_override = banner
	fabric.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(fabric)

func _lantern(at: Vector3) -> void:
	Parts.box(self,"LanternBracket",Vector3(0.2,0.12,0.65),at+Vector3(0,0.35,-0.1),dark)
	var glow := Parts.material(Color("ffcc85"))
	glow.emission_enabled = true
	glow.emission = Color("d39a53")
	Parts.box(self,"CitadelLantern",Vector3(0.24,0.38,0.24),at,glow)
	for y in [-0.24,0.24]:
		Parts.box(self,"LanternCap",Vector3(0.38,0.09,0.38),at+Vector3(0,y,0),dark)
	var socket := Marker3D.new()
	socket.position = at
	socket.add_to_group("ambient_lamp_sockets")
	add_child(socket)

func _process(delta: float) -> void:
	clock += delta
	banner.set_shader_parameter("clock",clock)
	var active := is_instance_valid(target) and is_instance_valid(camera) and target.visible
	for material in cutaway_materials:
		material.set_shader_parameter("cutaway_enabled",active)
	if not active:
		return
	var center := target.global_position+Vector3(0,0.95,0)
	var screen := camera.unproject_position(center)
	var edge := camera.unproject_position(center+camera.global_basis.x*1.7)
	var viewport_size := camera.get_viewport().get_visible_rect().size
	for material in cutaway_materials:
		material.set_shader_parameter("target_world",center)
		material.set_shader_parameter("target_uv",screen/viewport_size)
		material.set_shader_parameter("radius_ratio",screen.distance_to(edge)/viewport_size.y)
