extends CharacterBody3D

signal caught_player

var player: CharacterBody3D
var flashlight: SpotLight3D
var active := false
var frozen := false
var speed := 1.9
var navigation: RefCounted
var route := PackedVector3Array()
var repath_time := 0.0
var body_visual: Node3D
var animation_time := 0.0
var limbs: Array[Node3D] = []
var spawn_grace := 0.0

func setup(world: Node3D, target: CharacterBody3D, lamp: SpotLight3D) -> void:
	player = target
	flashlight = lamp
	floor_snap_length = 0.4
	floor_max_angle = deg_to_rad(48)
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 2.25
	collider.shape = capsule
	collider.position.y = 1.125
	add_child(collider)
	body_visual = Node3D.new()
	add_child(body_visual)
	var skin := _material(Color("858879"))
	var gown := _material(Color("7d887b"))
	gown.albedo_texture = load("res://assets/textures/plaster/PaintedPlaster017_1K-JPG_Color.jpg")
	gown.uv1_scale = Vector3(2, 2, 2)
	var dark := _material(Color("151b18"))
	var torso := CylinderMesh.new()
	torso.top_radius = 0.30
	torso.bottom_radius = 0.39
	torso.height = 0.94
	torso.radial_segments = 20
	_mesh(torso, Vector3(0, 1.27, 0), gown, body_visual)
	_sphere(Vector3(0.42, 0.50, 0.37), Vector3(0, 1.96, -0.055), skin, body_visual)
	_sphere(Vector3(0.3, 0.20, 0.055), Vector3(0, 1.82, -0.23), dark, body_visual)
	for side in [-1.0, 1.0]:
		var arm := Node3D.new()
		body_visual.add_child(arm)
		arm.position = Vector3(side * 0.34, 1.65, 0)
		_capsule(0.095, 0.6, Vector3(side * 0.05, -0.26, 0), gown, arm)
		_capsule(0.065, 0.6, Vector3(side * 0.07, -0.79, -0.03), skin, arm)
		_sphere(Vector3(0.13, 0.23, 0.09), Vector3(side * 0.07, -1.1, -0.03), skin, arm)
		limbs.append(arm)
		var leg := Node3D.new()
		body_visual.add_child(leg)
		leg.position = Vector3(side * 0.17, 0.9, 0)
		_capsule(0.095, 0.75, Vector3(0, -0.4, 0), skin, leg)
		_sphere(Vector3(0.19, 0.12, 0.33), Vector3(0, -0.8, -0.075), dark, leg)
		limbs.append(leg)
		_sphere(Vector3(0.1, 0.075, 0.05), Vector3(side * 0.10, 2.01, -0.235), dark, body_visual)
		var eye := _material(Color("ddbc8a"))
		eye.emission_enabled = true
		eye.emission = Color("9a5635")
		eye.emission_energy_multiplier = 1.4
		_sphere(Vector3(0.032, 0.028, 0.016), Vector3(side * 0.1, 2.01, -0.265), eye, body_visual)
	navigation = preload("res://hospital_navigation.gd").new()
	navigation.build(world.hospital.obstacle_bounds)
	# Disabled actors have neither visible geometry nor an invisible hitbox.
	collision_layer = 0
	collision_mask = 1
	hide()

func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.92
	return mat

func _mesh(shape: Mesh, pos: Vector3, mat: Material, parent: Node3D) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.mesh = shape
	mesh.material_override = mat
	parent.add_child(mesh)
	mesh.position = pos
	return mesh

func _sphere(size: Vector3, pos: Vector3, mat: Material, parent: Node3D) -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1
	sphere.radial_segments = 20
	sphere.rings = 10
	_mesh(sphere, pos, mat, parent).scale = size

func _capsule(radius: float, height: float, pos: Vector3, mat: Material, parent: Node3D) -> void:
	var capsule := CapsuleMesh.new()
	capsule.radius = radius
	capsule.height = height
	_mesh(capsule, pos, mat, parent)

func activate() -> void:
	# First encounter ahead in the corridor, with a visible face and a short grace.
	var floor_y := 4.2 if player.position.y > 2.2 else 0.0
	var spawn_z := clampf(player.position.z - 6, -22, 2)
	if absf(spawn_z - player.position.z) < 3:
		spawn_z = clampf(player.position.z + 6, -22, 2)
	position = Vector3(0, floor_y + 0.05, spawn_z)
	collision_layer = 2
	route.clear()
	repath_time = 0
	spawn_grace = 2.5
	active = true
	show()
	_face_player()

func _face_player() -> void:
	var direction := player.global_position - global_position
	direction.y = 0
	if direction.length_squared() > 0.001:
		rotation.y = atan2(-direction.x, -direction.z)

func _clear_line(from: Vector3, to: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid(), player.get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func is_illuminated() -> bool:
	if not flashlight.visible:
		return false
	for height in [1.4, 2.0]:
		var target: Vector3 = global_position + Vector3.UP * height
		var offset := target - flashlight.global_position
		if offset.length() <= flashlight.spot_range and (-flashlight.global_basis.z).dot(offset.normalized()) >= cos(deg_to_rad(flashlight.spot_angle)):
			if _clear_line(flashlight.global_position, target):
				return true
	return false

func tick(delta: float) -> void:
	if not active:
		return
	_face_player()
	spawn_grace = maxf(0, spawn_grace - delta)
	frozen = is_illuminated()
	if frozen or spawn_grace > 0:
		velocity = Vector3.ZERO
		return
	repath_time -= delta
	if repath_time <= 0:
		repath_time = 0.45
		route = navigation.path(global_position, player.global_position)
		if route.size() > 1:
			route.remove_at(0)
	while not route.is_empty() and Vector2(route[0].x - position.x, route[0].z - position.z).length() < 0.14:
		route.remove_at(0)
	var motion := Vector3.ZERO
	if not route.is_empty():
		motion = route[0] - global_position
		motion.y = 0
		motion = motion.normalized() * minf(speed, motion.length() / maxf(delta, 0.001))
	velocity.x = motion.x
	velocity.z = motion.z
	velocity.y = 0 if is_on_floor() else velocity.y - delta * 18
	move_and_slide()
	animation_time += delta * speed
	for i in range(limbs.size()):
		limbs[i].rotation.x = sin(animation_time * 4 + (PI if i >= 2 else 0)) * (0.16 if i % 2 == 0 else 0.28)
	body_visual.rotation.z = sin(animation_time * 2) * 0.025
	# Capture only when the rendered actor is active and physically close on this floor.
	if visible and global_position.distance_to(player.global_position) < 0.82 and _clear_line(global_position + Vector3.UP, player.global_position + Vector3.UP):
		active = false
		caught_player.emit()
