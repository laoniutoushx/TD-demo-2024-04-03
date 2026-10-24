extends Panel
## Presentation only. SelectionBox owns the complete gesture lifecycle.

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clear()

func show_rect(rectangle: Rect2) -> void:
	var rectangle_in_canvas := rectangle.abs()
	position = rectangle_in_canvas.position
	size = rectangle_in_canvas.size
	show()

func clear() -> void:
	hide()
	size = Vector2.ZERO
