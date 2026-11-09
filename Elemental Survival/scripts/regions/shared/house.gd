extends Node3D
## Reusable house model. Floor space is x [-3,3], z [-2.4,2.4].
## South and north doors share the same mesh and collision openings.
const Parts = preload("res://scripts/regions/shared/model_parts.gd")
@export var roof_color := Color("9ab2b2")
@export_range(0, 3) var variant := 0
@export var weathered := false
@export var wooden_walls := false
var roof: Node3D
var front: Node3D
var occupants: Array[Node3D] = []

func _ready() -> void:
	var plaster := Parts.material(Color("dcd6c5"), "plaster", Vector3.ONE * 0.35)
	if wooden_walls:
		plaster = Parts.material(Color("b1a297"),"wood",Vector3.ONE*0.4)
	elif weathered:
		plaster = Parts.material(Color("aab3a4"),"plaster",Vector3.ONE*0.35)
	var timber := Parts.material(Color("b9a09a"), "wood", Vector3.ONE * 0.4)
	var stone := Parts.material(Color("c9ccc0"), "stone")
	var tiles := Parts.material(roof_color, "roof", Vector3.ONE * 0.6)
	# Walkable surface is flush with outdoors. Only the visual is lifted 8 mm
	# to avoid z-fighting; a raised collision lip blocks move_and_slide at doors.
	var floor_surface := Parts.box(self, "Floor", Vector3(6, 0.1, 4.8), Vector3(0, -0.042, 0), timber, true)
	floor_surface.get_child(0).position.y = -0.008
	add_to_group("enterable_house")
	front = Node3D.new()
	front.name = "SouthFacade"
	add_child(front)
	for z in [-2.4, 2.4]:
		var holder: Node3D = front if z > 0 else self
		for x in [-1.95, 1.95]:
			Parts.box(holder, "DoorSideWall", Vector3(2.1, 2.7, 0.22), Vector3(x, 1.35, z), plaster, true)
		Parts.box(holder, "DoorLintel", Vector3(1.8, 0.55, 0.22), Vector3(0, 2.425, z), timber, true)
	for x in [-3.0, 3.0]:
		Parts.box(front if x > 0 else self, "SideWall", Vector3(0.22, 2.7, 4.8), Vector3(x, 1.35, 0), plaster, true)
		for z in [-2.4, 0.0, 2.4]:
			Parts.box(self, "TimberPost", Vector3(0.28, 2.8, 0.28), Vector3(x, 1.4, z), timber)
	for z in [-2.55, 2.55]:
		for x in [-1.95, 1.95]:
			Parts.box(self, "Foundation", Vector3(2.1, 0.35, 0.25), Vector3(x, 0.175, z), stone)
			Parts.box(front if z > 0 else self, "WindowFrame", Vector3(0.95, 1.05, 0.12), Vector3(x, 1.55, z), timber)
			var glass := Parts.material(Color("475957") if weathered else Color("e8bb77"))
			Parts.box(front if z > 0 else self, "Window", Vector3(0.7, 0.76, 0.14), Vector3(x, 1.55, z + signf(z) * 0.02), glass)
			Parts.box(front if z > 0 else self, "WindowMullion", Vector3(0.07, 0.8, 0.17), Vector3(x, 1.55, z + signf(z) * 0.04), timber)
	roof = Node3D.new()
	roof.name = "Roof"
	add_child(roof)
	Parts.gable(roof, -3.0, plaster)
	Parts.gable(roof, 3.0, plaster)
	for side in [-1.0, 1.0]:
		var slope := Parts.box(roof, "RoofSlope", Vector3(6.7, 0.18, 3.25), Vector3(0, 3.38, side * 1.38), tiles)
		slope.rotation.x = side * deg_to_rad(27)
	Parts.box(roof, "Ridge", Vector3(6.8, 0.2, 0.22), Vector3(0, 4.12, 0), timber)
	Parts.box(roof, "Chimney", Vector3(0.65, 1.6, 0.7), Vector3(1.8, 3.85, -0.8), stone)
	Parts.box(roof, "ChimneyCap", Vector3(0.8, 0.16, 0.85), Vector3(1.8, 4.67, -0.8), timber)
	Parts.box(roof, "ChimneyOpening", Vector3(0.42, 0.02, 0.46), Vector3(1.8, 4.76, -0.8), Parts.material(Color("383b3d")))
	_add_details(timber, stone, tiles)
	Parts.box(self, "Table", Vector3(1.3, 0.12, 0.75), Vector3(-1.7, 0.9, -0.9), timber, true)
	for x in [-2.2, -1.2]:
		Parts.box(self, "TableLeg", Vector3(0.12, 0.9, 0.5), Vector3(x, 0.45, -0.9), timber)
	var sockets := Node3D.new()
	sockets.name = "LootSockets"
	add_child(sockets)
	for at in [Vector3(-1.8, 0, 1.1), Vector3(1.8, 0, 1.1), Vector3(1.8, 0, -1.1)]:
		var socket := Marker3D.new()
		socket.position = at
		sockets.add_child(socket)
	var area := Area3D.new()
	area.name = "InteriorVisibility"
	area.collision_layer = 0
	area.collision_mask = 2
	var shape := CollisionShape3D.new()
	var volume := BoxShape3D.new()
	volume.size = Vector3(6.8, 3, 6.6)
	shape.shape = volume
	shape.position.y = 1
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(_on_entered)
	area.body_exited.connect(_on_exited)

