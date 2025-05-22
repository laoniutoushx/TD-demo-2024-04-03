class_name Laser
extends MeshInstance3D

var source_unit: BaseUnit
var target_unit: BaseUnit

var laser_mesh: Mesh = preload("res://VFX/laser/laser_mesh.tres")

func _ready() -> void:
	mesh = laser_mesh.duplicate()

func _physics_process(delta: float) -> void:
	_refresh_line()

	if mesh.material:
		mesh.material.uv1_offset.x += delta / 4.0


func set_line(start: Vector3, end: Vector3): 
	var direction = end - start
	var length = direction.length()

	if length < 0.01:
		return  # 避免长度为 0 的情况

	# 中点设置为激光位置
	var center = (start + end) * 0.5
	global_position = center

	# 安全朝向目标点
	CommonUtil.safe_look_at(self, center, end)
	# CommonUtil.safe_look_at(self, global_position, end)

	# 手动修正方向（根据你的模型实际情况）
	rotate_y(PI * 1.5)

	# 设置 mesh 长度（调整 x 轴缩放）
	mesh.size = Vector2(length, mesh.size.y)


func set_line_by_unit(_s: BaseUnit, _t: BaseUnit) -> void:
	source_unit = _s
	target_unit = _t
	_refresh_line()


func _refresh_line() -> void:
	if is_instance_valid(source_unit) and is_instance_valid(target_unit):
		var source_mesh = CommonUtil.get_first_node_by_node_type(source_unit, Constants.MeshInstance3D_CLZ)
		var source_aabb = CommonUtil.get_scaled_aabb(source_mesh)
		var source_height = max(0.01, source_aabb.size.y)

		var target_mesh = CommonUtil.get_first_node_by_node_type(target_unit, Constants.MeshInstance3D_CLZ)
		var target_aabb = CommonUtil.get_scaled_aabb(target_mesh)
		var target_height = max(0.01, target_aabb.size.y)

		var start = source_unit.global_position + Vector3(0, source_height * 0.5, 0)
		var end = target_unit.global_position + Vector3(0, target_height * 0.5, 0)

		set_line(start, end)
