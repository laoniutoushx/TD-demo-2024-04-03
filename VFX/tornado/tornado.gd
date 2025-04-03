extends Node3D


@onready var _ap: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
    _ap.play("burning")