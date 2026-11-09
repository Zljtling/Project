extends Node
## Delta-driven shader clock respects tree pause; resources belong to the scene that owns this node.
var material: ShaderMaterial
var clock := 0.0

func _process(delta: float) -> void:
	clock += delta
	if material != null:
		material.set_shader_parameter("clock",clock)

static func attach(parent: Node, target: ShaderMaterial) -> Node:
	var driver := new()
	driver.material = target
	parent.add_child(driver)
	return driver
