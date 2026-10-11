extends "res://hospital.gd"

const FLOOR_HEIGHT := 4.2
var room_count := 0
var obstacle_bounds: Array[AABB] = []
var floor_material: StandardMaterial3D
var wall_material: StandardMaterial3D
var painted_material: StandardMaterial3D
var next_bed_event := 24.0
var bed_event_time := 0.0
var moving_bed := -1
var bed_event_count := 0
var model_count := 0
var light_materials: Array[StandardMaterial3D] = []
var material_cache := {}
var user_pack := preload("res://user_hospital_assets.gd").new()
var user_model_count := 0
var user_surface_count := 0

func build(owner_game: Node3D) -> void:
	game = owner_game
	rng.seed = 4219
	floor_material = _pbr("tiles/Tiles002_1K-JPG", Color("919a93"), 0.42)
	wall_material = _pbr("plaster/PaintedPlaster017_1K-JPG", Color("b5b3a2"), 0.45)
	painted_material = _pbr("plaster/PaintedPlaster017_1K-JPG", Color("405c54"), 0.5)
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("030609")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("7e98a5")
	env.ambient_light_energy = 0.11
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = env
	add_child(world)
	for floor_index in range(2):
		_build_floor(floor_index)
	_build_stairs()
	_build_photo()
	game.add_key(Vector3(6.6, 1.02, -5.0), "HEMŞİRE İSTASYONU / ZEMİN")
	game.add_key(Vector3(-6.6, FLOOR_HEIGHT + 1.02, -12), "ARŞİV / ÜST KAT")
	game.add_key(Vector3(6.6, FLOOR_HEIGHT + 1.02, -19), "AMELİYATHANE / ÜST KAT")
	game.door = game.box(Vector3(2.6, 2.9, 0.18), Vector3(0, 1.45, 3.75), Color("344b47"))
	game.door.get_child(0).hide()
	for x in [-0.65, 0.65]:
		var leaf := user_pack.make("door_1")
		game.door.add_child(leaf)
		leaf.scale = Vector3(1.3, 1.44, 1)
		var bounds := _bounds(leaf, game.door)
		leaf.position = Vector3(x - bounds.get_center().x, -1.45 - bounds.position.y, -0.05)
	var exit_model := user_pack.make("Exit_sign")
	add_child(exit_model)
	exit_model.position = Vector3(0, 3.31, 3.58)
	exit_model.rotation.y = PI
	exit_model.scale = Vector3.ONE * 1.7
	_sign("ACİL ÇIKIŞ", Vector3(0, 3.14, 3.58), PI, Color("b3d1ad"), 32)
	game.red_light = OmniLight3D.new()
	add_child(game.red_light)
	game.red_light.position = Vector3(0, 2.9, 2.7)
	game.red_light.light_color = Color("d27652")
	game.red_light.omni_range = 4
	game.red_light.light_energy = 0.5
	_build_dust()
	dust.emission_box_extents = Vector3(7.7, 3.6, 13)
	dust.position.y = 3.8
	dust.amount = 330

