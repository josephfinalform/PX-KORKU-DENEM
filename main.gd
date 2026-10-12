extends Node3D

var player: CharacterBody3D
var camera: Camera3D
var flashlight: SpotLight3D
var key_item: Node3D
var door: Node3D
var prompt: Label
var objective: Label
var menu: ColorRect
var menu_title: Label
var menu_text: Label
var play_button: Button
var red_light: OmniLight3D
var has_key := false
var playing := false
var won := false
var pitch := 0.0
var elapsed := 0.0

func _ready() -> void:
	_build_world()
	_build_player()
	_build_ui()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func material(color: Color) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 0.9
	return result

func box(size: Vector3, pos: Vector3, color: Color, solid := true) -> Node3D:
	var body: Node3D = StaticBody3D.new() if solid else Node3D.new()
	add_child(body)
	body.position = pos
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = material(color)
	body.add_child(mesh)
	if solid:
		var collision := CollisionShape3D.new()
		var bounds := BoxShape3D.new()
		bounds.size = size
		collision.shape = bounds
		body.add_child(collision)
	return body

func _build_world() -> void:
	var environment_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.005, 0.008, 0.012)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.22, 0.28, 0.35)
	env.ambient_light_energy = 0.16
	environment_node.environment = env
	add_child(environment_node)
	box(Vector3(10, 0.3, 28), Vector3(0, -0.15, -10), Color("292d30"))
	box(Vector3(10, 0.3, 28), Vector3(0, 3.65, -10), Color("202628"))
	for x in [-5.0, 5.0]:
		box(Vector3(0.3, 3.6, 28), Vector3(x, 1.8, -10), Color("414b48"))
	box(Vector3(10, 3.6, 0.3), Vector3(0, 1.8, 4), Color("414b48"))
	box(Vector3(10, 3.6, 0.3), Vector3(0, 1.8, -24), Color("414b48"))
	for z in [-3.0, -10.0, -17.0]:
		for x in [-3.4, 3.4]:
			box(Vector3(3.0, 3.6, 0.4), Vector3(x, 1.8, z), Color("36423e"))
		box(Vector3(4, 0.18, 0.6), Vector3(0, 3.2, z), Color("202929"))
	for z in range(3, -24, -2):
		box(Vector3(9.7, 0.012, 0.025), Vector3(0, 0.008, z), Color("12191b"), false)
	for z in [-1.0, -8.0, -15.0]:
		box(Vector3(1.5, 0.08, 0.25), Vector3(0, 3.45, z), Color("a7b7ac"), false)
		var light := OmniLight3D.new()
		add_child(light)
		light.position = Vector3(0, 2.95, z)
		light.light_color = Color("84a69a")
		light.light_energy = 0.35
		light.omni_range = 5.0
	box(Vector3(1.8, 0.14, 0.8), Vector3(3.8, 0.95, -20.5), Color("483629"))
	for x in [3.1, 4.5]:
		box(Vector3(0.12, 0.9, 0.65), Vector3(x, 0.45, -20.5), Color("31251f"))
	key_item = box(Vector3(0.35, 0.08, 0.1), Vector3(3.8, 1.12, -20.5), Color("edc666"), false)
	var key_glow := OmniLight3D.new()
	key_item.add_child(key_glow)
	key_glow.light_color = Color("ffcf70")
	key_glow.light_energy = 0.65
	key_glow.omni_range = 1.6
	door = box(Vector3(1.8, 2.8, 0.15), Vector3(0, 1.4, -23.78), Color("532c27"))
	box(Vector3(0.12, 0.12, 0.15), Vector3(0.65, 1.3, -23.6), Color("bfad7e"), false)
	var sign_label := Label3D.new()
	add_child(sign_label)
	sign_label.position = Vector3(0, 3.04, -23.6)
	sign_label.text = "ÇIKIŞ"
	sign_label.font_size = 60
	sign_label.pixel_size = 0.007
	sign_label.modulate = Color("b3d9c7")
	red_light = OmniLight3D.new()
	add_child(red_light)
	red_light.position = Vector3(0, 2.8, -22)
	red_light.light_color = Color("ff4939")
	red_light.light_energy = 0.6
	red_light.omni_range = 5
	for pos in [Vector3(-3.6, 0.5, -6), Vector3(3.6, 0.5, -13)]:
		box(Vector3(1.3, 1.0, 1.3), pos, Color("4b4032"))

