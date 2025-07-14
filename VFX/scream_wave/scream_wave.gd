extends Node3D


@onready var _pal: GPUParticles3D = $DoubleRingCore

func _ready() -> void:
    _pal.emitting = true


