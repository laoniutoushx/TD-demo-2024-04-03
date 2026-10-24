extends Control


@onready var start_button = %Start
@onready var canvas_layer: CanvasLayer = $CanvasLayer


func _ready() -> void: 
	pass



func _on_start_pressed() -> void:
	start_button.disabled = true
	SOS.main.level_controller.next_level("level1")

func _on_setting_pressed() -> void:
	SOS.main.level_controller.open_settings()

func _show() -> void:
	canvas_layer.visible = true

func _hide() -> void:
	canvas_layer.visible = false

func _on_exit_pressed() -> void:
	SOS.main.request_quit()
