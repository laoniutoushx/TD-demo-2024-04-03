extends Node3D

@export var cam:Camera3D 
# 专门配置相机移动范围（防止超出地图边界）
@export var map_bounds: Rect2

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	mouse_camera_move(delta)
 


func mouse_camera_move(delta):
	var m_pos = get_viewport().get_mouse_position()
	var v_size = get_viewport().get_visible_rect().size

	var move_vec = Vector3(0, 0, 0)
	var camera_pos = cam.position

	# 向左、向上移动屏幕
	if m_pos.x < Constants.MOVE_MARGIN and camera_pos.x > map_bounds.position.x:
		move_vec.x -= 1
	if m_pos.y < Constants.MOVE_MARGIN and camera_pos.z > map_bounds.position.y:
		move_vec.z -= 1

	# 向右、向下移动屏幕
	if m_pos.x > v_size.x - Constants.MOVE_MARGIN and camera_pos.x < map_bounds.end.x:
		# TODO 处理边界值
		move_vec.x += 1
	if m_pos.y > v_size.y - Constants.MOVE_MARGIN and camera_pos.z < map_bounds.end.y:
		# TODO 处理边界值
		move_vec.z += 1

	# TODO 确保相机在地图边界内
	cam.global_translate(move_vec * delta * Constants.MOVE_SPEED)
	
	
func _click_to_choose():
	
	pass
