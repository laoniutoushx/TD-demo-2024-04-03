extends Node3D


@onready var building_key_indicator: Control = $BuildingKeyIndicator

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var viewport = get_viewport()
	var mouse_position = viewport.get_mouse_position()
	building_key_indicator.position = mouse_position

