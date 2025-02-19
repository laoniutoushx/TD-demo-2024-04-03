extends Node3D

var source: Node
var target: Node
var fire_pos: Vector3
var lerp_pos: float = 0
# 弧度参数，控制弹道弧度大小
@export var arc_factor: float = 4.0


var speed: float
var damage: float

signal finished()

func _ready() -> void:
	# 初始位置定位
	# WARNING 某些特殊情况下，在 projectile 不初始化情况下，
	# 有可能其位置在 0，0，0 点位，导致bug，某些帧可能会获取到 projectile 在 0，0，0 位置的的 position，影响 borning 与 death 特性的创建位置
	self.look_at(target.global_position)
	global_position = fire_pos

	finished.connect(_on_projectile_finished, CONNECT_ONE_SHOT)
	target.logical_death.connect(_on_target_logical_death, CONNECT_ONE_SHOT)


func _physics_process(delta: float) -> void:
	if target != null and !target.is_logic_dead():

		# 计算目标点的位置
		var target_pos = Vector3(target.global_position.x, target._height / 2, target.global_position.z)

		# 计算弹道插值位置
		lerp_pos += delta * speed / fire_pos.distance_to(target_pos)
		lerp_pos = clamp(lerp_pos, 0.0, 1.0)

		# 计算弧线弹道的高度偏移
		var height_offset = arc_factor * lerp_pos * (1.0 - lerp_pos)

		# 计算直线弹道位置
		var straight_pos = fire_pos.lerp(target_pos, lerp_pos)

		# 应用弧线高度偏移
		global_position = Vector3(straight_pos.x, straight_pos.y + height_offset, straight_pos.z)


		# 使用 look_at 让物体 朝向目标
		self.look_at(target_pos)


		# 判断物体是否接近目标
		var remaining_distance = self.global_position.distance_to(target_pos)

		# 判断是否接近目标并且方向正确
		if remaining_distance < 1:
			set_process(false)
			finished.emit()


# 时间
func _on_projectile_finished():
	queue_free()



func _on_target_logical_death(unit: BaseUnit) -> void:
	queue_free()