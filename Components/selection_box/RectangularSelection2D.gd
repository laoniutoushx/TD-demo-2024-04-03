extends Panel


signal finished(rect)

var selecting_delay: float = 0.05

var _rect = null

func _ready():
	# input event handler register
	pass
	
func _input(event: InputEvent) -> void:	
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		_start()
		
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed):
		_finish()
	




func _physics_process(_delta):
	_update()


func _selecting():
	return _rect != null


func _start():
	var mouse_pos = get_global_mouse_position()
	_rect = Rect2(0, 0, 100, 100)
	_rect.position = mouse_pos
	
	#CommonUtil.delay_execution(selecting_delay, func():
		#if _is_selecting:
			#_rect = Rect2(0, 0, 0, 0)
			#_rect.position = mouse_pos
		#)


func _finish():
	if not _selecting():
		return
	_rect.end = get_global_mouse_position()
	finished.emit(_rect.abs())
	_rect = null
	hide()


func _update():
	if not _selecting():
		return
	_rect.end = get_global_mouse_position()
	var absolute_rect = _rect.abs()
	if absolute_rect.has_area():
		show()
	position = absolute_rect.position
	size = absolute_rect.size
