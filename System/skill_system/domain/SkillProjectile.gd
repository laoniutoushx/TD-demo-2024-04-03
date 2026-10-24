extends Node3D

signal hit(target)

var source
var target
var speed := 1.0
var max_lifetime := 15.0
var _elapsed := 0.0
var _visual: Node3D

func configure(origin, destination, visual: Node3D, velocity: float) -> void:
	source = origin
	target = destination
	speed = velocity
	_visual = visual
	add_child(visual)
	global_position = source.global_position + Vector3.UP * source._height * 0.5

func _physics_process(delta: float) -> void:
	_elapsed += delta
	if not is_instance_valid(source) or not is_instance_valid(target) or not target.is_alive() or speed <= 0.0 or _elapsed >= max_lifetime:
		queue_free()
		return
	var destination = target.global_position + Vector3.UP * target._height * 0.5
	var distance = global_position.distance_to(destination)
	if distance <= maxf(1.0, speed * delta):
		hit.emit(target)
		queue_free()
		set_physics_process(false)
		return
	global_position = global_position.move_toward(destination, speed * delta)
	if not global_position.is_equal_approx(destination):
		look_at(destination, Vector3.UP)
