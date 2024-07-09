class_name LevelResource
extends Resource

enum level_status {
	WAITING,
	RUNNING,
	END
}

@export var code: String
@export var name: String
@export var scene:PackedScene

@export var start_delay: float = 5.0
@export var end_delay: float = 5.0

@export var waves: Array[WaveResource]
