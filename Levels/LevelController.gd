extends Node

# 假设这是关卡的入口场景
@export var current_level:String
@export var current_enemy:String

@export var next_level:String



func _ready():
	# 当前场景是关卡的入口
	var level_started = false
	var level_ended = false
 
 
# 检查关卡是否完成的条件
func is_level_complete():
	# 这里添加你的逻辑来检查玩家是否通过了关卡
	# 比如检查玩家是否到达了某个特定的位置或者战斗胜利
	return false
 
# 加载下一个关卡 TODO 胜利条件判断，进入下一关卡
func load_next_level():
	var next_level = "res://Levels/Level1.tscn"
	current_level = next_level
	get_tree().change_scene(next_level)
 
# 初始化关卡
func initialize_level():
	# 这里进行关卡的初始化，比如重置游戏状态
	
	# 开始刷怪
	var enemySpawner:EnemySpawner = EnemySpawner.new()
	enemySpawner.generate_enemy(1, get_parent().find_child("Path3D"), current_enemy) 

 
# 检查是否启动了新的关卡
func is_new_level_started():
	# 这里添加你的逻辑来检查玩家是否进入了新的关卡
	# 比如检查玩家是否移动到新的场景边界
	return false


func _on_path_3d_ready() -> void:
	initialize_level()
