extends PanelContainer

## ESC로 토글되는 카메라 위치 조절 패널.
## 현재 활성 카메라 뷰의 X, Y, Z를 슬라이더로 실시간 조정.

@onready var _title_label: Label = $VBox/TitleLabel
@onready var _slider_x: HSlider = $VBox/HBoxX/SliderX
@onready var _slider_y: HSlider = $VBox/HBoxY/SliderY
@onready var _slider_z: HSlider = $VBox/HBoxZ/SliderZ
@onready var _value_x: Label = $VBox/HBoxX/ValueX
@onready var _value_y: Label = $VBox/HBoxY/ValueY
@onready var _value_z: Label = $VBox/HBoxZ/ValueZ

var _camera_rig: CameraRig
var _initialized := false


func setup(camera_rig: CameraRig) -> void:
	_camera_rig = camera_rig
	if is_node_ready():
		_init_sliders()
	else:
		ready.connect(_init_sliders, CONNECT_ONE_SHOT)


func _init_sliders() -> void:
	if _initialized:
		return
	_initialized = true

	for slider: HSlider in [_slider_x, _slider_y, _slider_z]:
		slider.min_value = -3000.0
		slider.max_value = 3000.0
		slider.step = 1.0

	_slider_x.value_changed.connect(_on_x_changed)
	_slider_y.value_changed.connect(_on_y_changed)
	_slider_z.value_changed.connect(_on_z_changed)


func toggle() -> void:
	visible = not visible
	if visible:
		_refresh()


func _refresh() -> void:
	if not _camera_rig:
		return

	var view := _camera_rig._current_view
	_title_label.text = _camera_rig.get_current_view_name()

	var pos: Vector3
	if view == CameraRig.View.CLOSEUP:
		pos = Vector3(_camera_rig.closeup_distance, _camera_rig.closeup_height, 0)
	elif view == CameraRig.View.TRACKING:
		pos = _camera_rig.tracking_offset
	else:
		pos = _camera_rig.view_positions[view]

	_slider_x.set_value_no_signal(pos.x)
	_slider_y.set_value_no_signal(pos.y)
	_slider_z.set_value_no_signal(pos.z)
	_update_value_labels(pos)


func _update_value_labels(pos: Vector3) -> void:
	_value_x.text = str(int(pos.x))
	_value_y.text = str(int(pos.y))
	_value_z.text = str(int(pos.z))


func _on_x_changed(val: float) -> void:
	_apply_position(Vector3(val, _slider_y.value, _slider_z.value))


func _on_y_changed(val: float) -> void:
	_apply_position(Vector3(_slider_x.value, val, _slider_z.value))


func _on_z_changed(val: float) -> void:
	_apply_position(Vector3(_slider_x.value, _slider_y.value, val))


func _apply_position(pos: Vector3) -> void:
	if not _camera_rig:
		return

	var view := _camera_rig._current_view

	if view == CameraRig.View.CLOSEUP:
		_camera_rig.closeup_distance = pos.x
		_camera_rig.closeup_height = pos.y
	elif view == CameraRig.View.TRACKING:
		_camera_rig.tracking_offset = pos
	else:
		_camera_rig.view_positions[view] = pos
		# 고정 뷰는 즉시 카메라 위치 갱신
		_camera_rig._camera.global_position = pos
		_camera_rig._camera.look_at(CameraRig.FIXED_LOOK_TARGET, Vector3.UP)

	_update_value_labels(pos)
	print("[CameraSettings] ", _camera_rig.get_current_view_name(), " = Vector3(",
		int(pos.x), ", ", int(pos.y), ", ", int(pos.z), ")")
