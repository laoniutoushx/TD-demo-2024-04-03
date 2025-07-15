extends Node3D


@onready var _ap: AnimationPlayer = $AnimationPlayer



func _ready() -> void:
    if _ap:
        _ap.play("burning")




func _on_animation_player_animation_finished(anim_name:StringName) -> void:
    if anim_name == "burning":
        CommonUtil.delay_execution(1.8, 
        (func(_self) -> void: 
            if is_instance_valid(_self):
                _self.queue_free()
        ).bind(self)
        )