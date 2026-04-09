extends Node

## 데모 전체 흐름 관리.
## Phase 1: 인트로 카메라 → 말풍선 표시
## Phase 2: 위성 패널 펼침 애니메이션
## Phase 3: 위성 Y축 회전 (위치 보정)
## Phase 4: 정지궤도(GEO) 운행 시연
## Phase 5: 궤도 유형 비교 (← → 전환)

enum State {
	INTRO, WAIT_PHASE2, PHASE2_PLAYING,
	WAIT_PHASE3, PHASE3_PLAYING,
	WAIT_PHASE4, PHASE4_PLAYING,
	WAIT_PHASE5, PHASE5_PLAYING,
	DONE
}

const PHASE3_ROTATION_DEG := -136.0
const PHASE3_DURATION := 5.0

@onready var _camera: Camera3D = $"../Camera3D"
@onready var _callout: Control = $"../UILayer/SatelliteCallout"
@onready var _prompt: Label = $"../UILayer/SpacePrompt"
@onready var _satellite: Node3D = $"../Satellite_parent"
@onready var _earth: Node3D = $"../Earth"
@onready var _cam_view_label: Label = $"../UILayer/CamViewLabel"
@onready var _orbit_nav_label: Label = $"../UILayer/OrbitNavLabel"
@onready var _cam_settings: PanelContainer = $"../UILayer/CamSettingsPanel"

var _state: State = State.INTRO
var _anim_player: AnimationPlayer
var _blink_tween: Tween
var _tracking_satellite := false
var _cam_offset := Vector3.ZERO

# Phase 4~5: 궤도 시스템
var _orbit_mover: OrbitMover
var _camera_rig: CameraRig
var _current_orbit_path: OrbitPath
var _current_orbit_index := 0
var _orbit_types: Array[OrbitData.OrbitType] = []
var _earth_rotating := false


func _ready() -> void:
	_prompt.modulate.a = 0.0
	_cam_view_label.modulate.a = 0.0
	_orbit_nav_label.modulate.a = 0.0
	_camera.intro_finished.connect(_on_intro_finished)
	_find_animation_player()

	# 궤도 시스템 초기화
	_orbit_mover = OrbitMover.new()
	add_child(_orbit_mover)

	_camera_rig = CameraRig.new()
	_camera_rig.setup(_camera, _satellite)
	_camera_rig.view_changed.connect(_on_view_changed)
	add_child(_camera_rig)

	_orbit_types = OrbitData.get_all_types()

	_cam_settings.setup(_camera_rig)
	_cam_settings.visible = false


func _find_animation_player() -> void:
	_anim_player = _find_node_by_type(_satellite, "AnimationPlayer")
	if _anim_player:
		print("[DemoController] AnimationPlayer found: ", _anim_player.get_path())
		print("[DemoController] Animations: ", _anim_player.get_animation_list())
	else:
		push_warning("[DemoController] AnimationPlayer not found in Satellite_parent tree")


func _find_node_by_type(node: Node, type_name: String) -> Node:
	for child in node.get_children():
		if child.get_class() == type_name:
			return child
		var found := _find_node_by_type(child, type_name)
		if found:
			return found
	return null


func _process(delta: float) -> void:
	if _tracking_satellite:
		_camera.global_position = _satellite.global_position + _cam_offset
		_camera.look_at(_satellite.global_position, Vector3.UP)

	if _camera_rig and _camera_rig._active:
		_camera_rig.update(delta)

	if _earth_rotating:
		# 월드 Y축 기준 회전 (위성 공전과 같은 축)
		_earth.global_rotate(Vector3.UP, delta * 0.1)


