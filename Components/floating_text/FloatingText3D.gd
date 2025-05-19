extends Node3D

@export_group("基本设置")
@export var float_speed: float = 2.0
@export var gravity: float = 0.5
@export var lifetime: float = 1.2
@export var horizontal_variance: float = 0.5  # 水平方向随机性
@export var horizontal_force: float = 1.0  # 水平方向力度

@export_group("普通攻击效果")
@export var initial_scale: float = 0.7  # 初始大小
@export var max_scale: float = 1.5  # 最大大小
@export var final_scale: float = 1.0  # 最终大小
@export var scale_up_time: float = 0.2  # 放大时间
@export var scale_down_time: float = 0.3  # 缩小时间
@export var wobble_strength: float = 0.2  # 摇晃强度
@export var wobble_speed: float = 5.0  # 摇晃速度

@export_group("暴击效果增强")
@export var crit_float_speed_multiplier: float = 1.5  # 暴击上升速度倍率
@export var crit_max_scale: float = 2.2  # 暴击最大缩放
@export var crit_wobble_strength: float = 0.4  # 暴击摇晃强度
@export var crit_scale_up_time: float = 0.25  # 暴击放大时间
@export var crit_horizontal_force: float = 1.5  # 暴击水平力度
@export var crit_flash_count: int = 2  # 闪烁次数



var velocity: Vector3 = Vector3.ZERO
var time_passed: float = 0.0
var random_direction: Vector3 = Vector3.ZERO
var is_critical: bool = false
@onready var label: Label3D = $Label3D

# 基本设置函数 - 接口保持简单，新增 damage_type 参数
func setup(text: String, color: Color = Color.WHITE, damage_type: int = DamageCtx.DamageType.NORMAL, direction: Vector2 = Vector2.ZERO):

	# 应用不同伤害类型的设置
	match damage_type:
		DamageCtx.DamageType.CRITICAL:
			apply_critical_effect()
			color = Color.DARK_RED
		DamageCtx.DamageType.HEAL:
			apply_heal_effect()
		DamageCtx.DamageType.MISS:
			apply_miss_effect()
		DamageCtx.DamageType.BUFF:
			apply_buff_effect()
		DamageCtx.DamageType.DEBUFF:
			apply_debuff_effect()
		_:  # 默认为普通伤害
			apply_normal_effect()

	label.text = text
	label.modulate = color

	
	# 设置随机方向
	random_direction = Vector3(
		randf_range(-1.0, 1.0),
		randf_range(0.5, 1.0),
		randf_range(-1.0, 1.0)
	).normalized() * horizontal_variance
	
	# 应用指定的水平方向力 (如果提供)
	var horizontal_dir = Vector3.ZERO
	var current_horizontal_force = crit_horizontal_force if is_critical else horizontal_force
	
	if direction != Vector2.ZERO:
		horizontal_dir = Vector3(direction.x, 0, direction.y).normalized() * current_horizontal_force
	else:
		# 如果没有指定方向，则使用更强的随机水平方向
		horizontal_dir = Vector3(
			randf_range(-1.0, 1.0),
			0,
			randf_range(-1.0, 1.0)
		).normalized() * current_horizontal_force
	
	# 初始速度向上加强化的水平力
	var current_float_speed = float_speed
	if is_critical:
		current_float_speed *= crit_float_speed_multiplier
		
	velocity = Vector3(
		random_direction.x + horizontal_dir.x,
		current_float_speed + random_direction.y,
		random_direction.z + horizontal_dir.z
	)
	
	# 设置初始缩放
	scale = Vector3.ONE * initial_scale
	
	# 创建基本动画效果
	create_animation_tween(damage_type)

# 普通伤害效果
func apply_normal_effect():
	is_critical = false
	# 使用默认参数

# 暴击伤害效果
func apply_critical_effect():
	is_critical = true
	# 其他参数在各个地方已经通过条件判断使用

# 治疗效果 (可根据需要自定义)
func apply_heal_effect():
	is_critical = false
	# 这里可以设置治疗效果的特殊参数

# 闪避效果
func apply_miss_effect():
	is_critical = false
	# 这里可以设置闪避效果的特殊参数

# 增益效果
func apply_buff_effect():
	is_critical = false
	# 这里可以设置增益效果的特殊参数

# 减益效果
func apply_debuff_effect():
	is_critical = false
	# 这里可以设置减益效果的特殊参数

# 创建动画效果
func create_animation_tween(damage_type: int):
	var tween = create_tween()
	
	var current_max_scale = crit_max_scale if is_critical else max_scale
	var current_scale_up_time = crit_scale_up_time if is_critical else scale_up_time
	
	# 第一阶段：放大
	tween.tween_property(self, "scale", Vector3.ONE * current_max_scale, current_scale_up_time).set_ease(Tween.EASE_OUT)
	
	# 如果是暴击，添加闪烁效果
	if damage_type == DamageCtx.DamageType.CRITICAL:
		for i in range(crit_flash_count):
			tween.tween_property(label, "modulate:a", 0.3, 0.05)
			tween.tween_property(label, "modulate:a", 1.0, 0.05)
	
	# 第二阶段：缩小到最终大小
	tween.tween_property(self, "scale", Vector3.ONE * final_scale, scale_down_time).set_ease(Tween.EASE_IN)
	
	# 淡出效果
	tween.tween_property(label, "modulate:a", 0.0, lifetime - current_scale_up_time - scale_down_time)
	tween.tween_callback(queue_free)

func _physics_process(delta):
	time_passed += delta
	
	# 应用重力
	velocity.y -= gravity * delta
	
	# 添加轻微的摇晃效果
	var current_wobble_strength = crit_wobble_strength if is_critical else wobble_strength
	var wobble = Vector3(
		sin(time_passed * wobble_speed) * current_wobble_strength,
		0,
		cos(time_passed * wobble_speed * 1.3) * current_wobble_strength
	) * delta
	
	# 移动文本
	global_translate(velocity * delta + wobble)