func _pbr(prefix: String, tint: Color, scale_value: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	var path := "res://assets/textures/" + prefix
	mat.albedo_texture = load(path + "_Color.jpg")
	mat.normal_enabled = true
	mat.normal_texture = load(path + "_NormalGL.jpg")
	mat.normal_scale = 0.45
	mat.roughness_texture = load(path + "_Roughness.jpg")
	mat.roughness = 0.8
	mat.albedo_color = tint
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3.ONE * scale_value
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return mat

func _block(size: Vector3, pos: Vector3, mat: Material, solid := true, nav := true) -> Node3D:
	var result = game.box(size, pos, Color.WHITE, solid)
	result.get_child(0).material_override = mat
	if solid and nav:
		obstacle_bounds.append(AABB(pos - size * 0.5, size))
	if solid and mat == floor_material and size.x >= 2 and size.z >= 2 and size.y <= 0.3:
		result.get_child(0).hide()
		_tile_surface(size, Vector3(pos.x, pos.y + size.y * 0.5 - 0.1, pos.z), "floor_tile_1")
	return result

func _wall(size: Vector3, pos: Vector3) -> void:
	var blocker := _block(size, pos, wall_material)
	if size.y < 1.2:
		return
	blocker.get_child(0).hide()
	var along_z := size.z > size.x
	var length := size.z if along_z else size.x
	var count := ceili(length / 2.0)
	var segment := length / count
	for index in range(count):
		var panel := user_pack.make("tile_wall")
		add_child(panel)
		panel.position = pos - Vector3.UP * size.y * 0.5
		if along_z:
			panel.position.z += -length * 0.5 + segment * (index + 0.5)
			panel.rotation.y = PI / 2
		else:
			panel.position.x += -length * 0.5 + segment * (index + 0.5)
		panel.scale = Vector3(segment / 2.0, size.y / 2.5, (size.x if along_z else size.z) / 0.176916)
		user_surface_count += 1

func _tile_surface(size: Vector3, pos: Vector3, kind: String) -> void:
	var prototype := user_pack.make(kind)
	var meshes := prototype.find_children("*", "MeshInstance3D", true, false)
	var count_x := ceili(size.x / 2)
	var count_z := ceili(size.z / 2)
	for source_mesh: MeshInstance3D in meshes:
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = source_mesh.mesh
		multimesh.instance_count = count_x * count_z
		var batch := MultiMeshInstance3D.new()
		batch.multimesh = multimesh
		batch.material_override = source_mesh.get_active_material(0)
		batch.set_meta("user_asset", kind)
		add_child(batch)
		var original := user_pack.mesh_transform(source_mesh, prototype)
		for x in range(count_x):
			for z in range(count_z):
				var center := pos + Vector3(-size.x * 0.5 + (x + 0.5) * size.x / count_x, 0, -size.z * 0.5 + (z + 0.5) * size.z / count_z)
				var transform := Transform3D(Basis.from_scale(Vector3(size.x / count_x / 2, 1, size.z / count_z / 2)), center)
				multimesh.set_instance_transform(x * count_z + z, transform * original)
	user_surface_count += count_x * count_z
	prototype.free()

func _build_floor(level: int) -> void:
	var y := level * FLOOR_HEIGHT
	_block(Vector3(16, 0.25, 28), Vector3(0, y - 0.125, -10), floor_material, true, false)
	var ceiling := _block(Vector3(16, 0.2, 28), Vector3(0, y + 3.7, -10), game.material(Color("343d3b")), true, false)
	ceiling.get_child(0).hide()
	_tile_surface(Vector3(16, 0.2, 28), Vector3(0, y + 3.7, -10), "ceiling_tile")
	_wall(Vector3(0.22, 3.6, 28), Vector3(-8, y + 1.8, -10))
	_wall(Vector3(16, 3.6, 0.22), Vector3(0, y + 1.8, -24))
	_wall(Vector3(16, 3.6, 0.22), Vector3(0, y + 1.8, 4))
	# East side opens onto the lower or upper stair landing.
	if level == 0:
		_wall(Vector3(0.22, 3.6, 16), Vector3(8, y + 1.8, -16))
		_wall(Vector3(0.22, 3.6, 8), Vector3(8, y + 1.8, 0))
	else:
		_wall(Vector3(0.22, 3.6, 24), Vector3(8, y + 1.8, -8))
	var names := ["GÖZLEM", "HEMŞİRE", "RADYOLOJİ", "DEPO", "HASTA ODASI", "ARŞİV", "YOĞUN BAKIM", "AMELİYATHANE"]
	for side in [-1.0, 1.0]:
		for index in range(4):
			var z := -index * 7.0
			room_count += 1
			# Room doors are two metres wide, with a lintel and metal frame.
			_wall(Vector3(0.18, 3.6, 2.5), Vector3(side * 2.2, y + 1.8, z - 2.25))
			_wall(Vector3(0.18, 3.6, 2.5), Vector3(side * 2.2, y + 1.8, z + 2.25))
			_wall(Vector3(0.18, 0.8, 2), Vector3(side * 2.2, y + 3.2, z))
			_wall(Vector3(5.8, 3.6, 0.18), Vector3(side * 5.1, y + 1.8, z - 3.5))
			for dz in [-1.02, 1.02]:
				_block(Vector3(0.23, 2.8, 0.07), Vector3(side * 2.2, y + 1.4, z + dz), game.material(Color("788b83")), false)
			var room_title: String = names[(level * 4 + index + (1 if side > 0 else 0)) % names.size()]
			if level == 0 and side > 0 and index == 1:
				room_title = "HEMŞİRE İSTASYONU"
			if level == 1 and side < 0 and index == 2:
				room_title = "ARŞİV"
			if level == 1 and side > 0 and index == 3:
				room_title = "AMELİYATHANE"
			_sign("%d%02d / %s" % [level + 1, index * 2 + (1 if side < 0 else 2), room_title], Vector3(side * 2.08, y + 2.98, z), -side * PI / 2, Color("b4c3b1"), 17)
			_furnish_room(level, side, index, z, room_title)
	for z in [1.0, -6.0, -13.0, -21.0]:
		_fixture(Vector3(0, y + 3.45, z), level)
		for x in [-1.98, 1.98]:
			# Wall-mounted crash rails along the corridor between door openings.
			_block(Vector3(0.065, 0.11, 3.7), Vector3(x, y + 0.85, z - 2.8), game.material(Color("464e45")), false)
	_sign("%s  /  MERDİVEN →" % ("ZEMİN KAT" if level == 0 else "1. KAT"), Vector3(0, y + 2.9, -23.84), 0, Color("b0c6b6"), 27)
	# Keep hall intersections open so both actors can reach stair landings.
	for z in [-6.0, -22.0]:
		_sign("MERDİVEN →", Vector3(6, y + 2.7, z - 1.6), 0, Color("c7c1a1"), 22)
	_sign("KARANLIK SENİ İZLİYOR", Vector3(-7.86, y + 1.8, -14), PI / 2, Color("632721"), 25)
	for i in range(15):
		var paper = game.box(Vector3(0.19, 0.005, 0.28), Vector3(rng.randf_range(-1.8, 1.8), y + 0.008, rng.randf_range(-23, 3)), Color("858271"), false)
		paper.rotation.y = rng.randf_range(-PI, PI)
	for z in [-8.6, -15.0, -20.1]:
		_blood(self, Vector3(rng.randf_range(-1.6, 1.6), y + 0.012, z), Vector2(0.18, 0.6))
	for i in range(9):
		var drip := _part(self, Vector3(0.012, rng.randf_range(0.08, 0.38), 0.015), Vector3(-7.86, y + 1.45, -14 + rng.randf_range(-1.2, 1.2)), Color("46231e"))
		drip.rotation.x = rng.randf_range(-0.15, 0.15)

func _furnish_room(level: int, side: float, index: int, z: float, title: String) -> void:
	var y := level * FLOOR_HEIGHT
	var pos := Vector3(side * 5.4, y, z - 0.8)
	if title == "ARŞİV" or title == "DEPO":
		_asset("23650", Vector3(side * 6.6, y, z - 2.4))
		_asset("23642", Vector3(side * 4.0, y, z - 2.4))
	elif title == "AMELİYATHANE":
		_asset("23610", pos)
		_asset("23611", pos + Vector3(1.1, 0, -0.5))
		_asset("23614", Vector3(side * 6.6, y, z - 2.3))
	elif title == "RADYOLOJİ":
		_asset("23603", pos)
	elif title == "HEMŞİRE İSTASYONU" or title == "HEMŞİRE":
		_asset("23627", pos + Vector3(0, 0, -1.2))
		_asset("23629", Vector3(side * 4.3, y, z + 1.9))
	else:
		var bed := _asset("hospital-bed", pos)
		if index > 0:
			beds.append(bed)
			bed_origins.append(bed.position)
		_asset("23594", pos + Vector3(-side * 1.0, 0, -0.9))
		_asset("23589", pos + Vector3(side * 1.0, 0, -0.9))
	_asset("23593", Vector3(side * 6.6, y, z + 2.0))
	if index == 1:
		_asset("23600", Vector3(side * 3.4, y, z - 2.2))
	# Dark blue windows, mullions and shutters establish exterior walls.
	var window := _part(self, Vector3(0.025, 1.1, 2.1), Vector3(side * 7.85, y + 2.1, z), Color("172b35"))
	var window_mat: StandardMaterial3D = game.material(Color("172b35"))
	window_mat.emission_enabled = true
	window_mat.emission = Color("0e1c25")
	window_mat.emission_energy_multiplier = 0.3
	window.material_override = window_mat
	for dz in [-1.05, 0.0, 1.05]:
		_part(self, Vector3(0.04, 1.2, 0.035), Vector3(side * 7.81, y + 2.1, z + dz), Color("525c59"))
	var room_light := OmniLight3D.new()
	add_child(room_light)
	room_light.position = Vector3(side * 6.8, y + 2.5, z)
	room_light.light_color = Color("54758b")
	room_light.light_energy = 0.22
	room_light.omni_range = 4.4

func _asset(id: String, pos: Vector3) -> Node3D:
	var holder := Node3D.new()
	add_child(holder)
	var replaced: bool = user_pack.REPLACEMENTS.has(id)
	var model: Node3D = user_pack.make(user_pack.REPLACEMENTS[id]) if replaced else load("res://assets/models/" + id + ".scn").instantiate()
	holder.add_child(model)
	if id == "hospital-bed":
		model.scale = Vector3.ONE * 0.74
	elif replaced and id == "23600":
		model.scale = Vector3.ONE * 0.85
	elif replaced and id == "23593":
		model.scale = Vector3.ONE * 1.14
	var bounds := _bounds(model, holder)
	model.position -= Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z)
	holder.position = pos
	if not replaced:
		_tone_materials(model)
	else:
		user_model_count += 1
	if id == "23594":
		var bag := user_pack.make("IV_Bag")
		holder.add_child(bag)
		bag.position = Vector3(0, 1.65, 0)
	if id == "hospital-bed":
		_stain_bed(model, holder)
	var size := Vector3(bounds.size.x, minf(bounds.size.y, 1.3), bounds.size.z)
	if id in ["23594", "23589", "23611"]:
		size.x = minf(size.x, 0.45)
		size.z = minf(size.z, 0.45)
	var blocker = _block(size, pos + Vector3.UP * size.y * 0.5, game.material(Color.WHITE))
	blocker.get_child(0).hide()
	model_count += 1
	return holder

