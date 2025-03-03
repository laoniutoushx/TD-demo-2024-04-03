extends Node3D


@onready var snowl_flake: GPUParticles3D = $IceSpikeCore2/SnowFlake

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	snowl_flake.emitting = true
