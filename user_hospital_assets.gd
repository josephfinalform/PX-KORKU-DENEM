extends RefCounted

const ROOT := "res://assets/user_hospital/ready/"
const REPLACEMENTS := {
	"hospital-bed": "bed", "23600": "wheel_chair", "23594": "IV_Bag_holder",
	"23593": "cabinet_3", "23629": "bench", "23627": "cabinet_1",
	"23642": "cabinet_2"
}
var scenes := {}

func make(name_value: String) -> Node3D:
	if not scenes.has(name_value):
		scenes[name_value] = load(ROOT + name_value + ".scn")
	var result: Node3D = scenes[name_value].instantiate()
	result.set_meta("user_asset", name_value)
	return result

func mesh_transform(node: Node3D, root: Node3D) -> Transform3D:
	var result := node.transform
	var parent := node.get_parent()
	while parent != null and parent != root:
		if parent is Node3D:
			result = parent.transform * result
		parent = parent.get_parent()
	return root.transform * result
