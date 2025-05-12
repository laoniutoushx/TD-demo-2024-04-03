extends Control
class_name LevelBar2D

@onready var level_label: Label = $LevelLabel


func update_level(value) -> void:
	level_label.text = "Lv " + str(value)
