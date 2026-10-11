extends Node

var music: AudioStreamPlayer
var steps: AudioStreamPlayer
var effects: AudioStreamPlayer3D
var cue: AudioStreamPlayer
var dialogue: AudioStreamPlayer
var dialogue_blips := 0
var library := {}
var muted := false
var step_clock := 0.0
var event_clock := 6.0
var random := RandomNumberGenerator.new()

func _ready() -> void:
	random.seed = 712
	library["music"] = _synthesize("music", 12.0, true)
	library["step"] = _synthesize("step", 0.24)
	library["metal"] = _synthesize("metal", 1.8)
	library["air"] = _synthesize("air", 2.8)
	library["key"] = _synthesize("key", 0.5)
	library["talk"] = _synthesize("talk", 0.075)
	music = AudioStreamPlayer.new()
	add_child(music)
	music.stream = library["music"]
	music.volume_db = -23
	steps = AudioStreamPlayer.new()
	add_child(steps)
	steps.stream = library["step"]
	steps.volume_db = -27
	effects = AudioStreamPlayer3D.new()
	add_child(effects)
	effects.volume_db = -15
	effects.max_distance = 24
	effects.unit_size = 5
	cue = AudioStreamPlayer.new()
	add_child(cue)
	cue.volume_db = -19
	dialogue = AudioStreamPlayer.new()
	add_child(dialogue)
	dialogue.stream = library["talk"]
	dialogue.volume_db = -19

func _synthesize(kind: String, seconds: float, looping := false) -> AudioStreamWAV:
	const RATE := 16000
	var count := int(seconds * RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	var smoothed := 0.0
	for i in range(count):
		var t := float(i) / RATE
		var value := 0.0
		var noise := random.randf_range(-1, 1)
		smoothed = smoothed * 0.94 + noise * 0.06
		match kind:
			"music":
				# Frequencies are whole cycles over 12 seconds, avoiding loop clicks.
				value = sin(TAU * 55 * t) * 0.22 + sin(TAU * 82.5 * t) * 0.10
				value += sin(TAU * 110.25 * t) * (0.06 + 0.025 * sin(TAU * t / 12))
				value += sin(TAU * 164.8333333 * t) * 0.035
				value *= 0.85 + sin(TAU * t / 12) * 0.15
			"step":
				value = (smoothed * 1.8 + sin(TAU * 78 * t) * 0.4) * exp(-t * 23) * minf(t * 140, 1)
			"metal":
				value = (sin(TAU * 433 * t) * 0.24 + sin(TAU * 713 * t) * 0.14 + noise * 0.10) * exp(-t * 3) * minf(t * 120, 1)
			"air":
				value = (smoothed * 0.8 + sin(TAU * (140 * t + 14 * sin(t * 1.5))) * 0.055) * sin(PI * t / seconds)
			"key":
				value = (sin(TAU * 1260 * t) + sin(TAU * 1830 * t) * 0.4) * 0.16 * exp(-t * 12) * minf(t * 180, 1)
			"talk":
				value = (sin(TAU * (115 * t + 0.45 * sin(TAU * 38 * t))) * 0.38 + smoothed * 0.3) * sin(PI * t / seconds)
		var sample := int(clampf(value, -1, 1) * 32767)
		data.encode_s16(i * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = data
	if looping:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = count
	return stream

func set_running(running: bool) -> void:
	if running and not music.playing:
		music.play()
	for sound in [music, steps, effects, cue, dialogue]:
		sound.stream_paused = not running or muted

func toggle_mute(running: bool) -> void:
	muted = not muted
	set_running(running)

func play_cue(kind: String) -> void:
	if muted:
		return
	cue.stream = library[kind]
	cue.play()

func talk_blip() -> void:
	if muted or dialogue.stream_paused:
		return
	dialogue.pitch_scale = random.randf_range(0.8, 1.15)
	dialogue.play()
	dialogue_blips += 1

func tick(delta: float, moving: bool, running: bool, haunted: bool, listener: Vector3) -> void:
	step_clock -= delta
	if moving and step_clock <= 0:
		step_clock = 0.32 if running else 0.53
		if not muted:
			steps.pitch_scale = random.randf_range(0.9, 1.1)
			steps.play()
	if not haunted:
		return
	event_clock -= delta
	if event_clock <= 0:
		event_clock = random.randf_range(7, 12)
		if not muted:
			effects.position = listener + Vector3(random.randf_range(-3, 3), 0.8, random.randf_range(3, 7))
			effects.stream = library["metal" if random.randf() > 0.45 else "air"]
			effects.play()
