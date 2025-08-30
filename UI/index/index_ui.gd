extends Control


@onready var start_button = %Start
@onready var canvas_layer: CanvasLayer = $CanvasLayer


func _ready() -> void: 
	pass



func _on_start_pressed() -> void: 
	print("start clicked")
	# SignalBus.next_level.emit("choose_player")
	SignalBus.next_level.emit("level1")

	SOS.main.level_controller.level_map["index"].queue_free()
	pass # Replace with function body.    

func _show() -> void:
	canvas_layer.visible = true

func _hide() -> void:
	canvas_layer.visible = false