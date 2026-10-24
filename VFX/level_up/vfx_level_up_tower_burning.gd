extends Node3D


@onready var player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	player.play("default")
	await player.animation_finished
	queue_free()
