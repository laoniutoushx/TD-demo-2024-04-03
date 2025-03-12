extends Node3D


@onready var ap: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
    ap.play(Constants.ANIM_RUN)