func _unhandled_input(event: InputEvent) -> void:
	# 카메라 뷰 전환 (Phase 4~5)
	if _camera_rig and _camera_rig.handle_input(event):
		get_viewport().set_input_as_handled()
		return

	if not (event is InputEventKey and event.pressed):
		return

	# ESC: 카메라 설정 패널 토글
	if event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_cam_settings.toggle()
		return

	# SPACE: 단계 진행
	if event.keycode == KEY_SPACE:
		match _state:
			State.WAIT_PHASE2:
				get_viewport().set_input_as_handled()
				_start_phase2()
			State.WAIT_PHASE3:
				get_viewport().set_input_as_handled()
				_start_phase3()
			State.WAIT_PHASE4:
				get_viewport().set_input_as_handled()
				_start_phase4()
			State.WAIT_PHASE5:
				get_viewport().set_input_as_handled()
				_start_phase5()

	# ← →: 궤도 전환 (Phase 5)
	if _state == State.PHASE5_PLAYING:
		if event.keycode == KEY_LEFT:
			get_viewport().set_input_as_handled()
			_switch_orbit(-1)
		elif event.keycode == KEY_RIGHT:
			get_viewport().set_input_as_handled()
			_switch_orbit(1)


# === Phase 전환 ===

func _on_intro_finished() -> void:
	_state = State.WAIT_PHASE2
	_show_space_prompt()


func _show_space_prompt() -> void:
	_prompt.modulate.a = 1.0
	_blink_tween = create_tween().set_loops()
	_blink_tween.tween_property(_prompt, "modulate:a", 0.3, 0.8)\
		.set_ease(Tween.EASE_IN_OUT)\
		.set_trans(Tween.TRANS_SINE)
	_blink_tween.tween_property(_prompt, "modulate:a", 1.0, 0.8)\
		.set_ease(Tween.EASE_IN_OUT)\
		.set_trans(Tween.TRANS_SINE)


func _hide_space_prompt() -> void:
	if _blink_tween:
		_blink_tween.kill()
	var tween := create_tween()
	tween.tween_property(_prompt, "modulate:a", 0.0, 0.3)


func _set_callout_text(text: String) -> void:
	var label: Label = _callout.get_node("Panel/Label")
	label.text = text


# === Phase 2: 패널 펼침 ===

func _start_phase2() -> void:
	_state = State.PHASE2_PLAYING
	_hide_space_prompt()
	_set_callout_text("2. Solar Panel Deployment")

	var sat_pos := _satellite.global_position
	var zoom_out_offset := Vector3(15, 8, 25)
	var cam_tween := create_tween()
	cam_tween.tween_property(_camera, "global_position", sat_pos + zoom_out_offset, 3.0)\
		.set_ease(Tween.EASE_IN_OUT)\
		.set_trans(Tween.TRANS_SINE)

	if _anim_player:
		var anim_name := "Take 001"
		if not _anim_player.has_animation(anim_name):
			var anims := _anim_player.get_animation_list()
			anim_name = anims[0] if anims.size() > 0 else ""
		if anim_name != "":
			_anim_player.play(anim_name)
			_anim_player.animation_finished.connect(_on_phase2_done, CONNECT_ONE_SHOT)
		else:
			_on_phase2_done("")
	else:
		_on_phase2_done("")


func _on_phase2_done(_anim_name: String) -> void:
	_state = State.WAIT_PHASE3
	_show_space_prompt()


# === Phase 3: 위치 보정 ===

func _start_phase3() -> void:
	_state = State.PHASE3_PLAYING
	_hide_space_prompt()
	_set_callout_text("3. Satellite Position Adjustment")

	_cam_offset = _camera.global_position - _satellite.global_position
	_tracking_satellite = true

	var target_rot_y := _satellite.rotation.y + deg_to_rad(PHASE3_ROTATION_DEG)
	var rot_tween := create_tween()
	rot_tween.tween_property(_satellite, "rotation:y", target_rot_y, PHASE3_DURATION)\
		.set_ease(Tween.EASE_IN_OUT)\
		.set_trans(Tween.TRANS_SINE)
	rot_tween.tween_callback(_on_phase3_done)


func _on_phase3_done() -> void:
	_tracking_satellite = false
	_state = State.WAIT_PHASE4
	_show_space_prompt()


