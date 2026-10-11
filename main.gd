extends Node3D

var player: CharacterBody3D
var camera: Camera3D
var flashlight: SpotLight3D
var door: Node3D
var prompt: Label
var objective: Label
var menu: ColorRect
var menu_title: Label
var menu_text: Label
var play_button: Button
var red_light: OmniLight3D
var stalker: CharacterBody3D
var danger_label: Label
var danger_overlay: ColorRect
var wake_overlay: ColorRect
var subtitle: Label
var hospital: Node3D
var soundscape: Node
var keys: Array[Node3D] = []
var keys_collected := 0
var has_key := false
var lost := false
var playing := false
var won := false
var haunting := false
var pitch := 0.0
var elapsed := 0.0
var wake_time := 0.0
var photo_gaze := 0.0
var haunting_time := 0.0
var subtitle_time := 0.0
var exit_time := 0.0
var dialogue_progress := 0.0
var dialogue_sound_clock := 0.0
var upper_floor_seen := false
var encounter_seen := false

func _ready() -> void:
	hospital = preload("res://hospital_v2.gd").new()
	add_child(hospital)
	hospital.build(self)
	_build_player()
	_build_ui()
	soundscape = preload("res://soundscape.gd").new()
	add_child(soundscape)
	stalker = preload("res://stalker.gd").new()
	add_child(stalker)
	stalker.setup(self, player, flashlight)
	stalker.caught_player.connect(_caught)
	hospital.dust.speed_scale = 0
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

func add_key(pos: Vector3, title: String) -> void:
	var key := Node3D.new()
	add_child(key)
	key.position = pos
	key.set_meta("title", title)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.05
	torus.outer_radius = 0.085
	ring.mesh = torus
	ring.material_override = material(Color("c9a657"))
	key.add_child(ring)
	var shaft := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = Vector3(0.22, 0.035, 0.035)
	shaft.mesh = shape
	shaft.material_override = ring.material_override
	key.add_child(shaft)
	shaft.position.x = 0.16
	var tooth := MeshInstance3D.new()
	var tooth_shape := BoxMesh.new()
	tooth_shape.size = Vector3(0.04, 0.035, 0.08)
	tooth.mesh = tooth_shape
	tooth.material_override = ring.material_override
	key.add_child(tooth)
	tooth.position = Vector3(0.23, 0, 0.03)
	var glow := OmniLight3D.new()
	key.add_child(glow)
	glow.light_color = Color("edbd6a")
	glow.light_energy = 0.5
	glow.omni_range = 1.25
	keys.append(key)

func _build_player() -> void:
	player = CharacterBody3D.new()
	add_child(player)
	player.position = Vector3(-5, 0.05, 1.0)
	player.collision_mask = 3
	player.floor_snap_length = 0.4
	player.floor_max_angle = deg_to_rad(48)
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
	flashlight.light_energy = 2.4
	flashlight.spot_range = 17
	flashlight.spot_angle = 31
	flashlight.spot_attenuation = 0.7
	flashlight.shadow_enabled = true
	flashlight.shadow_bias = 0.15
	flashlight.shadow_normal_bias = 2.0

func label_at(parent: Node, value: String, pos: Vector2, size: int) -> Label:
	var result := Label.new()
	parent.add_child(result)
	result.text = value
	result.position = pos
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", Color("d4dfd6"))
	result.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	result.add_theme_constant_override("shadow_offset_x", 2)
	result.add_theme_constant_override("shadow_offset_y", 2)
	return result

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	danger_overlay = ColorRect.new()
	layer.add_child(danger_overlay)
	danger_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	danger_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	danger_overlay.color = Color(0.35, 0.005, 0.005, 0)
	wake_overlay = ColorRect.new()
	layer.add_child(wake_overlay)
	wake_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wake_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wake_overlay.color = Color.BLACK
	objective = label_at(layer, "GÖZLEM ODASI / Duvardaki resmi incele.", Vector2(30, 26), 22)
	danger_label = label_at(layer, "TERK EDİLMİŞ HASTANE  /  03:17", Vector2(30, 60), 16)
	label_at(layer, "WASD Yürü  •  Fare Bak  •  Shift Koş  •  F Fener  •  E Etkileşim  •  M Ses  •  Esc Duraklat", Vector2(30, 680), 16)
	var crosshair := label_at(layer, "·", Vector2(635, 344), 24)
	crosshair.modulate.a = 0.65
	prompt = label_at(layer, "", Vector2(0, 550), 22)
	prompt.size.x = 1280
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle = label_at(layer, "", Vector2(90, 605), 23)
	subtitle.size = Vector2(1100, 65)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu = ColorRect.new()
	layer.add_child(menu)
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.color = Color(0.012, 0.027, 0.029, 0.96)
	label_at(menu, "BÖLÜM 01  /  TERK EDİLMİŞ HASTANE", Vector2(100, 100), 18)
	menu_title = label_at(menu, "SON ZİYARET", Vector2(95, 155), 68)
	menu_text = label_at(menu, "Gece 03:17. Kapatılmış bir hastanenin gözlem odası.\nSon hatırladığın şey, eve dönerken çalan telefonun.\nŞimdi cebin boş. Duvardaki fotoğrafsa sana ait.\n\nHemşire istasyonu, üst kattaki arşiv ve ameliyathane.\nÜç anahtar. Tek çıkış. Seni bekleyen bir aile.", Vector2(100, 265), 24)
	play_button = Button.new()
	menu.add_child(play_button)
	play_button.position = Vector2(100, 495)
	play_button.size = Vector2(300, 60)
	play_button.text = "GÖZLERİNİ AÇ"
	play_button.add_theme_font_size_override("font_size", 23)
	play_button.pressed.connect(_start)
	label_at(menu, "Loş ışık • Toz parçacıkları • Düşük sesli atmosfer\nM: tüm sesleri aç / kapat", Vector2(100, 588), 17)

