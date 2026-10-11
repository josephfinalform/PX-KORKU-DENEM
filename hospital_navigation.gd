extends RefCounted

var graph := AStar3D.new()
const HEIGHT := 4.2

func build(bounds: Array[AABB]) -> void:
	graph.clear()
	for level in range(2):
		for x in range(31):
			for z in range(55):
				var pos := Vector3(-7.5 + x * 0.5, level * HEIGHT + 0.05, -23.5 + z * 0.5)
				var blocked := false
				for obstacle in bounds:
					if obstacle.end.y <= pos.y + 0.05 or obstacle.position.y >= pos.y + 2.3:
						continue
					if pos.x > obstacle.position.x - 0.37 and pos.x < obstacle.end.x + 0.37 and pos.z > obstacle.position.z - 0.37 and pos.z < obstacle.end.z + 0.37:
						blocked = true
						break
				if not blocked:
					graph.add_point(_id(level, x, z), pos)
	for level in range(2):
		for x in range(31):
			for z in range(55):
				var id := _id(level, x, z)
				if not graph.has_point(id):
					continue
				if x < 30:
					_connect(id, _id(level, x + 1, z))
				if z < 54:
					_connect(id, _id(level, x, z + 1))
	var stair_points: Array[Vector3] = []
	for i in range(1, 6):
		stair_points.append(Vector3(7.5 + i * 0.5, 0.05, -6))
	stair_points.append(Vector3(10, 0.05, -8))
	for i in range(1, 31):
		stair_points.append(Vector3(10, HEIGHT * i / 30.0 + 0.05, -8 - i * 0.4))
	stair_points.append(Vector3(10, HEIGHT + 0.05, -22))
	for i in range(1, 6):
		stair_points.append(Vector3(10 - i * 0.5, HEIGHT + 0.05, -22))
	var previous := _id(0, 30, 35)
	for i in range(stair_points.size()):
		var id := 10000 + i
		graph.add_point(id, stair_points[i])
		_connect(previous, id)
		previous = id
	_connect(previous, _id(1, 30, 3))

func _id(level: int, x: int, z: int) -> int:
	return level * 2000 + x * 55 + z

func _connect(a: int, b: int) -> void:
	if graph.has_point(a) and graph.has_point(b):
		graph.connect_points(a, b)

func path(from: Vector3, to: Vector3) -> PackedVector3Array:
	return graph.get_point_path(graph.get_closest_point(from), graph.get_closest_point(to))
