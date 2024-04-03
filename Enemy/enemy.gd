extends PathFollow3D

@export var speed := 2.5

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	self.progress += delta * speed
	pass