func _start() -> void:
	if won or lost:
		get_tree().reload_current_scene()
		return
	playing = true
	menu.hide()
	soundscape.set_running(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if wake_time == 0:
		_say("BEN — Başım... Ne oldu bana? En son yoldaydım. Burada kimse yok mu?", 7)

func _pause() -> void:
	playing = false
	soundscape.set_running(false)
	hospital.dust.speed_scale = 0
	menu_title.text = "DURAKLATILDI"
	menu_text.text = "Ailene ulaşmak için üç servis anahtarını bul.\nFenerini yaratığın üzerine tutunca durur.\n\nToplanan anahtar: %d / 3" % keys_collected
	play_button.text = "DEVAM ET"
	menu.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_M:
			soundscape.toggle_mute(playing)
			_say("Ses kapalı." if soundscape.muted else "Ses açık.", 2)
		elif event.keycode == KEY_ESCAPE and playing and not won:
			_pause()
		elif playing and event.keycode == KEY_F:
			flashlight.visible = not flashlight.visible
		elif playing and event.keycode == KEY_E and wake_time >= 3:
			_interact()
	if playing and not won and wake_time >= 3 and event is InputEventMouseMotion:
		player.rotate_y(-event.relative.x * 0.0025)
		pitch = clampf(pitch - event.relative.y * 0.0025, -1.45, 1.45)
		camera.rotation.x = pitch

func _physics_process(delta: float) -> void:
	if not playing:
		return
	if won:
		_tick_exit(delta)
		return
	elapsed += delta
	wake_time += delta
	wake_overlay.color.a = clampf(1.0 - wake_time / 3.0, 0, 1)
	hospital.tick(delta, haunting)
	_tick_dialogue(delta)
	if wake_time < 3:
		camera.position.y = lerpf(0.95, 1.62, wake_time / 3.0)
		return
	var movement := Vector3(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), 0, float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
	movement = player.basis * movement.normalized()
	var running := Input.is_physical_key_pressed(KEY_SHIFT)
	var speed := 4.6 if running else 2.6
	player.velocity.x = movement.x * speed
	player.velocity.z = movement.z * speed
	player.velocity.y = 0.0 if player.is_on_floor() else player.velocity.y - 18 * delta
	player.move_and_slide()
	if player.position.y > 3.9 and not upper_floor_seen:
		upper_floor_seen = true
		_say("BEN — Arşiv bu katta. Annemin aramasını açsaydım... Tamam. Önce çıkışı bul.", 7)
	camera.position.y = 1.62 + sin(elapsed * speed * 3) * 0.02 * movement.length()
	soundscape.tick(delta, Vector2(player.velocity.x, player.velocity.z).length() > 0.2 and player.is_on_floor(), running, haunting, camera.global_position)
	for key in keys:
		if is_instance_valid(key):
			key.rotation.y += delta * 0.65
	if not haunting:
		if _looking_at(hospital.photo, 3.3, 0.92):
			photo_gaze += delta
			if photo_gaze > 0.8:
				_begin_haunting()
		else:
			photo_gaze = 0
	_update_prompt()
	if haunting:
		haunting_time += delta
		if not encounter_seen and haunting_time > 3 and absf(player.position.x) < 1.7:
			stalker.activate()
			encounter_seen = true
			_say("BEN — Hey! Siz... Orada durun. Işığı görünce durdu. Feneri indirme.", 7)
		stalker.speed = 1.6 + keys_collected * 0.3
		stalker.tick(delta)
		if stalker.active:
			var distance := player.position.distance_to(stalker.position)
			danger_overlay.color.a = clampf((6.0 - distance) / 6.0, 0, 1) * 0.2
			if stalker.frozen:
				danger_label.text = "IŞIK ONU DURDURUYOR"
			elif distance < 4:
				danger_label.text = "ÇOK YAKIN... FENERİNİ ONA TUT."
			else:
				danger_label.text = "KARANLIK SENİ İZLİYOR"

func _update_prompt() -> void:
	prompt.text = ""
	if not haunting and _looking_at(hospital.photo, 3.3):
		prompt.text = "[E] Aile resmine bak"
	for key in keys:
		if is_instance_valid(key) and _looking_at(key):
			prompt.text = "[E] %s anahtarını al" % key.get_meta("title")
	if _looking_at(door):
		prompt.text = "[E] Acil çıkışı aç" if has_key else "Kapı kilitli. Servis anahtarları: %d / 3" % keys_collected

func _begin_haunting() -> void:
	if haunting:
		return
	haunting = true
	hospital.trigger_blackout(2.2)
	soundscape.play_cue("metal")
	_say("BEN — Bu fotoğraf... Bizim evdeydi. Annem, babam ve ben. Kim getirdi bunu buraya?", 8)
	_update_objective()

func _update_objective() -> void:
	objective.text = "ANAHTARLAR %d / 3  ·  Hemşire: Zemin  ·  Arşiv ve Ameliyathane: 1. kat" % keys_collected
	if has_key:
		objective.text = "AİLENE DÖN  /  Acil çıkıştaki üç kilidi aç."

func _say(value: String, seconds: float) -> void:
	subtitle.text = value
	subtitle.visible_characters = 0
	dialogue_progress = 0
	dialogue_sound_clock = 0
	subtitle_time = maxf(seconds, value.length() / 32.0 + 3.0)

func _tick_dialogue(delta: float) -> void:
	if subtitle.text.is_empty():
		return
	subtitle_time -= delta
	var previous := subtitle.visible_characters
	dialogue_progress += delta * 32
	subtitle.visible_characters = mini(int(dialogue_progress), subtitle.text.length())
	dialogue_sound_clock -= delta
	if subtitle.visible_characters > previous and dialogue_sound_clock <= 0:
		var character := subtitle.text.substr(maxi(0, subtitle.visible_characters - 1), 1)
		if character not in [" ", ".", ",", "—", "!", "?"]:
			soundscape.talk_blip()
			dialogue_sound_clock = 0.085
	if subtitle_time <= 0:
		subtitle.text = ""

func _caught() -> void:
	lost = true
	playing = false
	prompt.text = ""
	soundscape.set_running(false)
	hospital.dust.speed_scale = 0
	menu_title.text = "SENİ YAKALADI."
	menu_text.text = "Ailen hâlâ seni bekliyor.\nFenerini ona tut, arandaki mesafeyi koru.\n\nÜç anahtarı bul ve hastaneden çık."
	play_button.text = "YENİDEN UYAN"
	menu.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _looking_at(target: Node3D, reach := 2.5, alignment := 0.72) -> bool:
	if not is_instance_valid(target) or target.is_queued_for_deletion():
		return false
	var offset := target.global_position - camera.global_position
	if offset.length() >= reach or (-camera.global_basis.z).dot(offset.normalized()) <= alignment:
		return false
	var query := PhysicsRayQueryParameters3D.create(camera.global_position, target.global_position)
	query.exclude = [player.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.collider == target

func _interact() -> void:
	if won or lost:
		return
	if not haunting and _looking_at(hospital.photo, 3.3):
		_begin_haunting()
		return
	for key in keys:
		if is_instance_valid(key) and _looking_at(key):
			# A skipped portrait cannot leave the main encounter disabled.
			if not haunting:
				_begin_haunting()
			keys_collected += 1
			has_key = keys_collected == 3
			var lines := ["BEN — Bir anahtar. Üstünde servis numarası var. Diğerleri için üst kata bakmalıyım.", "BEN — İkinciyi buldum. Az kaldı. Koridordaki ses... yine aynı ayak sesleri.", "BEN — Üçü de burada. Artık aşağı inip giriş kapısını açabilirim. Lütfen hâlâ açık olsun."]
			_say(lines[keys_collected - 1], 7)
			key.queue_free()
			soundscape.play_cue("key")
			hospital.trigger_blackout(0.7)
			_update_objective()
			return
	if _looking_at(door):
		if has_key:
			won = true
			stalker.active = false
			prompt.text = ""
			danger_label.text = "KİLİTLER AÇILDI"
			soundscape.play_cue("key")
			_say("Dayanın... Eve geliyorum.", 4)
		else:
			_say("Üç ayrı kilit. Eksik anahtar: %d." % (3 - keys_collected), 3)

func _tick_exit(delta: float) -> void:
	_tick_dialogue(delta)
	exit_time += delta
	door.position.x = lerpf(0, 2.9, clampf(exit_time / 2, 0, 1))
	# The door opens into dawn; fade before the outside boundary is visible.
	wake_overlay.color = Color(0.75, 0.81, 0.76, clampf((exit_time - 1) / 2, 0, 1))
	if exit_time >= 3.2:
		playing = false
		soundscape.set_running(false)
		hospital.dust.speed_scale = 0
		menu_title.text = "EVE DÖNÜŞ"
		menu_text.text = "Üç kilit açıldı. Hastanenin kapısından çıktın.\nSabahın ilk ışığında telefonun yeniden çalıyor.\n\nEkranda tek bir kelime: AİLEM.\n“Geliyorum,” diyorsun. Bu kez gerçekten."
		play_button.text = "TEKRAR OYNA"
		menu.show()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
