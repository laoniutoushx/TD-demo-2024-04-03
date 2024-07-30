extends Node
class_name WaveManager

enum WaveState {
	WAITING,
	START,
	END
}

var current_state: WaveState
var wave_delay: float = 5.0	# 5s per wave interval

var level_controller: LevelController
var wave_resources: Array[WaveResource]

var 

class WaveSpawner:
	var start_delay
	var next_wave_delay
	var level_code
	var enemy_resource: EnemyResource
	signal finished


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
	for wave_resource in wave_resources:
		if wave_resource:
			# init
			var wave_spawner_and_enemy_spawner_res = _wave_spawner_init(wave_resource)
			# start
			var wave_spawner = _wave_spawner_start(wave_spawner_and_enemy_spawner_res)
			await wave_spawner.finished
	
	pass


func _wave_spawner_init(wave_resource: WaveResource) -> Array:
	var wave_spawner = WaveSpawner.new()
	wave_spawner.next_wave_delay = wave_resource.next_wave_delay
	wave_spawner.start_delay = wave_resource.start_delay
	# level code assign
	# enemy resource load
	var enemy_spawner_res: Array[EnemySpawnerResource] = wave_resource.enemy_spawner_resource as  Array[EnemySpawnerResource]
	
	#enemy_resource

	return [wave_spawner, enemy_spawner_res]


func _wave_spawner_start(wave_spawner_and_enemy_spawner_res:Array) -> WaveSpawner:
	var wave_spawner: WaveSpawner = wave_spawner_and_enemy_spawner_res[0]
	var enemy_spawner_reses: Array[EnemySpawnerResource] = wave_spawner_and_enemy_spawner_res[1]
	var start_delay = wave_spawner.start_delay
	# start delay
	if start_delay:
		CommonUtil.waiting_for(float(start_delay))
	
	# spawning
	for enemy_spawner_res: EnemySpawnerResource in enemy_spawner_reses:
		var enemy_spawner =  EnemySpawner.new(enemy_spawner_res, %Path3D, %StartMark, wave_spawner)
		enemy_spawner.start()
		
	return wave_spawner



	
	
	
