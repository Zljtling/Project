extends RefCounted
const Parts = preload("res://scripts/regions/shared/model_parts.gd")

static func lamp(parent: Node3D, at: Vector3, metal: Material) -> void:
	var socket := Marker3D.new()
	socket.name = "LanternLightSocket"
	socket.position = at+Vector3(0,2.7,0)
	socket.add_to_group("ambient_lamp_sockets")
	parent.add_child(socket)
	Parts.cylinder(parent,at+Vector3(0,1.45,0),0.08,0.05,2.9,metal)
	Parts.cylinder(parent,at+Vector3(0,0.1,0),0.22,0.13,0.2,metal)
	var glass := Parts.material(Color("e9c484"))
	glass.emission_enabled = true
	glass.emission = Color("ddb178")
	Parts.box(parent,"StreetLantern",Vector3(0.36,0.48,0.36),at+Vector3(0,2.75,0),glass)
	Parts.cylinder(parent,at+Vector3(0,3.1,0),0.34,0,0.28,metal)
	Parts.box(parent,"LanternBase",Vector3(0.44,0.1,0.44),at+Vector3(0,2.5,0),metal)
	for x in [-0.18,0.18]:
		Parts.box(parent,"LanternFrame",Vector3(0.04,0.5,0.4),at+Vector3(x,2.75,0),metal)

static func bench(parent: Node3D, at: Vector3, wood: Material, metal: Material) -> void:
	Parts.box(parent,"BenchSeat",Vector3(2,0.14,0.6),at+Vector3(0,0.6,0),wood,true)
	Parts.box(parent,"BenchBack",Vector3(2,0.55,0.12),at+Vector3(0,1,-0.28),wood)
	for x in [-0.7,0.7]:
		Parts.box(parent,"BenchLeg",Vector3(0.14,0.6,0.5),at+Vector3(x,0.3,0),metal)

static func planter(parent: Node3D, at: Vector3, wood: Material) -> void:
	Parts.box(parent,"Planter",Vector3(1.3,0.32,0.5),at+Vector3(0,0.16,0),wood)
	var leaves := Parts.material(Color("708653"))
	var petals := Parts.material(Color("d2ba8b"))
	for x in [-0.4,0,0.4]:
		Parts.cylinder(parent,at+Vector3(x,0.4,0),0.18,0.06,0.4,leaves)
		Parts.box(parent,"Blossom",Vector3(0.13,0.1,0.13),at+Vector3(x,0.62,0),petals)
