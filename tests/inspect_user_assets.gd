extends SceneTree
func _initialize() -> void:
	print("FBXDocument available: ", ClassDB.class_exists("FBXDocument"))
	for filename in DirAccess.get_files_at("res://assets/user_hospital/source"):
		if not filename.ends_with(".fbx"):
			continue
		var file := filename.get_basename()
		var doc = ClassDB.instantiate("FBXDocument")
		var state = ClassDB.instantiate("FBXState")
		var error = doc.append_from_file("res://assets/user_hospital/source/" + file + ".fbx", state)
		print(file, " parse ", error)
		if error == OK:
			var model = doc.generate_scene(state)
			inspect(model, Transform3D.IDENTITY)
			model.free()
	quit()

func inspect(node: Node, transform: Transform3D) -> void:
	if node is Node3D:
		transform = transform * node.transform
	if node is MeshInstance3D:
		print("  ", node.name, " bounds ", transform * node.get_aabb())
		for i in range(node.mesh.get_surface_count()):
			var mat = node.get_active_material(i)
			print("    material: ", mat.resource_name if mat else "none")
	for child in node.get_children():
		inspect(child, transform)
