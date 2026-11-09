extends SceneTree
## Export the parametric house to an editable interchange model.
func _initialize() -> void:
	call_deferred("export_house")

func export_house() -> void:
	var names := ["stone_house", "smithy_house", "canopy_shop", "green_awning_house"]
	for i in names.size():
		var house := load("res://scenes/regions/shared/stone_house.tscn").instantiate() as Node3D
		house.variant = i
		root.add_child(house)
		await process_frame
		var model := Node3D.new()
		model.name = names[i]
		_copy_meshes(house, model, house)
		var document := GLTFDocument.new()
		var state := GLTFState.new()
		var error := document.append_from_scene(model, state)
		if error == OK:
			DirAccess.make_dir_recursive_absolute("res://assets/regions/shared/models")
			error = document.write_to_filesystem(state, "res://assets/regions/shared/models/%s.glb" % names[i])
		model.free()
		house.queue_free()
		print(names[i], " export: ", error_string(error))
		if error != OK:
			quit(1)
			return
	quit(0)

func _copy_meshes(source: Node, destination: Node3D, origin: Node3D) -> void:
	if source is MeshInstance3D:
		var part := MeshInstance3D.new()
		part.name = source.name
		part.mesh = source.mesh
		part.material_override = source.material_override
		part.transform = origin.global_transform.affine_inverse() * source.global_transform
		destination.add_child(part)
	for child in source.get_children():
		_copy_meshes(child, destination, origin)
