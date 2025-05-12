class_name HUD extends Node3D


@onready var health_mana_bar3d: HealthManaBar = $HealthManaBar3D
@onready var level_bar3d: LevelBar = $LevelBar3D

var _unit:BaseUnit = null



func _ready() -> void:
	_unit = owner as BaseUnit



# HUD 初始化
func init_hud_bar(unit: BaseUnit) -> void:
	health_mana_bar3d.init_mana_over_bar(unit.mana)
	# listener unit mana changed
	unit.mana_changed.connect(health_mana_bar3d._on_mana_changed)