extends Node
class_name EnemySpawner



func _init() -> void:
	# preload something
	# 第一波
	var wave_1 = {
		"model": "",
		"interval": 1,
		"num": 5
	}
	
	
	
	
	pass

func generate_enemy(idx, enemy_res):
	if idx == 1:
		var path = get_node("./Path3D")
		for i in 5:
			var enemy_scene = load(enemy_res)
			var enemy_instance = enemy_scene.instance()
			# 查找 Path3d
			path.add_child(enemy_instance)
			await get_tree().creater_timer(1.0).timeout

