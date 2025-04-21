extends CenterContainer
class_name HealthManaBar2D

@onready var under_bar: TextureProgressBar = %HealthUnderBar
@onready var over_bar: TextureProgressBar = %HealthOverBar
@onready var mana_over_bar: TextureProgressBar = %ManaOverBar
@onready var defence_over_bar: TextureProgressBar = %DefenceOverBar

var _over_bar_value:float
var _under_bar_value:float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	over_bar.z_index = 1
	under_bar.z_index = 0


	# 默认不显示
	defence_over_bar.visible = false	



func update_health(value) -> void:
	var tween = create_tween()
	_over_bar_value -= value
	_under_bar_value -= value
	tween.tween_property(over_bar, "value", _over_bar_value, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(under_bar, "value", _under_bar_value, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func init_mana_over_bar(value) -> void:
	mana_over_bar.max_value = value
	mana_over_bar.value = value


func update_mana(value) -> void:
	var tween = create_tween()
	tween.tween_property(mana_over_bar, "value", value, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
