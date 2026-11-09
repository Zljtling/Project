class_name ESWeaponInstance
extends RefCounted

var spec: ESWeaponSpec
var stars := 1
var elements: Dictionary = {}
const MAX_ELEMENT_LEVEL := 5

func _init(source: ESWeaponSpec = null) -> void:
	spec = source

func title() -> String:
	var suffix := ""
	for element in elements:
		suffix += " %s%d" % [element, elements[element]]
	return "%s %s%s" % [spec.title, "★".repeat(stars), suffix]

func damage(base: float) -> float:
	return base * [1.0, 1.65, 2.8, 6.0][stars - 1]

func capacity() -> int:
	return 1 if stars == 1 else (3 if stars == 2 else 2147483647)
