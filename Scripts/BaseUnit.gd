# BaseUnit.gd
extends Node

# 基础单位类
class_name BaseUnit

# 单位的生命值
var health : int

# 单位的最大生命值
var max_health : int

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


