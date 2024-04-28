extends Node3D
class_name TurretManager


func build_turret(turret: PackedScene, position: Vector3, turret_code) -> void:
	var new_turret = turret.instantiate()
	new_turret.global_position = position
	add_child(new_turret)


# 炮塔应该有状态机来控制，状态应该包括（idle/patrolling/aimming/attacking/）
