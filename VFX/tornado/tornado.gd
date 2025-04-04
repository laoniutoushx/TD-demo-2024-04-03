extends Node3D


@onready var _ap: AnimationPlayer = $AnimationPlayer

func _ready() -> void:

    hide()
    visible = false

    _ap.play("burning")

    # show()