extends PathFollow3D

@export var speed := 5


@onready var base = get_tree().get_first_node_in_group("base")

var is_finish = false




# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	progress = progress + (delta * speed)
	if progress_ratio >= 1.0 && !is_finish:
		is_finish = true
		base.take_damage()
		set_process(false)
