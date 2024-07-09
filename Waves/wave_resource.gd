class_name WaveResource
extends Resource


@export_group("Wave")
@export var start_delay: float = 0.0
@export var next_wave_delay: float = 5.0
@export var wave_amount: int = 15
@export var level_code: String	# belong to which LevelManager


@export_group("Spawner")
@export var enemy_spawner: EnemySpawnerResource


