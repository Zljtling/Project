extends RefCounted
## Local simulation units (32 per metre). This is the single source for tower solids and art.
const BOUNDS := Rect2(-480,-440,960,880)
const ELITE := Vector2(0,-40)
const CHEST := Vector2(200,260)
const GATES := [Vector2(0,-440),Vector2(480,0),Vector2(0,440),Vector2(-480,0)]
const REWARD_DOORS := [Vector2(80,260),Vector2(360,260)]
const TOWERS := [
	{"rect":Rect2(-410,-395,160,150),"height":11.8,"name":"MainKeep"},
	{"rect":Rect2(295,-355,110,110),"height":7.7,"name":"EastWatchtower"},
	{"rect":Rect2(-395,245,120,120),"height":5.8,"name":"WestWatchtower"}
]

static func walls() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for z in [-440,416]:
		for x in [-480,100]:
			result.append({"rect":Rect2(x,z,380,24),"height":2.15,"kind":"curtain"})
	for x in [-480,456]:
		for z in [-440,100]:
			result.append({"rect":Rect2(x,z,24,340),"height":2.15,"kind":"curtain"})
	# Both galleries connect north/south; central gaps permit cross-court combat.
	for x in [-190,166]:
		result.append({"rect":Rect2(x,-180,24,120),"height":2.8,"kind":"gallery"})
		result.append({"rect":Rect2(x,60,24,100),"height":2.1,"kind":"gallery"})
	for x in [-318,302]:
		for z in [-166,-86,74,138]:
			result.append({"rect":Rect2(x,z,16,16),"height":2.5,"kind":"column"})
	# Two opposite doors, each 104 units wide; no one-way loot closet.
	for z in [150,346]:
		result.append({"rect":Rect2(80,z,280,24),"height":2.65,"kind":"treasury"})
	for x in [80,336]:
		for z in [174,312]:
			result.append({"rect":Rect2(x,z,24,34),"height":2.65,"kind":"treasury"})
	for tower in TOWERS:
		result.append({"rect":tower["rect"],"height":tower["height"],"kind":"tower","name":tower["name"]})
	return result

static func collision_rects(center: Vector2) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for part in walls():
		var rect: Rect2 = part["rect"]
		result.append(Rect2(rect.position+center,rect.size))
	return result
