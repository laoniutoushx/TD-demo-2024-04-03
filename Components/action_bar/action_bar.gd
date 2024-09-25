extends Node

@onready var canvas_layer: CanvasLayer = $CanvasLayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.player_select_units.connect(_on_player_select_units)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func show_toggle() -> void:
	# toggle
	canvas_layer.visible = !canvas_layer.visible

func _on_player_select_units(units: Array) -> void:
	print(units.size())
	if units.size() == 0:
		canvas_layer.visible = false
	else:
		canvas_layer.visible = true
	
