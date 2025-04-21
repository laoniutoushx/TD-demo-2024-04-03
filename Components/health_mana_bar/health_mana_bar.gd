class_name HealthManaBar extends Sprite3D


@onready var health_mana_bar2d: HealthManaBar2D = $SubViewport/HealthManaBar
var unit: BaseUnit


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass



func init_mana_over_bar(value) -> void:
	health_mana_bar2d.init_mana_over_bar(value)


func _on_mana_changed(unit: BaseUnit, left_mana: float) -> void:
	health_mana_bar2d.update_mana(left_mana)
