extends Control


var viewport: Viewport


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for control in find_children("*", "Control", true, false): control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()
	viewport = get_viewport()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	self.position = viewport.get_mouse_position()


func show_toggle() -> void:
	if is_visible():
		hide()
		set_process(false)
	else:
		show()
		set_process(true)
