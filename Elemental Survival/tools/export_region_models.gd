extends SceneTree
const RegionModule = preload("res://scripts/regions/region_module.gd")
const IDS := ["windmill_town", "waterfront", "farm", "overgrown", "broken_bridge"]

func _initialize() -> void:
	call_deferred("export_all")

func export_all() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/regions/models")
	for i in IDS.size():
		var module := RegionModule.new()
		module.region = i
		root.add_child(module)
		await process_frame
		var model := Node3D.new()
		model.name = IDS[i]
		_copy_meshes(module, model, module)
		var document := GLTFDocument.new()
		var state := GLTFState.new()
		var error := document.append_from_scene(model, state)
		if error == OK:
			error = document.write_to_filesystem(state, "res://assets/regions/models/%s.glb" % IDS[i])
		model.free()
		module.queue_free()
		print(IDS[i], ": ", error_string(error))
		if error != OK:
			quit(1)
			return
	quit()

func _copy_meshes(source: Node, destination: Node3D, origin: Node3D) -> void:
	if source is MeshInstance3D and source.visible:
		var part := MeshInstance3D.new()
		part.name = source.name
		part.mesh = source.mesh
		part.material_override = source.material_override
		part.transform = origin.global_transform.affine_inverse() * source.global_transform
		destination.add_child(part)
	for child in source.get_children():
		_copy_meshes(child, destination, origin)
