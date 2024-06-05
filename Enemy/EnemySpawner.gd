extends Node
class_name EnemySpawner



func generate_enemy(idx, path, enemy_res):
	if idx == 1:
		for i in 15:
			var enemy_scene = load(enemy_res)
			var enemy_instance = enemy_scene.instantiate()
			
			var start_node = path.get_parent().find_child("Start")
			enemy_instance.global_position = start_node.global_position

			
			# 查找 Path3d
			path.add_child(enemy_instance)
			await path.get_tree().create_timer(1.0).timeout

