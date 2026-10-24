extends Node3D

signal finished()
signal resolved(position: Vector3, arrived: bool)

var source: Node3D
var target: Node3D
var fire_pos: Vector3
var lerp_pos := 0.0
@export var arc_factor := 4.0
@export var max_lifetime := 15.0
var speed: float
var damage: float
var _elapsed := 0.0
var _arrived := false

func _ready() -> void:
	global_position = fire_pos

func _physics_process(delta: float) -> void:
	_elapsed += delta
	if not is_instance_valid(source) or not is_instance_valid(target) or target.is_logic_dead() or speed <= 0.0 or _elapsed >= max_lifetime:
		queue_free()
		return
	var target_pos = Vector3(target.global_position.x, target._height / 2, target.global_position.z)
	var distance = fire_pos.distance_to(target_pos)
	lerp_pos = clampf(lerp_pos + delta * speed / maxf(distance, 0.001), 0.0, 1.0)
	var straight_pos = fire_pos.lerp(target_pos, lerp_pos)
	global_position = straight_pos + Vector3.UP * arc_factor * lerp_pos * (1.0 - lerp_pos)
	CommonUtil.safe_look_at(self, global_position, target_pos)
	if lerp_pos >= 1.0 or global_position.distance_to(target_pos) < 1.0:
		_arrived = true
		finished.emit()
		queue_free()

func _exit_tree() -> void:
	resolved.emit(global_position, _arrived)
