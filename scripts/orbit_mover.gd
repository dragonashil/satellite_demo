extends Node
class_name OrbitMover

## 위성을 궤도 위에서 이동시키고 지구 방향을 바라보게 함.

var _target: Node3D
var _params: OrbitData.OrbitParams
var _angle := 0.0  # 현재 궤도 각도 (라디안)
var _active := false


func setup(target: Node3D, params: OrbitData.OrbitParams, start_angle: float = 0.0) -> void:
	_target = target
	_params = params
	_angle = start_angle


func start() -> void:
	_active = true


func stop() -> void:
	_active = false


func _process(delta: float) -> void:
	if not _active or not _target or not _params:
		return

	# 각속도 계산 (주기 기반)
	var angular_speed := TAU / _params.period_seconds

	# 타원 궤도: 케플러 제2법칙 근사 (근지점에서 빠르게)
	if _params.eccentricity > 0.01:
		var r := _get_radius_at_angle(_angle)
		var r_avg := _params.semi_major
		# 면적속도 보존: v ∝ 1/r
		angular_speed *= (r_avg * r_avg) / (r * r)

	_angle -= angular_speed * delta
	if _angle < 0.0:
		_angle += TAU

	# 위치 계산
	var pos := _calc_position(_angle)
	_target.global_position = pos

	# 지구(원점) 방향을 바라봄
	_target.look_at(Vector3.ZERO, Vector3.UP)


func _calc_position(angle: float) -> Vector3:
	var incl := deg_to_rad(_params.inclination_deg)
	var pos: Vector3

	if _params.eccentricity < 0.01:
		# 원형 궤도
		pos = Vector3(cos(angle) * _params.radius, 0.0, sin(angle) * _params.radius)
	else:
		# 타원 궤도 (초점 기준)
		var r := _get_radius_at_angle(angle)
		pos = Vector3(r * cos(angle), 0.0, r * sin(angle))

	# 경사각 적용 (X축 회전)
	var y := pos.y * cos(incl) - pos.z * sin(incl)
	var z := pos.y * sin(incl) + pos.z * cos(incl)
	return Vector3(pos.x, y, z)


func _get_radius_at_angle(angle: float) -> float:
	var a := _params.semi_major
	var e := _params.eccentricity
	return a * (1.0 - e * e) / (1.0 + e * cos(angle))