# === Phase 4: GEO 궤도 운행 ===

func _start_phase4() -> void:
	_state = State.PHASE4_PLAYING
	_hide_space_prompt()

	var geo := OrbitData.get_orbit(OrbitData.OrbitType.GEO)
	_set_callout_text(geo.title + "\n" + geo.description)

	# 궤도선 생성
	_current_orbit_path = OrbitPath.new()
	get_parent().add_child(_current_orbit_path)
	_current_orbit_path.setup(geo)
	_current_orbit_path.fade_in(1.0)

	# 위성을 궤도 위치로 이동 (현재 위치에서 GEO 궤도로)
	# 현재 위성의 각도를 계산하여 궤도상 가장 가까운 점으로
	var sat_pos := _satellite.global_position
	var start_angle := atan2(sat_pos.z, sat_pos.x)
	_orbit_mover.setup(_satellite, geo, start_angle)

	# 카메라를 줌아웃하여 궤도 전체가 보이도록
	_camera_rig.activate(CameraRig.View.OVERVIEW)
	_cam_view_label.modulate.a = 1.0

	# 위성을 궤도 위치로 부드럽게 이동 후 공전 시작
	var target_pos := _orbit_mover._calc_position(start_angle)
	var move_tween := create_tween()
	move_tween.tween_property(_satellite, "global_position", target_pos, 2.0)\
		.set_ease(Tween.EASE_IN_OUT)\
		.set_trans(Tween.TRANS_SINE)
	move_tween.tween_callback(_on_phase4_orbit_ready)


func _on_phase4_orbit_ready() -> void:
	_orbit_mover.start()
	_earth_rotating = true

	# 10초 후 Phase 5 대기
	var timer := get_tree().create_timer(10.0)
	timer.timeout.connect(_on_phase4_done)


func _on_phase4_done() -> void:
	_state = State.WAIT_PHASE5
	_show_space_prompt()


# === Phase 5: 궤도 비교 ===

func _start_phase5() -> void:
	_state = State.PHASE5_PLAYING
	_hide_space_prompt()

	# 궤도 네비게이션 UI 표시
	_orbit_nav_label.modulate.a = 1.0
	_current_orbit_index = 0
	_update_orbit_nav_label()


func _switch_orbit(direction: int) -> void:
	_current_orbit_index = wrapi(_current_orbit_index + direction, 0, _orbit_types.size())

	var orbit_type := _orbit_types[_current_orbit_index]
	var params := OrbitData.get_orbit(orbit_type)

	# 기존 궤도선 페이드아웃
	if _current_orbit_path:
		_current_orbit_path.fade_out(0.5)

	# 새 궤도선 생성
	_current_orbit_path = OrbitPath.new()
	get_parent().add_child(_current_orbit_path)
	_current_orbit_path.setup(params)
	_current_orbit_path.fade_in(0.5)

	# 궤도 운동 전환
	_orbit_mover.stop()
	var start_angle := atan2(_satellite.global_position.z, _satellite.global_position.x)
	_orbit_mover.setup(_satellite, params, start_angle)

	# 위성을 새 궤도로 이동
	var target_pos := _orbit_mover._calc_position(start_angle)
	var move_tween := create_tween()
	move_tween.tween_property(_satellite, "global_position", target_pos, 1.0)\
		.set_ease(Tween.EASE_IN_OUT)\
		.set_trans(Tween.TRANS_SINE)
	move_tween.tween_callback(_orbit_mover.start)

	# UI 업데이트
	_set_callout_text(params.title + "\n" + params.description)
	_update_orbit_nav_label()


func _update_orbit_nav_label() -> void:
	var params := OrbitData.get_orbit(_orbit_types[_current_orbit_index])
	_orbit_nav_label.text = "<  " + params.name + "  >"


func _on_view_changed(view_name: String) -> void:
	_cam_view_label.text = view_name
