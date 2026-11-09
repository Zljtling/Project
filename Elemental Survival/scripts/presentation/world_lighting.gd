extends Node3D
## Presentation-only light rig. Four reusable local lights, never one light per prop.
const LOCAL_LIGHT_LIMIT := 4
var world: Node2D
var camera: Camera3D
var environment := Environment.new()
var sun := DirectionalLight3D.new()
var local_lights: Array[OmniLight3D] = []
var clock := 0.0
var sample_left := 0.0
var biome := "meadow"
var fog_target := Color("b5c6b8")
var ambient_target := Color("b7cbd6")

func _ready() -> void:
	name = "WorldLighting"
	var holder := WorldEnvironment.new()
	holder.environment = environment
	add_child(holder)
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("64786b")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = ambient_target
	environment.ambient_light_energy = 0.56
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 0.98
	environment.fog_enabled = true
	environment.fog_mode = Environment.FOG_MODE_DEPTH
	environment.fog_depth_begin = 48
	environment.fog_depth_end = 155
	environment.fog_density = 0.24
	environment.fog_light_color = fog_target
	environment.glow_enabled = true
	environment.glow_intensity = 0.22
	environment.glow_hdr_threshold = 1.35
	sun.name = "AfternoonSun"
	sun.rotation_degrees = Vector3(-53,-35,0)
	sun.light_color = Color("ffebc9")
	sun.light_energy = 0.92
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 95
	sun.shadow_bias = 0.035
	sun.shadow_normal_bias = 1.0
	add_child(sun)
	for i in LOCAL_LIGHT_LIMIT:
		var lamp := OmniLight3D.new()
		lamp.name = "NearbyLantern%d" % i
		lamp.light_color = Color("ffcf86")
		lamp.omni_range = 4.2
		lamp.light_energy = 0.0
		lamp.shadow_enabled = false
		add_child(lamp)
		local_lights.append(lamp)

func _process(delta: float) -> void:
	clock += delta
	sample_left -= delta
	if sample_left <= 0:
		sample_left = 0.25
		_sample_region()
		_place_lights()
	var weight := 1.0-exp(-delta*2.0)
	environment.fog_light_color = environment.fog_light_color.lerp(fog_target,weight)
	environment.ambient_light_color = environment.ambient_light_color.lerp(ambient_target,weight)
	sun.light_energy = lerpf(sun.light_energy,0.46 if biome == "dungeon" else 0.92,weight)
	# Review cameras can zoom out without fog washing over the entire authored scene.
	var focus_distance := 32.0
	if is_instance_valid(camera) and is_instance_valid(world.player):
		var focus := Vector3(world.player.position.x/32,0,world.player.position.y/32)
		focus_distance = camera.global_position.distance_to(focus)
	environment.fog_depth_begin = maxf(48,focus_distance+16)
	environment.fog_depth_end = environment.fog_depth_begin+107
	for i in local_lights.size():
		var lamp := local_lights[i]
		if lamp.visible:
			lamp.light_energy = 0.72+sin(clock*2.3+i)*0.035

func _sample_region() -> void:
	biome = "dungeon" if world.in_dungeon else "meadow"
	if not world.in_dungeon and world.started:
		for element in ["poison","fire"]:
			for center in world.element_centers(element):
				if world.player.position.distance_to(center) < 1120:
					biome = element
	fog_target = {"meadow":Color("b5c6b8"),"poison":Color("aeb38a"),"fire":Color("b79b85"),"dungeon":Color("687889")}[biome]
	ambient_target = {"meadow":Color("b7cbd6"),"poison":Color("b7c7ad"),"fire":Color("c7b9b3"),"dungeon":Color("a0b4cb")}[biome]

func _place_lights() -> void:
	var candidates: Array[Node] = []
	var focus := Vector3(world.player.position.x/32,0,world.player.position.y/32)
	for socket in get_tree().get_nodes_in_group("ambient_lamp_sockets"):
		if socket is Node3D and socket.global_position.distance_squared_to(focus) < 28*28:
			candidates.append(socket)
	candidates.sort_custom(func(a: Node3D, b: Node3D): return a.global_position.distance_squared_to(focus) < b.global_position.distance_squared_to(focus))
	for i in local_lights.size():
		local_lights[i].visible = i < candidates.size()
		if i < candidates.size():
			local_lights[i].global_position = candidates[i].global_position
