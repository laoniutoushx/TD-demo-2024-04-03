class_name AudioManager extends Node3D


@export var bg_music: AudioStream
@onready var bg_player: AudioStreamPlayer3D = %BGPlayer

func _ready() -> void:
    pass


func play_bg_music(stream: AudioStream) -> void:
    if bg_player.playing:
        bg_player.stop()
    bg_player.stream = stream
    bg_player.volume_db = 0.0
    bg_player.play()