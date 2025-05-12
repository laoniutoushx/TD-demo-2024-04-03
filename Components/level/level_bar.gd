class_name LevelBar extends Sprite3D


@onready var level_bar2d: LevelBar2D = $SubViewport/LevelBar

func _ready() -> void:
    SignalBus.unit_level_up.connect(_on_unit_level_up)

func _on_unit_level_up(id: int, unit: BaseUnit, level: int) -> void:
    if owner.get_instance_id() == id:
        level_bar2d.update_level(level)