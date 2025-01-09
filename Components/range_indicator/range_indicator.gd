extends Node3D


@onready var circle = $FadedCircle3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	if owner is BaseUnit:
		if owner is Turret:
			# 初始化，默认设置为单位攻击范围
			set_radius(owner.attack_range)


func set_radius(rad: float):
	circle.radius = rad