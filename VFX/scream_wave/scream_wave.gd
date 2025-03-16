extends Node3D


@onready var _ap: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
    _ap.play("burning")


func _on_animation_player_animation_finished(anim_name:StringName) -> void:
    if anim_name == "burning":
        CommonUtil.delay_execution(3, (func(_self) -> void: 
            _self.queue_free()
            ).bind(self)
        )
