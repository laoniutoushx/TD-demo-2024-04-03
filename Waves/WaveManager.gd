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

class WaveSpawner:
	var start_delay
	var next_wave_delay
	var level_code
	var enemy_resource: EnemyResource


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
			var wave_spawner = _wave_spawner_init(wave_resource)
			# start
			_wave_spawner_start(wave_spawner)
	
	pass


func _wave_spawner_init(wave_resource: WaveResource) -> WaveSpawner:
	var wave_spawner = WaveSpawner.new()
	wave_spawner.next_wave_delay = wave_resource.next_wave_delay
	wave_spawner.start_delay = wave_resource.start_delay
	# level code assign
	# enemy resource load
	
	
	enemy_resource
	
	return wave_spawner


func _wave_spawner_start(wave_spawner:WaveSpawner):
	var start_delay = wave_spawner.start_delay
	# start delay
	if start_delay:
		CommonUtil.waiting_for(float(start_delay))
	
	# spawning
	
	
