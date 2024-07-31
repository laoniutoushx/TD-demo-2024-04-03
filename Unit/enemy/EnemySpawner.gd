extends Node
class_name EnemySpawner

var _enemy_spawner_res: EnemySpawnerResource
var _path: Node
var _start_node: Marker3D

signal enemy_spawn_finished



func _init(enemy_spawner_res: EnemySpawnerResource, path: Node, start_node: Node, wave_spawner: WaveManager.WaveSpawner) -> void:
	_enemy_spawner_res = enemy_spawner_res
	_path = path
	_start_node = start_node
	
	# bind spawning end event
	enemy_spawn_finished.connect(wave_spawner.finish_listener)

func start():
	# spawning

	for i in _enemy_spawner_res.enemy_amount:
	
		# enemy res name
		var enemy_res_name = _enemy_spawner_res.enemy_res_name
		# load enemy resource file
		var enemy_resource:EnemyResource = load("res://Unit/enemy/enemy_resources/%s.tres" % enemy_res_name)
		
		# generate enemy instance
		var enemy_instance: Enemy = enemy_resource.model_path.instantiate()
		enemy_instance.move_speed = enemy_resource.move_speed
		enemy_instance.max_health = enemy_resource.max_health
		
		if _start_node != null:
			enemy_instance.global_position = _start_node.global_position
		#enemy_instance.find_child()

		
		# 查找 Path3d
		if _path != null:
			_path.add_child(enemy_instance)
			await _path.get_tree().create_timer(_enemy_spawner_res.spawn_interval).timeout
			print("generate 1", enemy_instance)
	
	# emit spawning end signal
	enemy_spawn_finished.emit()
