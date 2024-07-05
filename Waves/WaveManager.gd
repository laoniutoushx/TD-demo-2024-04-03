extends Node
class_name WaveManager

enum WaveState {
	WAITING,
	START,
	END
}

var current_state: WaveState
var wave_delay: float = 5.0	# 5s per wave interval

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_state = WaveState.WAITING
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