func _bounds(node: Node3D, origin: Node3D) -> AABB:
	var result := AABB()
	var first := true
	var stack: Array[Node] = [node]
	while not stack.is_empty():
		var item: Node = stack.pop_back()
		if item is MeshInstance3D:
			var box_bounds: AABB = (origin.global_transform.affine_inverse() * item.global_transform) * item.get_aabb()
			result = box_bounds if first else result.merge(box_bounds)
			first = false
		for child in item.get_children():
			stack.append(child)
	return result

func _tone_materials(node: Node) -> void:
	if node is MeshInstance3D:
		for surface in range(node.mesh.get_surface_count()):
			var original = node.get_active_material(surface)
			if original is StandardMaterial3D:
				var identifier: int = original.get_instance_id()
				if not material_cache.has(identifier):
					var mat: StandardMaterial3D = original.duplicate()
					var c := mat.albedo_color
					var grey := (c.r + c.g + c.b) / 3.0
					mat.albedo_color = c.lerp(Color(grey, grey, grey, c.a), 0.55) * Color(0.77, 0.80, 0.74, 1)
					mat.roughness = maxf(mat.roughness, 0.55)
					material_cache[identifier] = mat
				node.set_surface_override_material(surface, material_cache[identifier])
	for child in node.get_children():
		_tone_materials(child)

