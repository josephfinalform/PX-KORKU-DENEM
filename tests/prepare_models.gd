extends SceneTree
func _initialize() -> void:
	for file in DirAccess.get_files_at("res://assets/models"):
		if not file.ends_with(".glb"):
			continue
		var document := GLTFDocument.new()
		var state := GLTFState.new()
		var result := document.append_from_file("res://assets/models/" + file, state)
		if result != OK:
			quit(1)
			return
		var scene := document.generate_scene(state)
		var packed := PackedScene.new()
		packed.pack(scene)
		ResourceSaver.save(packed, "res://assets/models/" + file.get_basename() + ".scn")
		scene.free()
		print("Prepared ", file)
	quit()
