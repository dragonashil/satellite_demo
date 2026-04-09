extends Control

## 위성에 흰 선으로 연결된 말풍선 UI.
## intro_finished 시그널을 받아 페이드인으로 나타남.

@onready var _camera: Camera3D = $"../../Camera3D"
@onready var _satellite: Node3D = $"../../Satellite_parent"
@onready var _panel: PanelContainer = $Panel

# 말풍선 화면 오프셋 (위성 화면좌표 기준 우상단)
const PANEL_OFFSET := Vector2(120, -100)
const LINE_COLOR := Color.WHITE
const LINE_WIDTH := 2.0

var _visible_amount := 0.0


func _ready() -> void:
	modulate.a = 0.0
	_camera.intro_finished.connect(_show)


func _process(_delta: float) -> void:
	if _visible_amount <= 0.0:
		return

	var sat_screen := _camera.unproject_position(_satellite.global_position)
	_panel.position = sat_screen + PANEL_OFFSET
	queue_redraw()


func _draw() -> void:
	if _visible_amount <= 0.0:
		return

	var sat_screen := _camera.unproject_position(_satellite.global_position)
	var panel_pos := _panel.position + Vector2(0, _panel.size.y * 0.5)
	draw_line(sat_screen, panel_pos, LINE_COLOR, LINE_WIDTH, true)


func _show() -> void:
	var tween := create_tween()
	tween.tween_property(self, "_visible_amount", 1.0, 0.3)
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.8)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_CUBIC)
