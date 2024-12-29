class_name Laser extends MeshInstance3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	mesh.material.uv1_offset.x = mesh.material.uv1_offset.x + delta


func set_line(start: Vector3, end: Vector3): 
	var direction = (end - start).normalized()
	var length = start.distance_to(end)
	
	# 计算中点作为mesh的位置
	var center = (end + start) / 2

	# 设置mesh位置
	global_position = center

	look_at(end)

	rotate_y(PI / 2)

    # # 计算旋转 



	# 设置mesh的长度
	mesh.size = Vector2(length, mesh.size.y)
