extends Node3D


@onready var build_located_vfx = $BuildLocated

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var tween = create_tween()

	tween.tween_property(build_located_vfx, "global_position", Vector3(1.0, 10.0, 1.0), 1.0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
