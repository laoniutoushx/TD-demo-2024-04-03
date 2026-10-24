class_name Level extends Node3D


@onready var ui: Node = $UI
@onready var action_bar: ActionBar = $ActionBar
@onready var gdbot: Gdbot = %GDbotSkin

@onready var turret_manager: TurretManager = $TurretManager

@onready var wave_manager: WaveManager = $WaveManager



func _ready() -> void:
    var health_layer := CanvasLayer.new()
    health_layer.layer = 0
    add_child(health_layer)
    var health_bars := Control.new()
    health_bars.set_script(preload("res://Components/health_bar/screen_health_bars.gd"))
    health_layer.add_child(health_bars)
    SOS.main.apply_graphics(self)
    SignalBus.bgm_volume_changed.connect(self._on_bgm_volume_changed)
    $BGMPlayer.bus = "Music"
    $BGMPlayer.volume_db = 0.0


func _on_bgm_volume_changed(value: float) -> void:
    $BGMPlayer.volume_db = 0.0
