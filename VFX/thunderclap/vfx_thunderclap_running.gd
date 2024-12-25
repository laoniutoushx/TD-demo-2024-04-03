extends Node3D

@onready var gpu_particles = $GPUParticles3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	gpu_particles.emitting = true


