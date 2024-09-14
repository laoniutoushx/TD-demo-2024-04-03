extends Node3D
class_name TurretManager

@export var turret: PackedScene
var ray_picker: RayPicker

@alias()
var turret_manager:TurretManager




func _ready() -> void:
	
	pass


func build_turret(position: Vector3, turret_code) -> void:
	var new_turret = turret.instantiate()
	new_turret.global_position = position
	add_child(new_turret)


# 炮塔应该有状态机来控制，状态应该包括（idle/patrolling/aimming/attacking/）



# 注册 build_turret function 到 RayPicker
func callable_build_turret(collider: Object, ray_cast_3d: RayCast3D, grid_map: GridMap) -> void:
	if collider is GridMap:
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
		if Input.is_action_pressed("click"):
			var point = ray_cast_3d.get_collision_point()
			var cell =  grid_map.local_to_map(point)
			if grid_map.get_cell_item(cell) == 0: 
				grid_map.set_cell_item(cell, 1)

				# TODO 逻辑耦合 buliding turret
				self.build_turret(grid_map.map_to_local(cell), null) 