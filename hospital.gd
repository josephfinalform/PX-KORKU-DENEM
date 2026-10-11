extends Node3D

var game: Node3D
var ceiling_lights: Array[OmniLight3D] = []
var beds: Array[Node3D] = []
var bed_origins: Array[Vector3] = []
var dust: CPUParticles3D
var photo: Node3D
var blackout := 0.0
var flicker_clock := 0.0
var next_blackout := 13.0
var rng := RandomNumberGenerator.new()

func build(owner_game: Node3D) -> void:
	game = owner_game
	rng.seed = 4219
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("030708")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("859eaa")
	env.ambient_light_energy = 0.095
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env_node.environment = env
	add_child(env_node)
	var wall_mat := _surface(false)
	var floor_mat := _surface(true)
	var floor_body = game.box(Vector3(10, 0.3, 28), Vector3(0, -0.15, -10), Color.WHITE)
	floor_body.get_child(0).material_override = floor_mat
	game.box(Vector3(10, 0.3, 28), Vector3(0, 3.65, -10), Color("242f30"))
	for x in [-5.0, 5.0]:
		var wall = game.box(Vector3(0.3, 3.6, 28), Vector3(x, 1.8, -10), Color.WHITE)
		wall.get_child(0).material_override = wall_mat
		game.box(Vector3(0.025, 1.05, 27.7), Vector3(x * 0.966, 0.53, -10), Color("243e3a"), false)
		game.box(Vector3(0.05, 0.08, 27.7), Vector3(x * 0.96, 1.08, -10), Color("63766b"), false)
	for z in [4.0, -24.0]:
		var wall = game.box(Vector3(10, 3.6, 0.3), Vector3(0, 1.8, z), Color.WHITE)
		wall.get_child(0).material_override = wall_mat
	for z in [-3.0, -10.0, -17.0]:
		for x in [-3.4, 3.4]:
			var wall = game.box(Vector3(3, 3.6, 0.4), Vector3(x, 1.8, z), Color.WHITE)
			wall.get_child(0).material_override = wall_mat
			game.box(Vector3(3, 1.05, 0.43), Vector3(x, 0.53, z), Color("2b4540"), false)
		game.box(Vector3(3.8, 0.55, 0.45), Vector3(0, 3.3, z), Color("2e4945"))
		for x in [-1.89, 1.89]:
			game.box(Vector3(0.09, 3, 0.48), Vector3(x, 1.5, z), Color("6f8076"), false)
	_sign("01 / GÖZLEM", Vector3(0, 3.27, -2.72), 0, Color("bed4c7"), 28)
	_sign("02 / TEDAVİ", Vector3(0, 3.27, -9.72), 0, Color("bed4c7"), 28)
	_sign("03 / TECRİT", Vector3(0, 3.27, -16.72), 0, Color("bed4c7"), 28)
	for z in [0.0, -6.0, -13.0, -20.0]:
		game.box(Vector3(1.4, 0.09, 0.3), Vector3(0, 3.46, z), Color("405554"), false)
		var tube = game.box(Vector3(1.2, 0.025, 0.1), Vector3(0, 3.39, z), Color("9ebdae"), false)
		var lamp_mat := StandardMaterial3D.new()
		lamp_mat.albedo_color = Color("a5c3af")
		lamp_mat.emission_enabled = true
		lamp_mat.emission = Color("677e73")
		tube.get_child(0).material_override = lamp_mat
		var light := OmniLight3D.new()
		add_child(light)
		light.position = Vector3(0, 2.95, z)
		light.light_color = Color("87b9a6")
		light.omni_range = 6.0
		light.light_energy = 0.38
		ceiling_lights.append(light)
	# Pipes, broken ceiling panels and scattered medical records.
	for x in [-4.25, -4.0]:
		game.box(Vector3(0.09, 0.09, 27), Vector3(x, 3.28, -10), Color("61594b"), false)
	for i in range(24):
		var paper = game.box(Vector3(rng.randf_range(0.15, 0.32), 0.009, 0.35), Vector3(rng.randf_range(-4.5, 4.5), 0.014, rng.randf_range(-23, 3)), Color("a79f83"), false)
		paper.rotation.y = rng.randf_range(-PI, PI)
	_make_bed(Vector3(-3.5, 0, 0.5), false)
	_make_bed(Vector3(3.65, 0, -6.8), true)
	_make_bed(Vector3(-3.65, 0, -13.8), true)
	_make_bed(Vector3(3.65, 0, -21), true)
	for z in [-5.6, -12.6, -20.2]:
		var side := -1.0 if z != -12.6 else 1.0
		game.box(Vector3(1.05, 0.85, 0.65), Vector3(side * 3.7, 0.425, z), Color("40554e"))
		for height in [0.28, 0.59]:
			game.box(Vector3(0.65, 0.025, 0.04), Vector3(side * 3.7, height, z + 0.34), Color("80938a"), false)
		game.add_key(Vector3(side * 3.7, 1.04, z), ["GÖZLEM", "TEDAVİ", "TECRİT"][game.keys.size()])
	_sign("KARANLIK\nSENİ İZLİYOR", Vector3(3.3, 2.15, -9.76), 0, Color("85251f"), 42)
	_sign("EVE DÖN", Vector3(-3.3, 2.1, -16.76), 0, Color("8d2b25"), 48)
	_sign("ONLAR SENİ BEKLİYOR", Vector3(-4.82, 2.1, -20.9), PI / 2, Color("812720"), 26)
	for i in range(15):
		var x := rng.randf_range(2.3, 4.3)
		game.box(Vector3(rng.randf_range(0.012, 0.04), rng.randf_range(0.1, 0.65), 0.012), Vector3(x, rng.randf_range(1.2, 1.8), -9.775), Color("461c19"), false)
	_build_photo()
	game.door = game.box(Vector3(2.6, 2.9, 0.18), Vector3(0, 1.45, -23.76), Color("304b48"))
	for x in [-0.65, 0.65]:
		game.box(Vector3(0.75, 0.65, 0.035), Vector3(x, 2.04, -23.64), Color("0a161c"), false)
		game.box(Vector3(0.06, 0.36, 0.08), Vector3(x * 0.3, 1.3, -23.6), Color("b3ae87"), false)
	_sign("ACİL ÇIKIŞ", Vector3(0, 3.12, -23.55), 0, Color("addcc2"), 44)
	_sign("3 SERVİS ANAHTARI GEREKLİ", Vector3(0, 0.83, -23.6), 0, Color("b6b995"), 19)
	game.red_light = OmniLight3D.new()
	add_child(game.red_light)
	game.red_light.position = Vector3(0, 2.8, -22.8)
	game.red_light.light_color = Color("c24735")
	game.red_light.light_energy = 0.38
	game.red_light.omni_range = 4.5
	_build_dust()

