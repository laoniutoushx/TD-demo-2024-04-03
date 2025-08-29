extends Node
# @trait
class_name WaveManager

enum WaveState {
	WAITING,
	START,
	END
}

var cur_wave_index: int = 1
var current_state: WaveState
var wave_delay: float = 5.0	# 5s per wave interval

var level_controller: LevelController
var wave_resources: Array[WaveResource]

var cur_wave_spawner

class WaveSpawner:
	var start_delay
	var next_wave_delay
	var level_code
	var enemy_spawner_reses: Array[EnemySpawnerResource]
	signal spawning_finished		# is finished spawing
	var finished_enemy_spawner_counter := 0		# EnemySpawner finished counter

	# Note 是否完成
	func finish_listener():
		finished_enemy_spawner_counter += 1
		if finished_enemy_spawner_counter == enemy_spawner_reses.size():
			print("finished wave spawner")
			spawning_finished.emit()
		


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_state = WaveState.WAITING
	
	# waiting for scene loaded, get levelresource

	print("wave manager ready")
	print(get_tree().get_meta(Constants.WAVE_RESOURCE))
	
	
	
	wave_resources = get_tree().get_meta(Constants.WAVE_RESOURCE) as Array[WaveResource]
	wave_start()
	pass # Replace with function body.


func wave_start():
	for idx in wave_resources.size():	
		var wave_resource: WaveResource = wave_resources[idx]
		if wave_resource:

			cur_wave_index = idx + 1

			SignalBus.wave_start.emit(idx, wave_resource, wave_resources)
			print("wave start: ", idx, wave_resource.level_code)

			# init
			var wave_spawner = _wave_spawner_initial(wave_resource)

			# start_delay
			await CommonUtil.await_timer(wave_spawner.start_delay)

			# start
			_wave_spawner_start(wave_spawner)

			# next_wave_delay
			await CommonUtil.await_timer(wave_spawner.next_wave_delay)

			# waiting for wave_spawner over
			await wave_spawner.spawning_finished
	
	pass


func _wave_spawner_initial(wave_resource: WaveResource) -> WaveSpawner:
	var wave_spawner = WaveSpawner.new()
	wave_spawner.next_wave_delay = wave_resource.next_wave_delay
	wave_spawner.start_delay = wave_resource.start_delay
	
	# level code assign
	# enemy resource load
	var enemy_spawner_res: Array[EnemySpawnerResource] = wave_resource.enemy_spawner_resource as  Array[EnemySpawnerResource]
	wave_spawner.enemy_spawner_reses = enemy_spawner_res
	
	#enemy_resource

	return wave_spawner


func _wave_spawner_start(wave_spawner: WaveManager.WaveSpawner) -> WaveSpawner:
	cur_wave_spawner = wave_spawner		# 当前 wave spawner 保存
	var enemy_spawner_reses: Array[EnemySpawnerResource] = wave_spawner.enemy_spawner_reses
	
	# spawning	(parallel spawning unit)
	for enemy_spawner_res: EnemySpawnerResource in enemy_spawner_reses:
		var enemy_spawner: EnemySpawner =  EnemySpawner.new(enemy_spawner_res, %Path3D, %StartMark, wave_spawner)
		#var enemy_spawner =  EnemySpawner.new(enemy_spawner_res, %OffsetNode, %StartMark, wave_spawner)

		enemy_spawner.start()
	
	return wave_spawner



	
	
	
