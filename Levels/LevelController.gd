extends Node
 
# 假设这是关卡的入口场景
var current_level = "res://Levels/Level1.tscn"
 
func _ready():
	# 当前场景是关卡的入口
	var level_started = false
	var level_ended = false
 
	# 检查是否到达了下一个关卡
	if is_level_complete():
		level_ended = true
		# 加载下一个关卡
		load_next_level()
 
	# 检查是否启动了新的关卡
	if !is_new_level_started():
		level_started = true
		# 初始化关卡
		initialize_level()
 
# 检查关卡是否完成的条件
func is_level_complete():
	# 这里添加你的逻辑来检查玩家是否通过了关卡
	# 比如检查玩家是否到达了某个特定的位置或者战斗胜利
	return false
 
# 加载下一个关卡
func load_next_level():
	var next_level = "res://Levels/Level2.tscn"
	current_level = next_level
	get_tree().change_scene(next_level)
 
# 初始化关卡
func initialize_level():
	# 这里进行关卡的初始化，比如重置游戏状态
	if current_level == "res://Levels/Level1.tscn":
		var enemySpawner:EnemySpawner = EnemySpawner.new()
		get_node("")
		enemySpawner.generate_enemy(1, "res://Enemy/enemy.tscn") 
	
	pass
 
# 检查是否启动了新的关卡
func is_new_level_started():
	# 这里添加你的逻辑来检查玩家是否进入了新的关卡
	# 比如检查玩家是否移动到新的场景边界
	return false
