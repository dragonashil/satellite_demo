extends Node

## 임시 스크립트: Earth 모델의 실제 크기를 측정하여 콘솔에 출력.
## Main 노드에 붙여서 한 번 실행 후 제거.

func _ready() -> void:
	var earth := $"../Earth"
	if not earth:
		push_error("Earth node not found")
		return

	print("=== Earth Model Measurement ===")
	print("Earth transform: ", earth.transform)
	print("Earth global_transform: ", earth.global_transform)
	print("Earth position: ", earth.global_position)
	print("Earth rotation: ", earth.rotation_degrees)
	print("Earth scale: ", earth.scale)

	# MeshInstance3D의 AABB 확인
	var meshes := _find_meshes(earth)
	for m: MeshInstance3D in meshes:
		var aabb := m.get_aabb()
		var global_aabb := m.global_transform * aabb
		print("\nMesh: ", m.get_path())
		print("  Local AABB: ", aabb)
		print("  AABB size: ", aabb.size)
		print("  AABB center: ", aabb.get_center())
		print("  Estimated radius (max half-extent): ", aabb.size.length() / 2.0)

	# Satellite_parent 위치도 출력
	var sat := $"../Satellite_parent"
	if sat:
		print("\nSatellite_parent position: ", sat.global_position)
		var dist := sat.global_position.length()
		print("Distance from origin: ", dist)


func _find_meshes(node: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		result.append_array(_find_meshes(child))
	return result
