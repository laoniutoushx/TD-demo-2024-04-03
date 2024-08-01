extends Area3D


var target: Node3D
var starting_position: Vector3


var lerp_pos: float = 0
@export var speed: float
@export var damage: float


func _ready() -> void:
	global_position = starting_position


func _physics_process(delta: float) -> void:
	if target != null:
		if lerp_pos < 1: 
			self.look_at(target.global_position)
			var aabb = target.find_child("MeshInstance3D").mesh.get_aabb()
			var height = aabb.size.y
			global_position = starting_position.lerp(Vector3(target.global_position.x, height / 2, target.global_position.z), lerp_pos)
			lerp_pos += delta * speed
		else:
			target.take_damage(damage)
			queue_free()
	else:
		queue_free()
	

