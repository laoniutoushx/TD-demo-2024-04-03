class_name Laser extends MeshInstance3D


var source_unit: BaseUnit
var target_unit: BaseUnit



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:

	_refresh_line()

	mesh.material.uv1_offset.x = mesh.material.uv1_offset.x + delta


func set_line(start: Vector3, end: Vector3): 
	var direction = (end - start).normalized()
	var length = start.distance_to(end)
	
	# 计算中点作为mesh的位置
	var center = (end + start) / 2

	# 设置mesh位置
	global_position = center

	look_at(end)

	# 手动修正（丑陋的）
	rotate_y(PI * 1.5) # 旋转 270 度

	# 设置mesh的长度
	mesh.size = Vector2(length, mesh.size.y)



func set_line_by_unit(_s: BaseUnit, _t: BaseUnit):
	source_unit = _s
	target_unit = _t
	_refresh_line()	


# 每一帧刷新
func _refresh_line():
	if is_instance_valid(source_unit)  and is_instance_valid(target_unit):

		var source_mesh = CommonUtil.get_first_node_by_node_type(source_unit, Constants.MeshInstance3D_CLZ)
		var source_aabb = CommonUtil.get_scaled_aabb(source_mesh)
		var source_height = source_aabb.size.y

		var target_mesh = CommonUtil.get_first_node_by_node_type(target_unit, Constants.MeshInstance3D_CLZ)
		var target_aabb = CommonUtil.get_scaled_aabb(target_mesh)
		var target_height = target_aabb.size.y

		set_line(
			Vector3(source_unit.global_position.x, source_unit.global_position.y + source_height / 2, source_unit.global_position.z),
			Vector3(target_unit.global_position.x, target_unit.global_position.y + target_height / 2, target_unit.global_position.z)
		)

	