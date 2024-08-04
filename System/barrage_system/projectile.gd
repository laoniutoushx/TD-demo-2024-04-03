extends Node3D

var source: Node
var target: Node
var fire_pos: Vector3
var lerp_pos: float = 0


@export var speed: float
@export var damage: float


func _physics_process(delta: float) -> void:
	if target != null:
		if lerp_pos < 1: 
			self.look_at(target.global_position)
			var aabb = target.find_child("MeshInstance3D").mesh.get_aabb()
			var height = aabb.size.y
			global_position = fire_pos.lerp(Vector3(target.global_position.x, height / 2, target.global_position.z), lerp_pos)
			lerp_pos += delta * speed
		else:
			target.take_damage(damage)
			queue_free()
	else:
		queue_free()
	

