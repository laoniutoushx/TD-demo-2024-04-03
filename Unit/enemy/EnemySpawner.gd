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
	enemy_spawn_finished.connect(wave_spawner.finish_listener, CONNECT_ONE_SHOT)

func start():
	# spawning

	await CommonUtil.await_timer(_enemy_spawner_res.spawn_start_delay)

	for i in _enemy_spawner_res.enemy_amount:
	
		# enemy res name
		var enemy_res_name = _enemy_spawner_res.enemy_res_name
		# load enemy resource file
		var enemy_resource:EnemyResource = load("res://Unit/enemy/resources/%s.tres" % enemy_res_name)
		
		# generate enemy instance
		var enemy_instance: Enemy = SystemUtil.unit_system.create_unit(enemy_resource, 1)
		
		# y offset
		enemy_instance.v_offset = _start_node.global_position.y
		


		
		# 查找 Path3d
		if _path != null:
			_path.add_child(enemy_instance)

			if _start_node != null:
				enemy_instance.global_position = _start_node.global_position
			#enemy_instance.find_child()

			await CommonUtil.await_timer(_enemy_spawner_res.spawn_interval)

	
	# emit spawning end signal
	enemy_spawn_finished.emit()
