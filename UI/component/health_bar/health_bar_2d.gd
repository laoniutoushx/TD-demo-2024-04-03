extends CenterContainer
class_name HealthBar2D

@onready var under_bar: TextureProgressBar = $UnderBar
@onready var over_bar: TextureProgressBar = $OverBar


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	over_bar.z_index = 1
	under_bar.z_index = 0
	print(self.size)
	pass # Replace with function body.


func update_health(value) -> void:
	var tween = create_tween()
	tween.tween_property(over_bar, "value", over_bar.value - value, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(under_bar, "value", under_bar.value - value, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
