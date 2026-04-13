extends Node
class_name CameraRig

## 다중 카메라 뷰 전환 시스템.
## 숫자키 1~5로 뷰 전환, Phase 4~5에서 활성화.
## 1~4는 고정 뷰 (지구 중심 look_at), 5만 위성 추적.

signal view_changed(view_name: String)

enum View { CLOSEUP, SIDE, OVERVIEW, TOPDOWN, TRACKING }

const VIEW_NAMES: Dictionary = {
	View.CLOSEUP: "[1] Satellite Close-up",
	View.SIDE: "[2] Orbit Side View",
	View.OVERVIEW: "[3] Earth Overview",
	View.TOPDOWN: "[4] Top-down View",
	View.TRACKING: "[5] Tracking View",
}

# 고정 뷰: 지구 중심 기준 절대 좌표 (슬라이더로 조정 가능)
var view_positions: Dictionary = {
	View.SIDE: Vector3(1400, 100, 0),
	View.OVERVIEW: Vector3(0, 600, 1800),
	View.TOPDOWN: Vector3(0, 1600, 1),
}

# 고정 뷰의 look_at 대상 (모두 지구 중심)
const FIXED_LOOK_TARGET := Vector3.ZERO

# Closeup: 위성 뒤쪽(지구 반대편)에서 위성을 바라보는 추적 카메라
var closeup_distance := 80.0   # 위성으로부터의 거리
var closeup_height := 20.0     # 약간 위에서 내려다보는 높이 오프셋

# Tracking: 위성 기준 오프셋 (슬라이더로 조정 가능)
var tracking_offset := Vector3(0, 20, 60)

var _camera: Camera3D
var _satellite: Node3D
var _current_view: View = View.OVERVIEW
var _active := false
var _transition_tween: Tween

const TRANSITION_DURATION := 0.8


func setup(camera: Camera3D, satellite: Node3D) -> void:
	_camera = camera
	_satellite = satellite


func activate(initial_view: View = View.OVERVIEW) -> void:
	_active = true
	switch_to(initial_view)


func deactivate() -> void:
	_active = false


func get_current_view_name() -> String:
	return VIEW_NAMES.get(_current_view, "")


func handle_input(event: InputEvent) -> bool:
	if not _active:
		return false
	if not (event is InputEventKey and event.pressed):
		return false

	var view := -1
	match event.keycode:
		KEY_1: view = View.CLOSEUP
		KEY_2: view = View.SIDE
		KEY_3: view = View.OVERVIEW
		KEY_4: view = View.TOPDOWN
		KEY_5: view = View.TRACKING

	if view >= 0 and view != _current_view:
		switch_to(view as View)
		return true
	return false


func _calc_closeup_position() -> Vector3:
	# 위성에서 지구 반대 방향(바깥쪽)으로 카메라를 배치
	var sat_pos := _satellite.global_position
	var radial_dir := sat_pos.normalized()
	# 지구 반대편으로 distance만큼 떨어진 위치 + 약간 위쪽 오프셋
	return sat_pos + radial_dir * closeup_distance + Vector3.UP * closeup_height


func switch_to(view: View) -> void:
	_current_view = view

	if _transition_tween and _transition_tween.is_running():
		_transition_tween.kill()

	var target_pos: Vector3
	if view == View.TRACKING:
		target_pos = _satellite.global_position + tracking_offset
	elif view == View.CLOSEUP:
		target_pos = _calc_closeup_position()
	else:
		target_pos = view_positions[view]

	_transition_tween = _camera.create_tween()
	_transition_tween.tween_property(_camera, "global_position", target_pos, TRANSITION_DURATION)\
		.set_ease(Tween.EASE_IN_OUT)\
		.set_trans(Tween.TRANS_SINE)

	# 전환 시 즉시 look_at 설정
	var look_target := _satellite.global_position if (view == View.TRACKING or view == View.CLOSEUP) else FIXED_LOOK_TARGET
	_camera.look_at(look_target, Vector3.UP)

	view_changed.emit(VIEW_NAMES[view])


func update(_delta: float) -> void:
	if not _active:
		return

	if _current_view == View.CLOSEUP:
		# 클로즈업: 지구 반대편에서 위성을 따라가며 바라봄
		_camera.global_position = _calc_closeup_position()
		_camera.look_at(_satellite.global_position, Vector3.UP)
	elif _current_view == View.TRACKING:
		# 추적 카메라: 매 프레임 위성을 따라감
		_camera.global_position = _satellite.global_position + tracking_offset
		_camera.look_at(_satellite.global_position, Vector3.UP)
	else:
		# 고정 뷰: Tween 이동 중에도 지구 중심을 바라보도록 매 프레임 갱신
		_camera.look_at(FIXED_LOOK_TARGET, Vector3.UP)
