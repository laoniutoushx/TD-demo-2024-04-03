extends CenterContainer
class_name HealthBar2D

@onready var under_bar: TextureProgressBar = $UnderBar
@onready var over_bar: TextureProgressBar = $OverBar

var _over_bar_value:float
var _under_bar_value:float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	over_bar.z_index = 1
	under_bar.z_index = 0



func update_health(value) -> void:
	var tween = create_tween()
	_over_bar_value -= value
	_under_bar_value -= value
	tween.tween_property(over_bar, "value", _over_bar_value, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(under_bar, "value", _under_bar_value, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
