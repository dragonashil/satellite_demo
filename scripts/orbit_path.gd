extends MeshInstance3D
class_name OrbitPath

## 궤도 경로를 3D 선으로 렌더링.
## 원형 및 타원 궤도 지원, 경사각 적용.

const SEGMENTS := 128

var _params: OrbitData.OrbitParams
var _material: StandardMaterial3D


func setup(params: OrbitData.OrbitParams) -> void:
	_params = params
	_build_mesh()


func _build_mesh() -> void:
	var im := ImmediateMesh.new()
	mesh = im

	_material = StandardMaterial3D.new()
	_material.albedo_color = _params.color
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.no_depth_test = true
	_material.render_priority = 1

	im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, _material)

	var incl := deg_to_rad(_params.inclination_deg)

	for i in range(SEGMENTS + 1):
		var t := float(i) / SEGMENTS * TAU
		var pos := _calc_point(t)
		# 경사각 적용 (X축 회전)
		pos = _apply_inclination(pos, incl)
		im.surface_add_vertex(pos)

	im.surface_end()


func _calc_point(angle: float) -> Vector3:
	if _params.eccentricity < 0.01:
		# 원형 궤도
		return Vector3(cos(angle) * _params.radius, 0.0, sin(angle) * _params.radius)
	else:
		# 타원 궤도 (초점이 원점)
		var a := _params.semi_major
		var e := _params.eccentricity
		var r := a * (1.0 - e * e) / (1.0 + e * cos(angle))
		return Vector3(r * cos(angle), 0.0, r * sin(angle))


func _apply_inclination(pos: Vector3, incl: float) -> Vector3:
	# X축 기준 회전 (경사각)
	var y := pos.y * cos(incl) - pos.z * sin(incl)
	var z := pos.y * sin(incl) + pos.z * cos(incl)
	return Vector3(pos.x, y, z)


func fade_in(duration: float = 0.5) -> void:
	if _material:
		_material.albedo_color.a = 0.0
		var tween := create_tween()
		tween.tween_property(_material, "albedo_color:a", _params.color.a, duration)


func fade_out(duration: float = 0.5) -> void:
	if _material:
		var tween := create_tween()
		tween.tween_property(_material, "albedo_color:a", 0.0, duration)
		tween.tween_callback(queue_free)
