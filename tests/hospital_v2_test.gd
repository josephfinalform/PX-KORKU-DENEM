extends SceneTree

var failures := 0
var game: Node3D

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, description: String) -> void:
	print("PASS: " if ok else "FAIL: ", description)
	if not ok:
		failures += 1

func drive(actor: CharacterBody3D, targets: Array[Vector3]) -> bool:
	for target in targets:
		var reached := false
		for frame in range(750):
			await physics_frame
			var difference := target - actor.position
			difference.y = 0
			if difference.length() < 0.12:
				reached = true
				break
			var motion := difference.normalized() * minf(3.0, difference.length() * 60)
			actor.velocity.x = motion.x
			actor.velocity.z = motion.z
			actor.velocity.y = 0 if actor.is_on_floor() else actor.velocity.y - 18.0 / 60.0
			actor.move_and_slide()
		if not reached:
			print("Stuck at ", actor.position, " aiming ", target)
			return false
	return true

func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.set_physics_process(false)
	await physics_frame
	await physics_frame
	check(game.hospital.room_count == 16 and game.hospital.model_count > 40, "Two floors, 16 rooms, imported medical assets")
	check(game.hospital.user_model_count > 25 and game.hospital.user_surface_count > 400, "Uploaded hospital props and textured architectural modules are used")
	var enemy = game.stalker
	check(not enemy.visible and enemy.collision_layer == 0, "Inactive creature has no invisible hitbox")
	for key in game.keys:
		var path: PackedVector3Array = enemy.navigation.path(Vector3(0, 0.05, 0), key.position + Vector3(0, -0.97, 1.3))
		check(path.size() > 2, "Navigation reaches " + str(key.get_meta("title")))
	game._start()
	game._tick_dialogue(0.12)
	check(game.subtitle.visible_characters > 0 and game.subtitle.visible_characters < game.subtitle.text.length(), "Dialogue reveals progressively")
	check(game.soundscape.dialogue_blips > 0, "Dialogue produces zvvzt syllables")
	game._pause()
	check(game.soundscape.dialogue.stream_paused and game.hospital.dust.speed_scale == 0, "Pause stops speech and particles")
	game._start()
	game.soundscape.toggle_mute(true)
	var blips: int = game.soundscape.dialogue_blips
	game.soundscape.talk_blip()
	check(game.soundscape.dialogue_blips == blips and game.soundscape.music.stream_paused, "Mute includes dialogue sound")
	game.soundscape.toggle_mute(true)
	game.wake_time = 4
	game.player.position = Vector3(-5, 0.05, -1.5)
	game.camera.look_at(game.hospital.photo.global_position)
	await physics_frame
	game._interact()
	check(game.haunting, "Photo starts the story")
	game.player.position = Vector3(0, 0.05, -1)
	game.haunting_time = 4
	game._physics_process(1.0 / 60)
	check(enemy.active and enemy.visible and enemy.collision_layer == 2, "First encounter displays creature and matching collision")
	game.camera.look_at(enemy.position + Vector3.UP * 1.65)
	await physics_frame
	enemy.tick(1.0 / 60)
	check(enemy.frozen, "Flashlight freezes visible enemy")
	game.flashlight.visible = false
	enemy.spawn_grace = 0
	var before: Vector3 = enemy.position
	for frame in range(45):
		await physics_frame
		enemy.tick(1.0 / 60)
	check(enemy.position.distance_to(before) > 0.5, "Enemy walks in darkness")
	var bed: Vector3 = game.hospital.beds[0].position
	game.hospital.next_bed_event = 100
	game.hospital.tick(5, true)
	check(game.hospital.beds[0].position == bed, "Furniture stays still between events")
	game.hospital.trigger_bed_event()
	var chosen: int = game.hospital.moving_bed
	var base: Vector3 = game.hospital.bed_origins[chosen]
	game.hospital.tick(0.6, true)
	check(game.hospital.beds[chosen].position != base, "One short furniture event moves a nearby bed")
	game.hospital.tick(1.0, true)
	check(game.hospital.moving_bed == -1 and game.hospital.beds[chosen].position == base, "Furniture event ends and becomes still")
	enemy.active = false
	enemy.collision_layer = 0
	game.player.position = Vector3(10, 0.05, -6)
	game.player.velocity = Vector3.ZERO
	await physics_frame
	var climbed: bool = await drive(game.player, [Vector3(10, 0, -8), Vector3(10, 4.2, -20), Vector3(10, 4.2, -22), Vector3(7.3, 4.2, -22)])
	check(climbed and game.player.position.y > 4.0, "Player physically climbs stairs and enters upper floor")
	var descended: bool = await drive(game.player, [Vector3(10, 4.2, -22), Vector3(10, 4.2, -20), Vector3(10, 0, -8), Vector3(10, 0, -6)])
	check(descended and game.player.position.y < 0.2, "Player descends stairs without teleporting")
	game.player.position = Vector3(0, 4.25, -21)
	enemy.activate()
	enemy.position = Vector3(10, 0.05, -6)
	enemy.spawn_grace = 0
	enemy.speed = 3
	for frame in range(1600):
		await physics_frame
		enemy.tick(1.0 / 60)
		if enemy.position.y > 4.0 and enemy.position.x < 7.9:
			break
	check(enemy.position.y > 4.0 and enemy.position.x < 7.9, "Enemy follows stairs onto upper floor")
	print("Enemy stair position ", enemy.position)
	enemy.active = false
	enemy.collision_layer = 0
	game.player.position = Vector3(0, 0.05, 1.9)
	game.camera.look_at(game.door.position)
	await physics_frame
	game._interact()
	check(not game.won, "Exit requires all keys")
	for index in range(3):
		var key = game.keys[index]
		game.player.position = Vector3(key.position.x, 0.05 if index == 0 else 4.25, key.position.z + 1.3)
		game.camera.look_at(key.position)
		await physics_frame
		if not game._looking_at(key):
			var query := PhysicsRayQueryParameters3D.create(game.camera.global_position, key.global_position)
			query.exclude = [game.player.get_rid()]
			var hit: Dictionary = game.get_world_3d().direct_space_state.intersect_ray(query)
			print("Key ray: ", hit)
			if not hit.is_empty():
				print("Blocking body at ", hit.collider.position)
		game._interact()
		game._interact()
		check(game.keys_collected == index + 1, "Collect key once: " + str(index + 1))
		await process_frame
	game.player.position = Vector3(0, 0.05, 1.9)
	game.camera.look_at(game.door.position)
	await physics_frame
	game._interact()
	check(game.won, "All three keys open the ground-floor exit")
	game._tick_exit(4)
	check(game.won and not game.playing and game.menu.visible, "Family ending completes")
	game.won = false
	game.playing = true
	game.player.position = Vector3(0, 0.05, 0)
	game.flashlight.visible = false
	enemy.activate()
	enemy.position = Vector3(0, 0.05, -0.75)
	enemy.spawn_grace = 0
	await physics_frame
	enemy.tick(1.0 / 60)
	check(game.lost and not game.playing, "Visible nearby enemy triggers capture")
	game._start()
	await process_frame
	await physics_frame
	game = current_scene
	game.set_physics_process(false)
	check(not game.lost and game.keys_collected == 0 and game.stalker.collision_layer == 0, "Retry resets story and disabled enemy hitbox")
	print("Failures: ", failures)
	game.free()
	await process_frame
	quit(1 if failures else 0)
