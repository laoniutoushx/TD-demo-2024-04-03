extends Camera3D

@onready var ray_cast_3d: RayCast3D = $RayCast3D
@export var grid_map: GridMap
@export var turret_manager: Node3D


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var mouse_position = get_viewport().get_mouse_position()
	var target = project_local_ray_normal(mouse_position)
	
	ray_cast_3d.target_position = project_local_ray_normal(mouse_position) * 100.0
	
	# 强制更新射线碰撞信息
	ray_cast_3d.force_raycast_update() 
	
	if ray_cast_3d.is_colliding():
		var collider = ray_cast_3d.get_collider()
		if collider is GridMap:
			Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
			if Input.is_action_pressed("click"):
				var point = ray_cast_3d.get_collision_point()
				var cell =  grid_map.local_to_map(point)
				if grid_map.get_cell_item(cell) == 0: 
					grid_map.set_cell_item(cell, 1)
					turret_manager.build_turret(grid_map.map_to_local(cell), null) 
			
	else:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
