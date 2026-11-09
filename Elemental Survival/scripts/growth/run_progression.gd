class_name ESRunProgression
extends Node

signal changed
const PRICES := {"battery": 15, "heal": 20, "chip": 90, "refresh": 35}
const ELEMENT_NAMES := {"poison": "毒", "fire": "火", "water": "水", "wind": "风", "thunder": "雷", "wood": "木"}
var coins := 50
var parts := 0
var batteries := 1
var battery := 100.0
var miracles := 0
var chips := 0
var free_refreshes := 0
var materials := {"poison": 0, "fire": 0, "water": 0, "wind": 0, "thunder": 0, "wood": 0}
var unlocked_elements: Array[String] = []
var inventory: Array[ESWeaponInstance] = []
var equipped: Array[ESWeaponInstance] = []
var rng := RandomNumberGenerator.new()
var stock := {"battery": 3, "heal": 2, "chip": 1, "refresh": 1}
var last_refresh_yield := 0

func _ready() -> void:
	rng.randomize()
	for path in ["blade", "needle", "orb"]:
		var item := ESWeaponInstance.new(load("res://data/weapons/%s.tres" % path))
		inventory.append(item)
		equipped.append(item)

func random_weapon(stars := 1) -> ESWeaponInstance:
	var paths := ["blade", "needle", "orb"]
	var item := ESWeaponInstance.new(load("res://data/weapons/%s.tres" % paths[rng.randi_range(0, 2)]))
	item.stars = clampi(stars,1,4)
	inventory.append(item)
	changed.emit()
	return item

func set_starting_weapon(id: String) -> bool:
	if id not in ["blade", "needle", "orb"]:
		return false
	var item := ESWeaponInstance.new(load("res://data/weapons/%s.tres" % id))
	inventory.assign([item])
	equipped.assign([item, null, null])
	changed.emit()
	return true

func equip(slot: int, item: ESWeaponInstance) -> bool:
	if slot < 0 or slot >= 3 or item not in inventory:
		return false
	var previous := equipped[slot]
	var existing := equipped.find(item)
	equipped[slot] = item
	if existing >= 0 and existing != slot:
		equipped[existing] = previous
	changed.emit()
	return true

func ingredients(main: ESWeaponInstance) -> Array[ESWeaponInstance]:
	var result: Array[ESWeaponInstance] = []
	if main.stars >= 3:
		return result
	var ordered: Array[ESWeaponInstance] = []
	for item in inventory:
		if item not in equipped:
			ordered.append(item)
	for item in equipped:
		if item != null:
			ordered.append(item)
	for item in ordered:
		if item != main and item.stars == main.stars:
			result.append(item)
			if result.size() == 2:
				break
	return result

func combine(main: ESWeaponInstance, fodder: Array[ESWeaponInstance]) -> bool:
	if main not in inventory or main.stars >= 3 or fodder.size() != 2:
		return false
	if fodder[0] == fodder[1]:
		return false
	for item in fodder:
		if item == main or item not in inventory or item.stars != main.stars:
			return false
	for item in fodder:
		for element in item.elements:
			main.elements[element] = mini(ESWeaponInstance.MAX_ELEMENT_LEVEL, int(main.elements.get(element, 0)) + int(item.elements[element]))
		inventory.erase(item)
		var equipped_slot := equipped.find(item)
		if equipped_slot >= 0:
			equipped[equipped_slot] = null
	main.stars += 1
	changed.emit()
	return true

func breakthrough(main: ESWeaponInstance) -> bool:
	if main not in inventory or main.stars != 3 or miracles <= 0:
		return false
	miracles -= 1
	main.stars = 4
	changed.emit()
	return true

func enchant(main: ESWeaponInstance, element: String) -> bool:
	if main not in inventory or element not in unlocked_elements:
		return false
	if not main.elements.has(element) and main.elements.size() >= main.capacity():
		return false
	var level := int(main.elements.get(element, 0))
	if level >= ESWeaponInstance.MAX_ELEMENT_LEVEL:
		return false
	var cost := 2 + level
	if int(materials.get(element, 0)) < cost:
		return false
	materials[element] -= cost
	main.elements[element] = level + 1
	changed.emit()
	return true

func buy(product: String) -> bool:
	var prices := PRICES
	if not prices.has(product) or stock.get(product, 0) <= 0 or coins < prices[product]:
		return false
	coins -= prices[product]
	stock[product] -= 1
	match product:
		"battery": batteries += 1
		"chip": chips += 1
		"refresh":
			last_refresh_yield = rng.randi_range(1, 3)
			free_refreshes += last_refresh_yield
	changed.emit()
	return true

func use_battery() -> bool:
	if batteries <= 0 or battery >= 100.0:
		return false
	batteries -= 1
	battery = minf(100.0, battery + 60.0)
	changed.emit()
	return true

func reset_stock() -> void:
	stock = {"battery": 3, "heal": 2, "chip": 1, "refresh": 1}
	changed.emit()
