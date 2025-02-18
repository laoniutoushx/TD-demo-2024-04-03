extends Node3D

var source: Node
var target: Node
var fire_pos: Vector3
var lerp_pos: float = 0

# 弧度相关参数
var arc_height: float = 2.0  # 弧度高度，可以通过参数控制
var start_pos: Vector3  # 记录起始位置
var target_pos: Vector3  # 记录目标位置

var speed: float
var damage: float

signal finished()

func _ready() -> void:
	# 初始位置定位
	# WARNING 某些特殊情况下，在 projectile 不初始化情况下，
	# 有可能其位置在 0，0，0 点位，导致bug，某些帧可能会获取到 projectile 在 0，0，0 位置的的 position，影响 borning 与 death 特性的创建位置
	self.look_at(target.global_position)
	global_position = fire_pos
	
	# 记录起始位置
	start_pos = global_position
	# 记录目标初始位置
	if target:
		target_pos = Vector3(target.global_position.x, target._height / 2, target.global_position.z)

	finished.connect(_on_projectile_finished, CONNECT_ONE_SHOT)
	target.logical_death.connect(_on_target_logical_death, CONNECT_ONE_SHOT)


func _physics_process(delta: float) -> void:
	if target != null and !target.is_logic_dead():
		# 更新目标点的位置
		target_pos = Vector3(target.global_position.x, target._height / 2, target.global_position.z)
		
		# 计算当前到目标的向量
		var to_target = target_pos - global_position
		var direction = to_target.normalized()
		var distance_to_target = to_target.length()
		
		# 计算从起点到终点的总距离
		var total_distance = start_pos.distance_to(target_pos)
		
		# 计算当前位置在起点到终点的插值比例 (0到1之间)
		var t = 1.0 - (distance_to_target / total_distance) if total_distance > 0 else 0
		
		# 计算当前应有的高度偏移 (使用抛物线曲线: 4 * h * t * (1-t))
		var height_offset = 4.0 * arc_height * t * (1.0 - t)
		
		# 计算基础移动
		var next_position = global_position + direction * delta * speed
		
		# 应用高度偏移 (只修改Y轴)
		var base_height = lerp(start_pos.y, target_pos.y, t)  # 线性插值基础高度
		next_position.y = base_height + height_offset  # 添加弧度偏移
		
		# 更新物体位置
		global_position = next_position
		
		# 计算下一个位置点用于朝向
		var look_t = min(t + 0.05, 1.0)  # 稍微往前看一点
		var look_height_offset = 4.0 * arc_height * look_t * (1.0 - look_t)
		var look_base_height = lerp(start_pos.y, target_pos.y, look_t)
		var look_target = lerp(start_pos, target_pos, look_t)
		look_target.y = look_base_height + look_height_offset
		
		# 调整朝向
		self.look_at(look_target)
		
		# 判断是否接近目标
		if distance_to_target < 1:
			set_process(false)
			finished.emit()


# 设置弧度高度
func set_arc_height(height: float) -> void:
	arc_height = height

# 时间
func _on_projectile_finished():
	queue_free()


func _on_target_logical_death(unit: BaseUnit) -> void:
	queue_free()