extends Control

## ESC 일시정지 메뉴: Resume / Restart / Exit.

signal resumed
signal restarted

@onready var _resume_btn: Button = $Panel/VBox/ResumeButton
@onready var _restart_btn: Button = $Panel/VBox/RestartButton
@onready var _exit_btn: Button = $Panel/VBox/ExitButton

var _cam_settings: PanelContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_resume_btn.pressed.connect(_on_resume)
	_restart_btn.pressed.connect(_on_restart)
	_exit_btn.pressed.connect(_on_exit)


func set_cam_settings(panel: PanelContainer) -> void:
	_cam_settings = panel


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func open() -> void:
	visible = true
	get_tree().paused = true


func close() -> void:
	visible = false
	if _cam_settings:
		_cam_settings.visible = false
	get_tree().paused = false


func _on_resume() -> void:
	close()
	resumed.emit()


func _on_restart() -> void:
	get_tree().paused = false
	visible = false
	restarted.emit()
	get_tree().reload_current_scene()


func _on_exit() -> void:
	get_tree().quit()
