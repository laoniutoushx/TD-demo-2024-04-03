extends Node3D




@onready var ap: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
    ap.play("burning")



func _on_animation_player_animation_finished(anim_name:StringName) -> void:
    queue_free()