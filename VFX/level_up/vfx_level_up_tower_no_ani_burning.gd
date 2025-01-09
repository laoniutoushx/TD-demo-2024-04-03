extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("child ready emitting ready")
	for child in get_children():
		child.emitting = true
		print("child ready emitting: %s" % [child.emitting])

	await CommonUtil.await_timer(2.0)
	queue_free()
