extends Camera3D

## Intro camera work for satellite demo.
## Attach this script to Camera3D node in main.tscn.
##
## Phase 1 (0~8s): 멀리서 위성으로 접근 → 클로즈업 후 인트로 종료

# 씬 좌표 기준
# Earth: (0, 0, 0)
# Satellite_parent: (0, 0, 498.46)

signal intro_finished

@export var skip_intro: bool = false

# 위성 노드를 실시간 참조 (형제 노드)
@onready var _satellite: Node3D = $"../Satellite_parent"

# Phase 1: 원거리 → 위성 클로즈업 (위성 기준 오프셋)
const OFFSET_START := Vector3(40, 30, 150)    # 위성에서 뒤쪽 멀리
const OFFSET_CLOSEUP := Vector3(8, 3, 10)     # 위성 바로 앞

const PHASE1_DURATION := 8.0

var _look_target_a := Vector3.ZERO
var _look_target_b := Vector3.ZERO
var _look_weight := 0.0
var _is_interpolating_look := false
var _active_tween: Tween


func _ready() -> void:
	if skip_intro:
		_jump_to_final()
		return
	start_intro()


func _process(_delta: float) -> void:
	if _is_interpolating_look:
		var sat_pos := _satellite.global_position
		var target := _look_target_a.lerp(_look_target_b, _look_weight)
		# _look_target에 오프셋이 적용된 경우 위성 위치 기준으로 계산
		look_at(sat_pos + target, Vector3.UP)


func _unhandled_input(event: InputEvent) -> void:
	if not _is_interpolating_look:
		return
	if event is InputEventKey and event.pressed:
		_skip_to_end()
	elif event is InputEventMouseButton and event.pressed:
		_skip_to_end()


func start_intro() -> void:
	var sat_pos := _satellite.global_position
	global_position = sat_pos + OFFSET_START
	look_at(sat_pos, Vector3.UP)
	_phase1_closeup()


func _phase1_closeup() -> void:
	# 위성을 향해 접근 → 클로즈업 (시선은 계속 위성 중앙)
	var sat_pos := _satellite.global_position
	_is_interpolating_look = true
	_look_target_a = Vector3.ZERO  # 오프셋 없음 = 위성 정중앙
	_look_target_b = Vector3.ZERO
	_look_weight = 0.0

	_active_tween = create_tween()
	_active_tween.tween_property(self, "global_position", sat_pos + OFFSET_CLOSEUP, PHASE1_DURATION)\
		.set_ease(Tween.EASE_IN_OUT)\
		.set_trans(Tween.TRANS_SINE)
	_active_tween.tween_callback(_on_intro_complete)


func _on_intro_complete() -> void:
	_is_interpolating_look = false
	intro_finished.emit()


func _skip_to_end() -> void:
	if _active_tween and _active_tween.is_running():
		_active_tween.kill()
	_jump_to_final()
	_on_intro_complete()


func _jump_to_final() -> void:
	_is_interpolating_look = false
	var sat_pos := _satellite.global_position
	global_position = sat_pos + OFFSET_CLOSEUP
	look_at(sat_pos, Vector3.UP)
