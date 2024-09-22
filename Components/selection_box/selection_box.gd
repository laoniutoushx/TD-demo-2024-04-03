extends Sprite3D

var dragging = false
var start_mouse_position : Vector2
var current_mouse_position : Vector2

@onready var selection_rect: ReferenceRect = $SubViewport/CanvasLayer/Control/SelectionRect


func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				dragging = true
				start_mouse_position = event.position

			else:
				dragging = false

				_select_objects_in_box()
	elif event is InputEventMouseMotion and dragging:
		current_mouse_position = event.position



func _get_mouse_ray(screen_pos: Vector2):
	var camera = get_viewport().get_camera_3d()
	var ray_origin = camera.project_ray_origin(screen_pos)
	var ray_direction = camera.project_ray_normal(screen_pos)
	return [ray_origin, ray_direction]

func _select_objects_in_box():
	var top_left = _get_mouse_ray(start_mouse_position)
	var bottom_right = _get_mouse_ray(current_mouse_position)
	# 计算框选区域内的物体
	print(top_left, bottom_right)