func _add_details(timber: Material, stone: Material, tiles: Material) -> void:
	if weathered:
		for x in [-1.95,1.95]:
			var board := Parts.box(front,"BoardedWindow",Vector3(1.15,0.16,0.1),Vector3(x,1.55,2.81),timber)
			board.rotation.z = 0.35 if x < 0 else -0.25
		var moss := Parts.material(Color("5b7351"))
		for i in 8:
			var x := -2.8+i*0.8
			if absf(x) > 0.9:
				Parts.box(front,"FoundationMoss",Vector3(0.55,0.12,0.14),Vector3(x,0.3,2.7),moss)
			Parts.box(roof,"EaveMoss",Vector3(0.45,0.06,0.26),Vector3(x,2.8,2.65),moss)
	for side in [-1.0, 1.0]:
		var eave := Parts.box(roof, "EaveTrim", Vector3(6.9, 0.2, 0.18), Vector3(0, 2.67, side * 2.85), timber)
		eave.rotation.x = side * deg_to_rad(27)
	for x in [-1.95, 1.95]:
		for side in [-1, 1]:
			Parts.box(front, "WindowShutter", Vector3(0.28, 1.0, 0.12), Vector3(x+side*0.66, 1.55, 2.65), timber)
			for y in [1.25, 1.8]:
				Parts.box(front, "ShutterStrap", Vector3(0.3, 0.06, 0.14), Vector3(x+side*0.66, y, 2.68), stone)
		Parts.box(front, "WindowSill", Vector3(1.25, 0.12, 0.4), Vector3(x, 1.0, 2.7), timber)
	for x in [-2.8, 2.8]:
		Parts.box(front, "FacadePost", Vector3(0.17, 2.7, 0.2), Vector3(x, 1.35, 2.58), timber)
	Parts.box(front, "UpperFacadeBeam", Vector3(6, 0.12, 0.17), Vector3(0, 2.62, 2.58), timber)
	for x in [-1.95, 1.95]:
		Parts.box(front, "LowerFacadeBeam", Vector3(2.1, 0.12, 0.17), Vector3(x, 0.65, 2.58), timber)
	# A small dormer gives the roof an authored silhouette.
	Parts.box(roof, "Dormer", Vector3(1.25, 0.9, 0.9), Vector3(-1.1, 3.65, 1.25), timber)
	Parts.box(roof, "DormerWindow", Vector3(0.75, 0.55, 0.05), Vector3(-1.1, 3.7, 1.73), Parts.material(Color("d1b477")))
	for side in [-1, 1]:
		var cap := Parts.box(roof, "DormerRoof", Vector3(0.85, 0.12, 1.25), Vector3(-1.1+side*0.34, 4.16, 1.25), tiles)
		cap.rotation.z = side * -0.45
	if variant == 1:
		# Smithy sign and external workbench; door remains unobstructed.
		var sign := Parts.box(front, "SmithySign", Vector3(1.8, 0.6, 0.16), Vector3(0, 2.5, 2.8), Parts.material(Color("cba563")))
		Parts.box(sign, "AnvilTop", Vector3(0.65, 0.12, 0.04), Vector3(0, 0.12, 0.1), stone)
		Parts.box(sign, "AnvilWaist", Vector3(0.3, 0.16, 0.04), Vector3(0, -0.02, 0.1), stone)
		Parts.box(sign, "AnvilFoot", Vector3(0.55, 0.1, 0.04), Vector3(0, -0.15, 0.1), stone)
	if variant >= 2:
		var cloth := Parts.material(Color("936879") if variant == 2 else Color("788c77"))
		var awning := Parts.box(front, "CanvasAwning", Vector3(4.8, 0.08, 1.25), Vector3(0, 2.2, 3.05), cloth)
		awning.rotation.x = 0.16
		for x in [-2.3, 2.3]:
			Parts.box(front, "AwningPost", Vector3(0.1, 2.1, 0.1), Vector3(x, 1.05, 3.65), timber)

func _on_entered(body: Node3D) -> void:
	if not occupants.has(body):
		occupants.append(body)
	_update_visibility()

func _on_exited(body: Node3D) -> void:
	occupants.erase(body)
	_update_visibility()

func _update_visibility() -> void:
	roof.visible = occupants.is_empty()
	front.visible = occupants.is_empty()