func _fixture(pos: Vector3, level: int) -> void:
	var fixture := user_pack.make("ceiling_light")
	add_child(fixture)
	fixture.position = pos
	fixture.scale = Vector3(1.8, 1, 1.8)
	var tube := _part(self, Vector3(1.1, 0.025, 0.16), pos + Vector3(0, -0.065, 0), Color("b4c7b7"))
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("b4c7b7")
	mat.emission_enabled = true
	mat.emission = Color("95b2a0")
	mat.emission_energy_multiplier = 0.6
	tube.material_override = mat
	light_materials.append(mat)
	var light := OmniLight3D.new()
	add_child(light)
	light.position = pos - Vector3.UP * 0.4
	light.light_color = Color("adc8b2") if level == 0 else Color("b8c2a5")
	light.light_energy = 0.42
	light.omni_range = 5.0
	ceiling_lights.append(light)

func _build_stairs() -> void:
	# Continuous collision ramp under individual visible treads: no teleporting.
	_block(Vector3(4, 0.25, 20), Vector3(10, -0.125, -14), floor_material, true, false)
	_block(Vector3(4, 0.25, 4), Vector3(10, FLOOR_HEIGHT - 0.125, -22), floor_material, true, false)
	_wall(Vector3(0.25, 8, 20), Vector3(12, 4, -14))
	_wall(Vector3(4, 8, 0.25), Vector3(10, 4, -24))
	_wall(Vector3(4, 8, 0.25), Vector3(10, 4, -4))
	_block(Vector3(4, 0.2, 20), Vector3(10, 8, -14), wall_material, true, false)
	for i in range(30):
		var height := (i + 1) * FLOOR_HEIGHT / 30.0
		_block(Vector3(3.25, 0.14, 0.4), Vector3(10, height - 0.07, -8.2 - i * 0.4), floor_material, false)
		_part(self, Vector3(3.25, 0.025, 0.04), Vector3(10, height + 0.008, -8.01 - i * 0.4), Color("757b6c"))
	var body := StaticBody3D.new()
	game.add_child(body)
	var shape := CollisionShape3D.new()
	var ramp := ConvexPolygonShape3D.new()
	ramp.points = PackedVector3Array([Vector3(8.35, -0.15, -8), Vector3(11.65, -0.15, -8), Vector3(8.35, -0.15, -20), Vector3(11.65, -0.15, -20), Vector3(8.35, 0.04, -8), Vector3(11.65, 0.04, -8), Vector3(8.35, FLOOR_HEIGHT, -20), Vector3(11.65, FLOOR_HEIGHT, -20)])
	shape.shape = ramp
	body.add_child(shape)
	for x in [8.4, 11.6]:
		for i in range(11):
			var t := i / 10.0
			_part(self, Vector3(0.035, 1, 0.035), Vector3(x, t * FLOOR_HEIGHT + 0.5, -8 - t * 12), Color("626b60"))
		var rail := _part(self, Vector3(0.06, 0.06, sqrt(144 + FLOOR_HEIGHT * FLOOR_HEIGHT)), Vector3(x, FLOOR_HEIGHT * 0.5 + 1, -14), Color("7c8171"))
		rail.rotation.x = atan2(FLOOR_HEIGHT, 12)
	_fixture(Vector3(10, 7.6, -19), 1)
	_fixture(Vector3(10, 3.5, -6), 0)
	_sign("1. KAT\nARŞİV / AMELİYATHANE", Vector3(10, 6.3, -23.8), 0, Color("c4c8b0"), 30)

