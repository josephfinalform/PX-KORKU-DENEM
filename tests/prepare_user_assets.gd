extends SceneTree

const ROOT := "res://assets/user_hospital/"
const SETS := {
	"Bed": ["bed/Bed", "bed/hospital_Bed"],
	"Ceiling_1": ["ceiling_1/Ceiling_1", ""],
	"Ceiling_light": ["Ceiling_light/Ceiling_light", "Ceiling_light/hospital_Ceiling_light"],
	"Chairs_tables_1": ["Chairs_table_1/Chairs_tables_1", "Chairs_table_1/hospital_Chairs_tables_1"],
	"Door_mat": ["Door_1/Door_1", "Door_1/hospital_Door_1"],
	"Doorway_1": ["Doorway_1/Doorway_1", "Doorway_1/hospital_Doorway_1"],
	"Exit_sign": ["exit_sign/Exit_sign", "exit_sign/Exit_sign_Exit_sign"],
	"Floors_1": ["Floors_1/Floors_1", "Floors_1/hospital_Floors_1"],
	"IV_bag": ["Iv_bag/IV_Bag_IV_pole_bag", "iv_bag/IV_Bag_IV_pole_bag"],
	"IV_Pole": ["Iv_pole/IV_pole_bag", "iv_bag_holder/IV_Bag_holder_IV_pole_bag"],
	"Magazine": ["Magazine/Magazine", "magazine/Magazine1_Magazine"],
	"Walls_1": ["Walls_1/Walls_1", "Walls_1/hospital_Walls_1"],
	"Wheel_chair": ["wheel_chair/Wheel_chair", "wheel_chair/hospital_Wheel_chair"]
}
var textures := {}
var materials := {}
var failed := false

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ROOT + "ready")
	DirAccess.make_dir_recursive_absolute(ROOT + "ready/materials")
	DirAccess.make_dir_recursive_absolute(ROOT + "ready/textures")
	for filename in DirAccess.get_files_at(ROOT + "source"):
		if not filename.ends_with(".fbx"):
			continue
		var document := FBXDocument.new()
		var state := FBXState.new()
		if document.append_from_file(ROOT + "source/" + filename, state) != OK:
			failed = true
			continue
		var scene := document.generate_scene(state)
		_assign(scene)
		var packed := PackedScene.new()
		packed.pack(scene)
		ResourceSaver.save(packed, ROOT + "ready/" + filename.get_basename() + ".scn")
		scene.free()
		print("Prepared user model: ", filename)
	print("Material sets: ", materials.size(), "; shared textures: ", textures.size())
	quit(1 if failed else 0)

func _assign(node: Node) -> void:
	if node is MeshInstance3D:
		for index in range(node.mesh.get_surface_count()):
			var old = node.get_active_material(index)
			var name_value: String = old.resource_name if old else ""
			if not materials.has(name_value):
				materials[name_value] = _material(name_value)
			node.set_surface_override_material(index, materials[name_value])
	for child in node.get_children():
		_assign(child)

func _texture(path: String) -> Texture2D:
	if textures.has(path):
		return textures[path]
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		failed = true
		push_error("Missing source texture: " + path)
		return null
	# Engine-side conversion, preserving the untouched source PNG/TGA files.
	if image.get_width() > 1024 or image.get_height() > 1024:
		var ratio := 1024.0 / maxf(image.get_width(), image.get_height())
		image.resize(int(image.get_width() * ratio), int(image.get_height() * ratio), Image.INTERPOLATE_LANCZOS)
	image.generate_mipmaps()
	image.compress(Image.COMPRESS_S3TC)
	var texture := ImageTexture.create_from_image(image)
	ResourceSaver.save(texture, ROOT + "ready/textures/" + path.get_file().get_basename() + "_" + path.md5_text().substr(0, 8) + ".res", ResourceSaver.FLAG_CHANGE_PATH)
	textures[path] = texture
	return texture

func _material(name_value: String) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.resource_name = name_value
	if name_value == "Window":
		mat.albedo_color = Color(0.1, 0.19, 0.23, 0.4)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.roughness = 0.2
	elif SETS.has(name_value):
		var prefix: String = ROOT + "textures/" + SETS[name_value][0]
		var base := prefix + "_BaseColor.png"
		if not FileAccess.file_exists(base):
			base = prefix + "_Base_color.png"
		mat.albedo_texture = _texture(base)
		mat.normal_enabled = true
		mat.normal_texture = _texture(prefix + "_Normal.png")
		mat.normal_scale = 0.65
		mat.roughness = 1.0
		mat.metallic = 1.0
		var orm: String = ROOT + "ue5/UE5_textures/" + SETS[name_value][1] + "_OcclusionRoughnessMetallic"
		var orm_path := orm + ".tga" if FileAccess.file_exists(orm + ".tga") else orm + ".png"
		if not SETS[name_value][1].is_empty() and FileAccess.file_exists(orm_path):
			var texture := _texture(orm_path)
			mat.ao_enabled = true
			mat.ao_texture = texture
			mat.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
			mat.roughness_texture = texture
			mat.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
			mat.metallic_texture = texture
			mat.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_BLUE
		else:
			mat.roughness_texture = _texture(prefix + "_Roughness.png")
			mat.metallic_texture = _texture(prefix + "_Metallic.png")
		if name_value == "IV_bag":
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.albedo_color.a = 0.8
	else:
		failed = true
		push_error("Unmapped material: " + name_value)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	ResourceSaver.save(mat, ROOT + "ready/materials/" + name_value + ".tres", ResourceSaver.FLAG_CHANGE_PATH)
	return mat
