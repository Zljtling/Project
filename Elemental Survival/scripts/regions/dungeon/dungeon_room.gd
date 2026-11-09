extends Node3D
## Visuals only. DungeonLayout supplies the room and solid obstacle bounds.
const Parts = preload("res://scripts/regions/shared/model_parts.gd")
const G = preload("res://scripts/world/scene_geometry.gd")
var layout: RefCounted
var room_index := 0
var obstacle: Node3D

func _ready() -> void:
	name = "DungeonRoom%d" % room_index
	var room: Rect2 = layout.room
	var at := G.point3(room.get_center())
	var size := room.size/G.UNITS
	var stone := Parts.material(Color("7b877e"),"stone",Vector3.ONE*0.4)
	var trim := Parts.material(Color("aaa68a"),"stone",Vector3.ONE*0.35)
	var dark := Parts.material(Color("3e514c"),"stone",Vector3.ONE*0.4)
	Parts.box(self,"DungeonFloor",Vector3(size.x,0.2,size.y),at+Vector3(0,-0.1,0),stone)
	for x in [-1,1]:
		Parts.box(self,"DungeonWall",Vector3(0.4,2.5,size.y),at+Vector3(x*size.x*0.5,1.25,0),stone)
	for z in [-1,1]:
		Parts.box(self,"DungeonWall",Vector3(size.x,2.5,0.4),at+Vector3(0,1.25,z*size.y*0.5),stone)
	obstacle = Node3D.new()
	obstacle.name = "CentralObstacle"
	obstacle.position = G.point3(layout.obstacle.get_center())
	add_child(obstacle)
	var footprint: Vector2 = layout.obstacle.size/G.UNITS
	var timber := Parts.material(Color("96704e"),"wood",Vector3.ONE*0.4)
	Parts.box(obstacle,"SolidBase",Vector3(footprint.x,0.9,footprint.y),Vector3(0,0.45,0),timber if room_index == 1 else stone,true)
	Parts.box(obstacle,"BaseFooting",Vector3(footprint.x,0.18,footprint.y),Vector3(0,0.12,0),dark)
	match room_index:
		0:
			Parts.box(obstacle,"BrokenColumnPlinth",Vector3(7.4,0.18,5.5),Vector3(0,0.98,0),trim)
			for i in 3:
				var height := 1.15+i*0.38
				var pos := Vector3(-2.3+i*2.3,1.08,0.2 if i%2 else -0.4)
				Parts.cylinder(obstacle,pos+Vector3(0,0.08,0),0.83,0.83,0.16,dark)
				Parts.cylinder(obstacle,pos+Vector3(0,height*0.5,0),0.6,0.53,height,trim)
				Parts.rock(obstacle,pos+Vector3(0,height,0),Vector3(0.53,0.15,0.51),stone)
			for i in 6:
				Parts.rock(obstacle,Vector3(-2.8+i*1.05,1.2,1.65),Vector3(0.33,0.2,0.4),dark)
		1:
			Parts.box(obstacle,"WorkbenchTop",Vector3(7.5,0.3,5.625),Vector3(0,1.22,0),timber)
			for x in [-2.8,0.0,2.8]:
				Parts.box(obstacle,"IronWorkbenchBand",Vector3(0.14,0.035,5.625),Vector3(x,1.39,0),dark)
			for x in [-2.5,2.5]:
				Parts.box(obstacle,"ToolCrate",Vector3(1.1,0.75,1),Vector3(x,1.75,-1.5),timber)
			Parts.box(obstacle,"AnvilFoot",Vector3(1.5,0.22,0.8),Vector3(0,1.52,0),dark)
			Parts.box(obstacle,"AnvilNeck",Vector3(0.6,0.6,0.65),Vector3(0,1.87,0),dark)
			Parts.box(obstacle,"AnvilTop",Vector3(1.8,0.22,0.8),Vector3(0,2.22,0),trim)
			var hammer := Parts.box(obstacle,"DiscardedHammer",Vector3(1.2,0.12,0.13),Vector3(1.6,1.52,1.1),timber)
			hammer.rotation.y = -0.4
			Parts.box(obstacle,"HammerHead",Vector3(0.3,0.3,0.5),Vector3(2.1,1.62,1.3),dark)
		2:
			Parts.box(obstacle,"BrokenDaisStep",Vector3(6.5,0.28,4.6),Vector3(0,1.02,0),trim)
			Parts.box(obstacle,"BrokenDaisCore",Vector3(4.7,0.55,3.4),Vector3(0,1.43,0),stone)
			for side in [-1,1]:
				var slab := Parts.box(obstacle,"SplitCapstone",Vector3(2.15,0.32,3.4),Vector3(side*1.18,1.86,0),trim)
				slab.rotation.z = side*0.06
			Parts.rock(obstacle,Vector3(-2.6,1.35,1.8),Vector3(0.5,0.35,0.4),dark)
