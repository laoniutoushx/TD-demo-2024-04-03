class_name Level extends Node3D


@onready var ui: Node = $UI
@onready var action_bar: ActionBar = $ActionBar
@onready var turret_manager: TurretManager = $TurretManager

@onready var wave_manager: WaveManager = $WaveManager



func _ready() -> void:
    pass