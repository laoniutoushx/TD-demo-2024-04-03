extends Node3D


@onready var star: GPUParticles3D = %Star

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	# scale = owner.transform.basis.get_scale()

	star.emitting = true
	await star.finished
	queue_free()


