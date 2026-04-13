extends Control

## 시작 화면: 프로그램 설명 + 깜빡이는 START 버튼.

signal start_pressed

@onready var _start_btn: Button = $VBox/StartButton
var _blink_tween: Tween


func _ready() -> void:
	_start_btn.pressed.connect(_on_start)
	_start_blink()
	# 시작 화면이 보이는 동안 게임 일시정지
	process_mode = Node.PROCESS_MODE_ALWAYS


func _start_blink() -> void:
	_blink_tween = create_tween().set_loops()
	_blink_tween.tween_property(_start_btn, "modulate:a", 0.3, 0.8)\
		.set_ease(Tween.EASE_IN_OUT)\
		.set_trans(Tween.TRANS_SINE)
	_blink_tween.tween_property(_start_btn, "modulate:a", 1.0, 0.8)\
		.set_ease(Tween.EASE_IN_OUT)\
		.set_trans(Tween.TRANS_SINE)


func _on_start() -> void:
	if _blink_tween:
		_blink_tween.kill()
	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 0.0, 0.5)
	fade.tween_callback(_done)


func _done() -> void:
	start_pressed.emit()
	queue_free()
