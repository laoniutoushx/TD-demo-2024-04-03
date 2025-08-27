extends Control


@onready var start_button = %Start
@onready var canvas_layer: CanvasLayer = $CanvasLayer


func _ready() -> void: 
	pass



func _on_start_pressed() -> void: 
	print("start clicked")
	# SignalBus.next_level.emit("choose_player")
	SignalBus.next_level.emit("level1")

	owner.queue_free()
	pass # Replace with function body.    