func _build_photo() -> void:
	var before := get_child_count()
	super._build_photo()
	var shift := Vector3(-2.1, 0, -0.48)
	for index in range(before, get_child_count()):
		var child = get_child(index)
		if child is Node3D:
			child.position += shift

func trigger_bed_event() -> void:
	if beds.is_empty() or moving_bed >= 0:
		return
	# Pick a nearby bed on the player's floor, not a distant random room.
	var nearest := INF
	for i in range(beds.size()):
		var distance := beds[i].position.distance_to(game.player.position)
		if distance < nearest:
			nearest = distance
			moving_bed = i
	bed_event_time = 0
	bed_event_count += 1
	if is_instance_valid(game.soundscape):
		game.soundscape.play_cue("metal")

func tick(delta: float, haunted: bool) -> void:
	dust.speed_scale = 1
	flicker_clock += delta
	blackout = maxf(0, blackout - delta)
	if haunted:
		next_blackout -= delta
		next_bed_event -= delta
		if next_blackout <= 0:
			trigger_blackout(0.65)
			next_blackout = rng.randf_range(32, 50)
		if next_bed_event <= 0:
			trigger_bed_event()
			next_bed_event = rng.randf_range(28, 48)
	for i in range(ceiling_lights.size()):
		var dim := 0.8 if i % 3 == 0 else 1.0
		ceiling_lights[i].light_energy = 0 if blackout > 0 else 0.42 * dim
		light_materials[i].emission_energy_multiplier = 0 if blackout > 0 else 0.6 * dim
	if moving_bed >= 0:
		bed_event_time += delta
		var pulse := sin(clampf(bed_event_time / 1.5, 0, 1) * PI)
		beds[moving_bed].position.z = bed_origins[moving_bed].z + pulse * 0.2
		if bed_event_time >= 1.5:
			beds[moving_bed].position = bed_origins[moving_bed]
			moving_bed = -1

func _blood(parent: Node3D, pos: Vector3, radius: Vector2) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points: Array[Vector3] = []
	for i in range(19):
		var angle := TAU * i / 18.0
		var variation := rng.randf_range(0.64, 1.0)
		points.append(Vector3(cos(angle) * radius.x * variation, 0, sin(angle) * radius.y * variation))
	points[18] = points[0]
	for i in range(18):
		for vertex in [Vector3.ZERO, points[i + 1], points[i]]:
			surface.set_normal(Vector3.UP)
			surface.add_vertex(vertex)
	var mesh := MeshInstance3D.new()
	mesh.mesh = surface.commit()
	var mat: StandardMaterial3D = game.material(Color("341814"))
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 0.65
	mesh.material_override = mat
	parent.add_child(mesh)
	mesh.position = pos

func _stain_bed(node: Node, holder: Node3D) -> void:
	if node is MeshInstance3D and "mattress" in node.name.to_lower():
		var bounds := _bounds(node, holder)
		_blood(holder, Vector3(bounds.get_center().x, bounds.end.y + 0.004, bounds.get_center().z), Vector2(0.22, 0.43))
	for child in node.get_children():
		_stain_bed(child, holder)
