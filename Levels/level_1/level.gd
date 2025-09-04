class_name Level extends Node3D


@onready var ui: Node = $UI
@onready var action_bar: ActionBar = $ActionBar
@onready var gdbot: Gdbot = %GDbotSkin

@onready var turret_manager: TurretManager = $TurretManager

@onready var wave_manager: WaveManager = $WaveManager



func _ready() -> void:
    SignalBus.bgm_volume_changed.connect(self._on_bgm_volume_changed)
    $BGMPlayer.volume_db = SOS.main.config["bg_volume"]


func _on_bgm_volume_changed(value: float) -> void:
    $BGMPlayer.volume_db = value