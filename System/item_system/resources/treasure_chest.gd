extends Item


func _ready() -> void:
    super._ready()

    
    $AnimationPlayer.play("burning")
