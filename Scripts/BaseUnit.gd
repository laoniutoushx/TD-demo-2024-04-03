# BaseUnit.gd
extends Node

# 基础单位类
class_name BaseUnit

# 单位分类
enum UnitCate {
	HUMAN,
	BUILDING,
	DECORATE_DESTORIED,
	DECORATE_FOREVER
}

# 单位移动类型
enum UnitMoveType {
	FLYING,
	WALKING,
	SWIMMING
}

# 单位的生命值
var health : int
@export var unit_cate: UnitCate
@export var unit_move_type: UnitMoveType

# 单位的最大生命值
@export var max_health : int


# 单位的死亡效果
func death_effect():
	pass # 子类将实现具体的死亡效果

# 虚函数，用于检查单位是否死亡
func is_dead() -> bool:
	return health <= 0

# 伤害单位
func take_damage(damage: float):
	health -= damage
	if is_dead():
		death_effect()

# 恢复单位生命值
func heal(amount: int):
	health = min(health + amount, max_health)


