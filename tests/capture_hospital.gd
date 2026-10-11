extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.set_physics_process(false)
	game.wake_overlay.hide()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://hospital-menu.png")
	game.menu.hide()
	game.player.position = Vector3(0, 0.05, 1.0)
	game.camera.look_at(Vector3(0, 1.65, -12))
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://hospital-ward.png")
	game.player.position = Vector3(-3.1, 0.05, 1.9)
	game.camera.look_at(Vector3(-5.4, 0.9, -0.8))
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://hospital-photo.png")
	game.player.position = Vector3(0, 0.05, -2.8)
	game.stalker.activate()
	game.camera.look_at(game.stalker.position + Vector3.UP * 1.6)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://hospital-creature.png")
	game.player.position = Vector3(10, 0.05, -5.9)
	game.camera.look_at(Vector3(10, 4.3, -20))
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://hospital-stairs.png")
	quit()
