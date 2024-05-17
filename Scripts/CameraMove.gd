extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _process(delta):
	var mouse_position = get_viewport().get_mouse_position()
	print(m_pos)
	var mouse_position = get_global_mouse_position() # 获取全局鼠标位置
	var window_size = OS.get_window_size() # 获取窗口大小
	var window_edge_distance = {
		"left": mouse_position.x,
		"top": mouse_position.y,
		"right": window_size.x - mouse_position.x,
		"bottom": window_size.y - mouse_position.y
	}
	
	# 打印鼠标距离窗口边缘的距离
	for edge in window_edge_distance:
		print("Mouse to " + edge + " edge distance: " + str(window_edge_distance[edge]))	
