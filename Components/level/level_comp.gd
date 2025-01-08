class_name LevelComp extends Node

## 引入此组件的单位，可以升级（）
# 两种等级配置方式，第一种，数组形式配置
# 第二种，公式形式配置（默认 第一种优先级 大于 公式）

# 信号
signal level_up_event(level_up_unit: BaseUnit, level: int)	# scene code


# 引用对象
var reference: Variant



@export var relife : int = 1    # 转生次数
@export var level : int = 1		# 当前等级

@export var exp_growth_factor: float = 1.0     # 经验成长率

# 经验值(L)=100×(L−1)^{1.5}
@export var exp: float = 0.0   # 当前经验值
@export var exp_range: float = 300   # 经验值获取范围
@export var max_level: float = 100   # 最大等级
@export var level_up_experience: float = 100   # 升级经验值（按等级递增）

#
@export var exp_provide: float = 25.0   # 可供其他单位获取经验


# 初始化
func _ready() -> void:
	# current component listend global unit logic death event
	SignalBus.unit_logic_death.connect(_on_unit_logic_death)

	# 组件加载后，自动初始化
	reference = owner
	print(owner.name + " level comp is ready")

	# 如果 reference is unit，创建 ui 经验条等信息



	pass # Replace with function body.


# 升级
func level_up() -> void:
	if level < max_level:
		print("level up %s %s" % [owner.title, level])
		level += 1
		# level up vfx
		if owner is BaseUnit:
			# create vfx for BaseUnit
			var vfx = SystemUtil.vfx_system.create_vfx("level_up_tower", VFXSystem.VFX_TYPE.BURNING)
			if vfx:
				var vfx_pivot: Node3D = Node3D.new()
				owner.add_child(vfx_pivot)
				vfx_pivot.add_child(vfx)
				CommonUtil.delay_execution(2, func(): vfx_pivot.queue_free() )

				# 播放特效
				var player: AnimationPlayer = CommonUtil.get_first_node_by_node_type(vfx, Constants.AnimationPlayer_CLZ)
				if player:
					player.play("default")



# 单位死亡事件监听
func _on_unit_logic_death(id: int, unit: BaseUnit) -> void:
	# 玩家组判断
	if unit.player_group == SOS.main.player_controller.player_group_idx:
		return

	## 检测当前单位距离
	var distance := (owner.global_position as Vector3).distance_to(unit.global_position)
	if distance < exp_range:
		obtain_exp(get_unit_exp(unit))

# 获取经验
func obtain_exp(_exp: float) -> void:
	if _exp > 0:
		exp += _exp
		while exp >= level_up_experience:
			level_up()
			exp = exp - level_up_experience

# 获取单位经验值
func get_unit_exp(unit: BaseUnit) -> float:
	# 检查是否可以获取经验
	var level_comp: LevelComp = SystemUtil.unit_system.get_component_from_unit(unit, BaseUnitResource.COMPONENT_SYSTEM.LEVEL)
	if level_comp:
		return level_comp.exp_provide
	return 0

		