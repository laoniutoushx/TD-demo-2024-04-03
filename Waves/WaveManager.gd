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
var is_game_over: bool = false

var level_controller: LevelController
var wave_resources: Array[WaveResource]

var cur_wave_spawner
var all_spawning_finished := false
var live_enemies: Dictionary = {}
var wave_live_counts: Dictionary = {}
signal wave_cleared(index: int)
var generated_waves: Dictionary = {}
var cleared_waves: Dictionary = {}
var generation := 0

func cancel_spawning() -> void:
	is_game_over = true
	generation += 1
	for child in get_children():
		if child is EnemySpawner: child._on_game_over()
	if cur_wave_spawner != null and not cur_wave_spawner.finished:
		cur_wave_spawner.finished = true
		cur_wave_spawner.spawning_finished.emit()

func register_enemy(enemy: Enemy, index: int) -> void:
	var id := enemy.get_instance_id()
	live_enemies[id] = index
	wave_live_counts[index] = wave_live_counts.get(index, 0) + 1
	enemy.logical_death.connect(func(_unit): _enemy_left(id), CONNECT_ONE_SHOT)
	enemy.tree_exiting.connect(_enemy_left.bind(id), CONNECT_ONE_SHOT)

func _enemy_left(id: int) -> void:
	if not live_enemies.has(id): return
	var index: int = live_enemies[id]
	live_enemies.erase(id)
	wave_live_counts[index] = maxi(0, wave_live_counts.get(index, 0) - 1)
	_check_clear.call_deferred()

func _check_clear() -> void:
	if is_game_over or not is_inside_tree(): return
	for index in generated_waves:
		if wave_live_counts.get(index, 0) == 0 and not cleared_waves.has(index):
			cleared_waves[index] = true
			wave_cleared.emit(index)
	if all_spawning_finished and live_enemies.is_empty():
		var base = get_tree().get_first_node_in_group("base")
		if is_instance_valid(base) and base.current_life > 0:
			SOS.main.level_controller.finish_battle(true)


class WaveSpawner:
	var start_delay
	var next_wave_delay
	var level_code
	var enemy_spawner_reses: Array[EnemySpawnerResource]
	signal spawning_finished		# is finished spawing
	var finished_enemy_spawner_counter := 0
	var finished := false		# EnemySpawner finished counter
	var wave_index := -1

	# Note 是否完成
	func finish_listener():
		finished_enemy_spawner_counter += 1
		if finished_enemy_spawner_counter == enemy_spawner_reses.size():
			CommonUtil.debug_log(["finished wave spawner"])
			finished = true
			spawning_finished.emit()
	


		


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_state = WaveState.WAITING
	
	# waiting for scene loaded, get levelresource

	CommonUtil.debug_log(["wave manager ready"])
	CommonUtil.debug_log([get_tree().get_meta(Constants.WAVE_RESOURCE)])
	
	# game over listener
	SignalBus.game_over.connect(self._on_game_over)
	
	wave_resources = get_tree().get_meta(Constants.WAVE_RESOURCE) as Array[WaveResource]
	wave_start()
	pass # Replace with function body.


func wave_start():
	var started_generation := generation
	for idx in wave_resources.size():	
		if is_game_over or started_generation != generation:
			return
			
		var wave_resource: WaveResource = wave_resources[idx]
		if wave_resource:

			cur_wave_index = idx + 1

			SignalBus.wave_start.emit(idx, wave_resource, wave_resources)
			CommonUtil.debug_log(["wave start: ", idx, wave_resource.level_code])

			# init
			var wave_spawner = _wave_spawner_initial(wave_resource)

			# start_delay
			await CommonUtil.await_timer(wave_spawner.start_delay)
			if not is_inside_tree() or is_game_over or started_generation != generation:
				return

			# start
			_wave_spawner_start(wave_spawner)

			# next_wave_delay
			await CommonUtil.await_timer(wave_spawner.next_wave_delay)
			if not is_inside_tree() or is_game_over or started_generation != generation:
				return			

			# waiting for wave_spawner over
			if not wave_spawner.finished:
				await wave_spawner.spawning_finished
			if not is_inside_tree() or is_game_over or started_generation != generation:
				return			
			generated_waves[cur_wave_index] = true
			_check_clear()
	all_spawning_finished = true
	_check_clear.call_deferred()


func _wave_spawner_initial(wave_resource: WaveResource) -> WaveSpawner:
	var wave_spawner = WaveSpawner.new()
	wave_spawner.next_wave_delay = wave_resource.next_wave_delay
	wave_spawner.start_delay = wave_resource.start_delay
	wave_spawner.wave_index = cur_wave_index
	
	# level code assign
	# enemy resource load
	var enemy_spawner_res: Array[EnemySpawnerResource] = wave_resource.enemy_spawner_resource as  Array[EnemySpawnerResource]
	wave_spawner.enemy_spawner_reses = enemy_spawner_res
	
	#enemy_resource

	return wave_spawner


func _wave_spawner_start(wave_spawner: WaveManager.WaveSpawner) -> WaveSpawner:
	cur_wave_spawner = wave_spawner		# 当前 wave spawner 保存
	var enemy_spawner_reses: Array[EnemySpawnerResource] = wave_spawner.enemy_spawner_reses
	if enemy_spawner_reses.is_empty():
		wave_spawner.finished = true
		wave_spawner.spawning_finished.emit()
	
	# spawning	(parallel spawning unit)
	for enemy_spawner_res: EnemySpawnerResource in enemy_spawner_reses:
		if is_game_over:
			return wave_spawner
			
		var enemy_spawner: EnemySpawner = EnemySpawner.new(enemy_spawner_res, %Path3D, %StartMark, wave_spawner)
		#var enemy_spawner =  EnemySpawner.new(enemy_spawner_res, %OffsetNode, %StartMark, wave_spawner)

		add_child(enemy_spawner)
		enemy_spawner.start()
	
	return wave_spawner



func _on_game_over():
	cancel_spawning()
	if cur_wave_spawner != null and not cur_wave_spawner.finished:
		cur_wave_spawner.finished = true
		cur_wave_spawner.spawning_finished.emit()
	
	
