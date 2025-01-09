extends Node3D


@onready var player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	print("vfx player ing")
	player.play("default")
	await player.animation_finished
	queue_free()
