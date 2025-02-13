extends Node3D

var source: Node
var target: Node
var fire_pos: Vector3
var lerp_pos: float = 0


var speed: float
var damage: float

func _ready() -> void:
	# 初始位置定位
	# WARNING 某些特殊情况下，在 projectile 不初始化情况下，
	# 有可能其位置在 0，0，0 点位，导致bug，某些帧可能会获取到 projectile 在 0，0，0 位置的的 position，影响 borning 与 death 特性的创建位置
	self.look_at(target.global_position)
	global_position = fire_pos


func _physics_process(delta: float) -> void:
	if target != null and !target.is_logic_dead():
		if lerp_pos < 1:  
			# 获取 target 高度
			var target_pos = Vector3(target.global_position.x, target._height / 2.0, target.global_position.z)

			self.look_at(target_pos, Vector3.UP)
			global_position = fire_pos.lerp(target_pos, lerp_pos)
			lerp_pos += delta * speed
		else:
			queue_free()
	else:
		queue_free()
