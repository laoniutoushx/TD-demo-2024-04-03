extends Node3D


@onready var ani_sprite_3d: AnimatedSprite3D = $AnimatedSprite3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ani_sprite_3d.play()