func _build_player() -> void:
	player = CharacterBody3D.new()
	add_child(player)
	player.position = Vector3(0, 0.05, 1.5)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.75
	collision.shape = capsule
	collision.position.y = 0.875
	player.add_child(collision)
	camera = Camera3D.new()
	player.add_child(camera)
	camera.position.y = 1.62
	camera.current = true
	camera.fov = 75
	flashlight = SpotLight3D.new()
	camera.add_child(flashlight)
	flashlight.position = Vector3(0.16, -0.12, -0.15)
	flashlight.light_color = Color("ffe5b6")
	flashlight.light_energy = 5
	flashlight.spot_range = 19
	flashlight.spot_angle = 32
	flashlight.spot_attenuation = 0.7
	flashlight.shadow_enabled = true

func label_at(parent: Node, text_value: String, pos: Vector2, size: int) -> Label:
	var result := Label.new()
	parent.add_child(result)
	result.text = text_value
	result.position = pos
	result.add_theme_font_size_override("font_size", size)
	return result

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	objective = label_at(layer, "AMAÇ / Anahtarı bul ve çıkışa ulaş.", Vector2(28, 26), 22)
	label_at(layer, "WASD  Hareket   •   Fare  Bakış   •   Shift  Koş   •   F  Fener   •   E  Etkileşim   •   Esc  Duraklat", Vector2(28, 675), 16)
	var crosshair := label_at(layer, "+", Vector2(634, 343), 22)
	crosshair.modulate.a = 0.6
	prompt = label_at(layer, "", Vector2(420, 560), 24)
	menu = ColorRect.new()
	layer.add_child(menu)
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.color = Color(0.015, 0.024, 0.029, 0.96)
	menu_title = label_at(menu, "SON KORİDOR", Vector2(100, 175), 60)
	menu_text = label_at(menu, "Gece vardiyası bitti. Ama çıkış kilitli.\nKoridorun sonundaki anahtarı bul.\n\nKulaklarını açık tut. Gözlerini karanlıktan ayırma.", Vector2(105, 285), 24)
	play_button = Button.new()
	menu.add_child(play_button)
	play_button.position = Vector2(105, 460)
	play_button.size = Vector2(280, 60)
	play_button.text = "KORİDORA GİR"
	play_button.add_theme_font_size_override("font_size", 24)
	play_button.pressed.connect(_start)
	label_at(menu, "3D KORKU PROTOTİPİ  /  01", Vector2(105, 110), 18)

func _start() -> void:
	if won:
		get_tree().reload_current_scene()
		return
	playing = true
	menu.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and playing:
			playing = false
			menu_title.text = "DURAKLATILDI"
			play_button.text = "DEVAM ET"
			menu.show()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif playing and event.keycode == KEY_F:
			flashlight.visible = not flashlight.visible
		elif playing and event.keycode == KEY_E:
			_interact()
	if playing and event is InputEventMouseMotion:
		player.rotate_y(-event.relative.x * 0.0025)
		pitch = clampf(pitch - event.relative.y * 0.0025, -1.45, 1.45)
		camera.rotation.x = pitch

func _physics_process(delta: float) -> void:
	if not playing:
		return
	elapsed += delta
	var movement := Vector3(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), 0, float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
	movement = player.basis * movement.normalized()
	var speed := 4.6 if Input.is_physical_key_pressed(KEY_SHIFT) else 2.6
	player.velocity.x = movement.x * speed
	player.velocity.z = movement.z * speed
	if not player.is_on_floor():
		player.velocity.y -= 18 * delta
	else:
		player.velocity.y = 0
	player.move_and_slide()
	camera.position.y = 1.62 + sin(elapsed * speed * 3) * 0.025 * movement.length()
	red_light.light_energy = 0.55 + sin(elapsed * 7) * 0.13
	if is_instance_valid(key_item):
		key_item.rotation.y += delta
	prompt.text = ""
	if not has_key and _looking_at(key_item):
		prompt.text = "[E] Anahtarı al"
	elif _looking_at(door):
		prompt.text = "[E] Çıkış kapısını aç" if has_key else "Kapı kilitli. Anahtarı bul."

func _looking_at(target: Node3D) -> bool:
	if not is_instance_valid(target):
		return false
	var offset := target.global_position - camera.global_position
	return offset.length() < 2.5 and (-camera.global_basis.z).dot(offset.normalized()) > 0.72

func _interact() -> void:
	if not has_key and _looking_at(key_item):
		has_key = true
		key_item.queue_free()
		objective.text = "AMAÇ / Anahtar sende. Çıkış kapısını aç."
	elif has_key and _looking_at(door):
		won = true
		playing = false
		menu_title.text = "DIŞARIDASIN."
		menu_text.text = "Kilit açıldı. Soğuk hava yüzüne çarptı.\nBu gece koridordan çıkmayı başardın.\n\nİlk bölüm tamamlandı."
		play_button.text = "TEKRAR OYNA"
		menu.show()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