func _surface(is_floor: bool) -> StandardMaterial3D:
	var img := Image.create(128, 128, false, Image.FORMAT_RGB8)
	for y in range(128):
		for x in range(128):
			var grime := rng.randf_range(-0.05, 0.035) + sin(x * 0.15) * sin(y * 0.09) * 0.045
			var color := Color(0.39 + grime, 0.44 + grime, 0.40 + grime)
			if is_floor:
				color = Color(0.24 + grime, 0.29 + grime, 0.28 + grime)
				if x % 32 < 2 or y % 32 < 2:
					color *= 0.38
			img.set_pixel(x, y, color)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = ImageTexture.create_from_image(img)
	mat.uv1_triplanar = true
	mat.uv1_scale = Vector3.ONE * (0.65 if is_floor else 0.8)
	mat.roughness = 0.85
	return mat

func _part(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var geometry := BoxMesh.new()
	geometry.size = size
	mesh.mesh = geometry
	mesh.material_override = game.material(color)
	parent.add_child(mesh)
	mesh.position = pos
	return mesh

func _make_bed(pos: Vector3, haunted: bool) -> void:
	# Reserve the entire movement area for both player collision and enemy navigation.
	var blocker = game.box(Vector3(1.35, 1.0, 2.8), pos + Vector3(0, 0.5, 0), Color.WHITE)
	blocker.get_child(0).hide()
	var bed := Node3D.new()
	add_child(bed)
	bed.position = pos
	_part(bed, Vector3(1.05, 0.12, 2.1), Vector3(0, 0.7, 0), Color("5a6963"))
	_part(bed, Vector3(0.98, 0.18, 1.96), Vector3(0, 0.85, 0), Color("a29d7f"))
	_part(bed, Vector3(0.65, 0.12, 0.4), Vector3(0, 0.99, -0.65), Color("b7b196"))
	for x in [-0.47, 0.47]:
		for z in [-0.8, 0.8]:
			_part(bed, Vector3(0.07, 0.65, 0.07), Vector3(x, 0.39, z), Color("718078"))
			_part(bed, Vector3(0.16, 0.17, 0.2), Vector3(x, 0.12, z), Color("1b2423"))
		_part(bed, Vector3(0.035, 0.035, 1.8), Vector3(x, 1.15, 0), Color("7f8c7e"))
	for z in [-1.0, 1.0]:
		_part(bed, Vector3(1.05, 0.5, 0.055), Vector3(0, 0.95, z), Color("53665c"))
	for i in range(12):
		var stain := _part(bed, Vector3(rng.randf_range(0.07, 0.28), 0.008, rng.randf_range(0.08, 0.35)), Vector3(rng.randf_range(-0.3, 0.3), 0.946, rng.randf_range(-0.4, 0.6)), Color("491f1b"))
		stain.rotation.y = rng.randf_range(-0.8, 0.8)
	if haunted:
		beds.append(bed)
		bed_origins.append(pos)

func _sign(text_value: String, pos: Vector3, angle: float, color: Color, size: int) -> Label3D:
	var sign_label := Label3D.new()
	add_child(sign_label)
	sign_label.text = text_value
	sign_label.position = pos
	sign_label.rotation.y = angle
	sign_label.font_size = size
	sign_label.pixel_size = 0.008
	sign_label.modulate = color
	sign_label.no_depth_test = false
	sign_label.shaded = true
	return sign_label

func _build_photo() -> void:
	photo = Node3D.new()
	add_child(photo)
	photo.position = Vector3(-2.9, 1.85, -2.73)
	_part(photo, Vector3(1.26, 0.96, 0.07), Vector3.ZERO, Color("392e24"))
	_part(photo, Vector3(1.12, 0.82, 0.014), Vector3(0, 0, 0.046), Color("ab9674"))
	# A faded, stylized family portrait assembled from flat silhouettes.
	for index in range(3):
		var x := (index - 1) * 0.29
		var small := index == 1
		_part(photo, Vector3(0.22, 0.3 if small else 0.44, 0.012), Vector3(x, -0.18, 0.058), Color("51574b") if small else Color("414b4a"))
		var face := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.10 if small else 0.12
		sphere.height = sphere.radius * 2
		face.mesh = sphere
		face.scale.z = 0.08
		face.material_override = game.material(Color("cebb91"))
		photo.add_child(face)
		face.position = Vector3(x, 0.045 if small else 0.17, 0.068)
	_sign("AİLEN  /  1998", Vector3(-2.9, 1.18, -2.65), 0, Color("c8b58e"), 20)

func _build_dust() -> void:
	dust = CPUParticles3D.new()
	add_child(dust)
	dust.position = Vector3(0, 1.7, -10)
	dust.amount = 240
	dust.lifetime = 16
	dust.preprocess = 12
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	dust.emission_box_extents = Vector3(4.6, 1.5, 13)
	dust.direction = Vector3(0.3, 0.1, 0.1)
	dust.spread = 90
	dust.gravity = Vector3(0, -0.006, 0)
	dust.initial_velocity_min = 0.015
	dust.initial_velocity_max = 0.055
	dust.scale_amount_min = 0.4
	dust.scale_amount_max = 1.3
	var quad := SphereMesh.new()
	quad.radius = 0.012
	quad.height = 0.024
	quad.radial_segments = 4
	quad.rings = 2
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.65, 0.70, 0.63, 0.3)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	quad.material = mat
	dust.mesh = quad

func trigger_blackout(seconds: float) -> void:
	blackout = seconds

func tick(delta: float, haunted: bool) -> void:
	dust.speed_scale = 1.0
	flicker_clock += delta
	blackout = maxf(0, blackout - delta)
	if haunted:
		next_blackout -= delta
		if next_blackout <= 0:
			trigger_blackout(1.1)
			next_blackout = rng.randf_range(14, 23)
	for i in range(ceiling_lights.size()):
		var flicker := 0.55 if sin(flicker_clock * 19 + i * 4.1) > 0.94 else 1.0
		ceiling_lights[i].light_energy = 0.0 if blackout > 0 else 0.38 * flicker
	if haunted:
		for i in range(beds.size()):
			beds[i].position.z = bed_origins[i].z + sin(flicker_clock * 0.85 + i * 2) * 0.28
			beds[i].rotation.y = sin(flicker_clock * 1.4 + i) * 0.025
