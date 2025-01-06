class_name LevelComp extends Node

## 引入此组件的单位，可以升级（）
# 两种等级配置方式，第一种，数组形式配置
# 第二种，公式形式配置（默认 第一种优先级 大于 公式）


# 引用对象
var reference: Variant



@export var relife : int = 1    # 转生次数
@export var level : int = 1		# 当前等级

@export var exp_growth_factor: float = 1.0     # 经验成长率

# 经验值(L)=100×(L−1)^{1.5}
@export var experience: float = 0.0   # 经验值
@export var max_level: float = 100   # 最大等级
@export var level_up_experience: float = 100   # 升级经验值（按等级递增）



func _ready() -> void:
	# current component listend global unit logic death event
	SignalBus.unit_logic_death.connect(_on_unit_logic_death)


	pass # Replace with function body.





func level_up() -> void:
	pass



func _on_unit_logic_death(id: int, unit: BaseUnit) -> void:
	pass